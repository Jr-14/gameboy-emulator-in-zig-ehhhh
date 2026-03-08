const std = @import("std");

const Memory = @import("../memory.zig");
const PackedRegister = @import("../register_packed.zig").PackgedRegisterPair;
const Processor = @import("../processor_new.zig");
const utils = @import("../utils.zig");

const Bit = utils.Bit;

const expectEqual = std.testing.expectEqual;

/// Tests the bit b of the 8-bit register r.
/// The zero flag is set to 1 if the chosen bit is 0, and 0 otherwise.
pub fn test_bit_reg8(proc: *Processor, bit: Bit, registerValue: *u8) void {
    const b: u1 = @truncate(registerValue.* >> @intFromEnum(bit));

    proc.flags.zero = ~b;
    proc.flags.negative = 0;
    proc.flags.half_carry = 1;
}

test "test_bit_reg8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .D = 0xF0, });

    test_bit_reg8(&processor, .seven, processor.D());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_reg8(&processor, .six, processor.D());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_reg8(&processor, .five, processor.D());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_reg8(&processor, .four, processor.D());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_reg8(&processor, .three, processor.D());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_reg8(&processor, .two, processor.D());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_reg8(&processor, .one, processor.D());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_reg8(&processor, .zero, processor.D());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);
}

/// Tests the bit b of the 8-bit data at the absolute address specified by the 16-bit register HL.
/// The zero flag is set to 1 if the chosen bit is 0, and 0 otherwise.
pub fn test_bit_hl_indirect(proc: *Processor, bit: Bit) void {
    const contents: *u8 = &proc.memory.address[proc.HL.value];
    const b: u1 = @truncate(contents.* >> @intFromEnum(bit));

    proc.flags.zero = ~b;
    proc.flags.negative = 0;
    proc.flags.half_carry = 1;
}

test "test_bit_hl_indirect" {
    const HL: u16 = 0x31E7;
    var memory = Memory.init();
    memory.address[HL] = 0xF0;
    var processor = Processor.init(&memory, .{});
    processor.HL.value = HL;

    test_bit_hl_indirect(&processor, .seven);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_hl_indirect(&processor, .six);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_hl_indirect(&processor, .five);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_hl_indirect(&processor, .four);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_hl_indirect(&processor, .three);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_hl_indirect(&processor, .two);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_hl_indirect(&processor, .one);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);

    test_bit_hl_indirect(&processor, .zero);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(1, processor.flags.half_carry);
}
