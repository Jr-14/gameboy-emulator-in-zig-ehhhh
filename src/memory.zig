// 65,536 positions inlcuding 0x00 and 0xffff
pub const ARRAY_SIZE: u32 = 0xFFFF + 1;

pub const Memory = struct {
    memory_array: [ARRAY_SIZE]u8 = undefined,

    const Self = @This();

    pub fn init() Self {
        var memory: [ARRAY_SIZE]u8 = undefined;
        @memset(&memory, 0);
        const self: Memory = .{
            .memory_array = memory,
        };
        return self;
    }

    pub inline fn read(self: Self, index: u32) u8 {
        return self.memory_array[index];
    }

    pub inline fn write(self: *Self, index: u32, value: u8) void {
        self.memory_array[index] = value;
    }
};

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
