const std = @import("std");
const c = @import("rtc_c");
const core = @import("core");
const node = core.node;

const log = std.log.scoped(.webrtc);

pub const Events = std.Io.Queue(node.Event);

pub const Config = struct {
    bind_address: ?[:0]const u8 = null,
    udp_port: u16 = 0,
};

const Sink = struct { mid: []const u8, track: c_int };
const Handles = struct { pc: c_int, sink: ?Sink = null };

const Context = struct { io: std.Io, gpa: std.mem.Allocator, events: *Events };

// Os callbacks da libdatachannel rodam nas threads dela e só recebem um ponteiro opaco.
// O ponteiro carrega o PcId como inteiro, e não um endereço, porque um callback pode
// rodar depois do rtcDelete e encontraria memória já liberada.
var context: ?Context = null;

pub const Peers = struct {
    gpa: std.mem.Allocator,
    config: Config,
    handles: std.AutoHashMapUnmanaged(node.PcId, Handles) = .empty,

    pub fn start(io: std.Io, gpa: std.mem.Allocator, events: *Events, config: Config) Peers {
        context = .{ .io = io, .gpa = gpa, .events = events };
        c.rtcInitLogger(c.RTC_LOG_WARNING, onLog);
        return .{ .gpa = gpa, .config = config };
    }

    pub fn stop(peers: *Peers) void {
        var it = peers.handles.valueIterator();
        while (it.next()) |handles| _ = c.rtcDeletePeerConnection(handles.pc);
        peers.handles.deinit(peers.gpa);
        c.rtcCleanup();
        context = null;
    }

    pub fn dispatch(peers: *Peers, effect: node.Effect) void {
        peers.apply(effect) catch |err| switch (err) {
            error.OutOfMemory => log.err("sem memória ao aplicar um efeito de WebRTC", .{}),
            error.Rtc => failed(effect),
        };
    }

    fn apply(peers: *Peers, effect: node.Effect) !void {
        switch (effect) {
            .send, .close => unreachable,
            .rtc_create => |request| try peers.create(request.pc, request.track),
            .rtc_remote_description => |remote| {
                const handles = peers.handles.get(remote.pc) orelse return;
                const sdp = try peers.gpa.dupeSentinel(u8, remote.sdp, 0);
                defer peers.gpa.free(sdp);
                try check(c.rtcSetRemoteDescription(handles.pc, sdp, @tagName(remote.kind)));
            },
            .rtc_remote_candidate => |remote| {
                const handles = peers.handles.get(remote.pc) orelse return;
                const candidate = try peers.gpa.dupeSentinel(u8, remote.candidate, 0);
                defer peers.gpa.free(candidate);
                const mid = try peers.gpa.dupeSentinel(u8, remote.mid, 0);
                defer peers.gpa.free(mid);
                // Candidatos mDNS (.local) do navegador não resolvem aqui. O ICE segue pelos
                // candidatos do nó e pelos peer-reflexive, então a falha é esperada e ignorada.
                _ = c.rtcAddRemoteCandidate(handles.pc, candidate, mid);
            },
            .rtc_send => |send| {
                const handles = peers.handles.get(send.pc) orelse return;
                const sink = handles.sink orelse return;
                if (!std.mem.eql(u8, sink.mid, send.mid)) return;
                _ = c.rtcSendMessage(sink.track, send.packet.ptr, @intCast(send.packet.len));
            },
            .rtc_close => |pc| {
                const entry = peers.handles.fetchRemove(pc) orelse return;
                _ = c.rtcDeletePeerConnection(entry.value.pc);
            },
        }
    }

    fn create(peers: *Peers, id: node.PcId, track: ?node.OutgoingTrack) !void {
        var config = std.mem.zeroes(c.rtcConfiguration);
        if (peers.config.bind_address) |address| config.bindAddress = address;
        if (peers.config.udp_port != 0) {
            config.enableIceUdpMux = true;
            config.portRangeBegin = peers.config.udp_port;
            config.portRangeEnd = peers.config.udp_port;
        }

        const pc = c.rtcCreatePeerConnection(&config);
        try check(pc);
        errdefer _ = c.rtcDeletePeerConnection(pc);
        c.rtcSetUserPointer(pc, pcPointer(id));
        try check(c.rtcSetStateChangeCallback(pc, onState));
        try check(c.rtcSetGatheringStateChangeCallback(pc, onGathering));
        try check(c.rtcSetTrackCallback(pc, onTrack));

        var handles: Handles = .{ .pc = pc };
        if (track) |outgoing| {
            const mid = try peers.gpa.dupeSentinel(u8, outgoing.mid, 0);
            defer peers.gpa.free(mid);
            var init = std.mem.zeroes(c.rtcTrackInit);
            init.direction = c.RTC_DIRECTION_SENDONLY;
            init.codec = c.RTC_CODEC_OPUS;
            init.payloadType = outgoing.payload_type;
            init.ssrc = outgoing.ssrc;
            init.mid = mid;
            init.name = "eco";
            init.msid = "bairdwire";
            init.trackId = "eco";
            const sink_track = c.rtcAddTrackEx(pc, &init);
            try check(sink_track);
            handles.sink = .{ .mid = node.sink_mid, .track = sink_track };
        }
        try peers.handles.put(peers.gpa, id, handles);
        errdefer _ = peers.handles.remove(id);
        if (track != null) try check(c.rtcSetLocalDescription(pc, "offer"));
    }

    fn failed(effect: node.Effect) void {
        const pc = switch (effect) {
            .rtc_create => |request| request.pc,
            .rtc_remote_description => |remote| remote.pc,
            else => return,
        };
        enqueue(.{ .rtc_state = .{ .pc = pc, .state = .failed } });
    }
};

