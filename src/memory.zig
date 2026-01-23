const Memory = @This();

// 65,536 positions inlcuding 0x00 and 0xffff
pub const ARRAY_SIZE: u32 = 0xFFFF + 1;

address: [ARRAY_SIZE]u8 = undefined,

pub fn init() Memory {
    var memory: [ARRAY_SIZE]u8 = undefined;
    @memset(&memory, 0);
    const m: Memory = .{
        .address = memory,
    };
    return m;
}

pub inline fn read(m: Memory, index: u32) u8 {
    return m.address[index];
}

pub inline fn write(m: *Memory, index: u32, value: u8) void {
    m.address[index] = value;
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;

test "reading and writing boundaries" {
    var memory = Memory.init();

    memory.write(0xFFFF, 0xAC);
    memory.write(0x0000, 0x7F);

    try expectEqual(0xAC, memory.read(0xFFFF));
    try expectEqual(0x00, memory.read(0xFFFE));
    try expectEqual(0x7F, memory.read(0x0000));
    try expectEqual(0x00, memory.read(0x0001));
}

test "reading and writing" {
    var memory = Memory.init();

    memory.write(0x1004, 0xAC);
    memory.write(0x7AC0, 0x7F);

    try expectEqual(0xAC, memory.read(0x1004));
    try expectEqual(0x00, memory.read(0x1005));
    try expectEqual(0x00, memory.read(0x1003));
    try expectEqual(0x7F, memory.read(0x7AC0));
    try expectEqual(0x00, memory.read(0x7AC1));
    try expectEqual(0x00, memory.read(0x7ABF));
}
