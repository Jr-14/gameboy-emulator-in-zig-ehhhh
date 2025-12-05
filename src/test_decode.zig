const std = @import("std");
const main = @import("main.zig");

const expect = std.testing.expect;

test "testing simple decode no op" {
    try expect(std.mem.eql(u8, main.decode(0x00), "NOP"));
}
