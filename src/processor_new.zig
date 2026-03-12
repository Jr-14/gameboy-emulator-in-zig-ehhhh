const std = @import("std");
const utils = @import("utils.zig");

const PackedRegisterPair = @import("register_packed.zig").PackgedRegisterPair;
const Memory = @import("memory.zig");
// const instructions = @import("instruction_new.zig");
const instructionsNew = @import("instructions/root.zig");

const masks = @import("masks.zig");
pub const FlagMasks = masks.FlagMasks;
const Flag = masks.ProcessorFlag;

const Bit = utils.Bit;

pub const FlagCondition = enum(u1) {
    is_not_set,
    is_set,
};

const FlagsRegister = packed struct {
    zero: u1 = 0,
    negative: u1 = 0,
    half_carry: u1 = 0,
    carry: u1 = 0,
    _unused: u4 = 0,
};

const Processor = @This();

accumulator: u8 = 0,
flags: FlagsRegister = .{},
BC: PackedRegisterPair = .{ .value = 0 },
DE: PackedRegisterPair = .{ .value = 0 },
HL: PackedRegisterPair = .{ .value = 0 },

SP: u16 = 0,
PC: u16 = 0,

// Interrupt Master Enabled
IME: bool = false,

// Can we use this as a halting mechanism?
isHalted: bool = false,

memory: *Memory = undefined,

const ProcessorValues = struct {
    accumulator: u8 = 0,
    zeroFlag: u1 = 0,
    negativeFlag: u1 = 0,
    halfCarryFlag: u1 = 0,
    carryFlag: u1 = 0,
    B: u8 = 0,
    C: u8 = 0,
    D: u8 = 0,
    E: u8 = 0,
    H: u8 = 0,
    L: u8 = 0,
    SP: u16 = 0,
    PC: u16 = 0,
    IME: bool = false,
};

pub fn init(memory: *Memory, initialValues: ProcessorValues) Processor {
    return .{
        .memory = memory,
        .accumulator = initialValues.accumulator,
        .SP = initialValues.SP,
        .PC = initialValues.PC,
        .IME = initialValues.IME,
        .flags = .{
            .zero = initialValues.zeroFlag,
            .negative = initialValues.negativeFlag,
            .half_carry = initialValues.halfCarryFlag,
            .carry = initialValues.carryFlag,
        },
        .BC = .{
            .bytes = .{
                .high = initialValues.B,
                .low = initialValues.C,
            }
        },
        .DE = .{
            .bytes = .{
                .high = initialValues.D,
                .low = initialValues.E,
            }
        },
        .HL = .{
            .bytes = .{
                .high = initialValues.H,
                .low = initialValues.L,
            }
        },
    };
}

pub inline fn B(proc: *Processor) *u8 {
    return &proc.BC.bytes.high;
}

pub inline fn C(proc: *Processor) *u8 {
    return &proc.BC.bytes.low;
}

pub inline fn D(proc: *Processor) *u8 {
    return &proc.DE.bytes.high;
}

pub inline fn E(proc: *Processor) *u8 {
    return &proc.DE.bytes.low;
}

pub inline fn H(proc: *Processor) *u8 {
    return &proc.HL.bytes.high;
}

pub inline fn L(proc: *Processor) *u8 {
    return &proc.HL.bytes.low;
}

/// Read from memory the value pointed to by PC
pub inline fn readFromPC(proc: *Processor) u8 {
    return proc.memory.read(proc.PC);
}

/// Fetches the next instruction or byte of data from the current memory address pointed at by PC
pub inline fn fetch(proc: *Processor) u8 {
    const instruction = proc.readFromPC();
    proc.PC += 1;
    return instruction;
}

/// Pop the current value from the stack pointed to by SP
pub inline fn popStack(proc: *Processor) u8 {
    const val = proc.memory.read(proc.SP);
    proc.SP += 1;
    return val;
}

/// Push a value into the stack
pub inline fn pushStack(proc: *Processor, val: u8) void {
    proc.SP -= 1;
    proc.memory.write(proc.SP, val);
}

pub inline fn isFlagSet(proc: *Processor, flag: Flag) bool {
    return switch (flag) {
        .zero => proc.flags.zero == 1,
        .negative => proc.flags.negative == 1,
        .half_carry => proc.flags.half_carry == 1,
        .carry => proc.flags.carry == 1,
    };
}

pub inline fn resetFlags(proc: *Processor) void {
    proc.flags.zero = 0;
    proc.flags.negative = 0;
    proc.flags.half_carry = 0;
    proc.flags.carry = 0;
}

