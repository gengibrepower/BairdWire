const std = @import("std");
const connection = @import("connection.zig");
const protocol = @import("protocol.zig");
const rtp = @import("rtp.zig");
const sdp = @import("sdp.zig");

pub const ConnId = u64;
pub const PcId = u64;
pub const TrackId = i32;
pub const Role = protocol.Role;

pub const PcState = enum { connecting, connected, disconnected, failed, closed };
pub const DescriptionKind = enum { offer, answer };

pub const sink_mid = "0";

pub const Event = union(enum) {
    opened: struct { id: ConnId, now: i64 },
    text: struct { id: ConnId, payload: []const u8 },
    binary: ConnId,
    closed: ConnId,
    tick: i64,
    rtc_description: struct { pc: PcId, sdp: []const u8 },
    rtc_track: struct { pc: PcId, track: TrackId, description: []const u8 },
    rtc_media: struct { pc: PcId, track: TrackId, packet: []const u8 },
    rtc_state: struct { pc: PcId, state: PcState },

    pub fn free(event: Event, gpa: std.mem.Allocator) void {
        switch (event) {
            .text => |text| gpa.free(text.payload),
            .rtc_description => |description| gpa.free(description.sdp),
            .rtc_track => |track| gpa.free(track.description),
            .rtc_media => |media| gpa.free(media.packet),
            .opened, .binary, .closed, .tick, .rtc_state => {},
        }
    }
};

pub const OutgoingTrack = struct { mid: []const u8, payload_type: u8, ssrc: u32 };

pub const Effect = union(enum) {
    send: struct { id: ConnId, payload: []const u8 },
    close: struct { id: ConnId, code: u16 },
    rtc_create: struct { pc: PcId, track: ?OutgoingTrack },
    rtc_remote_description: struct { pc: PcId, kind: DescriptionKind, sdp: []const u8 },
    rtc_remote_candidate: struct { pc: PcId, candidate: []const u8, mid: []const u8 },
    rtc_send: struct { pc: PcId, mid: []const u8, packet: []const u8 },
    rtc_close: PcId,
};

pub const Effects = std.ArrayList(Effect);

const Peer = struct { conn: ConnId, role: Role };

const RequestId = struct {
    bytes: [protocol.max_id_len]u8 = undefined,
    len: usize = 0,

    fn init(value: []const u8) RequestId {
        var id: RequestId = .{ .len = value.len };
        @memcpy(id.bytes[0..value.len], value);
        return id;
    }

    fn slice(id: *const RequestId) []const u8 {
        return id.bytes[0..id.len];
    }
};

const Call = struct {
    publish: ?Publish = null,
    subscribe: ?Subscribe = null,

    const Publish = struct {
        pc: PcId,
        offer_id: RequestId,
        answered: bool = false,
        source: ?TrackId = null,
    };

    const Subscribe = struct {
        pc: PcId,
        ssrc: u32,
        payload_type: u8,
        offered: bool = false,
        answered: bool = false,
    };
};

