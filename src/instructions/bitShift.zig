const std = @import("std");

const Processor = @import("../processor_new.zig");
const Memory = @import("../memory.zig");

pub const bitShift = struct {
    /// Rotates the 8-bit A register value left through the carry flag.
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). The carry flag is copied to bit
    /// 0, and bit 7 is copied to the carry flag. Note that unlike the related RL r instruction, RLA always
    /// sets the zero flag to 0 without looking at the resulting value of the calculation.
    pub fn rotate_left_a(proc: *Processor) void {
        const bit_7: u1 = @truncate(proc.accumulator >> 7);

        proc.accumulator <<= 1;
        proc.accumulator |= proc.flags.carry;

        proc.flags.carry = bit_7;
        proc.flags.zero = 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
    }

    /// Rotates the 8-bit A register value left in a circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). Bit 7 is copied both to bit
    /// 0 and the carry flag. Note that unlike the related RLC r instruction, RLCA always sets the zero
    /// flag to 0 without looking at the resulting value of the calculation.
    pub fn rotate_left_circular_a(proc: *Processor) void {
        const bit_7: u1 = @truncate(proc.accumulator >> 7);

        proc.accumulator <<= 1;
        proc.accumulator |= bit_7;

        proc.flags.zero = 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotate the contents of register A to the right, through the carry (CY) flag.
    /// That is, the contents of bit 7 are copied to bit 6, and the previous contents of bit 6 (before the copy) are
    /// copied to bit 5. The same operation is repeated in sequence for the rest of the register.
    /// The previous contents of the carry flag are copied to bit 7.
    pub fn rotate_right_a(proc: *Processor) void {
        const bit_0: u1 = @truncate(proc.accumulator);

        proc.accumulator >>= 1;
        if (proc.isFlagSet(.carry)) {
            proc.accumulator |= 0x80;
        }

        proc.flags.zero = 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotate the contents of register A to the right.
    /// That is, the contents of bit 7 are copied to bit 6, and the previous contents of bit 6 (before the copy) are
    /// copied to bit 5. The same operation is repeated in sequence for the rest of the register.
    /// The contents of bit 0 are placed in both the CY flag and bit 7 of register A.
    pub fn rotate_right_circular_a(proc: *Processor) void {
        const bit_0: u1 = @truncate(proc.accumulator);

        proc.accumulator >>= 1;
        if (bit_0 == 1) {
            proc.accumulator |= 0x80;
        }

        proc.flags.zero = 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotates the 8-bit register r value left in a circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). Bit 7 is copied both to bit 0
    /// and the carry flag.
    pub fn rotate_left_circular_r8(proc: *Processor, registerValue: *u8) void {
        const bit_7: u1 = @truncate(registerValue.* >> 7);

        registerValue.* <<= 1;
        registerValue.* |= bit_7;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotates the 8-bit register r value right in a circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). Bit 0 is copied both to bit 7
    /// and the carry flag.
    pub fn rotate_right_circular_r8(proc: *Processor, registerValue: *u8) void {
        const bit_0: u1 = @truncate(registerValue.* >> 7);

        registerValue.* >>= 1;
        if (bit_0 == 1) {
            registerValue |= 0x80;
        }

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, left in a
    /// circular manner (carry flag is updated but not used).
    /// Every bit is shifted t
    pub fn rotate_left_circular_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_7: u1 = @truncate(contents.* >> 7);

        contents.* <<= 1;
        contents.* |= bit_7;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, right in a
    /// circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). Bit 0 is copied both to bit 7
    /// and the carry flag.
    pub fn rotate_right_circular_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_0: u1 = @truncate(contents.*);

        contents.* >>= 1;
        if (bit_0 == 1) {
            contents |= 0x80;
        }

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotates the 8-bit register r value left through the carry flag.
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). The carry flag is copied to bit
    /// 0, and bit 7 is copied to the carry flag.{
    pub fn rotate_left_arithmetic_r8(proc: *Processor, registerValue: *u8) void {
        const bit_7: u1 = @truncate(registerValue.* >> 7);

        registerValue.* <<= 1;
        registerValue.* |= proc.flags.carry;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, left through
    /// the carry flag.
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). The carry flag is copied to bit
    /// 0, and bit 7 is copied to the carry flag.
    pub fn rotate_left_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_7: u1 = @truncate(contents.* >> 7);

        contents.* <<= 1;
        contents.* |= proc.flags.carry;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotates the 8-bit register r value right through the carry flag.
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). The carry flag is copied to bit
    /// 7, and bit 0 is copied to the carry flag
    pub fn rotate_right_r8(proc: *Processor, registerValue: *u8) void {
        const bit_0: u1 = @truncate(registerValue.*);

        registerValue.* >>= 1;
        if (proc.flags.carry == 1) {
            registerValue.* |= 0x80;
        }

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, right through
    /// the carry flag.
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). The carry flag is copied to bit
    /// 7, and bit 0 is copied to the carry flag.
    pub fn rotate_right_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_0: u1 = @truncate(contents.*);

        contents.* >>= 1;
        if (proc.flags.carry == 1) {
            contents.* |= 0x80;
        }

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Shifts the 8-bit register r value left by one bit using an arithmetic shift.
    /// Bit 7 is shifted to the carry flag, and bit 0 is set to a fixed value of 0.
    pub fn shift_left_arithmetic_r8(proc: *Processor, registerValue: *u8) void {
        const bit_7: u1 = @truncate(registerValue.* >> 7);

        registerValue.* <<= 1;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Shifts, the 8-bit value at the address specified by the HL register, left by one bit using an
    /// arithmetic shift.
    /// Bit 7 is shifted to the carry flag, and bit 0 is set to a fixed value of 0.
    pub fn shift_left_arithmetic_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_7: u1 = @truncate(contents.* >> 7);

        contents.* <<= 1;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Shifts the 8-bit register r value right by one bit using an arithmetic shift.
    /// Bit 7 retains its value, and bit 0 is shifted to the carry flag.
    pub fn shift_right_arithmetic_r8(proc: *Processor, registerValue: *u8) void {
        const bit_0: u1 = @truncate(registerValue.*);
        const bit_7: u1 = @truncate(registerValue.* >> 7);

        registerValue.* >>= 1;
        registerValue.* |= bit_7;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Shifts, the 8-bit value at the address specified by the HL register, right by one bit using an
    /// arithmetic shift.
    /// Bit 7 retains its value, and bit 0 is shifted to the carry flag.
    pub fn shift_right_arithmetic_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_0: u1 = @truncate(contents.*);
        const bit_7: u1 = @truncate(contents.* >> 7);

        contents.* >>= 1;
        contents.* |= bit_7;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Swaps the high and low 4-bit nibbles of the 8-bit register r.
    pub fn swap_r8(proc: *Processor, registerValue: *u8) void {
        const lo_nibble_mask: u8 = (registerValue.* & 0xF) << 4;
        registerValue.* >>= 4;
        registerValue.* |= lo_nibble_mask;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = 0;
    }

    /// Swaps the high and low 4-bit nibbles of the 8-bit data at the absolute address specified by the
    /// 16-bit register HL
    pub fn swap_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const lo_nibble_mask: u8 = (contents.* & 0xF) << 4;
        contents.* >>= 4;
        contents.* |= lo_nibble_mask;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = 0;
    }

    /// Shifts the 8-bit register r value right by one bit using a logical shift.
    /// Bit 7 is set to a fixed value of 0, and bit 0 is shifted to the carry flag.
    pub fn shift_right_logical_r8(proc: *Processor, registerValue: *u8) void {
        const bit_0: u1 = @truncate(registerValue.*);

        registerValue.* >>= 1;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Shifts, the 8-bit value at the address specified by the HL register, right by one bit using a logical
    /// shift.
    /// Bit 7 is set to a fixed value of 0, and bit 0 is shifted to the carry flag.
    pub fn shift_right_logical_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_0: u1 = @truncate(contents.*);

        contents.* >>= 1;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }
};

const expectEqual = std.testing.expectEqual;

test "bitShift.rotate_left_a" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .A = 0xFF });

    bitShift.rotate_left_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.accumulator);

    bitShift.rotate_left_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1101, processor.accumulator);

    processor.flags.carry = 0;
    bitShift.rotate_left_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1010, processor.accumulator);
}

