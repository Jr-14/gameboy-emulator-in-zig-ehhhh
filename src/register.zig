const std = @import("std");
const builtin = @import("builtin");

const low_byte_index: usize = if (builtin.target.cpu.arch.endian() == .little) 0 else 1;
const high_byte_index: usize = if (builtin.target.cpu.arch.endian() == .little) 1 else 0;

pub const PackedRegisterPair = packed union {
    value: u16,
    bytes: packed struct(u16) {
        low: u8,
        high: u8,
    },

    pub inline fn lowPtr(pair: *PackedRegisterPair) *u8 {
        const raw_bytes: *[2]u8 = @ptrCast(&pair.value);
        return &raw_bytes[low_byte_index];
    }

    pub inline fn highPtr(pair: *PackedRegisterPair) *u8 {
        const raw_bytes: *[2]u8 = @ptrCast(&pair.value);
        return &raw_bytes[high_byte_index];
    }
};

const expectEqual = std.testing.expectEqual;

test "packing" {
    var HL = PackedRegisterPair{ .value = 0x0000 };
    try expectEqual(0x0000, HL.value);
    try expectEqual(0x00, HL.bytes.low);
    try expectEqual(0x00, HL.bytes.high);

    HL.bytes.low = 0xFA;
    try expectEqual(0x00FA, HL.value);
    try expectEqual(0xFA, HL.bytes.low);
    try expectEqual(0x00, HL.bytes.high);

    HL.bytes.high = 0xFA;
    HL.bytes.low = 0x00;
    try expectEqual(0xFA00, HL.value);
    try expectEqual(0x00, HL.bytes.low);
    try expectEqual(0xFA, HL.bytes.high);
}