fn decodeAndExecuteCBPrefix(proc: *Processor) !void {
    const op_code = proc.fetch();
    switch (op_code) {
        // RLC B
        0x00 => instructionsNew.bitShift.rotate_left_circular_reg8(proc, proc.B()),

        // RLC C
        0x01 => instructionsNew.bitShift.rotate_left_circular_reg8(proc, proc.C()),

        // RLC D
        0x02 => instructionsNew.bitShift.rotate_left_circular_reg8(proc, proc.D()),

        // RLC E
        0x03 => instructionsNew.bitShift.rotate_left_circular_reg8(proc, proc.E()),

        // RLC H
        0x04 => instructionsNew.bitShift.rotate_left_circular_reg8(proc, proc.H()),

        // RLC L
        0x05 => instructionsNew.bitShift.rotate_left_circular_reg8(proc, proc.L()),

        // RLC (HL)
        0x06 => instructionsNew.bitShift.rotate_left_circular_hl_indirect(proc),

        // RLC A
        0x07 => instructionsNew.bitShift.rotate_left_circular_reg8(proc, &proc.accumulator),

        // RRC B
        0x08 => instructionsNew.bitShift.rotate_right_circular_reg8(proc, proc.B()),

        // RRC C
        0x09 => instructionsNew.bitShift.rotate_right_circular_reg8(proc, proc.C()),

        // RRC D
        0x0A => instructionsNew.bitShift.rotate_right_circular_reg8(proc, proc.D()),

        // RRC E
        0x0B => instructionsNew.bitShift.rotate_right_circular_reg8(proc, proc.E()),

        // RRC H
        0x0C => instructionsNew.bitShift.rotate_right_circular_reg8(proc, proc.H()),

        // RRC L
        0x0D => instructionsNew.bitShift.rotate_right_circular_reg8(proc, proc.L()),

        // RRC (HL)
        0x0E => instructionsNew.bitShift.rotate_right_circular_hl_indirect(proc),

        // RRC
        0x0F => instructionsNew.bitShift.rotate_right_circular_reg8(proc, &proc.A),

        // RL B
        0x10 => instructionsNew.bitShift.rotate_left_reg8(proc, proc.B()),

        // RL C
        0x11 => instructionsNew.bitShift.rotate_left_reg8(proc, proc.C()),

        // RL D
        0x12 => instructionsNew.bitShift.rotate_left_reg8(proc, proc.D()),

        // RL E
        0x13 => instructionsNew.bitShift.rotate_left_reg8(proc, proc.E()),

        // RL H
        0x14 => instructionsNew.bitShift.rotate_left_reg8(proc, proc.H()),

        // RL L
        0x15 => instructionsNew.bitShift.rotate_left_reg8(proc, proc.L()),

        // RL (HL)
        0x16 => instructionsNew.bitShift.rotate_left_hl_indirect(&proc),

        // RL A
        0x17 => instructionsNew.bitShift.rotate_left_reg8(proc, &proc.accumulator),

        // RR B
        0x18 => instructionsNew.bitShift.rotate_right_reg8(proc, proc.B()),

        // RR C
        0x19 => instructionsNew.bitShift.rotate_right_reg8(proc, proc.C()),

        // RR D
        0x1A => instructionsNew.bitShift.rotate_right_reg8(proc, proc.D()),

        // RR E
        0x1B => instructionsNew.bitShift.rotate_right_reg8(proc, proc.E()),

        // RR H
        0x1C => instructionsNew.bitShift.rotate_right_reg8(proc, proc.H()),

        // RR L
        0x1D => instructionsNew.bitShift.rotate_right_reg8(proc, proc.L()),

        // RR (HL)
        0x1E => instructionsNew.bitShift.rotate_right_hl_indirect(&proc),

        // RR A
        0x1F => instructionsNew.bitShift.rotate_right_reg8(proc, &proc.accumulator),

        // SLA B
        0x20 => instructionsNew.bitShift.shift_left_arithmetic_reg8(proc, proc.B()),

        // SLA C
        0x21 => instructionsNew.bitShift.shift_left_arithmetic_reg8(proc, proc.C()),

        // SLA D
        0x22 => instructionsNew.bitShift.shift_left_arithmetic_reg8(proc, proc.D()),

        // SLA E
        0x23 => instructionsNew.bitShift.shift_left_arithmetic_reg8(proc, proc.E()),

        // SLA H
        0x24 => instructionsNew.bitShift.shift_left_arithmetic_reg8(proc, proc.H()),

        // SLA L
        0x25 => instructionsNew.bitShift.shift_left_arithmetic_reg8(proc, proc.L()),

        // SLA (HL)
        0x26 => instructionsNew.bitShift.shift_left_arithmetic_hl_indirect(&proc),

        // SLA A
        0x27 => instructionsNew.bitShift.shift_left_arithmetic_reg8(proc, &proc.accumulator),

        // SRA B
        0x28 => instructionsNew.bitShift.shift_right_arithmetic_reg8(proc, proc.B()),

        // SRA C
        0x29 => instructionsNew.bitShift.shift_right_arithmetic_reg8(proc, proc.C()),

        // SRA D
        0x2A => instructionsNew.bitShift.shift_right_arithmetic_reg8(proc, proc.D()),

        // SRA E
        0x2B => instructionsNew.bitShift.shift_right_arithmetic_reg8(proc, proc.E()),

        // SRA H
        0x2C => instructionsNew.bitShift.shift_right_arithmetic_reg8(proc, proc.H()),

        // SRA L
        0x2D => instructionsNew.bitShift.shift_right_arithmetic_reg8(proc, proc.L()),

        // SRA (HL)
        0x2E => instructionsNew.bitShift.shift_right_arithmetic_hl_indirect(&proc),

        // SRA A
        0x2F => instructionsNew.bitShift.shift_right_arithmetic_reg8(proc, &proc.accumulator),

        // SWAP B
        0x30 => instructionsNew.bitShift.swap_reg8(proc, proc.B()),

        // SWAP C
        0x31 => instructionsNew.bitShift.swap_reg8(proc, proc.C()),

        // SWAP D
        0x32 => instructionsNew.bitShift.swap_reg8(proc, proc.D()),

        // SWAP E
        0x33 => instructionsNew.bitShift.swap_reg8(proc, proc.E()),

        // SWAP H
        0x34 => instructionsNew.bitShift.swap_reg8(proc, proc.H()),

        // SWAP L
        0x35 => instructionsNew.bitShift.swap_reg8(proc, proc.L()),

        // SWAP (HL)
        0x36 => instructionsNew.bitShift.swap_hl_indirect(&proc),

        // SWAP A
        0x37 => instructionsNew.bitShift.swap_reg8(proc, &proc.accumulator),

        // SRL B
        0x38 => instructionsNew.bitShift.shift_right_logical_reg8(proc, proc.B()),

        // SRL C
        0x39 => instructionsNew.bitShift.shift_right_logical_reg8(proc, proc.D()),

        // SRL D
        0x3A => instructionsNew.bitShift.shift_right_logical_reg8(proc, proc.D()),

        // SRL E
        0x3B => instructionsNew.bitShift.shift_right_logical_reg8(proc, proc.E()),

        // SRL H
        0x3C => instructionsNew.bitShift.shift_right_logical_reg8(proc, proc.H()),

        // SRL L
        0x3D => instructionsNew.bitShift.shift_right_logical_reg8(proc, proc.L()),

        // SRL (HL)
        0x3E => instructionsNew.bitShift.shift_right_logical_hl_indirect(&proc),

        // SRL A
        0x3F => instructionsNew.bitShift.shift_right_logical_reg8(proc, &proc.accumulator),

        // BIT 0, B
        0x40 => instructionsNew.bitFlag.test_bit_reg8(proc, .zero, proc.B()),

        // BIT 0, C
        0x41 => instructionsNew.bitFlag.test_bit_reg8(proc, .zero, proc.C()),

        // BIT 0, D
        0x42 => instructionsNew.bitFlag.test_bit_reg8(proc, .zero, proc.D()),

        // BIT 0, E
        0x43 => instructionsNew.bitFlag.test_bit_reg8(proc, .zero, proc.E()),

        // BIT 0, H
        0x44 => instructionsNew.bitFlag.test_bit_reg8(proc, .zero, proc.H()),

        // BIT 0, L
        0x45 => instructionsNew.bitFlag.test_bit_reg8(proc, .zero, proc.L()),

        // BIT 0, (HL)
        0x46 => instructionsNew.bitFlag.test_bit_hl_indirect(proc, .zero),

        // BIT 0, A
        0x47 => instructionsNew.bitFlag.test_bit_reg8(proc, .zero, &proc.accumulator),

        // BIT 1, B
        0x48 => instructionsNew.bitFlag.test_bit_reg8(proc, .one, proc.B()),

        // BIT 1, C
        0x49 => instructionsNew.bitFlag.test_bit_reg8(proc, .one, proc.C()),

        // BIT 1, D
        0x4A => instructionsNew.bitFlag.test_bit_reg8(proc, .one, proc.D()),

        // BIT 1, E
        0x4B => instructionsNew.bitFlag.test_bit_reg8(proc, .one, proc.E()),

        // BIT 1, H
        0x4C => instructionsNew.bitFlag.test_bit_reg8(proc, .one, proc.H()),

        // BIT 1, L
        0x4D => instructionsNew.bitFlag.test_bit_reg8(proc, .one, proc.L()),

        // BIT 1, (HL)
        0x4E => instructionsNew.bitFlag.test_bit_hl_indirect(proc, .one),

        // BIT 1, A
        0x4F => instructionsNew.bitFlag.test_bit_reg8(proc, .one, &proc.accumulator),

        // BIT 2, B
        0x50 => instructionsNew.bitFlag.test_bit_reg8(proc, .two, proc.B()),

        // BIT 2, C
        0x51 => instructionsNew.bitFlag.test_bit_reg8(proc, .two, proc.C()),

        // BIT 2, D
        0x52 => instructionsNew.bitFlag.test_bit_reg8(proc, .two, proc.D()),

        // BIT 2, E
        0x53 => instructionsNew.bitFlag.test_bit_reg8(proc, .two, proc.E()),

        // BIT 2, H
        0x54 => instructionsNew.bitFlag.test_bit_reg8(proc, .two, proc.H()),

        // BIT 2, L
        0x55 => instructionsNew.bitFlag.test_bit_reg8(proc, .two, proc.L()),

        // BIT 2, (HL)
        0x56 => instructionsNew.bitFlag.test_bit_hl_indirect(proc, .two),

        // BIT 2, A
        0x57 => instructionsNew.bitFlag.test_bit_reg8(proc, .two, &proc.accumulator),

        // BIT 3, B
        0x58 => instructionsNew.bitFlag.test_bit_reg8(proc, .three, proc.B()),

        // BIT 3, C
        0x59 => instructionsNew.bitFlag.test_bit_reg8(proc, .three, proc.C()),

        // BIT 3, D
        0x5A => instructionsNew.bitFlag.test_bit_reg8(proc, .three, proc.D()),

        // BIT 3, E
        0x5B => instructionsNew.bitFlag.test_bit_reg8(proc, .three, proc.E()),

        // BIT 3, H
        0x5C => instructionsNew.bitFlag.test_bit_reg8(proc, .three, proc.H()),

        // BIT 3, L
        0x5D => instructionsNew.bitFlag.test_bit_reg8(proc, .three, proc.L()),

        // BIT 3, (HL)
        0x5E => instructionsNew.bitFlag.test_bit_hl_indirect(proc, .three),

        // BIT 3, A
        0x5F => instructionsNew.bitFlag.test_bit_reg8(proc, .three, &proc.accumulator),

        // BIT 4, B
        0x60 => instructionsNew.bitFlag.test_bit_reg8(proc, .four, proc.B()),

        // BIT 4, C
        0x61 => instructionsNew.bitFlag.test_bit_reg8(proc, .four, proc.C()),

        // BIT 4, D
        0x62 => instructionsNew.bitFlag.test_bit_reg8(proc, .four, proc.D()),

        // BIT 4, E
        0x63 => instructionsNew.bitFlag.test_bit_reg8(proc, .four, proc.E()),

        // BIT 4, H
        0x64 => instructionsNew.bitFlag.test_bit_reg8(proc, .four, proc.H()),

        // BIT 4, L
        0x65 => instructionsNew.bitFlag.test_bit_reg8(proc, .four, proc.L()),

        // BIT 4, (HL)
        0x66 => instructionsNew.bitFlag.test_bit_hl_indirect(proc, .four),

        // BIT 4, A
        0x67 => instructionsNew.bitFlag.test_bit_reg8(proc, .four, &proc.accumulator),

        // BIT 5, B
        0x68 => instructionsNew.bitFlag.test_bit_reg8(proc, .five, proc.B()),

        // BIT 5, C
        0x69 => instructionsNew.bitFlag.test_bit_reg8(proc, .five, proc.C()),

        // BIT 5, D
        0x6A => instructionsNew.bitFlag.test_bit_reg8(proc, .five, proc.D()),

        // BIT 5, E
        0x6B => instructionsNew.bitFlag.test_bit_reg8(proc, .five, proc.E()),

        // BIT 5, H
        0x6C => instructionsNew.bitFlag.test_bit_reg8(proc, .five, proc.H()),

        // BIT 5, L
        0x6D => instructionsNew.bitFlag.test_bit_reg8(proc, .five, proc.L()),

        // BIT 5, (HL)
        0x6E => instructionsNew.bitFlag.test_bit_hl_indirect(proc, .five),

        // BIT 5, A
        0x6F => instructionsNew.bitFlag.test_bit_reg8(proc, .five, &proc.accumulator),

        // BIT 6, B
        0x70 => instructionsNew.bitFlag.test_bit_reg8(proc, .six, proc.B()),

        // BIT 6, C
        0x71 => instructionsNew.bitFlag.test_bit_reg8(proc, .six, proc.C()),

        // BIT 6, D
        0x72 => instructionsNew.bitFlag.test_bit_reg8(proc, .six, proc.D()),

        // BIT 6, E
        0x73 => instructionsNew.bitFlag.test_bit_reg8(proc, .six, proc.E()),

        // BIT 6, H
        0x74 => instructionsNew.bitFlag.test_bit_reg8(proc, .six, proc.H()),

        // BIT 6, L
        0x75 => instructionsNew.bitFlag.test_bit_reg8(proc, .six, proc.L()),

        // BIT 6, (HL)
        0x76 => instructionsNew.bitFlag.test_bit_hl_indirect(proc, .six),

        // BIT 6, A
        0x77 => instructionsNew.bitFlag.test_bit_reg8(proc, .six, &proc.accumulator),

        // BIT 7, B
        0x78 => instructionsNew.bitFlag.test_bit_reg8(proc, .seven, proc.B()),

        // BIT 7, C
        0x79 => instructionsNew.bitFlag.test_bit_reg8(proc, .seven, proc.C()),

        // BIT 7, D
        0x7A => instructionsNew.bitFlag.test_bit_reg8(proc, .seven, proc.D()),

        // BIT 7, E
        0x7B => instructionsNew.bitFlag.test_bit_reg8(proc, .seven, proc.E()),

        // BIT 7, H
        0x7C => instructionsNew.bitFlag.test_bit_reg8(proc, .seven, proc.H()),

        // BIT 7, L
        0x7D => instructionsNew.bitFlag.test_bit_reg8(proc, .seven, proc.L()),

        // BIT 7, (HL)
        0x7E => instructionsNew.bitFlag.test_bit_hl_indirect(proc, .seven),

        // BIT 7, A
        0x7F => instructionsNew.bitFlag.test_bit_reg8(proc, .seven, &proc.accumulator),

        // RES 0, B
        0x80 => instructionsNew.bits.reset_bit_reg8(.zero, &proc.B),

        // RES 0, C
        0x81 => instructionsNew.bits.reset_bit_reg8(.zero, &proc.C),

        // RES 0, D
        0x82 => instructionsNew.bits.reset_bit_reg8(.zero, &proc.D),

        // RES 0, E
        0x83 => instructionsNew.bits.reset_bit_reg8(.zero, &proc.E),

        // RES 0, H
        0x84 => instructionsNew.bits.reset_bit_reg8(.zero, &proc.H),

        // RES 0, L
        0x85 => instructionsNew.bits.reset_bit_reg8(.zero, &proc.L),

        // RES 0, (HL)
        0x86 => instructionsNew.bits.reset_bit_hl_indirect(proc, .zero),

        // RES 0, A
        0x87 => instructionsNew.bits.reset_bit_reg8(.zero, &proc.A),

        // RES 1, B
        0x88 => instructionsNew.bits.reset_bit_reg8(.one, &proc.B),

        // RES 1, C
        0x89 => instructionsNew.bits.reset_bit_reg8(.one, &proc.C),

        // RES 1, D
        0x8A => instructionsNew.bits.reset_bit_reg8(.one, &proc.D),

        // RES 1, E
        0x8B => instructionsNew.bits.reset_bit_reg8(.one, &proc.E),

        // RES 1, H
        0x8C => instructionsNew.bits.reset_bit_reg8(.one, &proc.H),

        // RES 1, L
        0x8D => instructionsNew.bits.reset_bit_reg8(.one, &proc.L),

        // RES 1, (HL)
        0x8E => instructionsNew.bits.reset_bit_hl_indirect(proc, .one),

        // RES 1, A
        0x8F => instructionsNew.bits.reset_bit_reg8(.two, &proc.A),

        // RES 2, B
        0x90 => instructionsNew.bits.reset_bit_reg8(.two, &proc.B),

        // RES 2, C
        0x91 => instructionsNew.bits.reset_bit_reg8(.two, &proc.C),

        // RES 2, D
        0x92 => instructionsNew.bits.reset_bit_reg8(.two, &proc.D),

        // RES 2, E
        0x93 => instructionsNew.bits.reset_bit_reg8(.two, &proc.E),

        // RES 2, H
        0x94 => instructionsNew.bits.reset_bit_reg8(.two, &proc.H),

        // RES 2, L
        0x95 => instructionsNew.bits.reset_bit_reg8(.two, &proc.L),

        // RES 2, (HL)
        0x96 => instructionsNew.bits.reset_bit_hl_indirect(proc, .two),

        // RES 2, A
        0x97 => instructionsNew.bits.reset_bit_reg8(.two, &proc.A),

        // RES 3, B
        0x98 => instructionsNew.bits.reset_bit_reg8(.three, &proc.B),

        // RES 3, C
        0x99 => instructionsNew.bits.reset_bit_reg8(.three, &proc.C),

        // RES 3, D
        0x9A => instructionsNew.bits.reset_bit_reg8(.three, &proc.D),

        // RES 3, E
        0x9B => instructionsNew.bits.reset_bit_reg8(.three, &proc.E),

        // RES 3, H
        0x9C => instructionsNew.bits.reset_bit_reg8(.three, &proc.H),

        // RES 3, L
        0x9D => instructionsNew.bits.reset_bit_reg8(.three, &proc.L),

        // RES 3, (HL)
        0x9E => instructionsNew.bits.reset_bit_hl_indirect(proc, .three),

        // RES 3, A
        0x9F => instructionsNew.bits.reset_bit_reg8(.three, &proc.A),

        // RES 4, B
        0xA0 => instructionsNew.bits.reset_bit_reg8(.four, &proc.B),

        // RES 4, C
        0xA1 => instructionsNew.bits.reset_bit_reg8(.four, &proc.C),

        // RES 4, D
        0xA2 => instructionsNew.bits.reset_bit_reg8(.four, &proc.D),

        // RES 4, E
        0xA3 => instructionsNew.bits.reset_bit_reg8(.four, &proc.E),

        // RES 4, H
        0xA4 => instructionsNew.bits.reset_bit_reg8(.four, &proc.H),

        // RES 4, L
        0xA5 => instructionsNew.bits.reset_bit_reg8(.four, &proc.L),

        // RES 4, (HL)
        0xA6 => instructionsNew.bits.reset_bit_hl_indirect(proc, .four),

        // RES 4, A
        0xA7 => instructionsNew.bits.reset_bit_reg8(.four, &proc.A),

        // RES 5, B
        0xA8 => instructionsNew.bits.reset_bit_reg8(.five, &proc.B),

        // RES 5, C
        0xA9 => instructionsNew.bits.reset_bit_reg8(.five, &proc.C),

        // RES 5, D
        0xAA => instructionsNew.bits.reset_bit_reg8(.five, &proc.D),

        // RES 5, E
        0xAB => instructionsNew.bits.reset_bit_reg8(.five, &proc.E),

        // RES 5, H
        0xAC => instructionsNew.bits.reset_bit_reg8(.five, &proc.H),

        // RES 5, L
        0xAD => instructionsNew.bits.reset_bit_reg8(.five, &proc.L),

        // RES 5, (HL)
        0xAE => instructionsNew.bits.reset_bit_hl_indirect(proc, .five),

        // RES 5, A
        0xAF => instructionsNew.bits.reset_bit_reg8(.five, &proc.accumulator),

        // RES 6, B
        0xB0 => instructionsNew.bits.reset_bit_reg8(.six, proc.B()),

        // RES 6, C
        0xB1 => instructionsNew.bits.reset_bit_reg8(.six, proc.C()),

        // RES 6, D
        0xB2 => instructionsNew.bits.reset_bit_reg8(.six, proc.D()),

        // RES 6, E
        0xB3 => instructionsNew.bits.reset_bit_reg8(.six, proc.E()),

        // RES 6, H
        0xB4 => instructionsNew.bits.reset_bit_reg8(.six, proc.H()),

        // RES 6, L
        0xB5 => instructionsNew.bits.reset_bit_reg8(.six, proc.L()),

        // RES 6, (HL)
        0xB6 => instructionsNew.bits.reset_bit_hl_indirect(proc, .six),

        // RES 6, A
        0xB7 => instructionsNew.bits.reset_bit_reg8(.six, &proc.accumulator),

        // RES 7, B
        0xB8 => instructionsNew.bits.reset_bit_reg8(.seven, proc.B()),

        // RES 7, C
        0xB9 => instructionsNew.bits.reset_bit_reg8(.seven, proc.C()),

        // RES 7, D
        0xBA => instructionsNew.bits.reset_bit_reg8(.seven, proc.D()),

        // RES 7, E
        0xBB => instructionsNew.bits.reset_bit_reg8(.seven, proc.E()),

        // RES 7, H
        0xBC => instructionsNew.bits.reset_bit_reg8(.seven, proc.H()),

        // RES 7, L
        0xBD => instructionsNew.bits.reset_bit_reg8(.seven, proc.L()),

        // RES 7, (HL)
        0xBE => instructionsNew.bits.reset_bit_hl_indirect(proc, .seven),

        // RES 7, A
        0xBF => instructionsNew.bits.reset_bit_reg8(.seven, &proc.accumulator),

        // SET 0, B
        0xC0 => instructions.bits.set_bit_r8(.zero, &proc.B),

        // SET 0, C
        0xC1 => instructions.bits.set_bit_r8(.zero, &proc.C),

        // SET 0, D
        0xC2 => instructions.bits.set_bit_r8(.zero, &proc.D),

        // SET 0, E
        0xC3 => instructions.bits.set_bit_r8(.zero, &proc.E),

        // SET 0, H
        0xC4 => instructions.bits.set_bit_r8(.zero, &proc.H),

        // SET 0, L
        0xC5 => instructions.bits.set_bit_r8(.zero, &proc.L),

        // SET 0, (HL)
        0xC6 => instructions.bits.set_bit_hlMem(proc, .zero),

        // SET 0, A
        0xC7 => instructions.bits.set_bit_r8(.zero, &proc.A),

        // SET 1, B
        0xC8 => instructions.bits.set_bit_r8(.one, &proc.B),

        // SET 1, C
        0xC9 => instructions.bits.set_bit_r8(.one, &proc.C),

        // SET 1, D
        0xCA => instructions.bits.set_bit_r8(.one, &proc.D),

        // SET 1, E
        0xCB => instructions.bits.set_bit_r8(.one, &proc.E),

        // SET 1, H
        0xCC => instructions.bits.set_bit_r8(.one, &proc.H),

        // SET 1, L
        0xCD => instructions.bits.set_bit_r8(.one, &proc.L),

        // SET 1, (HL)
        0xCE => instructions.bits.set_bit_hlMem(&proc, .one),

        // SET 1, A
        0xCF => instructions.bits.set_bit_r8(.one, &proc.A),

        // SET 2, B
        0xD0 => instructions.bits.set_bit_r8(.two, &proc.B),

        // SET 2, C
        0xD1 => instructions.bits.set_bit_r8(.two, &proc.C),

        // SET 2, D
        0xD2 => instructions.bits.set_bit_r8(.two, &proc.D),

        // SET 2, E
        0xD3 => instructions.bits.set_bit_r8(.two, &proc.E),

        // SET 2, H
        0xD4 => instructions.bits.set_bit_r8(.two, &proc.H),

        // SET 2, L
        0xD5 => instructions.bits.set_bit_r8(.two, &proc.L),

        // SET 2, (HL)
        0xD6 => instructions.bits.set_bit_hlMem(proc, .two),

        // SET 2, A
        0xD7 => instructions.bits.set_bit_r8(.two, &proc.A),

        // SET 3, B
        0xD8 => instructions.bits.set_bit_r8(.three, &proc.B),

        // SET 3, C
        0xD9 => instructions.bits.set_bit_r8(.three, &proc.C),

        // SET 3, D
        0xDA => instructions.bits.set_bit_r8(.three, &proc.D),

        // SET 3, E
        0xDB => instructions.bits.set_bit_r8(.three, &proc.E),

        // SET 3, H
        0xDC => instructions.bits.set_bit_r8(.three, &proc.H),

        // SET 3, L
        0xDD => instructions.bits.set_bit_r8(.three, &proc.L),

        // SET 3, (HL)
        0xDE => instructions.bits.set_bit_hlMem(&proc, .three),

        // SET 3, A
        0xDF => instructions.bits.set_bit_r8(.three, &proc.A),

        // SET 4, B
        0xE0 => instructions.bits.set_bit_r8(.four, &proc.B),

        // SET 4, C
        0xE1 => instructions.bits.set_bit_r8(.four, &proc.C),

        // SET 4, D
        0xE2 => instructions.bits.set_bit_r8(.four, &proc.D),

        // SET 4, E
        0xE3 => instructions.bits.set_bit_r8(.four, &proc.E),

        // SET 4, H
        0xE4 => instructions.bits.set_bit_r8(.four, &proc.H),

        // SET 4, L
        0xE5 => instructions.bits.set_bit_r8(.four, &proc.L),

        // SET 4, (HL)
        0xE6 => instructions.bits.set_bit_hlMem(proc, .four),

        // SET 4 A
        0xE7 => instructions.bits.set_bit_r8(.four, &proc.A),

        // SET 5, B
        0xE8 => instructions.bits.set_bit_r8(.five, &proc.B),

        // SET 5, C
        0xE9 => instructions.bits.set_bit_r8(.five, &proc.C),

        // SET 5, D
        0xEA => instructions.bits.set_bit_r8(.five, &proc.D),

        // SET 5, E
        0xEB => instructions.bits.set_bit_r8(.five, &proc.E),

        // SET 5, H
        0xEC => instructions.bits.set_bit_r8(.five, &proc.H),

        // SET 5, L
        0xED => instructions.bits.set_bit_r8(.five, &proc.L),

        // SET 5, (HL)
        0xEE => instructions.bits.set_bit_hlMem(&proc, .five),

        // SET 5, A
        0xEF => instructions.bits.set_bit_r8(.five, &proc.A),

        // SET 6, B
        0xF0 => instructions.bits.set_bit_r8(.six, &proc.B),

        // SET 6, C
        0xF1 => instructions.bits.set_bit_r8(.six, &proc.C),

        // SET 6, D
        0xF2 => instructions.bits.set_bit_r8(.six, &proc.D),

        // SET 6, E
        0xF3 => instructions.bits.set_bit_r8(.six, &proc.E),

        // SET 6, H
        0xF4 => instructions.bits.set_bit_r8(.six, &proc.H),

        // SET 6, L
        0xF5 => instructions.bits.set_bit_r8(.six, &proc.L),

        // SET 6, (HL)
        0xF6 => instructions.bits.set_bit_hlMem(proc, .six),

        // SET 6 A
        0xF7 => instructions.bits.set_bit_r8(.six, &proc.A),

        // SET 7, B
        0xF8 => instructions.bits.set_bit_r8(.seven, &proc.B),

        // SET 7, C
        0xF9 => instructions.bits.set_bit_r8(.seven, &proc.C),

        // SET 7, D
        0xFA => instructions.bits.set_bit_r8(.seven, &proc.D),

        // SET 7, E
        0xFB => instructions.bits.set_bit_r8(.seven, &proc.E),

        // SET 7, H
        0xFC => instructions.bits.set_bit_r8(.seven, &proc.H),

        // SET 7, L
        0xFD => instructions.bits.set_bit_r8(.seven, &proc.L),

        // SET 7, (HL)
        0xFE => instructions.bits.set_bit_hlMem(&proc, .seven),

        // SET 7, A
        0xFF => instructions.bits.set_bit_r8(.seven, &proc.A),
    }
}