test "bitShift.rotate_left_circular_a" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .A = 0xF0 });

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1110_0001, processor.accumulator);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1100_0011, processor.accumulator);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1000_0111, processor.accumulator);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b0000_1111, processor.accumulator);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0001_1110, processor.accumulator);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0011_1100, processor.accumulator);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0111_1000, processor.accumulator);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1111_0000, processor.accumulator);
}

test "bitShift.rotate_right_a" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .A = 0xFE }); // 0b1111_1110

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0111_1111, processor.accumulator);

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b0011_1111, processor.accumulator);

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1001_1111, processor.accumulator);

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1100_1111, processor.accumulator);

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1110_0111, processor.accumulator);

    processor.flags.carry = 0;
    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b0111_0011, processor.accumulator);
}

test "bitShift.rotate_right_circular_a" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .A = 0xFE }); // 0b1111_1110

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0111_1111, processor.accumulator);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1011_1111, processor.accumulator);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1101_1111, processor.accumulator);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1110_1111, processor.accumulator);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_0111, processor.accumulator);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1011, processor.accumulator);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1101, processor.accumulator);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.accumulator);
}

test "bitShift.rotate_left_circular_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0x7F });

    bitShift.rotate_left_circular_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.B().*);

    bitShift.rotate_left_circular_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1101, processor.B().*);

    bitShift.rotate_left_circular_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1011, processor.B().*);

    processor.BC.bytes.low = 0x00;
    bitShift.rotate_left_circular_r8(&processor, processor.C());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.C.value);
}