fn check(result: c_int) error{Rtc}!void {
    if (result < 0) return error.Rtc;
}

fn pcPointer(id: node.PcId) ?*anyopaque {
    return @ptrFromInt(@as(usize, @intCast(id)));
}

fn pcId(pointer: ?*anyopaque) node.PcId {
    return @intFromPtr(pointer);
}

fn enqueue(event: node.Event) void {
    const ctx = context orelse return;
    ctx.events.putOneUncancelable(ctx.io, event) catch event.free(ctx.gpa);
}

fn enqueueOrDrop(event: node.Event) void {
    const ctx = context orelse return;
    const put = ctx.events.putUncancelable(ctx.io, &.{event}, 0) catch 0;
    if (put == 0) event.free(ctx.gpa);
}

fn copyFromLibrary(comptime getter: anytype, id: c_int) ?[]u8 {
    const ctx = context orelse return null;
    const size = getter(id, null, 0);
    if (size <= 1) return null;
    const buffer = ctx.gpa.alloc(u8, @intCast(size)) catch return null;
    defer ctx.gpa.free(buffer);
    if (getter(id, buffer.ptr, size) != size) return null;
    return ctx.gpa.dupe(u8, buffer[0 .. buffer.len - 1]) catch null;
}

fn onGathering(pc: c_int, state: c.rtcGatheringState, pointer: ?*anyopaque) callconv(.c) void {
    if (state != c.RTC_GATHERING_COMPLETE) return;
    const sdp = copyFromLibrary(c.rtcGetLocalDescription, pc) orelse return;
    enqueue(.{ .rtc_description = .{ .pc = pcId(pointer), .sdp = sdp } });
}

fn onState(_: c_int, state: c.rtcState, pointer: ?*anyopaque) callconv(.c) void {
    const mapped: node.PcState = switch (state) {
        c.RTC_CONNECTING => .connecting,
        c.RTC_CONNECTED => .connected,
        c.RTC_DISCONNECTED => .disconnected,
        c.RTC_FAILED => .failed,
        c.RTC_CLOSED => .closed,
        else => return,
    };
    enqueue(.{ .rtc_state = .{ .pc = pcId(pointer), .state = mapped } });
}