pub const Node = struct {
    gpa: std.mem.Allocator,
    version: []const u8,
    prng: std.Random.DefaultPrng,
    next_pc: PcId = 1,
    connections: std.AutoHashMapUnmanaged(ConnId, connection.Connection) = .empty,
    calls: std.AutoHashMapUnmanaged(ConnId, Call) = .empty,
    peers: std.AutoHashMapUnmanaged(PcId, Peer) = .empty,

    pub fn init(gpa: std.mem.Allocator, version: []const u8, seed: u64) Node {
        return .{ .gpa = gpa, .version = version, .prng = .init(seed) };
    }

    pub fn deinit(node: *Node) void {
        node.connections.deinit(node.gpa);
        node.calls.deinit(node.gpa);
        node.peers.deinit(node.gpa);
    }

    pub fn handle(node: *Node, arena: std.mem.Allocator, event: Event, effects: *Effects) std.mem.Allocator.Error!void {
        switch (event) {
            .opened => |opened| try node.connections.put(node.gpa, opened.id, .init(opened.now, node.version)),
            .closed => |id| {
                _ = node.connections.remove(id);
                try node.endCall(arena, id, effects);
            },
            .text => |text| try node.forward(arena, text.id, .{ .text = text.payload }, effects),
            .binary => |id| try node.forward(arena, id, .binary, effects),
            .tick => |now| {
                var it = node.connections.iterator();
                while (it.next()) |entry| try node.deliver(arena, entry.key_ptr.*, entry.value_ptr, .{ .tick = now }, effects);
            },
            .rtc_description => |description| try node.onLocalDescription(arena, description.pc, description.sdp, effects),
            .rtc_track => |track| try node.onTrack(arena, track.pc, track.track, track.description, effects),
            .rtc_media => |media| try node.onMedia(arena, media.pc, media.track, media.packet, effects),
            .rtc_state => |change| switch (change.state) {
                .failed, .closed => if (node.peers.get(change.pc)) |peer| try node.endCall(arena, peer.conn, effects),
                .connecting, .connected, .disconnected => {},
            },
        }
    }

    fn forward(node: *Node, arena: std.mem.Allocator, id: ConnId, event: connection.Event, effects: *Effects) !void {
        const conn = node.connections.getPtr(id) orelse return;
        try node.deliver(arena, id, conn, event, effects);
    }

    fn deliver(node: *Node, arena: std.mem.Allocator, id: ConnId, conn: *connection.Connection, event: connection.Event, effects: *Effects) !void {
        var produced: connection.Effects = .empty;
        try conn.handle(arena, event, &produced);
        for (produced.items) |effect| switch (effect) {
            .send => |payload| try effects.append(arena, .{ .send = .{ .id = id, .payload = payload } }),
            .close => |code| try effects.append(arena, .{ .close = .{ .id = id, .code = code } }),
            .signal => |signaled| try node.onSignal(arena, id, signaled, effects),
        };
    }

    fn onSignal(node: *Node, arena: std.mem.Allocator, conn: ConnId, signaled: connection.Signaled, effects: *Effects) !void {
        switch (signaled.signal) {
            .offer => |offer| {
                const entry = try node.calls.getOrPut(node.gpa, conn);
                if (!entry.found_existing) entry.value_ptr.* = .{};
                const call = entry.value_ptr;
                if (call.publish != null) return node.reject(arena, conn, signaled.id, effects);

                const pc = try node.addPeer(conn, .publish);
                call.publish = .{ .pc = pc, .offer_id = .init(signaled.id.?) };
                try effects.append(arena, .{ .rtc_create = .{ .pc = pc, .track = null } });
                try effects.append(arena, .{ .rtc_remote_description = .{ .pc = pc, .kind = .offer, .sdp = offer.sdp } });
            },
            .answer => |answer| {
                const call = node.calls.getPtr(conn) orelse return node.reject(arena, conn, signaled.re, effects);
                const subscribe = if (call.subscribe) |*subscribe| subscribe else return node.reject(arena, conn, signaled.re, effects);
                const expected = try subscribeOfferId(arena, subscribe.pc);
                if (!subscribe.offered or subscribe.answered or !std.mem.eql(u8, signaled.re.?, expected))
                    return node.reject(arena, conn, signaled.re, effects);

                subscribe.answered = true;
                try effects.append(arena, .{ .rtc_remote_description = .{ .pc = subscribe.pc, .kind = .answer, .sdp = answer.sdp } });
            },
            .candidate => |candidate| {
                const call = node.calls.getPtr(conn) orelse return node.reject(arena, conn, signaled.id, effects);
                const pc = switch (candidate.pc) {
                    .publish => if (call.publish) |publish| publish.pc else null,
                    .subscribe => if (call.subscribe) |subscribe| (if (subscribe.answered) subscribe.pc else null) else null,
                } orelse return node.reject(arena, conn, signaled.id, effects);
                if (candidate.candidate.len == 0) return;
                try effects.append(arena, .{ .rtc_remote_candidate = .{ .pc = pc, .candidate = candidate.candidate, .mid = candidate.mid } });
            },
        }
    }

    fn onLocalDescription(node: *Node, arena: std.mem.Allocator, pc: PcId, local_sdp: []const u8, effects: *Effects) !void {
        const peer = node.peers.get(pc) orelse return;
        const call = node.calls.getPtr(peer.conn) orelse return;
        switch (peer.role) {
            .publish => {
                const publish = if (call.publish) |*publish| publish else return;
                if (publish.pc != pc or publish.answered) return;
                publish.answered = true;
                const message = try protocol.rtcDescription(arena, .answer, null, publish.offer_id.slice(), .publish, local_sdp);
                try effects.append(arena, .{ .send = .{ .id = peer.conn, .payload = message } });
            },
            .subscribe => {
                const subscribe = if (call.subscribe) |*subscribe| subscribe else return;
                if (subscribe.pc != pc or subscribe.offered) return;
                subscribe.offered = true;
                const id = try subscribeOfferId(arena, pc);
                const message = try protocol.rtcDescription(arena, .offer, id, null, .subscribe, local_sdp);
                try effects.append(arena, .{ .send = .{ .id = peer.conn, .payload = message } });
            },
        }
    }

    fn onTrack(node: *Node, arena: std.mem.Allocator, pc: PcId, track: TrackId, description: []const u8, effects: *Effects) !void {
        const peer = node.peers.get(pc) orelse return;
        if (peer.role != .publish) return;
        const call = node.calls.getPtr(peer.conn) orelse return;
        const publish = if (call.publish) |*publish| publish else return;
        if (publish.source != null) return;
        const payload_type = sdp.opusPayloadType(description) orelse return;
        publish.source = track;

        if (call.subscribe != null) return;
        const subscribe_pc = try node.addPeer(peer.conn, .subscribe);
        const ssrc = node.prng.random().intRangeAtMost(u32, 1, std.math.maxInt(u32));
        call.subscribe = .{ .pc = subscribe_pc, .ssrc = ssrc, .payload_type = payload_type };
        try effects.append(arena, .{ .rtc_create = .{
            .pc = subscribe_pc,
            .track = .{ .mid = sink_mid, .payload_type = payload_type, .ssrc = ssrc },
        } });
    }

    fn onMedia(node: *Node, arena: std.mem.Allocator, pc: PcId, track: TrackId, packet: []const u8, effects: *Effects) !void {
        const peer = node.peers.get(pc) orelse return;
        if (peer.role != .publish) return;
        const call = node.calls.getPtr(peer.conn) orelse return;
        const publish = call.publish orelse return;
        if (publish.source != track) return;
        const subscribe = call.subscribe orelse return;
        if (!subscribe.answered) return;
        if (!rtp.isRtp(packet) or rtp.payloadType(packet) != subscribe.payload_type) return;

        const echoed = try arena.dupe(u8, packet);
        rtp.setSsrc(echoed, subscribe.ssrc);
        try effects.append(arena, .{ .rtc_send = .{ .pc = subscribe.pc, .mid = sink_mid, .packet = echoed } });
    }

    fn endCall(node: *Node, arena: std.mem.Allocator, conn: ConnId, effects: *Effects) !void {
        const entry = node.calls.fetchRemove(conn) orelse return;
        const call = entry.value;
        if (call.publish) |publish| try node.removePeer(arena, publish.pc, effects);
        if (call.subscribe) |subscribe| try node.removePeer(arena, subscribe.pc, effects);
    }

    fn addPeer(node: *Node, conn: ConnId, role: Role) !PcId {
        const pc = node.next_pc;
        try node.peers.put(node.gpa, pc, .{ .conn = conn, .role = role });
        node.next_pc += 1;
        return pc;
    }

    fn removePeer(node: *Node, arena: std.mem.Allocator, pc: PcId, effects: *Effects) !void {
        _ = node.peers.remove(pc);
        try effects.append(arena, .{ .rtc_close = pc });
    }

    fn reject(_: *Node, arena: std.mem.Allocator, conn: ConnId, re: ?[]const u8, effects: *Effects) !void {
        const message = try protocol.errorMessage(arena, re, .invalid_state);
        try effects.append(arena, .{ .send = .{ .id = conn, .payload = message } });
    }
};

fn subscribeOfferId(arena: std.mem.Allocator, pc: PcId) ![]const u8 {
    return std.fmt.allocPrint(arena, "subscribe-{d}", .{pc});
}