test "bitShift.rotate_right_circular_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0xFE });

    bitShift.rotate_right_circular_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0111_1111, processor.B().*);

    bitShift.rotate_right_circular_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1011_1111, processor.B().*);

    bitShift.rotate_right_circular_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1101_1111, processor.B().*);

    processor.BC.bytes.low = 0x00;
    bitShift.rotate_right_circular_r8(&processor, processor.C());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.C.value);
}

test "bitShift.rotate_left_circular_hlMem" {
    const HL: u16 = 0xAC13;
    const contents = 0x7F; // 0b0111_1111
    var memory = Memory.init();
    memory.write(HL, contents);

    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.memory.read(HL));

    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1101, processor.memory.read(HL));

    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1011, processor.memory.read(HL));

    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_0111, processor.memory.read(HL));

    memory.write(HL, 0x00);
    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.memory.read(HL));
}

test "bitShift.rotate_right_circular_hlMem" {
    const HL: u16 = 0xAC13;
    const contents = 0xFE; // 0b1111_1110
    var memory = Memory.init();
    memory.write(HL, contents);

    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0111_1111, processor.memory.read(HL));

    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1011_1111, processor.memory.read(HL));

    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1101_1111, processor.memory.read(HL));

    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1110_1111, processor.memory.read(HL));

    memory.write(HL, 0x00);
    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.memory.read(HL));
}

test "bitShift.rotate_left_arithmetic_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0x7F });

    bitShift.rotate_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.B().*);

    bitShift.rotate_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1100, processor.B().*);

    bitShift.rotate_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1001, processor.B().*);

    bitShift.rotate_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_0011, processor.B().*);

    processor.unsetFlag(.C);
    processor.H.value = 0x00;
    bitShift.rotate_left_arithmetic_r8(&processor, &processor.H);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.H.value);

    processor.setFlag(.C);
    bitShift.rotate_left_arithmetic_r8(&processor, &processor.H);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0000_0001, processor.H.value);
}

test "bitShift.rotate_left_hlMem" {
    var HL: u16 = 0x17C2;
    var memory = Memory.init();
    memory.address[HL] = 0x7F;
    var processor = Processor.init(&memory, .{
        .H = 0x17,
        .L = 0xC2,
    });

    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.memory.address[HL]);

    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1100, processor.memory.address[HL]);
    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1001, processor.memory.address[HL]);

    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_0011, processor.memory.address[HL]);

    HL = 0x0100;
    processor.memory.address[HL] = 0;
    processor.setHL(HL);
    processor.unsetFlag(.C);
    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.memory.address[HL]);

    processor.setFlag(.C);
    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0000_0001, processor.memory.address[HL]);
}

