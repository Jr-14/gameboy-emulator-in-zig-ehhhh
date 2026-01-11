// 65,536 positions inlcuding 0x00 and 0xffff
pub const ARRAY_SIZE: u32 = 0xffff + 1;

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
