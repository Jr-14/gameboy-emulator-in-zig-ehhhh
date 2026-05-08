const std = @import("std");

pub const TestError = error{
    NotImplemented,
    Incomplete,
};

const BEGIN_INVALID_MEMORY_REGION: u16 = 0xE000;
const END_INVALID_MEMORY_REGION: u16 = 0xFDFF;

pub fn generateValidMemoryAddress(io: std.Io) u16 {
    var source: std.Random.IoSource = .{ .io = io };
    const rand = source.interface();

    var address = rand.int(u16);
    while (address >= BEGIN_INVALID_MEMORY_REGION and address <= END_INVALID_MEMORY_REGION) {
        address = rand.int(u16);
    }

    return address;
}

test "generateValidMemoryAddress" {
    const random_number = generateValidMemoryAddress(std.testing.io);
    std.debug.print("Random number is 0x{x}\n", .{ random_number });
    try std.testing.expectEqual(random_number, random_number);
}
