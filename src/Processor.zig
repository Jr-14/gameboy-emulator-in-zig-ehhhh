const std = @import("std");
const utils = @import("utils.zig");

const PackedRegisterPair = @import("register.zig").PackgedRegisterPair;
const Memory = @import("Memory.zig");
const Instruction = @import("instructions/root.zig");

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
isStopped: bool = false,

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
    return proc.BC.highPtr();
}

pub inline fn C(proc: *Processor) *u8 {
    return proc.BC.lowPtr();
}

pub inline fn D(proc: *Processor) *u8 {
    return proc.DE.highPtr();
}

pub inline fn E(proc: *Processor) *u8 {
    return proc.DE.lowPtr();
}

pub inline fn H(proc: *Processor) *u8 {
    return proc.HL.highPtr();
}

pub inline fn L(proc: *Processor) *u8 {
    return proc.HL.lowPtr();
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
        0x00 => Instruction.bitShift.rotate_left_circular_reg8(proc, proc.B()),

        // RLC C
        0x01 => Instruction.bitShift.rotate_left_circular_reg8(proc, proc.C()),

        // RLC D
        0x02 => Instruction.bitShift.rotate_left_circular_reg8(proc, proc.D()),

        // RLC E
        0x03 => Instruction.bitShift.rotate_left_circular_reg8(proc, proc.E()),

        // RLC H
        0x04 => Instruction.bitShift.rotate_left_circular_reg8(proc, proc.H()),

        // RLC L
        0x05 => Instruction.bitShift.rotate_left_circular_reg8(proc, proc.L()),

        // RLC (HL)
        0x06 => Instruction.bitShift.rotate_left_circular_hl_indirect(proc),

        // RLC A
        0x07 => Instruction.bitShift.rotate_left_circular_reg8(proc, &proc.accumulator),

        // RRC B
        0x08 => Instruction.bitShift.rotate_right_circular_reg8(proc, proc.B()),

        // RRC C
        0x09 => Instruction.bitShift.rotate_right_circular_reg8(proc, proc.C()),

        // RRC D
        0x0A => Instruction.bitShift.rotate_right_circular_reg8(proc, proc.D()),

        // RRC E
        0x0B => Instruction.bitShift.rotate_right_circular_reg8(proc, proc.E()),

        // RRC H
        0x0C => Instruction.bitShift.rotate_right_circular_reg8(proc, proc.H()),

        // RRC L
        0x0D => Instruction.bitShift.rotate_right_circular_reg8(proc, proc.L()),

        // RRC (HL)
        0x0E => Instruction.bitShift.rotate_right_circular_hl_indirect(proc),

        // RRC
        0x0F => Instruction.bitShift.rotate_right_circular_reg8(proc, &proc.A),

        // RL B
        0x10 => Instruction.bitShift.rotate_left_reg8(proc, proc.B()),

        // RL C
        0x11 => Instruction.bitShift.rotate_left_reg8(proc, proc.C()),

        // RL D
        0x12 => Instruction.bitShift.rotate_left_reg8(proc, proc.D()),

        // RL E
        0x13 => Instruction.bitShift.rotate_left_reg8(proc, proc.E()),

        // RL H
        0x14 => Instruction.bitShift.rotate_left_reg8(proc, proc.H()),

        // RL L
        0x15 => Instruction.bitShift.rotate_left_reg8(proc, proc.L()),

        // RL (HL)
        0x16 => Instruction.bitShift.rotate_left_hl_indirect(&proc),

        // RL A
        0x17 => Instruction.bitShift.rotate_left_reg8(proc, &proc.accumulator),

        // RR B
        0x18 => Instruction.bitShift.rotate_right_reg8(proc, proc.B()),

        // RR C
        0x19 => Instruction.bitShift.rotate_right_reg8(proc, proc.C()),

        // RR D
        0x1A => Instruction.bitShift.rotate_right_reg8(proc, proc.D()),

        // RR E
        0x1B => Instruction.bitShift.rotate_right_reg8(proc, proc.E()),

        // RR H
        0x1C => Instruction.bitShift.rotate_right_reg8(proc, proc.H()),

        // RR L
        0x1D => Instruction.bitShift.rotate_right_reg8(proc, proc.L()),

        // RR (HL)
        0x1E => Instruction.bitShift.rotate_right_hl_indirect(&proc),

        // RR A
        0x1F => Instruction.bitShift.rotate_right_reg8(proc, &proc.accumulator),

        // SLA B
        0x20 => Instruction.bitShift.shift_left_arithmetic_reg8(proc, proc.B()),

        // SLA C
        0x21 => Instruction.bitShift.shift_left_arithmetic_reg8(proc, proc.C()),

        // SLA D
        0x22 => Instruction.bitShift.shift_left_arithmetic_reg8(proc, proc.D()),

        // SLA E
        0x23 => Instruction.bitShift.shift_left_arithmetic_reg8(proc, proc.E()),

        // SLA H
        0x24 => Instruction.bitShift.shift_left_arithmetic_reg8(proc, proc.H()),

        // SLA L
        0x25 => Instruction.bitShift.shift_left_arithmetic_reg8(proc, proc.L()),

        // SLA (HL)
        0x26 => Instruction.bitShift.shift_left_arithmetic_hl_indirect(&proc),

        // SLA A
        0x27 => Instruction.bitShift.shift_left_arithmetic_reg8(proc, &proc.accumulator),

        // SRA B
        0x28 => Instruction.bitShift.shift_right_arithmetic_reg8(proc, proc.B()),

        // SRA C
        0x29 => Instruction.bitShift.shift_right_arithmetic_reg8(proc, proc.C()),

        // SRA D
        0x2A => Instruction.bitShift.shift_right_arithmetic_reg8(proc, proc.D()),

        // SRA E
        0x2B => Instruction.bitShift.shift_right_arithmetic_reg8(proc, proc.E()),

        // SRA H
        0x2C => Instruction.bitShift.shift_right_arithmetic_reg8(proc, proc.H()),

        // SRA L
        0x2D => Instruction.bitShift.shift_right_arithmetic_reg8(proc, proc.L()),

        // SRA (HL)
        0x2E => Instruction.bitShift.shift_right_arithmetic_hl_indirect(&proc),

        // SRA A
        0x2F => Instruction.bitShift.shift_right_arithmetic_reg8(proc, &proc.accumulator),

        // SWAP B
        0x30 => Instruction.bitShift.swap_reg8(proc, proc.B()),

        // SWAP C
        0x31 => Instruction.bitShift.swap_reg8(proc, proc.C()),

        // SWAP D
        0x32 => Instruction.bitShift.swap_reg8(proc, proc.D()),

        // SWAP E
        0x33 => Instruction.bitShift.swap_reg8(proc, proc.E()),

        // SWAP H
        0x34 => Instruction.bitShift.swap_reg8(proc, proc.H()),

        // SWAP L
        0x35 => Instruction.bitShift.swap_reg8(proc, proc.L()),

        // SWAP (HL)
        0x36 => Instruction.bitShift.swap_hl_indirect(&proc),

        // SWAP A
        0x37 => Instruction.bitShift.swap_reg8(proc, &proc.accumulator),

        // SRL B
        0x38 => Instruction.bitShift.shift_right_logical_reg8(proc, proc.B()),

        // SRL C
        0x39 => Instruction.bitShift.shift_right_logical_reg8(proc, proc.D()),

        // SRL D
        0x3A => Instruction.bitShift.shift_right_logical_reg8(proc, proc.D()),

        // SRL E
        0x3B => Instruction.bitShift.shift_right_logical_reg8(proc, proc.E()),

        // SRL H
        0x3C => Instruction.bitShift.shift_right_logical_reg8(proc, proc.H()),

        // SRL L
        0x3D => Instruction.bitShift.shift_right_logical_reg8(proc, proc.L()),

        // SRL (HL)
        0x3E => Instruction.bitShift.shift_right_logical_hl_indirect(&proc),

        // SRL A
        0x3F => Instruction.bitShift.shift_right_logical_reg8(proc, &proc.accumulator),

        // BIT 0, B
        0x40 => Instruction.bitFlag.test_bit_reg8(proc, .zero, proc.B()),

        // BIT 0, C
        0x41 => Instruction.bitFlag.test_bit_reg8(proc, .zero, proc.C()),

        // BIT 0, D
        0x42 => Instruction.bitFlag.test_bit_reg8(proc, .zero, proc.D()),

        // BIT 0, E
        0x43 => Instruction.bitFlag.test_bit_reg8(proc, .zero, proc.E()),

        // BIT 0, H
        0x44 => Instruction.bitFlag.test_bit_reg8(proc, .zero, proc.H()),

        // BIT 0, L
        0x45 => Instruction.bitFlag.test_bit_reg8(proc, .zero, proc.L()),

        // BIT 0, (HL)
        0x46 => Instruction.bitFlag.test_bit_hl_indirect(proc, .zero),

        // BIT 0, A
        0x47 => Instruction.bitFlag.test_bit_reg8(proc, .zero, &proc.accumulator),

        // BIT 1, B
        0x48 => Instruction.bitFlag.test_bit_reg8(proc, .one, proc.B()),

        // BIT 1, C
        0x49 => Instruction.bitFlag.test_bit_reg8(proc, .one, proc.C()),

        // BIT 1, D
        0x4A => Instruction.bitFlag.test_bit_reg8(proc, .one, proc.D()),

        // BIT 1, E
        0x4B => Instruction.bitFlag.test_bit_reg8(proc, .one, proc.E()),

        // BIT 1, H
        0x4C => Instruction.bitFlag.test_bit_reg8(proc, .one, proc.H()),

        // BIT 1, L
        0x4D => Instruction.bitFlag.test_bit_reg8(proc, .one, proc.L()),

        // BIT 1, (HL)
        0x4E => Instruction.bitFlag.test_bit_hl_indirect(proc, .one),

        // BIT 1, A
        0x4F => Instruction.bitFlag.test_bit_reg8(proc, .one, &proc.accumulator),

        // BIT 2, B
        0x50 => Instruction.bitFlag.test_bit_reg8(proc, .two, proc.B()),

        // BIT 2, C
        0x51 => Instruction.bitFlag.test_bit_reg8(proc, .two, proc.C()),

        // BIT 2, D
        0x52 => Instruction.bitFlag.test_bit_reg8(proc, .two, proc.D()),

        // BIT 2, E
        0x53 => Instruction.bitFlag.test_bit_reg8(proc, .two, proc.E()),

        // BIT 2, H
        0x54 => Instruction.bitFlag.test_bit_reg8(proc, .two, proc.H()),

        // BIT 2, L
        0x55 => Instruction.bitFlag.test_bit_reg8(proc, .two, proc.L()),

        // BIT 2, (HL)
        0x56 => Instruction.bitFlag.test_bit_hl_indirect(proc, .two),

        // BIT 2, A
        0x57 => Instruction.bitFlag.test_bit_reg8(proc, .two, &proc.accumulator),

        // BIT 3, B
        0x58 => Instruction.bitFlag.test_bit_reg8(proc, .three, proc.B()),

        // BIT 3, C
        0x59 => Instruction.bitFlag.test_bit_reg8(proc, .three, proc.C()),

        // BIT 3, D
        0x5A => Instruction.bitFlag.test_bit_reg8(proc, .three, proc.D()),

        // BIT 3, E
        0x5B => Instruction.bitFlag.test_bit_reg8(proc, .three, proc.E()),

        // BIT 3, H
        0x5C => Instruction.bitFlag.test_bit_reg8(proc, .three, proc.H()),

        // BIT 3, L
        0x5D => Instruction.bitFlag.test_bit_reg8(proc, .three, proc.L()),

        // BIT 3, (HL)
        0x5E => Instruction.bitFlag.test_bit_hl_indirect(proc, .three),

        // BIT 3, A
        0x5F => Instruction.bitFlag.test_bit_reg8(proc, .three, &proc.accumulator),

        // BIT 4, B
        0x60 => Instruction.bitFlag.test_bit_reg8(proc, .four, proc.B()),

        // BIT 4, C
        0x61 => Instruction.bitFlag.test_bit_reg8(proc, .four, proc.C()),

        // BIT 4, D
        0x62 => Instruction.bitFlag.test_bit_reg8(proc, .four, proc.D()),

        // BIT 4, E
        0x63 => Instruction.bitFlag.test_bit_reg8(proc, .four, proc.E()),

        // BIT 4, H
        0x64 => Instruction.bitFlag.test_bit_reg8(proc, .four, proc.H()),

        // BIT 4, L
        0x65 => Instruction.bitFlag.test_bit_reg8(proc, .four, proc.L()),

        // BIT 4, (HL)
        0x66 => Instruction.bitFlag.test_bit_hl_indirect(proc, .four),

        // BIT 4, A
        0x67 => Instruction.bitFlag.test_bit_reg8(proc, .four, &proc.accumulator),

        // BIT 5, B
        0x68 => Instruction.bitFlag.test_bit_reg8(proc, .five, proc.B()),

        // BIT 5, C
        0x69 => Instruction.bitFlag.test_bit_reg8(proc, .five, proc.C()),

        // BIT 5, D
        0x6A => Instruction.bitFlag.test_bit_reg8(proc, .five, proc.D()),

        // BIT 5, E
        0x6B => Instruction.bitFlag.test_bit_reg8(proc, .five, proc.E()),

        // BIT 5, H
        0x6C => Instruction.bitFlag.test_bit_reg8(proc, .five, proc.H()),

        // BIT 5, L
        0x6D => Instruction.bitFlag.test_bit_reg8(proc, .five, proc.L()),

        // BIT 5, (HL)
        0x6E => Instruction.bitFlag.test_bit_hl_indirect(proc, .five),

        // BIT 5, A
        0x6F => Instruction.bitFlag.test_bit_reg8(proc, .five, &proc.accumulator),

        // BIT 6, B
        0x70 => Instruction.bitFlag.test_bit_reg8(proc, .six, proc.B()),

        // BIT 6, C
        0x71 => Instruction.bitFlag.test_bit_reg8(proc, .six, proc.C()),

        // BIT 6, D
        0x72 => Instruction.bitFlag.test_bit_reg8(proc, .six, proc.D()),

        // BIT 6, E
        0x73 => Instruction.bitFlag.test_bit_reg8(proc, .six, proc.E()),

        // BIT 6, H
        0x74 => Instruction.bitFlag.test_bit_reg8(proc, .six, proc.H()),

        // BIT 6, L
        0x75 => Instruction.bitFlag.test_bit_reg8(proc, .six, proc.L()),

        // BIT 6, (HL)
        0x76 => Instruction.bitFlag.test_bit_hl_indirect(proc, .six),

        // BIT 6, A
        0x77 => Instruction.bitFlag.test_bit_reg8(proc, .six, &proc.accumulator),

        // BIT 7, B
        0x78 => Instruction.bitFlag.test_bit_reg8(proc, .seven, proc.B()),

        // BIT 7, C
        0x79 => Instruction.bitFlag.test_bit_reg8(proc, .seven, proc.C()),

        // BIT 7, D
        0x7A => Instruction.bitFlag.test_bit_reg8(proc, .seven, proc.D()),

        // BIT 7, E
        0x7B => Instruction.bitFlag.test_bit_reg8(proc, .seven, proc.E()),

        // BIT 7, H
        0x7C => Instruction.bitFlag.test_bit_reg8(proc, .seven, proc.H()),

        // BIT 7, L
        0x7D => Instruction.bitFlag.test_bit_reg8(proc, .seven, proc.L()),

        // BIT 7, (HL)
        0x7E => Instruction.bitFlag.test_bit_hl_indirect(proc, .seven),

        // BIT 7, A
        0x7F => Instruction.bitFlag.test_bit_reg8(proc, .seven, &proc.accumulator),

        // RES 0, B
        0x80 => Instruction.bits.reset_bit_reg8(.zero, &proc.B),

        // RES 0, C
        0x81 => Instruction.bits.reset_bit_reg8(.zero, &proc.C),

        // RES 0, D
        0x82 => Instruction.bits.reset_bit_reg8(.zero, &proc.D),

        // RES 0, E
        0x83 => Instruction.bits.reset_bit_reg8(.zero, &proc.E),

        // RES 0, H
        0x84 => Instruction.bits.reset_bit_reg8(.zero, &proc.H),

        // RES 0, L
        0x85 => Instruction.bits.reset_bit_reg8(.zero, &proc.L),

        // RES 0, (HL)
        0x86 => Instruction.bits.reset_bit_hl_indirect(proc, .zero),

        // RES 0, A
        0x87 => Instruction.bits.reset_bit_reg8(.zero, &proc.A),

        // RES 1, B
        0x88 => Instruction.bits.reset_bit_reg8(.one, &proc.B),

        // RES 1, C
        0x89 => Instruction.bits.reset_bit_reg8(.one, &proc.C),

        // RES 1, D
        0x8A => Instruction.bits.reset_bit_reg8(.one, &proc.D),

        // RES 1, E
        0x8B => Instruction.bits.reset_bit_reg8(.one, &proc.E),

        // RES 1, H
        0x8C => Instruction.bits.reset_bit_reg8(.one, &proc.H),

        // RES 1, L
        0x8D => Instruction.bits.reset_bit_reg8(.one, &proc.L),

        // RES 1, (HL)
        0x8E => Instruction.bits.reset_bit_hl_indirect(proc, .one),

        // RES 1, A
        0x8F => Instruction.bits.reset_bit_reg8(.two, &proc.A),

        // RES 2, B
        0x90 => Instruction.bits.reset_bit_reg8(.two, &proc.B),

        // RES 2, C
        0x91 => Instruction.bits.reset_bit_reg8(.two, &proc.C),

        // RES 2, D
        0x92 => Instruction.bits.reset_bit_reg8(.two, &proc.D),

        // RES 2, E
        0x93 => Instruction.bits.reset_bit_reg8(.two, &proc.E),

        // RES 2, H
        0x94 => Instruction.bits.reset_bit_reg8(.two, &proc.H),

        // RES 2, L
        0x95 => Instruction.bits.reset_bit_reg8(.two, &proc.L),

        // RES 2, (HL)
        0x96 => Instruction.bits.reset_bit_hl_indirect(proc, .two),

        // RES 2, A
        0x97 => Instruction.bits.reset_bit_reg8(.two, &proc.A),

        // RES 3, B
        0x98 => Instruction.bits.reset_bit_reg8(.three, &proc.B),

        // RES 3, C
        0x99 => Instruction.bits.reset_bit_reg8(.three, &proc.C),

        // RES 3, D
        0x9A => Instruction.bits.reset_bit_reg8(.three, &proc.D),

        // RES 3, E
        0x9B => Instruction.bits.reset_bit_reg8(.three, &proc.E),

        // RES 3, H
        0x9C => Instruction.bits.reset_bit_reg8(.three, &proc.H),

        // RES 3, L
        0x9D => Instruction.bits.reset_bit_reg8(.three, &proc.L),

        // RES 3, (HL)
        0x9E => Instruction.bits.reset_bit_hl_indirect(proc, .three),

        // RES 3, A
        0x9F => Instruction.bits.reset_bit_reg8(.three, &proc.A),

        // RES 4, B
        0xA0 => Instruction.bits.reset_bit_reg8(.four, &proc.B),

        // RES 4, C
        0xA1 => Instruction.bits.reset_bit_reg8(.four, &proc.C),

        // RES 4, D
        0xA2 => Instruction.bits.reset_bit_reg8(.four, &proc.D),

        // RES 4, E
        0xA3 => Instruction.bits.reset_bit_reg8(.four, &proc.E),

        // RES 4, H
        0xA4 => Instruction.bits.reset_bit_reg8(.four, &proc.H),

        // RES 4, L
        0xA5 => Instruction.bits.reset_bit_reg8(.four, &proc.L),

        // RES 4, (HL)
        0xA6 => Instruction.bits.reset_bit_hl_indirect(proc, .four),

        // RES 4, A
        0xA7 => Instruction.bits.reset_bit_reg8(.four, &proc.A),

        // RES 5, B
        0xA8 => Instruction.bits.reset_bit_reg8(.five, &proc.B),

        // RES 5, C
        0xA9 => Instruction.bits.reset_bit_reg8(.five, &proc.C),

        // RES 5, D
        0xAA => Instruction.bits.reset_bit_reg8(.five, &proc.D),

        // RES 5, E
        0xAB => Instruction.bits.reset_bit_reg8(.five, &proc.E),

        // RES 5, H
        0xAC => Instruction.bits.reset_bit_reg8(.five, &proc.H),

        // RES 5, L
        0xAD => Instruction.bits.reset_bit_reg8(.five, &proc.L),

        // RES 5, (HL)
        0xAE => Instruction.bits.reset_bit_hl_indirect(proc, .five),

        // RES 5, A
        0xAF => Instruction.bits.reset_bit_reg8(.five, &proc.accumulator),

        // RES 6, B
        0xB0 => Instruction.bits.reset_bit_reg8(.six, proc.B()),

        // RES 6, C
        0xB1 => Instruction.bits.reset_bit_reg8(.six, proc.C()),

        // RES 6, D
        0xB2 => Instruction.bits.reset_bit_reg8(.six, proc.D()),

        // RES 6, E
        0xB3 => Instruction.bits.reset_bit_reg8(.six, proc.E()),

        // RES 6, H
        0xB4 => Instruction.bits.reset_bit_reg8(.six, proc.H()),

        // RES 6, L
        0xB5 => Instruction.bits.reset_bit_reg8(.six, proc.L()),

        // RES 6, (HL)
        0xB6 => Instruction.bits.reset_bit_hl_indirect(proc, .six),

        // RES 6, A
        0xB7 => Instruction.bits.reset_bit_reg8(.six, &proc.accumulator),

        // RES 7, B
        0xB8 => Instruction.bits.reset_bit_reg8(.seven, proc.B()),

        // RES 7, C
        0xB9 => Instruction.bits.reset_bit_reg8(.seven, proc.C()),

        // RES 7, D
        0xBA => Instruction.bits.reset_bit_reg8(.seven, proc.D()),

        // RES 7, E
        0xBB => Instruction.bits.reset_bit_reg8(.seven, proc.E()),

        // RES 7, H
        0xBC => Instruction.bits.reset_bit_reg8(.seven, proc.H()),

        // RES 7, L
        0xBD => Instruction.bits.reset_bit_reg8(.seven, proc.L()),

        // RES 7, (HL)
        0xBE => Instruction.bits.reset_bit_hl_indirect(proc, .seven),

        // RES 7, A
        0xBF => Instruction.bits.reset_bit_reg8(.seven, &proc.accumulator),

        // SET 0, B
        0xC0 => Instruction.bits.set_bit_reg8(.zero, proc.B()),

        // SET 0, C
        0xC1 => Instruction.bits.set_bit_reg8(.zero, proc.C()),

        // SET 0, D
        0xC2 => Instruction.bits.set_bit_reg8(.zero, proc.D()),

        // SET 0, E
        0xC3 => Instruction.bits.set_bit_reg8(.zero, proc.E()),

        // SET 0, H
        0xC4 => Instruction.bits.set_bit_reg8(.zero, proc.H()),

        // SET 0, L
        0xC5 => Instruction.bits.set_bit_reg8(.zero, proc.L()),

        // SET 0, (HL)
        0xC6 => Instruction.bits.set_bit_hl_indirect(proc, .zero),

        // SET 0, A
        0xC7 => Instruction.bits.set_bit_reg8(.zero, &proc.accumulator),

        // SET 1, B
        0xC8 => Instruction.bits.set_bit_reg8(.one, proc.B()),

        // SET 1, C
        0xC9 => Instruction.bits.set_bit_reg8(.one, proc.C()),

        // SET 1, D
        0xCA => Instruction.bits.set_bit_reg8(.one, proc.D()),

        // SET 1, E
        0xCB => Instruction.bits.set_bit_reg8(.one, proc.E()),

        // SET 1, H
        0xCC => Instruction.bits.set_bit_reg8(.one, proc.H()),

        // SET 1, L
        0xCD => Instruction.bits.set_bit_reg8(.one, proc.L()),

        // SET 1, (HL)
        0xCE => Instruction.bits.set_bit_hl_indirect(&proc, .one),

        // SET 1, A
        0xCF => Instruction.bits.set_bit_reg8(.one, &proc.accumulator),

        // SET 2, B
        0xD0 => Instruction.bits.set_bit_reg8(.two, proc.B()),

        // SET 2, C
        0xD1 => Instruction.bits.set_bit_reg8(.two, proc.C()),

        // SET 2, D
        0xD2 => Instruction.bits.set_bit_reg8(.two, proc.D()),

        // SET 2, E
        0xD3 => Instruction.bits.set_bit_reg8(.two, proc.E()),

        // SET 2, H
        0xD4 => Instruction.bits.set_bit_reg8(.two, proc.H()),

        // SET 2, L
        0xD5 => Instruction.bits.set_bit_reg8(.two, proc.L()),

        // SET 2, (HL)
        0xD6 => Instruction.bits.set_bit_hl_indirect(proc, .two),

        // SET 2, A
        0xD7 => Instruction.bits.set_bit_reg8(.two, &proc.accumulator),

        // SET 3, B
        0xD8 => Instruction.bits.set_bit_reg8(.three, proc.B()),

        // SET 3, C
        0xD9 => Instruction.bits.set_bit_reg8(.three, proc.C()),

        // SET 3, D
        0xDA => Instruction.bits.set_bit_reg8(.three, proc.D()),

        // SET 3, E
        0xDB => Instruction.bits.set_bit_reg8(.three, proc.E()),

        // SET 3, H
        0xDC => Instruction.bits.set_bit_reg8(.three, proc.H()),

        // SET 3, L
        0xDD => Instruction.bits.set_bit_reg8(.three, proc.L()),

        // SET 3, (HL)
        0xDE => Instruction.bits.set_bit_hl_indirect(&proc, .three),

        // SET 3, A
        0xDF => Instruction.bits.set_bit_reg8(.three, &proc.accumulator),

        // SET 4, B
        0xE0 => Instruction.bits.set_bit_reg8(.four, proc.B()),

        // SET 4, C
        0xE1 => Instruction.bits.set_bit_reg8(.four, proc.C()),

        // SET 4, D
        0xE2 => Instruction.bits.set_bit_reg8(.four, proc.D()),

        // SET 4, E
        0xE3 => Instruction.bits.set_bit_reg8(.four, proc.E()),

        // SET 4, H
        0xE4 => Instruction.bits.set_bit_reg8(.four, proc.H()),

        // SET 4, L
        0xE5 => Instruction.bits.set_bit_reg8(.four, proc.L()),

        // SET 4, (HL)
        0xE6 => Instruction.bits.set_bit_hl_indirect(proc, .four),

        // SET 4 A
        0xE7 => Instruction.bits.set_bit_reg8(.four, &proc.accumulator),

        // SET 5, B
        0xE8 => Instruction.bits.set_bit_reg8(.five, proc.B()),

        // SET 5, C
        0xE9 => Instruction.bits.set_bit_reg8(.five, proc.C()),

        // SET 5, D
        0xEA => Instruction.bits.set_bit_reg8(.five, proc.D()),

        // SET 5, E
        0xEB => Instruction.bits.set_bit_reg8(.five, proc.E()),

        // SET 5, H
        0xEC => Instruction.bits.set_bit_reg8(.five, proc.H()),

        // SET 5, L
        0xED => Instruction.bits.set_bit_reg8(.five, proc.L()),

        // SET 5, (HL)
        0xEE => Instruction.bits.set_bit_hl_indirect(&proc, .five),

        // SET 5, A
        0xEF => Instruction.bits.set_bit_reg8(.five, &proc.accumulator),

        // SET 6, B
        0xF0 => Instruction.bits.set_bit_reg8(.six, proc.B()),

        // SET 6, C
        0xF1 => Instruction.bits.set_bit_reg8(.six, proc.C()),

        // SET 6, D
        0xF2 => Instruction.bits.set_bit_reg8(.six, proc.D()),

        // SET 6, E
        0xF3 => Instruction.bits.set_bit_reg8(.six, proc.E()),

        // SET 6, H
        0xF4 => Instruction.bits.set_bit_reg8(.six, proc.H()),

        // SET 6, L
        0xF5 => Instruction.bits.set_bit_reg8(.six, proc.L()),

        // SET 6, (HL)
        0xF6 => Instruction.bits.set_bit_hl_indirect(proc, .six),

        // SET 6 A
        0xF7 => Instruction.bits.set_bit_reg8(.six, &proc.accumulator),

        // SET 7, B
        0xF8 => Instruction.bits.set_bit_reg8(.seven, proc.B()),

        // SET 7, C
        0xF9 => Instruction.bits.set_bit_reg8(.seven, proc.C()),

        // SET 7, D
        0xFA => Instruction.bits.set_bit_reg8(.seven, proc.D()),

        // SET 7, E
        0xFB => Instruction.bits.set_bit_reg8(.seven, proc.E()),

        // SET 7, H
        0xFC => Instruction.bits.set_bit_reg8(.seven, proc.H()),

        // SET 7, L
        0xFD => Instruction.bits.set_bit_reg8(.seven, proc.L()),

        // SET 7, (HL)
        0xFE => Instruction.bits.set_bit_hl_indirect(&proc, .seven),

        // SET 7, A
        0xFF => Instruction.bits.set_bit_reg8(.seven, &proc.accumulator),
    }
}

