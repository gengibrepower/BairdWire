const std = @import("std");

pub const current_version: u32 = 1;
pub const supported_versions = [_]u32{current_version};

pub const hello_timeout_ms: i64 = 5_000;
pub const max_message_before_hello: usize = 4 * 1024;
pub const max_message: usize = 64 * 1024;
pub const max_id_len: usize = 64;
pub const max_client_len: usize = 64;
pub const max_resume_len: usize = 256;

pub const ErrorCode = enum {
    protocol_error,
    version_incompatible,
    hello_timeout,
    message_too_large,
    unknown_type,

    pub fn closeCode(code: ErrorCode) ?u16 {
        return switch (code) {
            .protocol_error => 4000,
            .version_incompatible => 4001,
            .hello_timeout => 4002,
            .message_too_large => 1009,
            .unknown_type => null,
        };
    }
};

pub const Envelope = struct {
    v: i64,
    t: []const u8,
    id: ?[]const u8,
    re: ?[]const u8,
    d: std.json.ObjectMap,
};

pub const Hello = struct {
    versions: std.json.Array,
    client: ?[]const u8,
    resume_token: ?[]const u8,
};

pub fn parseEnvelope(arena: std.mem.Allocator, payload: []const u8) std.mem.Allocator.Error!?Envelope {
    const root = std.json.parseFromSliceLeaky(std.json.Value, arena, payload, .{}) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return null,
    };
    const object = asObject(root) orelse return null;

    const v = asInteger(object.get("v") orelse return null) orelse return null;
    if (v < 1) return null;
    const t = asString(object.get("t") orelse return null) orelse return null;
    const id = optionalString(object.get("id"), max_id_len) orelse return null;
    const re = optionalString(object.get("re"), max_id_len) orelse return null;
    const d = asObject(object.get("d") orelse return null) orelse return null;

    return .{ .v = v, .t = t, .id = id.value, .re = re.value, .d = d };
}

pub fn parseHello(d: std.json.ObjectMap) ?Hello {
    const versions = switch (d.get("versions") orelse return null) {
        .array => |array| array,
        else => return null,
    };
    if (versions.items.len == 0) return null;
    for (versions.items) |item| {
        const version = asInteger(item) orelse return null;
        if (version < 1) return null;
    }
    const client = optionalString(d.get("client"), max_client_len) orelse return null;
    const resume_token = optionalString(d.get("resume"), max_resume_len) orelse return null;
    return .{ .versions = versions, .client = client.value, .resume_token = resume_token.value };
}

pub fn chooseVersion(offered: std.json.Array) ?u32 {
    var chosen: ?u32 = null;
    for (offered.items) |item| {
        const version = item.integer;
        for (supported_versions) |supported| {
            if (version == supported and (chosen == null or supported > chosen.?)) chosen = supported;
        }
    }
    return chosen;
}

pub fn welcome(arena: std.mem.Allocator, re: []const u8, version: u32, node: []const u8) std.mem.Allocator.Error![]const u8 {
    return std.json.Stringify.valueAlloc(arena, .{
        .v = version,
        .t = "session.welcome",
        .re = re,
        .d = .{ .version = version, .node = node, .resumed = false },
    }, .{});
}

pub fn errorMessage(arena: std.mem.Allocator, re: ?[]const u8, code: ErrorCode) std.mem.Allocator.Error![]const u8 {
    const Data = struct { code: []const u8, supported: ?[]const u32 = null };
    const Message = struct { v: u32, t: []const u8, re: ?[]const u8, d: Data };
    return std.json.Stringify.valueAlloc(arena, Message{
        .v = current_version,
        .t = "session.error",
        .re = re,
        .d = .{
            .code = @tagName(code),
            .supported = if (code == .version_incompatible) &supported_versions else null,
        },
    }, .{ .emit_null_optional_fields = false });
}

const OptionalString = struct { value: ?[]const u8 };

fn optionalString(value: ?std.json.Value, max_len: usize) ?OptionalString {
    const present = value orelse return .{ .value = null };
    return switch (present) {
        .null => .{ .value = null },
        .string => |s| if (s.len <= max_len) .{ .value = s } else null,
        else => null,
    };
}

fn asObject(value: std.json.Value) ?std.json.ObjectMap {
    return switch (value) {
        .object => |object| object,
        else => null,
    };
}

fn asString(value: std.json.Value) ?[]const u8 {
    return switch (value) {
        .string => |s| s,
        else => null,
    };
}

fn asInteger(value: std.json.Value) ?i64 {
    return switch (value) {
        .integer => |i| i,
        else => null,
    };
}