pub fn decodeAndExecute(proc: *Processor, op_code: u8) !void {
    if (proc.isHalted) {
        std.debug.print("Processor is currently halted. Not executing any operations\n", .{});
        return;
    }

    switch (op_code) {
        // NOP (No operation) Only advances the program counter by 1.
        0x00 => {},

        // LD BC, d16
        0x01 => instructions.load.reg16_imm16(proc, .BC),

        // LD (BC), A
        0x02 => instructions.load.reg16_indirect_acc8(proc, .BC, &proc.A),

        // INC BC
        0x03 => instructionsNew.arithmetic.inc_reg16(&proc.BC.value),

        // INC B
        0x04 => instructionsNew.arithmetic.inc_reg8(proc, proc.B()),

        // DEC B
        0x05 => instructionsNew.arithmetic.dec_reg8(proc, proc.B()),

        // LD B, d8
        0x06 => instructions.load.reg_imm8(proc, &proc.B),

        // RLCA
        0x07 => instructions.bitShift.rotate_left_circular_a(&proc),

        // LD (a16), SP
        0x08 => instructions.load.imm16Mem_spr(proc, proc.SP),

        // ADD HL, BC
        0x09 => instructionsNew.arithmetic.add_reg16_reg16(proc, &proc.HL.value, &proc.BC.value),

        // LD A, (BC)
        0x0A => instructions.load.reg8_reg16_indirect(proc, &proc.A, .BC),

        // DEC BC
        0x0B => instructionsNew.arithmetic.dec_reg16(proc, &proc.BC.value),

        // INC C
        0x0C => instructionsNew.arithmetic.inc_reg8(proc, proc.C()),

        // DEC C
        0x0D => instructionsNew.arithmetic.dec_reg8(proc, proc.C()),

        // LD C, d8
        0x0E => instructions.load.reg_imm8(proc, &proc.C),

        // RRCA
        0x0F => instructions.bitShift.rotate_right_circular_a(proc),

        // LD DE, d16
        0x11 => instructions.load.reg16_imm16(proc, .DE),

        // LD (DE), A
        0x12 => instructions.load.reg16_indirect_acc8(proc, .DE, &proc.A),

        // INC DE
        0x13 => instructionsNew.arithmetic.inc_reg16(proc, &proc.DE.value),

        // INC D
        0x14 => instructionsNew.arithmetic.inc_reg8(proc, proc.D()),

        // DEC D
        0x15 => instructionsNew.arithmetic.dec_reg8(proc, proc.D()),

        // LD D, d8
        0x16 => instructions.load.reg_imm8(proc, &proc.D),

        // RLA
        0x17 => instructions.bitShift.rotate_left_a(&proc),

        // JR s8
        0x18 => instructions.controlFlow.jump_rel_imm8(proc),

        // ADD HL, DE
        0x19 => instructionsNew.arithmetic.add_reg16_reg16(proc, &proc.HL.value, &proc.DE.value),

        // DEC DE
        0x1B => instructionsNew.arithmetic.dec_reg16(proc, &proc.DE.value),

        // INC E
        0x1C => instructionsNew.arithmetic.inc_reg8(proc, proc.E()),

        // DEC E
        0x1D => instructionsNew.arithmetic.dec_reg8(proc, proc.E()),

        // RRA
        0x1F => instructions.bitShift.rotate_right_a(proc),

        // JR NZ, s8
        0x20 => instructions.controlFlow.jump_rel_cc_imm8(proc, &proc.flags.zero, .is_not_set),

        // LD HL, d16
        0x21 => instructions.load.reg16_imm16(proc, .HL),

        // INC HL
        0x23 => instructionsNew.arithmetic.inc_reg16(proc, &proc.HL.value),

        // INC H
        0x24 => instructionsNew.arithmetic.inc_reg8(proc, proc.H()),

        // DEC H
        0x25 => instructionsNew.arithmetic.dec_reg8(proc, proc.H()),

        // DAA
        0x27 => instructions.misc.decimal_adjust_accumulator(proc),

        // JR Z, s8
        0x28 => instructions.controlFlow.jump_rel_cc_imm8(proc, .Z),

        // ADD HL, HL
        0x29 => instructionsNew.arithmetic.add_reg16_reg16(proc, &proc.HL.value, &proc.HL.value),

        // DEC HL
        0x2B => instructionsNew.arithmetic.dec_reg16(proc, &proc.HL.value),

        // INC L
        0x2C => instructionsNew.arithmetic.inc_reg8(proc, proc.L()),

        // DEC L
        0x2D => instructionsNew.arithmetic.dec_reg8(proc, proc.L()),

        // CPL
        0x2F => instructions.misc.complement_a8(proc),

        // JR NC, s8
        0x30 => instructions.controlFlow.jump_rel_cc_imm8(proc, .NC),

        // INC SP
        0x33 => instructionsNew.arithmetic.inc_sp(proc),

        // INC (HL)
        0x34 => instructionsNew.arithmetic.inc_reg16(proc, &proc.HL.value),

        // DEC (HL)
        0x35 => instructionsNew.arithmetic.dec_reg16(proc, &proc.HL.value),

        // SCF
        0x37 => instructions.misc.set_carry_flag(proc),

        // JR C, s8
        0x38 => instructions.controlFlow.jump_rel_cc_imm8(proc, .C),

        // ADD HL, SP
        0x39 => instructionsNew.arithmetic.add_hl_sp(proc),

        // DEC SP
        0x3B => instructionsNew.arithmetic.dec_sp(proc),

        // INC A
        0x3C => instructionsNew.arithmetic.inc_reg8(proc, proc.A()),

        // DEC A
        0x3D => instructionsNew.arithmetic.dec_reg8(proc, proc.A()),

        // CCF
        0x3F => instructions.misc.complement_carry_flag(proc),

        // LD A, (DE)
        0x1A => instructions.load.reg8_reg16_indirect(proc, &proc.A, .DE),

        // LD E, d8
        0x1E => instructions.load.reg_imm8(proc, &proc.E),

        // LD (HL+), A
        0x22 => instructions.load.hl_indirect_inc_reg8(proc, &proc.A),

        // LD H, d8
        0x26 => instructions.load.reg_imm8(proc, &proc.H),

        // LD A, (HL+)
        0x2A => instructions.load.reg8_hl_indirect_inc(proc, &proc.A),

        // LD L, d8
        0x2E => instructions.load.reg_imm8(proc, &proc.L),

        // LD SP, d16
        0x31 => instructions.load.spr_imm16(proc, &proc.SP),

        // LD (HL-), A
        0x32 => instructions.load.hl_indirect_dec_reg8(proc, &proc.A),

        // LD (HL), d8
        0x36 => instructions.load.reg16_indirect_imm8(proc, .HL),

        // LD A, (HL-)
        0x3A => instructions.load.reg8_hl_indirect_dec(proc, &proc.A),

        // LD A, d8
        0x3E => instructions.load.reg_imm8(proc, &proc.A),

        // LD B, B
        0x40 => instructions.load.reg8_reg8(&proc.B, &proc.B),

        // LD B, C
        0x41 => instructions.load.reg8_reg8(&proc.B, &proc.C),

        // LD B, D
        0x42 => instructions.load.reg8_reg8(&proc.B, &proc.D),

        // LD B, E
        0x43 => instructions.load.reg8_reg8(&proc.B, &proc.E),

        // LD B, H
        0x44 => instructions.load.reg8_reg8(&proc.B, &proc.H),

        // LD B, L
        0x45 => instructions.load.reg8_reg8(&proc.B, &proc.L),

        // LD B, (HL)
        0x46 => instructions.load.reg8_reg16_indirect(proc, &proc.B, .HL),

        // LD B, A
        0x47 => instructions.load.reg8_reg8(&proc.B, &proc.A),

        // LD C, B
        0x48 => instructions.load.reg8_reg8(&proc.C, &proc.B),

        // LD C, C
        0x49 => instructions.load.reg8_reg8(&proc.C, &proc.C),

        // LD C, D
        0x4A => instructions.load.reg8_reg8(&proc.C, &proc.D),

        // LD C, E
        0x4B => instructions.load.reg8_reg8(&proc.C, &proc.E),

        // LD C, H
        0x4C => instructions.load.reg8_reg8(&proc.C, &proc.H),

        // LD C, L
        0x4D => instructions.load.reg8_reg8(&proc.C, &proc.L),

        // LD C, (HL)
        0x4E => instructions.load.reg8_reg16_indirect(proc, &proc.C, .HL),

        // LD C, A
        0x4F => instructions.load.reg8_reg8(&proc.C, &proc.A),

        // LD D, B
        0x50 => instructions.load.reg8_reg8(&proc.D, &proc.B),

        // LD D, C
        0x51 => instructions.load.reg8_reg8(&proc.D, &proc.C),

        // LD D, D
        0x52 => instructions.load.reg8_reg8(&proc.D, &proc.D),

        // LD D, E
        0x53 => instructions.load.reg8_reg8(&proc.D, &proc.E),

        // LD D, H
        0x54 => instructions.load.reg8_reg8(&proc.D, &proc.H),

        // LD D, L
        0x55 => instructions.load.reg8_reg8(&proc.D, &proc.L),

        // LD D, (HL)
        0x56 => instructions.load.reg8_reg16_indirect(proc, &proc.D, .HL),

        // LD D, A
        0x57 => instructions.load.reg8_reg8(&proc.D, &proc.A),

        // LD E, B
        0x58 => instructions.load.reg8_reg8(&proc.E, &proc.B),

        // LD E, C
        0x59 => instructions.load.reg8_reg8(&proc.E, &proc.C),

        // LD E, D
        0x5A => instructions.load.reg8_reg8(&proc.E, &proc.D),

        // LD E, E
        0x5B => instructions.load.reg8_reg8(&proc.E, &proc.E),

        // LD E, H
        0x5C => instructions.load.reg8_reg8(&proc.E, &proc.H),

        // LD E, L
        0x5D => instructions.load.reg8_reg8(&proc.E, &proc.L),

        // LD E, (HL)
        0x5E => instructions.load.reg8_reg16_indirect(proc, &proc.E, .HL),

        // LD E, A
        0x5F => instructions.load.reg8_reg8(&proc.E, &proc.A),

        // LD H, B
        0x60 => instructions.load.reg8_reg8(&proc.H, &proc.B),

        // LD H, C
        0x61 => instructions.load.reg8_reg8(&proc.H, &proc.C),

        // LD H, D
        0x62 => instructions.load.reg8_reg8(&proc.H, &proc.D),

        // LD H, E
        0x63 => instructions.load.reg8_reg8(&proc.H, &proc.E),

        // LD H, H
        0x64 => instructions.load.reg8_reg8(&proc.H, &proc.H),

        // LD H, L
        0x65 => instructions.load.reg8_reg8(&proc.H, &proc.L),

        // LD H, (HL)
        0x66 => instructions.load.reg8_reg16_indirect(proc, &proc.H, .HL),

        // LD H, A
        0x67 => instructions.load.reg8_reg8(&proc.H, &proc.A),

        // LD L, B
        0x68 => instructions.load.reg8_reg8(&proc.L, &proc.B),

        // LD L, C
        0x69 => instructions.load.reg8_reg8(&proc.L, &proc.C),

        // LD L, D
        0x6A => instructions.load.reg8_reg8(&proc.L, &proc.D),

        // LD L, E
        0x6B => instructions.load.reg8_reg8(&proc.L, &proc.E),

        // LD L, H
        0x6C => instructions.load.reg8_reg8(&proc.L, &proc.H),

        // LD L, L
        0x6D => instructions.load.reg8_reg8(&proc.L, &proc.L),

        // LD L, (HL)
        0x6E => instructions.load.reg8_reg16_indirect(proc, &proc.L, .HL),

        // LD L, A
        0x6F => instructions.load.reg8_reg8(&proc.L, &proc.A),

        // LD (HL), B
        0x70 => instructions.load.hl_indirect_reg8(proc, &proc.B),

        // LD (HL), C
        0x71 => instructions.load.hl_indirect_reg8(proc, &proc.C),

        // LD (HL), D
        0x72 => instructions.load.hl_indirect_reg8(proc, &proc.D),

        // LD (HL), E
        0x73 => instructions.load.hl_indirect_reg8(proc, &proc.E),

        // LD (HL), H
        0x74 => instructions.load.hl_indirect_reg8(proc, &proc.H),

        // LD (HL), L
        0x75 => instructions.load.hl_indirect_reg8(proc, &proc.L),

        // HALT
        0x76 => { proc.isHalted = true; },

        // LD (HL), A
        0x77 => instructions.load.hl_indirect_reg8(proc, &proc.A),

        // LD A, B
        0x78 => instructions.load.reg8_reg8(&proc.A, &proc.B),

        // LD A, C
        0x79 => instructions.load.reg8_reg8(&proc.A, &proc.C),

        // LD A, D
        0x7A => instructions.load.reg8_reg8(&proc.A, &proc.D),

        // LD A, E
        0x7B => instructions.load.reg8_reg8(&proc.A, &proc.E),

        // LD A, H
        0x7C => instructions.load.reg8_reg8(&proc.A, &proc.H),

        // LD A, L
        0x7D => instructions.load.reg8_reg8(&proc.A, &proc.L),

        // LD A, (HL)
        0x7E => instructions.load.reg8_reg16_indirect(proc, &proc.A, .HL),

        // LD A, A
        0x7F => instructions.load.reg8_reg8(&proc.A, &proc.A),

        // ADD B
        0x80 => instructionsNew.arithmetic.add_reg8(proc, proc.B()),

        // ADD C
        0x81 => instructionsNew.arithmetic.add_reg8(proc, proc.C()),

        // ADD D
        0x82 => instructionsNew.arithmetic.add_reg8(proc, proc.D()),

        // ADD E
        0x83 => instructionsNew.arithmetic.add_reg8(proc, proc.E()),

        // ADD H
        0x84 => instructionsNew.arithmetic.add_reg8(proc, proc.H()),

        // ADD L
        0x85 => instructionsNew.arithmetic.add_reg8(proc, proc.L()),

        // ADD A, (HL)
        0x86 => instructionsNew.arithmetic.add_hl_indirect(proc),

        // ADD A ,A
        0x87 => instructionsNew.arithmetic.add_reg8(proc, &proc.accumulator),

        // ADC B
        0x88 => instructionsNew.arithmetic.addc_reg8(proc, proc.B()),

        // ADC C
        0x89 => instructionsNew.arithmetic.addc_reg8(proc, proc.C()),

        // ADC D
        0x8A => instructionsNew.arithmetic.addc_reg8(proc, proc.D()),

        // ADC E
        0x8B => instructionsNew.arithmetic.addc_reg8(proc, proc.E()),

        // ADC H
        0x8C => instructionsNew.arithmetic.addc_reg8(proc, proc.H()),

        // ADC H
        0x8D => instructionsNew.arithmetic.addc_reg8(proc, proc.L()),

        // ADC (HL)
        0x8E => instructionsNew.arithmetic.addc_hl_indirect(proc),

        // ADC A
        0x8F => instructionsNew.arithmetic.addc_reg8(proc, proc.A()),

        // SUB B
        0x90 => instructionsNew.arithmetic.sub_reg8(proc, proc.B()),

        // SUB C
        0x91 => instructionsNew.arithmetic.sub_reg8(proc, proc.C()),

        // SUB D
        0x92 => instructionsNew.arithmetic.sub_reg8(proc, proc.D()),

        // SUB E
        0x93 => instructionsNew.arithmetic.sub_reg8(proc, proc.E()),

        // SUB H
        0x94 => instructionsNew.arithmetic.sub_reg8(proc, proc.H()),

        // SUB L
        0x95 => instructionsNew.arithmetic.sub_reg8(proc, proc.L()),

        // SUB (HL)
        0x96 => instructionsNew.arithmetic.sub_hl_indirect(proc),

        // SUB A, A
        0x97 => instructionsNew.arithmetic.sub_reg8(proc, proc.A()),

        // SBC B
        0x98 => instructionsNew.arithmetic.subc_reg8(proc, proc.B()),

        // SBC C
        0x99 => instructionsNew.arithmetic.subc_reg8(proc, proc.C()),

        // SBC D
        0x9A => instructionsNew.arithmetic.subc_reg8(proc, proc.D()),

        // SBC E
        0x9B => instructionsNew.arithmetic.subc_reg8(proc, proc.E()),

        // SBC H
        0x9C => instructionsNew.arithmetic.subc_reg8(proc, proc.H()),

        // SBC L
        0x9D => instructionsNew.arithmetic.subc_reg8(proc, proc.L()),

        // SBC A, (HL)
        0x9E => instructionsNew.arithmetic.subc_hl_indirect(proc),

        // SBC A, A
        0x9F => instructionsNew.arithmetic.subc_reg8(proc, proc.A()),

        // AND B
        0xA0 => instructionsNew.arithmetic.and_reg8(proc, proc.B()),

        // AND C
        0xA1 => instructionsNew.arithmetic.and_reg8(proc, proc.C()),

        // AND D
        0xA2 => instructionsNew.arithmetic.and_reg8(proc, proc.D()),

        // AND E
        0xA3 => instructionsNew.arithmetic.and_reg8(proc, proc.E()),

        // AND H
        0xA4 => instructionsNew.arithmetic.and_reg8(proc, proc.H()),

        // AND L
        0xA5 => instructionsNew.arithmetic.and_reg8(proc, proc.L()),

        // AND A, (HL)
        0xA6 => instructionsNew.arithmetic.and_hl_indirect(proc),

        // AND A, A
        0xA7 => instructionsNew.arithmetic.and_reg8(proc, &proc.accumulator),

        // XOR B
        0xA8 => instructionsNew.arithmetic.xor_reg8(proc, proc.B()),

        // XOR C
        0xA9 => instructionsNew.arithmetic.xor_reg8(proc, proc.C()),

        // XOR D
        0xAA => instructionsNew.arithmetic.xor_reg8(proc, proc.D()),

        // XOR E
        0xAB => instructionsNew.arithmetic.xor_reg8(proc, proc.E()),

        // XOR H
        0xAC => instructionsNew.arithmetic.xor_reg8(proc, proc.H()),

        // XOR L
        0xAD => instructionsNew.arithmetic.xor_reg8(proc, proc.L()),

        // XOR (HL)
        0xAE => instructionsNew.arithmetic.xor_hl_indirect(proc),

        // XOR A, A
        0xAF => instructionsNew.arithmetic.xor_reg8(proc, &proc.accumulator),

        // OR B
        0xB0 => instructionsNew.arithmetic.or_reg8(proc, proc.B()),

        // OR C
        0xB1 => instructionsNew.arithmetic.or_reg8(proc, proc.C()),

        // OR D
        0xB2 => instructionsNew.arithmetic.or_reg8(proc, proc.D()),

        // OR E
        0xB3 => instructionsNew.arithmetic.or_reg8(proc, proc.E()),

        // OR H
        0xB4 => instructionsNew.arithmetic.or_reg8(proc, proc.H()),

        // OR L
        0xB5 => instructionsNew.arithmetic.or_reg8(proc, proc.L()),

        // OR (HL)
        0xB6 => instructionsNew.arithmetic.or_hl_indirect(proc),

        // OR A, A
        0xB7 => instructionsNew.arithmetic.or_reg8(proc, &proc.accumulator),

        // CP B
        0xB8 => instructionsNew.arithmetic.compare_reg8(proc, proc.B()),

        // CP C
        0xB9 => instructionsNew.arithmetic.compare_reg8(proc, proc.C()),

        // CP D
        0xBA => instructionsNew.arithmetic.compare_reg8(proc, proc.D()),

        // CP E
        0xBB => instructionsNew.arithmetic.compare_reg8(proc, proc.E()),

        // CP H
        0xBC => instructionsNew.arithmetic.compare_reg8(proc, proc.H()),

        // CP L
        0xBD => instructionsNew.arithmetic.compare_reg8(proc, proc.L()),

        // CP (HL)
        0xBE => instructionsNew.arithmetic.compare_hl_indirect(proc),

        // CP A, A
        0xBF => instructionsNew.arithmetic.compare_reg8(proc, &proc.accumulator),

        // RET NZ
        0xC0 => instructions.controlFlow.ret_cc(proc, .NZ),

        // POP BC
        0xC1 => instructions.controlFlow.pop_rr(proc, .BC),

        // JP NZ, a16
        0xC2 => instructions.controlFlow.jump_cc_imm16(proc, .NZ),

        // JP a16
        0xC3 => instructions.controlFlow.jump_imm16(proc),

        // CALL NZ, a16
        0xC4 => instructions.controlFlow.call_cc_imm16(proc, .NZ),

        // PUSH BC
        0xC5 => instructions.controlFlow.push_rr(proc, .BC),

        // ADD A, d8
        0xC6 => instructionsNew.arithmetic.add_imm8(proc),

        // RST 0
        0xC7 => instructions.controlFlow.rst(proc, 0),

        // RET Z
        0xC8 => instructions.controlFlow.ret_cc(proc, .Z),

        // RET
        0xC9 => instructions.controlFlow.ret(proc),

        // JP Z, a16
        0xCA => instructions.controlFlow.jump_cc_imm16(proc, .Z),

        // CB Prefix
        0xCB => proc.decodeAndExecuteCBPrefix(),

        // CALL Z, a16
        0xCC => instructions.controlFlow.call_cc_imm16(proc, .Z),

        // CALL a16
        0xCD => instructions.controlFlow.call_imm16(proc),

        // ADC A, d8
        0xCE => instructionsNew.arithmetic.addc_imm8(proc),

        // RST 1
        0xCF => instructions.controlFlow.rst(proc, 1),

        // RET NC
        0xD0 => instructions.controlFlow.ret_cc(proc, .NC),

        // POP DE
        0xD1 => instructions.controlFlow.pop_rr(proc, .DE),

        // JP NC, a16
        0xD2 => instructions.controlFlow.jump_cc_imm16(proc, .NC),

        // CALL NC, a16
        0xD4 => instructions.controlFlow.call_cc_imm16(proc, .N),

        // PUSH DE
        0xD5 => instructions.controlFlow.push_rr(proc, .DE),

        // 0xD6
        0xD6 => instructionsNew.arithmetic.sub_imm8(proc),

        // RST 2
        0xD7 => instructions.controlFlow.rst(proc, 2),

        // RET C
        0xD8 => instructions.controlFlow.ret_cc(proc, .C),

        // RETI
        0xD9 => instructions.controlFlow.reti(proc),

        // JP C, a16
        0xDA => instructions.controlFlow.jump_cc_imm16(proc, .C),

        // CALL C, a16
        0xDC => instructions.controlFlow.call_cc_imm16(proc, .C),

        // RST 3
        0xDF => instructions.controlFlow.rst(proc, 3),

        // SBC A, d8
        0xDE => instructionsNew.arithmetic.subc_imm8(proc),

        // LD (a8), A
        0xE0 => instructions.load.imm8_indirect_reg8(proc, &proc.A),

        // POP HL
        0xE1 => instructions.controlFlow.pop_rr(proc, .HL),

        // LD (C), A
        0xE2 => instructions.load.reg8_indirect_reg8(proc, &proc.C, &proc.A),

        // PUSH HL
        0xE5 => instructions.controlFlow.push_rr(proc, .HL),

        // AND d8
        0xE6 => instructionsNew.arithmetic.and_imm8(proc),

        // RST 4
        0xE7 => instructions.controlFlow.rst(proc, 4),

        // ADD SP s8
        0xE8 => instructionsNew.arithmetic.add_sp_offset(proc),

        // JP HL
        0xE9 => instructions.controlFlow.jump_hl(proc, .HL),

        // LD (a16), A
        0xEA => instructions.load.imm16Mem_reg(proc, &proc.A),

        // XOR d8
        0xEE => instructionsNew.arithmetic.xor_imm8(proc),

        // RST 5
        0xEF => instructions.controlFlow.rst(proc, 5),

        // LD A, (a8)
        0xF0 => instructions.load.reg_imm8_indirect(proc, &proc.A),

        // POP AF
        0xF1 => instructions.controlFlow.pop_rr(proc, .AF),

        // LD A, (C)
        0xF2 => instructions.load.reg8_reg8_indirect(proc, &proc.A, &proc.C),

        // DI
        0xF3 => { proc.IME = false; },

        // PUSH AF
        0xF5 => instructions.controlFlow.push_rr(proc, .AF),

        // OR d8
        0xF6 => instructionsNew.arithmetic.or_imm8(proc),

        // RST 6
        0xF7 => instructions.controlFlow.rst(proc, 6),

        // LD HL, SP+s8
        0xF8 => instructions.load.hl_sp_imm8(proc),

        // LD SP, HL
        0xF9 => instructions.load.spr_rr(proc, &proc.SP, .HL),

        // LD A, (a16)
        0xFA => instructions.load.reg8_imm16_indirect(proc, &proc.A),

        // EI
        0xFB => { proc.IME = true; },

        // CP d8
        0xFE => instructionsNew.arithmetic.compare_imm8(proc),

        // RST 7
        0xFF => instructions.controlFlow.rst(proc, 7),

        else => {
            std.debug.print("op_code: {any} not implemented!", .{op_code});
        },
    }
}