test "bitShift.rotate_right_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0xFE });

    bitShift.rotate_right_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0111_1111, processor.B().*);

    bitShift.rotate_right_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b0011_1111, processor.B().*);

    bitShift.rotate_right_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1001_1111, processor.B().*);

    bitShift.rotate_right_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1100_1111, processor.B().*);

    processor.unsetFlag(.C);
    processor.H.value = 0x00;
    bitShift.rotate_right_r8(&processor, &processor.H);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.H.value);

    processor.setFlag(.C);
    bitShift.rotate_right_r8(&processor, &processor.H);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1000_0000, processor.H.value);
}

test "bitShift.rotate_right_hlMem" {
    var HL: u16 = 0x80C3;
    var memory = Memory.init();
    memory.address[HL] = 0xFE;
    var processor = Processor.init(&memory, .{
        .H = 0x80,
        .L = 0xC3,
    });

    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b0111_1111, processor.memory.address[HL]);

    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b0011_1111, processor.memory.address[HL]);

    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1001_1111, processor.memory.address[HL]);

    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1100_1111, processor.memory.address[HL]);

    HL = 0x0100;
    processor.setHL(HL);
    processor.memory.address[HL] = 0;
    processor.unsetFlag(.C);
    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.memory.address[HL]);

    processor.setFlag(.C);
    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1000_0000, processor.memory.address[HL]);
}

test "bitShift.shift_left_arithmetic_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0x7F });

    bitShift.shift_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.B().*);

    bitShift.shift_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1100, processor.B().*);

    bitShift.shift_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1000, processor.B().*);

    bitShift.shift_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_0000, processor.B().*);

    bitShift.shift_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1110_0000, processor.B().*);

    processor.B().* = 0x0;
    bitShift.shift_left_arithmetic_r8(&processor, processor.B());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x0, processor.B().*);
}

test "bitShift.shift_left_arithmetic_hlMem" {
    const HL = 0x01B2;
    var memory = Memory.init();
    memory.address[HL] = 0x7F;
    var processor = Processor.init(&memory, .{
        .H = 0x01,
        .L = 0xB2,
    });

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.memory.address[HL]);

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1100, processor.memory.address[HL]);

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1000, processor.memory.address[HL]);

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_0000, processor.memory.address[HL]);

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1110_0000, processor.memory.address[HL]);

    processor.memory.address[HL] = 0;
    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x0, processor.memory.address[HL]);
}

test "bitShift.shift_right_arithmetic_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0xF7 }); // 0b1111_0111

    bitShift.shift_right_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1011, processor.B().*);

    bitShift.shift_right_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1101, processor.B().*);

    bitShift.shift_right_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.B().*);

    bitShift.shift_right_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1111_1111, processor.B().*);

    bitShift.shift_right_arithmetic_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1111, processor.B().*);

    processor.B().* = 0x0;
    bitShift.shift_right_arithmetic_r8(&processor, processor.B());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x0, processor.B().*);

    bitShift.shift_right_arithmetic_r8(&processor, processor.B());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x0, processor.B().*);
}

test "bitShift.shift_right_arithmetic_hlMem" {
    const HL: u16 = 0x74F0;
    var memory = Memory.init();
    memory.address[HL] = 0xF7;
    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1011, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1101, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1110, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0b1111_1111, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0b1111_1111, processor.memory.address[HL]);

    processor.memory.address[HL] = 0x0;
    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x0, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x0, processor.memory.address[HL]);
}

test "bitShift.swap_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{
        .B = 0x93,
        .C = 0x00,
    });

    bitShift.swap_r8(&processor, processor.B());
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x39, processor.B().*);

    bitShift.swap_r8(&processor, processor.C());
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.C.value);
}

test "bitShift.swap_hlMem" {
    const HL: u16 = 0x95A2;
    var memory = Memory.init();
    memory.address[HL] = 0xA2;
    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bitShift.swap_hlMem(&processor);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x2A, processor.memory.address[HL]);

    memory.address[HL] = 0x00;
    bitShift.swap_hlMem(&processor);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0x00, processor.memory.address[HL]);
}