pub fn decodeAndExecute(proc: *Processor, op_code: u8) !void {
    if (proc.isHalted) {
        std.debug.print("Processor is currently halted. Not executing any operations\n", .{});
        return;
    }

    _ = switch (op_code) {
        // NOP (No operation) Only advances the program counter by 1.
        0x00 => { return 4; },

        // LD BC, d16
        0x01 => Instruction.load.reg16_imm16(proc, &proc.BC),

        // LD (BC), A
        0x02 => Instruction.load.reg16_indirect_acc8(proc, &proc.BC),

        // INC BC
        0x03 => Instruction.arithmetic.inc_reg16(&proc.BC.value),

        // INC B
        0x04 => Instruction.arithmetic.inc_reg8(proc, proc.B()),

        // DEC B
        0x05 => Instruction.arithmetic.dec_reg8(proc, proc.B()),

        // LD B, d8
        0x06 => Instruction.load.reg8_imm8(proc, proc.B()),

        // RLCA
        0x07 => Instruction.bitShift.rotate_left_circular_accumulator(proc),

        // LD (a16), SP
        0x08 => Instruction.load.imm16_indirect_spr(proc, proc.SP),

        // ADD HL, BC
        0x09 => Instruction.arithmetic.add_reg16_reg16(proc, &proc.HL.value, &proc.BC.value),

        // LD A, (BC)
        0x0A => Instruction.load.reg8_reg16_indirect(proc, &proc.accumulator, &proc.BC),

        // DEC BC
        0x0B => Instruction.arithmetic.dec_reg16(proc, &proc.BC.value),

        // INC C
        0x0C => Instruction.arithmetic.inc_reg8(proc, proc.C()),

        // DEC C
        0x0D => Instruction.arithmetic.dec_reg8(proc, proc.C()),

        // LD C, d8
        0x0E => Instruction.load.reg8_imm8(proc, proc.C()),

        // RRCA
        0x0F => Instruction.bitShift.rotate_right_circular_accumulator(proc),

        // STOP
        0x10 => { proc.isStopped = true; },

        // LD DE, d16
        0x11 => Instruction.load.reg16_imm16(proc, &proc.DE),

        // LD (DE), A
        0x12 => Instruction.load.reg16_indirect_acc8(proc, &proc.DE),

        // INC DE
        0x13 => Instruction.arithmetic.inc_reg16(proc, &proc.DE.value),

        // INC D
        0x14 => Instruction.arithmetic.inc_reg8(proc, proc.D()),

        // DEC D
        0x15 => Instruction.arithmetic.dec_reg8(proc, proc.D()),

        // LD D, d8
        0x16 => Instruction.load.reg8_imm8(proc, proc.D()),

        // RLA
        0x17 => Instruction.bitShift.rotate_left_accumulator(&proc),

        // JR s8
        0x18 => Instruction.controlFlow.jump_rel_imm8(proc),

        // ADD HL, DE
        0x19 => Instruction.arithmetic.add_reg16_reg16(proc, &proc.HL.value, &proc.DE.value),

        // DEC DE
        0x1B => Instruction.arithmetic.dec_reg16(proc, &proc.DE.value),

        // INC E
        0x1C => Instruction.arithmetic.inc_reg8(proc, proc.E()),

        // DEC E
        0x1D => Instruction.arithmetic.dec_reg8(proc, proc.E()),

        // RRA
        0x1F => Instruction.bitShift.rotate_right_accumulator(proc),

        // JR NZ, s8
        0x20 => Instruction.controlFlow.jump_rel_cc_imm8(proc, proc.flags.zero, .is_not_set),

        // LD HL, d16
        0x21 => Instruction.load.reg16_imm16(proc, &proc.HL),

        // INC HL
        0x23 => Instruction.arithmetic.inc_reg16(proc, &proc.HL.value),

        // INC H
        0x24 => Instruction.arithmetic.inc_reg8(proc, proc.H()),

        // DEC H
        0x25 => Instruction.arithmetic.dec_reg8(proc, proc.H()),

        // DAA
        0x27 => Instruction.misc.decimal_adjust_accumulator(proc),

        // JR Z, s8
        0x28 => Instruction.controlFlow.jump_rel_cc_imm8(proc, &proc.flags.zero, .is_set),

        // ADD HL, HL
        0x29 => Instruction.arithmetic.add_reg16_reg16(proc, &proc.HL.value, &proc.HL.value),

        // DEC HL
        0x2B => Instruction.arithmetic.dec_reg16(proc, &proc.HL.value),

        // INC L
        0x2C => Instruction.arithmetic.inc_reg8(proc, proc.L()),

        // DEC L
        0x2D => Instruction.arithmetic.dec_reg8(proc, proc.L()),

        // CPL
        0x2F => Instruction.misc.complement_accumulator(proc),

        // JR NC, s8
        0x30 => Instruction.controlFlow.jump_rel_cc_imm8(proc, proc.flags.carry, .is_not_set),

        // INC SP
        0x33 => Instruction.arithmetic.inc_sp(proc),

        // INC (HL)
        0x34 => Instruction.arithmetic.inc_reg16(proc, &proc.HL.value),

        // DEC (HL)
        0x35 => Instruction.arithmetic.dec_reg16(proc, &proc.HL.value),

        // SCF
        0x37 => Instruction.misc.set_carry_flag(proc),

        // JR C, s8
        0x38 => Instruction.controlFlow.jump_rel_cc_imm8(proc, proc.flags.carry, .is_set),

        // ADD HL, SP
        0x39 => Instruction.arithmetic.add_hl_sp(proc),

        // DEC SP
        0x3B => Instruction.arithmetic.dec_sp(proc),

        // INC A
        0x3C => Instruction.arithmetic.inc_reg8(proc, &proc.accumulator),

        // DEC A
        0x3D => Instruction.arithmetic.dec_reg8(proc, &proc.accumulator),

        // CCF
        0x3F => Instruction.misc.complement_carry_flag(proc),

        // LD A, (DE)
        0x1A => Instruction.load.reg8_reg16_indirect(proc, &proc.accumulator, &proc.DE),

        // LD E, d8
        0x1E => Instruction.load.reg8_imm8(proc, proc.E()),

        // LD (HL+), A
        0x22 => Instruction.load.hl_indirect_inc_reg8(proc, &proc.accumulator),

        // LD H, d8
        0x26 => Instruction.load.reg8_imm8(proc, proc.H()),

        // LD A, (HL+)
        0x2A => Instruction.load.reg8_hl_indirect_inc(proc, &proc.accumulator),

        // LD L, d8
        0x2E => Instruction.load.reg8_imm8(proc, proc.L()),

        // LD SP, d16
        0x31 => Instruction.load.spr_imm16(proc, &proc.SP),

        // LD (HL-), A
        0x32 => Instruction.load.hl_indirect_dec_reg8(proc, &proc.accumulator),

        // LD (HL), d8
        0x36 => Instruction.load.reg16_indirect_imm8(proc, &proc.HL),

        // LD A, (HL-)
        0x3A => Instruction.load.reg8_hl_indirect_dec(proc, &proc.accumulator),

        // LD A, d8
        0x3E => Instruction.load.reg8_imm8(proc, &proc.accumulator),

        // LD B, B
        0x40 => Instruction.load.reg8_reg8(proc.B(), proc.B()),

        // LD B, C
        0x41 => Instruction.load.reg8_reg8(proc.B(), proc.C()),

        // LD B, D
        0x42 => Instruction.load.reg8_reg8(proc.B(), proc.D()),

        // LD B, E
        0x43 => Instruction.load.reg8_reg8(proc.B(), proc.E()),

        // LD B, H
        0x44 => Instruction.load.reg8_reg8(proc.B(), proc.H()),

        // LD B, L
        0x45 => Instruction.load.reg8_reg8(proc.B(), proc.L()),

        // LD B, (HL)
        0x46 => Instruction.load.reg8_reg16_indirect(proc, proc.B(), &proc.HL),

        // LD B, A
        0x47 => Instruction.load.reg8_reg8(proc.B(), &proc.accumulator),

        // LD C, B
        0x48 => Instruction.load.reg8_reg8(proc.C(), proc.B()),

        // LD C, C
        0x49 => Instruction.load.reg8_reg8(proc.C(), proc.C()),

        // LD C, D
        0x4A => Instruction.load.reg8_reg8(proc.C(), proc.D()),

        // LD C, E
        0x4B => Instruction.load.reg8_reg8(proc.C(), proc.E()),

        // LD C, H
        0x4C => Instruction.load.reg8_reg8(proc.C(), proc.H()),

        // LD C, L
        0x4D => Instruction.load.reg8_reg8(proc.C(), proc.L()),

        // LD C, (HL)
        0x4E => Instruction.load.reg8_reg16_indirect(proc, proc.C(), &proc.HL),

        // LD C, A
        0x4F => Instruction.load.reg8_reg8(proc.C(), &proc.accumulator),

        // LD D, B
        0x50 => Instruction.load.reg8_reg8(proc.D(), proc.B()),

        // LD D, C
        0x51 => Instruction.load.reg8_reg8(proc.D(), proc.C()),

        // LD D, D
        0x52 => Instruction.load.reg8_reg8(proc.D(), proc.D()),

        // LD D, E
        0x53 => Instruction.load.reg8_reg8(proc.D(), proc.E()),

        // LD D, H
        0x54 => Instruction.load.reg8_reg8(proc.D(), proc.H()),

        // LD D, L
        0x55 => Instruction.load.reg8_reg8(proc.D(), proc.L()),

        // LD D, (HL)
        0x56 => Instruction.load.reg8_reg16_indirect(proc, proc.D(), &proc.HL),

        // LD D, A
        0x57 => Instruction.load.reg8_reg8(proc.D(), &proc.accumulator),

        // LD E, B
        0x58 => Instruction.load.reg8_reg8(proc.E(), proc.B()),

        // LD E, C
        0x59 => Instruction.load.reg8_reg8(proc.E(), proc.C()),

        // LD E, D
        0x5A => Instruction.load.reg8_reg8(proc.E(), proc.D()),

        // LD E, E
        0x5B => Instruction.load.reg8_reg8(proc.E(), proc.E()),

        // LD E, H
        0x5C => Instruction.load.reg8_reg8(proc.E(), proc.H()),

        // LD E, L
        0x5D => Instruction.load.reg8_reg8(proc.E(), proc.L()),

        // LD E, (HL)
        0x5E => Instruction.load.reg8_reg16_indirect(proc, proc.E(), &proc.HL),

        // LD E, A
        0x5F => Instruction.load.reg8_reg8(proc.E(), &proc.accumulator),

        // LD H, B
        0x60 => Instruction.load.reg8_reg8(proc.H(), proc.B()),

        // LD H, C
        0x61 => Instruction.load.reg8_reg8(proc.H(), proc.C()),

        // LD H, D
        0x62 => Instruction.load.reg8_reg8(proc.H(), proc.D()),

        // LD H, E
        0x63 => Instruction.load.reg8_reg8(proc.H(), proc.E()),

        // LD H, H
        0x64 => Instruction.load.reg8_reg8(proc.H(), proc.H()),

        // LD H, L
        0x65 => Instruction.load.reg8_reg8(proc.H(), proc.L()),

        // LD H, (HL)
        0x66 => Instruction.load.reg8_reg16_indirect(proc, proc.H(), &proc.HL),

        // LD H, A
        0x67 => Instruction.load.reg8_reg8(proc.H(), &proc.A),

        // LD L, B
        0x68 => Instruction.load.reg8_reg8(proc.L(), proc.B()),

        // LD L, C
        0x69 => Instruction.load.reg8_reg8(proc.L(), proc.C()),

        // LD L, D
        0x6A => Instruction.load.reg8_reg8(proc.L(), proc.D()),

        // LD L, E
        0x6B => Instruction.load.reg8_reg8(proc.L(), proc.E()),

        // LD L, H
        0x6C => Instruction.load.reg8_reg8(proc.L(), proc.H()),

        // LD L, L
        0x6D => Instruction.load.reg8_reg8(proc.L(), proc.L()),

        // LD L, (HL)
        0x6E => Instruction.load.reg8_reg16_indirect(proc, proc.L(), &proc.HL),

        // LD L, A
        0x6F => Instruction.load.reg8_reg8(proc.LI(), &proc.accumulator),

        // LD (HL), B
        // 0x70 => instructions.load.hl_indirect_reg8(proc, &proc.B),
        0x70 => Instruction.load.hl_indirect_reg8(proc, proc.B()),

        // LD (HL), C
        0x71 => Instruction.load.hl_indirect_reg8(proc, proc.C()),

        // LD (HL), D
        0x72 => Instruction.load.hl_indirect_reg8(proc, proc.D()),

        // LD (HL), E
        0x73 => Instruction.load.hl_indirect_reg8(proc, proc.E()),

        // LD (HL), H
        0x74 => Instruction.load.hl_indirect_reg8(proc, proc.H()),

        // LD (HL), L
        0x75 => Instruction.load.hl_indirect_reg8(proc, proc.L()),

        // HALT
        0x76 => { proc.isHalted = true; },

        // LD (HL), A
        0x77 => Instruction.load.hl_indirect_reg8(proc, &proc.accumulator),

        // LD A, B
        0x78 => Instruction.load.reg8_reg8(&proc.accumulator, proc.B()),

        // LD A, C
        0x79 => Instruction.load.reg8_reg8(&proc.accumulator, proc.C()),

        // LD A, D
        0x7A => Instruction.load.reg8_reg8(&proc.accumulator, proc.D()),

        // LD A, E
        0x7B => Instruction.load.reg8_reg8(&proc.accumulator, proc.E()),

        // LD A, H
        0x7C => Instruction.load.reg8_reg8(&proc.accumulator, proc.H()),

        // LD A, L
        0x7D => Instruction.load.reg8_reg8(&proc.accumulator, proc.L()),

        // LD A, (HL)
        0x7E => Instruction.load.reg8_reg16_indirect(proc, &proc.accumulator, &proc.HL),

        // LD A, A
        0x7F => Instruction.load.reg8_reg8(&proc.accumulator, &proc.accumulator),

        // ADD B
        0x80 => Instruction.arithmetic.add_reg8(proc, proc.B()),

        // ADD C
        0x81 => Instruction.arithmetic.add_reg8(proc, proc.C()),

        // ADD D
        0x82 => Instruction.arithmetic.add_reg8(proc, proc.D()),

        // ADD E
        0x83 => Instruction.arithmetic.add_reg8(proc, proc.E()),

        // ADD H
        0x84 => Instruction.arithmetic.add_reg8(proc, proc.H()),

        // ADD L
        0x85 => Instruction.arithmetic.add_reg8(proc, proc.L()),

        // ADD A, (HL)
        0x86 => Instruction.arithmetic.add_hl_indirect(proc),

        // ADD A ,A
        0x87 => Instruction.arithmetic.add_reg8(proc, &proc.accumulator),

        // ADC B
        0x88 => Instruction.arithmetic.addc_reg8(proc, proc.B()),

        // ADC C
        0x89 => Instruction.arithmetic.addc_reg8(proc, proc.C()),

        // ADC D
        0x8A => Instruction.arithmetic.addc_reg8(proc, proc.D()),

        // ADC E
        0x8B => Instruction.arithmetic.addc_reg8(proc, proc.E()),

        // ADC H
        0x8C => Instruction.arithmetic.addc_reg8(proc, proc.H()),

        // ADC H
        0x8D => Instruction.arithmetic.addc_reg8(proc, proc.L()),

        // ADC (HL)
        0x8E => Instruction.arithmetic.addc_hl_indirect(proc),

        // ADC A
        0x8F => Instruction.arithmetic.addc_reg8(proc, &proc.accumulator),

        // SUB B
        0x90 => Instruction.arithmetic.sub_reg8(proc, proc.B()),

        // SUB C
        0x91 => Instruction.arithmetic.sub_reg8(proc, proc.C()),

        // SUB D
        0x92 => Instruction.arithmetic.sub_reg8(proc, proc.D()),

        // SUB E
        0x93 => Instruction.arithmetic.sub_reg8(proc, proc.E()),

        // SUB H
        0x94 => Instruction.arithmetic.sub_reg8(proc, proc.H()),

        // SUB L
        0x95 => Instruction.arithmetic.sub_reg8(proc, proc.L()),

        // SUB (HL)
        0x96 => Instruction.arithmetic.sub_hl_indirect(proc),

        // SUB A, A
        0x97 => Instruction.arithmetic.sub_reg8(proc, &proc.accumulator),

        // SBC B
        0x98 => Instruction.arithmetic.subc_reg8(proc, proc.B()),

        // SBC C
        0x99 => Instruction.arithmetic.subc_reg8(proc, proc.C()),

        // SBC D
        0x9A => Instruction.arithmetic.subc_reg8(proc, proc.D()),

        // SBC E
        0x9B => Instruction.arithmetic.subc_reg8(proc, proc.E()),

        // SBC H
        0x9C => Instruction.arithmetic.subc_reg8(proc, proc.H()),

        // SBC L
        0x9D => Instruction.arithmetic.subc_reg8(proc, proc.L()),

        // SBC A, (HL)
        0x9E => Instruction.arithmetic.subc_hl_indirect(proc),

        // SBC A, A
        0x9F => Instruction.arithmetic.subc_reg8(proc, &proc.accumulator),

        // AND B
        0xA0 => Instruction.arithmetic.and_reg8(proc, proc.B()),

        // AND C
        0xA1 => Instruction.arithmetic.and_reg8(proc, proc.C()),

        // AND D
        0xA2 => Instruction.arithmetic.and_reg8(proc, proc.D()),

        // AND E
        0xA3 => Instruction.arithmetic.and_reg8(proc, proc.E()),

        // AND H
        0xA4 => Instruction.arithmetic.and_reg8(proc, proc.H()),

        // AND L
        0xA5 => Instruction.arithmetic.and_reg8(proc, proc.L()),

        // AND A, (HL)
        0xA6 => Instruction.arithmetic.and_hl_indirect(proc),

        // AND A, A
        0xA7 => Instruction.arithmetic.and_reg8(proc, &proc.accumulator),

        // XOR B
        0xA8 => Instruction.arithmetic.xor_reg8(proc, proc.B()),

        // XOR C
        0xA9 => Instruction.arithmetic.xor_reg8(proc, proc.C()),

        // XOR D
        0xAA => Instruction.arithmetic.xor_reg8(proc, proc.D()),

        // XOR E
        0xAB => Instruction.arithmetic.xor_reg8(proc, proc.E()),

        // XOR H
        0xAC => Instruction.arithmetic.xor_reg8(proc, proc.H()),

        // XOR L
        0xAD => Instruction.arithmetic.xor_reg8(proc, proc.L()),

        // XOR (HL)
        0xAE => Instruction.arithmetic.xor_hl_indirect(proc),

        // XOR A, A
        0xAF => Instruction.arithmetic.xor_reg8(proc, &proc.accumulator),

        // OR B
        0xB0 => Instruction.arithmetic.or_reg8(proc, proc.B()),

        // OR C
        0xB1 => Instruction.arithmetic.or_reg8(proc, proc.C()),

        // OR D
        0xB2 => Instruction.arithmetic.or_reg8(proc, proc.D()),

        // OR E
        0xB3 => Instruction.arithmetic.or_reg8(proc, proc.E()),

        // OR H
        0xB4 => Instruction.arithmetic.or_reg8(proc, proc.H()),

        // OR L
        0xB5 => Instruction.arithmetic.or_reg8(proc, proc.L()),

        // OR (HL)
        0xB6 => Instruction.arithmetic.or_hl_indirect(proc),

        // OR A, A
        0xB7 => Instruction.arithmetic.or_reg8(proc, &proc.accumulator),

        // CP B
        0xB8 => Instruction.arithmetic.compare_reg8(proc, proc.B()),

        // CP C
        0xB9 => Instruction.arithmetic.compare_reg8(proc, proc.C()),

        // CP D
        0xBA => Instruction.arithmetic.compare_reg8(proc, proc.D()),

        // CP E
        0xBB => Instruction.arithmetic.compare_reg8(proc, proc.E()),

        // CP H
        0xBC => Instruction.arithmetic.compare_reg8(proc, proc.H()),

        // CP L
        0xBD => Instruction.arithmetic.compare_reg8(proc, proc.L()),

        // CP (HL)
        0xBE => Instruction.arithmetic.compare_hl_indirect(proc),

        // CP A, A
        0xBF => Instruction.arithmetic.compare_reg8(proc, &proc.accumulator),

        // RET NZ
        0xC0 => Instruction.controlFlow.ret_cc(proc, proc.flags.zero, .is_set),

        // POP BC
        0xC1 => Instruction.controlFlow.pop_reg16(proc, &proc.BC),

        // JP NZ, a16
        0xC2 => Instruction.controlFlow.jump_cc_imm16(proc, proc.flags.zero, .is_not_set),

        // JP a16
        0xC3 => Instruction.controlFlow.jump_imm16(proc),

        // CALL NZ, a16
        0xC4 => Instruction.controlFlow.call_cc_imm16(proc, proc.flags.zero, .is_not_set),

        // PUSH BC
        0xC5 => Instruction.controlFlow.push_reg16(proc, &proc.BC),

        // ADD A, d8
        0xC6 => Instruction.arithmetic.add_imm8(proc),

        // RST 0
        0xC7 => Instruction.controlFlow.rst(proc, 0),

        // RET Z
        0xC8 => Instruction.controlFlow.ret_cc(proc, proc.flags.zero, .is_set),

        // RET
        0xC9 => Instruction.controlFlow.ret(proc),

        // JP Z, a16
        0xCA => Instruction.controlFlow.jump_cc_imm16(proc, proc.flags.zero, .is_set),

        // CB Prefix
        0xCB => proc.decodeAndExecuteCBPrefix(),

        // CALL Z, a16
        0xCC => Instruction.controlFlow.call_cc_imm16(proc, proc.flags.zero, .is_set),

        // CALL a16
        0xCD => Instruction.controlFlow.call_imm16(proc),

        // ADC A, d8
        0xCE => Instruction.arithmetic.addc_imm8(proc),

        // RST 1
        0xCF => Instruction.controlFlow.rst(proc, 1),

        // RET NC
        0xD0 => Instruction.controlFlow.ret_cc(proc, proc.flags.carry, .is_not_set),

        // POP DE
        0xD1 => Instruction.controlFlow.pop_reg16(proc, &proc.DE),

        // JP NC, a16
        0xD2 => Instruction.controlFlow.jump_cc_imm16(proc, proc.flags.carry, .is_not_set),

        // CALL NC, a16
        0xD4 => Instruction.controlFlow.call_cc_imm16(proc, proc.flags.carry, .is_not_set),

        // PUSH DE
        0xD5 => Instruction.controlFlow.push_reg16(proc, &proc.DE),

        // 0xD6
        0xD6 => Instruction.arithmetic.sub_imm8(proc),

        // RST 2
        0xD7 => Instruction.controlFlow.rst(proc, 2),

        // RET C
        0xD8 => Instruction.controlFlow.ret_cc(proc, proc.flags.carry, .is_set),

        // RETI
        0xD9 => Instruction.controlFlow.reti(proc),

        // JP C, a16
        0xDA => Instruction.controlFlow.jump_cc_imm16(proc, proc.flags.carry, .is_set),

        // CALL C, a16
        0xDC => Instruction.controlFlow.call_cc_imm16(proc, proc.flags.carry, .is_set),

        // RST 3
        0xDF => Instruction.controlFlow.rst(proc, 3),

        // SBC A, d8
        0xDE => Instruction.arithmetic.subc_imm8(proc),

        // LD (a8), A
        0xE0 => Instruction.load.imm8_indirect_reg8(proc, &proc.accumulator),

        // POP HL
        0xE1 => Instruction.controlFlow.pop_reg16(proc, &proc.HL),

        // LD (C), A
        0xE2 => Instruction.load.reg8_indirect_reg8(proc, proc.C(), &proc.accumulator),

        // PUSH HL
        0xE5 => Instruction.controlFlow.push_reg16(proc, &proc.HL),

        // AND d8
        0xE6 => Instruction.arithmetic.and_imm8(proc),

        // RST 4
        0xE7 => Instruction.controlFlow.rst(proc, 4),

        // ADD SP s8
        0xE8 => Instruction.arithmetic.add_sp_offset(proc),

        // JP HL
        0xE9 => Instruction.controlFlow.jump_hl(proc, &proc.HL),

        // LD (a16), A
        0xEA => Instruction.load.imm16_indirect_reg8(proc, &proc.accumulator),

        // XOR d8
        0xEE => Instruction.arithmetic.xor_imm8(proc),

        // RST 5
        0xEF => Instruction.controlFlow.rst(proc, 5),

        // LD A, (a8)
        0xF0 => Instruction.load.reg8_imm8_indirect(proc, &proc.accumulator),

        // POP AF
        0xF1 => Instruction.controlFlow.pop_AF(proc),

        // LD A, (C)
        0xF2 => Instruction.load.reg8_reg8_indirect(proc, &proc.A, &proc.C),

        // DI
        0xF3 => { proc.IME = false; },

        // PUSH AF
        0xF5 => Instruction.controlFlow.push_AF(),

        // OR d8
        0xF6 => Instruction.arithmetic.or_imm8(proc),

        // RST 6
        0xF7 => Instruction.controlFlow.rst(proc, 6),

        // LD HL, SP+s8
        0xF8 => Instruction.load.hl_sp_imm8(proc),

        // LD SP, HL
        0xF9 => Instruction.load.spr_reg16(proc, &proc.SP, &proc.HL),

        // LD A, (a16)
        0xFA => Instruction.load.reg8_imm16_indirect(proc, &proc.accumulator),

        // EI
        0xFB => { proc.IME = true; },

        // CP d8
        0xFE => Instruction.arithmetic.compare_imm8(proc),

        // RST 7
        0xFF => Instruction.controlFlow.rst(proc, 7),

        else => {
            std.debug.print("op_code: {any} not implemented!", .{op_code});
        },
    };
}

test {
    _ = Instruction;
    _ = Memory;
    _ = PackedRegisterPair;
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
