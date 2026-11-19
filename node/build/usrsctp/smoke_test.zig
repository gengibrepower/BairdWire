const std = @import("std");
const c = @import("usrsctp_c");

fn discardOutput(_: ?*anyopaque, _: ?*anyopaque, _: usize, _: u8, _: u8) callconv(.c) c_int {
    return 0;
}

test "abre e fecha um socket SCTP sobre AF_CONN" {
    c.usrsctp_init_nothreads(0, discardOutput, null);
    var address: u8 = 0;
    c.usrsctp_register_address(&address);

    const socket = c.usrsctp_socket(c.AF_CONN, c.SOCK_STREAM, c.IPPROTO_SCTP, null, null, 0, null) orelse
        return error.SocketNotCreated;
    c.usrsctp_close(socket);

    c.usrsctp_deregister_address(&address);
    while (c.usrsctp_finish() != 0) c.usrsctp_handle_timers(10);
}
