const std = @import("std");

pub const PackgedRegisterPair = packed union {
    value: u16,
    bytes: packed struct {
        low: u8,
        high: u8,
    },
};

const expectEqual = std.testing.expectEqual;

test "packing" {
    var HL = PackgedRegisterPair{ .value = 0x0000 };
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