fn onTrack(_: c_int, track: c_int, pointer: ?*anyopaque) callconv(.c) void {
    c.rtcSetUserPointer(track, pointer);
    if (c.rtcSetMessageCallback(track, onMessage) < 0) return;
    const description = copyFromLibrary(c.rtcGetTrackDescription, track) orelse return;
    enqueue(.{ .rtc_track = .{ .pc = pcId(pointer), .track = track, .description = description } });
}

fn onMessage(track: c_int, data: [*c]const u8, size: c_int, pointer: ?*anyopaque) callconv(.c) void {
    if (size <= 0) return;
    const ctx = context orelse return;
    const packet = ctx.gpa.dupe(u8, data[0..@intCast(size)]) catch return;
    enqueueOrDrop(.{ .rtc_media = .{ .pc = pcId(pointer), .track = track, .packet = packet } });
}

fn onLog(level: c.rtcLogLevel, message: [*c]const u8) callconv(.c) void {
    const text = std.mem.span(message);
    if (isExpectedNoise(text)) return;
    var buffer: [512]u8 = undefined;
    const redacted = redact(&buffer, text);
    switch (level) {
        c.RTC_LOG_FATAL, c.RTC_LOG_ERROR => log.err("{s}", .{redacted}),
        else => log.warn("{s}", .{redacted}),
    }
}

// O Firefox manda candidatos TCP, e o libjuice avisa uma vez por candidato que
// ignorou cada um, porque o nó não tem ICE-TCP (P5).
const expected_noise = [_][]const u8{"ICE-TCP is disabled, ignoring TCP candidate"};

pub fn isExpectedNoise(message: []const u8) bool {
    for (expected_noise) |noise| {
        if (std.mem.find(u8, message, noise) != null) return true;
    }
    return false;
}

const redaction = "<redigido>";

pub fn redact(out: []u8, message: []const u8) []const u8 {
    var len: usize = 0;
    var i: usize = 0;
    while (i < message.len and len < out.len) {
        if (!isAddressChar(message[i])) {
            out[len] = message[i];
            len += 1;
            i += 1;
            continue;
        }
        const start = i;
        var has_digit = false;
        var has_separator = false;
        while (i < message.len and isAddressChar(message[i])) : (i += 1) {
            if (std.ascii.isDigit(message[i])) has_digit = true;
            if (message[i] == '.' or message[i] == ':') has_separator = true;
        }
        const token = if (has_digit and has_separator) redaction else message[start..i];
        const n = @min(token.len, out.len - len);
        @memcpy(out[len..][0..n], token[0..n]);
        len += n;
    }
    return out[0..len];
}

fn isAddressChar(char: u8) bool {
    return std.ascii.isHex(char) or char == '.' or char == ':' or char == '[' or char == ']';
}

test "redact tira IPv4, IPv6 e portas e mantém o texto" {
    var buffer: [256]u8 = undefined;
    const cases = [_][2][]const u8{
        .{ "ICE failed for 192.168.0.12:50000", "ICE failed for <redigido>" },
        .{ "Using [2804:14c:5b8::1]:443 now", "Using <redigido> now" },
        .{ "fe80::1%eth0 down", "<redigido>%eth0 down" },
        .{ "DTLS handshake failed", "DTLS handshake failed" },
        .{ "add face bead", "add face bead" },
        .{ "Peer 4b1d-9c.local unreachable", "Peer 4b1d-<redigido>local unreachable" },
    };
    for (cases) |case| try std.testing.expectEqualStrings(case[1], redact(&buffer, case[0]));
}

test "redact trunca no tamanho do buffer" {
    var buffer: [8]u8 = undefined;
    try std.testing.expectEqualStrings("conexão", redact(&buffer, "conexão perdida"));
}

test "isExpectedNoise só cala o aviso de candidato TCP ignorado" {
    try std.testing.expect(isExpectedNoise("rtc::impl::IceTransport::LogCallback@123: juice: ICE-TCP is disabled, ignoring TCP candidate"));
    try std.testing.expect(!isExpectedNoise("juice: ICE failed"));
    try std.testing.expect(!isExpectedNoise("DTLS handshake failed"));
}