const expectEqual = std.testing.expectEqual;

test "isFlagSet, Z" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .zeroFlag = 1 });

    try expectEqual(true, processor.isFlagSet(.zero));
    try expectEqual(false, processor.isFlagSet(.negative));
    try expectEqual(false, processor.isFlagSet(.half_carry));
    try expectEqual(false, processor.isFlagSet(.carry));
}

test "isFlagSet, N" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .negativeFlag = 1 });

    try expectEqual(false, processor.isFlagSet(.zero));
    try expectEqual(true, processor.isFlagSet(.negative));
    try expectEqual(false, processor.isFlagSet(.half_carry));
    try expectEqual(false, processor.isFlagSet(.carry));
}

test "isFlagSet, H" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .halfCarryFlag = 1 });

    try expectEqual(false, processor.isFlagSet(.zero));
    try expectEqual(false, processor.isFlagSet(.negative));
    try expectEqual(true, processor.isFlagSet(.half_carry));
    try expectEqual(false, processor.isFlagSet(.carry));
}

test "isFlagSet, C" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .carryFlag = 1 });

    try expectEqual(false, processor.isFlagSet(.zero));
    try expectEqual(false, processor.isFlagSet(.negative));
    try expectEqual(false, processor.isFlagSet(.half_carry));
    try expectEqual(true, processor.isFlagSet(.carry));
}

test "popStack" {
    const SP: u16 = 0x0AFF;
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .SP = SP });

    const content: u8 = 0x13;
    processor.memory.write(SP, content);

    try expectEqual(content, processor.popStack());
    try expectEqual(SP + 1, processor.SP);
}

test "pushStack" {
    const SP: u16 = 0x0AFF;
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .SP = SP });

    const content: u8 = 0x13;
    processor.pushStack(content);

    try expectEqual(content, processor.memory.read(SP - 1));
    try expectEqual(SP - 1, processor.SP);
}

test "test instructions" {
    _ = @import("./instructions/root.zig");
}
