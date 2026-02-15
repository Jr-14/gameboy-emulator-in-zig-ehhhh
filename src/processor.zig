const std = @import("std");
const utils = @import("utils.zig");

const RegisterNew = @import("register.zig");
const Memory = @import("memory.zig");
const instructions = @import("instruction.zig");

const masks = @import("masks.zig");

const Bit = utils.Bit;

const HI_MASK = masks.HI_MASK;
const LO_MASK = masks.LO_MASK;

const Z_MASK = masks.Z_MASK;
const N_MASK = masks.N_MASK;
const H_MASK = masks.H_MASK;
const C_MASK = masks.C_MASK;

pub const Flag = enum {
    Z,
    N,
    H,
    C,
};

pub const RegisterPair = enum { AF, BC, DE, HL };

const Processor = @This();

A: RegisterNew = .{},
F: RegisterNew = .{},
B: RegisterNew = .{},
C: RegisterNew = .{},
D: RegisterNew = .{},
E: RegisterNew = .{},
H: RegisterNew = .{},
L: RegisterNew = .{},

SP: u16 = 0,
PC: u16 = 0,

// Interrupt Master Enabled
IME: bool = false,

// Can we use this as a halting mechanism?
isHalted: bool = false,

memory: *Memory = undefined,

const InitProcessor = struct {
    A: u8 = 0,
    F: u8 = 0,
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

pub fn init(memory: *Memory, initProc: InitProcessor) Processor {
    return .{
        .memory = memory,
        .A = .{ .value = initProc.A },
        .F = .{ .value = initProc.F },
        .B = .{ .value = initProc.B },
        .C = .{ .value = initProc.C },
        .D = .{ .value = initProc.D },
        .E = .{ .value = initProc.E },
        .H = .{ .value = initProc.H },
        .L = .{ .value = initProc.L },
        .SP = initProc.SP,
        .PC = initProc.PC,
        .IME = initProc.IME,
    };
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

inline fn setRegisterPair(hiReg: *RegisterNew, loReg: *RegisterNew, value: u16) void {
    hiReg.value = @truncate(value >> 8);
    loReg.value = @truncate(value);
}

inline fn getRegisterPair(hiReg: *RegisterNew, loReg: *RegisterNew) u16 {
    return (@as(u16, hiReg.value) << 8) | loReg.value;
}

pub fn setAF(proc: *Processor, value: u16) void {
    setRegisterPair(&proc.A, &proc.F, value);
}

pub fn getAF(proc: *Processor) u16 {
    return getRegisterPair(&proc.A, &proc.F);
}

pub fn setBC(proc: *Processor, value: u16) void {
    setRegisterPair(&proc.B, &proc.C, value);
}

pub fn getBC(proc: *Processor) u16 {
    return getRegisterPair(&proc.B, &proc.C);
}

pub fn setDE(proc: *Processor, value: u16) void {
    setRegisterPair(&proc.D, &proc.E, value);
}

pub fn getDE(proc: *Processor) u16 {
    return getRegisterPair(&proc.D, &proc.E);
}

pub fn setHL(proc: *Processor, value: u16) void {
    setRegisterPair(&proc.H, &proc.L, value);
}

pub fn getHL(proc: *Processor) u16 {
    return getRegisterPair(&proc.H, &proc.L);
}

pub fn incrementHL(proc: *Processor) void {
    proc.setHL(proc.getHL() +% 1);
}

pub fn decrementHL(proc: *Processor) void {
    proc.setHL(proc.getHL() -% 1);
}

pub inline fn isFlagSet(proc: *Processor, flag: Flag) bool {
    return switch (flag) {
        .Z => (proc.F.value & Z_MASK) == Z_MASK,
        .N => (proc.F.value & N_MASK) == N_MASK,
        .H => (proc.F.value & H_MASK) == H_MASK,
        .C => (proc.F.value & C_MASK) == C_MASK,
    };
}

pub inline fn setFlag(proc: *Processor, flag: Flag) void {
    switch (flag) {
        .Z => proc.F.value |= Z_MASK,
        .N => proc.F.value |= N_MASK,
        .H => proc.F.value |= H_MASK,
        .C => proc.F.value |= C_MASK,
    }
}

pub inline fn unsetFlag(proc: *Processor, flag: Flag) void {
    switch (flag) {
        .Z => proc.F.value &= ~Z_MASK,
        .N => proc.F.value &= ~N_MASK,
        .H => proc.F.value &= ~H_MASK,
        .C => proc.F.value &= ~C_MASK,
    }
}

pub inline fn getFlag(proc: *Processor, flag: Flag) u1 {
    return switch (flag) {
        .Z => @truncate(proc.F.value >> 7),
        .N => @truncate(proc.F.value >> 6),
        .H => @truncate(proc.F.value >> 5),
        .C => @truncate(proc.F.value >> 4),
    };
}

pub inline fn resetFlags(proc: *Processor) void {
    proc.F.value = 0;
}

fn decodeAndExecuteCBPrefix(proc: *Processor) !void {
    const op_code = proc.fetch();
    switch (op_code) {
        // RLC B
        0x00 => instructions.bitShift.rotate_left_circular_r8(proc, &proc.B),

        // RLC C
        0x01 => instructions.bitShift.rotate_left_circular_r8(proc, &proc.C),

        // RLC D
        0x02 => instructions.bitShift.rotate_left_circular_r8(proc, &proc.D),

        // RLC E
        0x03 => instructions.bitShift.rotate_left_circular_r8(proc, &proc.E),

        // RLC H
        0x04 => instructions.bitShift.rotate_left_circular_r8(proc, &proc.H),

        // RLC L
        0x05 => instructions.bitShift.rotate_left_circular_r8(proc, &proc.L),

        // RLC (HL)
        0x06 => instructions.bitShift.rotate_left_circular_hlMem(proc),

        // RLC A
        0x07 => instructions.bitShift.rotate_left_circular_r8(proc, &proc.A),

        // RRC B
        0x08 => instructions.bitShift.rotate_right_circular_r8(proc, &proc.B),

        // RRC C
        0x09 => instructions.bitShift.rotate_right_circular_r8(proc, &proc.C),

        // RRC D
        0x0A => instructions.bitShift.rotate_right_circular_r8(proc, &proc.D),

        // RRC E
        0x0B => instructions.bitShift.rotate_right_circular_r8(proc, &proc.E),

        // RRC H
        0x0C => instructions.bitShift.rotate_right_circular_r8(proc, &proc.H),

        // RRC L
        0x0D => instructions.bitShift.rotate_right_circular_r8(proc, &proc.L),

        // RRC (HL)
        0x0E => instructions.bitShift.rotate_right_circular_hlMem(proc),

        // RRC
        0x0F => instructions.bitShift.rotate_right_circular_r8(proc, &proc.A),

        // RL B
        0x10 => instructions.bitShift.rotate_left_r8(proc, &proc.B),

        // RL C
        0x11 => instructions.bitShift.rotate_left_r8(proc, &proc.C),

        // RL D
        0x12 => instructions.bitShift.rotate_left_r8(proc, &proc.D),

        // RL E
        0x13 => instructions.bitShift.rotate_left_r8(proc, &proc.E),

        // RL H
        0x14 => instructions.bitShift.rotate_left_r8(proc, &proc.H),

        // RL L
        0x15 => instructions.bitShift.rotate_left_r8(proc, &proc.L),

        // RL (HL)
        0x16 => instructions.bitShift.rotate_left_hlMem(&proc),

        // RL A
        0x17 => instructions.bitShift.rotate_left_r8(proc, &proc.A),

        // RR B
        0x18 => instructions.bitShift.rotate_right_r8(proc, &proc.B),

        // RR C
        0x19 => instructions.bitShift.rotate_right_r8(proc, &proc.C),

        // RR D
        0x1A => instructions.bitShift.rotate_right_r8(proc, &proc.D),

        // RR E
        0x1B => instructions.bitShift.rotate_right_r8(proc, &proc.E),

        // RR H
        0x1C => instructions.bitShift.rotate_right_r8(proc, &proc.H),

        // RR L
        0x1D => instructions.bitShift.rotate_right_r8(proc, &proc.L),

        // RR (HL)
        0x1E => instructions.bitShift.rotate_right_hlMem(&proc),

        // RR A
        0x1F => instructions.bitShift.rotate_right_r8(proc, &proc.A),

        // SLA B
        0x20 => instructions.bitShift.shift_left_arithmetic_r8(proc, &proc.B),

        // SLA C
        0x21 => instructions.bitShift.shift_left_arithmetic_r8(proc, &proc.C),

        // SLA D
        0x22 => instructions.bitShift.shift_left_arithmetic_r8(proc, &proc.D),

        // SLA E
        0x23 => instructions.bitShift.shift_left_arithmetic_r8(proc, &proc.E),

        // SLA H
        0x24 => instructions.bitShift.shift_left_arithmetic_r8(proc, &proc.H),

        // SLA L
        0x25 => instructions.bitShift.shift_left_arithmetic_r8(proc, &proc.L),

        // SLA (HL)
        0x26 => instructions.bitShift.shift_left_arithmetic_hlMem(&proc),

        // SLA A
        0x27 => instructions.bitShift.shift_left_arithmetic_r8(proc, &proc.A),

        // SRA B
        0x28 => instructions.bitShift.shift_right_arithmetic_r8(proc, &proc.B),

        // SRA C
        0x29 => instructions.bitShift.shift_right_arithmetic_r8(proc, &proc.C),

        // SRA D
        0x2A => instructions.bitShift.shift_right_arithmetic_r8(proc, &proc.D),

        // SRA E
        0x2B => instructions.bitShift.shift_right_arithmetic_r8(proc, &proc.E),

        // SRA H
        0x2C => instructions.bitShift.shift_right_arithmetic_r8(proc, &proc.H),

        // SRA L
        0x2D => instructions.bitShift.shift_right_arithmetic_r8(proc, &proc.L),

        // SRA (HL)
        0x2E => instructions.bitShift.shift_right_arithmetic_hlMem(&proc),

        // SRA A
        0x2F => instructions.bitShift.shift_right_arithmetic_r8(proc, &proc.A),

        // SWAP B
        0x30 => instructions.bitShift.swap_r8(proc, &proc.B),

        // SWAP C
        0x31 => instructions.bitShift.swap_r8(proc, &proc.C),

        // SWAP D
        0x32 => instructions.bitShift.swap_r8(proc, &proc.D),

        // SWAP E
        0x33 => instructions.bitShift.swap_r8(proc, &proc.E),

        // SWAP H
        0x34 => instructions.bitShift.swap_r8(proc, &proc.H),

        // SWAP L
        0x35 => instructions.bitShift.swap_r8(proc, &proc.L),

        // SWAP (HL)
        0x36 => instructions.bitShift.swap_hlMem(&proc),

        // SWAP A
        0x37 => instructions.bitShift.swap_r8(proc, &proc.A),

        // SRL B
        0x38 => instructions.bitShift.shift_right_logical_r8(proc, &proc.B),

        // SRL C
        0x39 => instructions.bitShift.shift_right_logical_r8(proc, &proc.C),

        // SRL D
        0x3A => instructions.bitShift.shift_right_logical_r8(proc, &proc.D),

        // SRL E
        0x3B => instructions.bitShift.shift_right_logical_r8(proc, &proc.E),

        // SRL H
        0x3C => instructions.bitShift.shift_right_logical_r8(proc, &proc.H),

        // SRL L
        0x3D => instructions.bitShift.shift_right_logical_r8(proc, &proc.L),

        // SRL (HL)
        0x3E => instructions.bitShift.shift_right_logical_hlMem(&proc),

        // SRL A
        0x3F => instructions.bitShift.shift_right_logical_r8(proc, &proc.A),

        // BIT 0, B
        0x40 => instructions.bitFlag.test_bit_r8(proc, Bit.zero, &proc.B),

        // BIT 0, C
        0x41 => instructions.bitFlag.test_bit_r8(proc, Bit.zero, &proc.C),

        // BIT 0, D
        0x42 => instructions.bitFlag.test_bit_r8(proc, Bit.zero, &proc.D),

        // BIT 0, E
        0x43 => instructions.bitFlag.test_bit_r8(proc, Bit.zero, &proc.D),

        // BIT 0, H
        0x44 => instructions.bitFlag.test_bit_r8(proc, Bit.zero, &proc.H),

        // BIT 0, L
        0x45 => instructions.bitFlag.test_bit_r8(proc, Bit.zero, &proc.L),

        // BIT 0, (HL)
        0x46 => instructions.bitFlag.test_bit_hlMem(proc, Bit.zero),

        // BIT 0, A
        0x47 => instructions.bitFlag.test_bit_r8(proc, Bit.zero, &proc.A),

        // BIT 1, B
        0x48 => instructions.bitFlag.test_bit_r8(proc, Bit.one, &proc.B),

        // BIT 1, C
        0x49 => instructions.bitFlag.test_bit_r8(proc, Bit.one, &proc.C),

        // BIT 1, D
        0x4A => instructions.bitFlag.test_bit_r8(proc, Bit.one, &proc.D),

        // BIT 1, E
        0x4B => instructions.bitFlag.test_bit_r8(proc, Bit.one, &proc.E),

        // BIT 1, H
        0x4C => instructions.bitFlag.test_bit_r8(proc, Bit.one, &proc.H),

        // BIT 1, L
        0x4D => instructions.bitFlag.test_bit_r8(proc, Bit.one, &proc.L),

        // BIT 1, (HL)
        0x4E => instructions.bitFlag.test_bit_hlMem(proc, Bit.one),

        // BIT 1, A
        0x4F => instructions.bitFlag.test_bit_r8(proc, Bit.one, &proc.A),

        // BIT 2, B
        0x50 => instructions.bitFlag.test_bit_r8(proc, Bit.two, &proc.B),

        // BIT 2, C
        0x51 => instructions.bitFlag.test_bit_r8(proc, Bit.two, &proc.C),

        // BIT 2, D
        0x52 => instructions.bitFlag.test_bit_r8(proc, Bit.two, &proc.D),

        // BIT 2, E
        0x53 => instructions.bitFlag.test_bit_r8(proc, Bit.two, &proc.E),

        // BIT 2, H
        0x54 => instructions.bitFlag.test_bit_r8(proc, Bit.two, &proc.H),

        // BIT 2, L
        0x55 => instructions.bitFlag.test_bit_r8(proc, Bit.two, &proc.L),

        // BIT 2, (HL)
        0x56 => instructions.bitFlag.test_bit_hlMem(proc, Bit.two),

        // BIT 2, A
        0x57 => instructions.bitFlag.test_bit_r8(proc, Bit.two, &proc.A),

        // BIT 3, B
        0x58 => instructions.bitFlag.test_bit_r8(proc, Bit.three, &proc.B),

        // BIT 3, C
        0x59 => instructions.bitFlag.test_bit_r8(proc, Bit.three, &proc.C),

        // BIT 3, D
        0x5A => instructions.bitFlag.test_bit_r8(proc, Bit.three, &proc.D),

        // BIT 3, E
        0x5B => instructions.bitFlag.test_bit_r8(proc, Bit.three, &proc.E),

        // BIT 3, H
        0x5C => instructions.bitFlag.test_bit_r8(proc, Bit.three, &proc.H),

        // BIT 3, L
        0x5D => instructions.bitFlag.test_bit_r8(proc, Bit.three, &proc.L),

        // BIT 3, (HL)
        0x5E => instructions.bitFlag.test_bit_hlMem(proc, Bit.three),

        // BIT 3, A
        0x5F => instructions.bitFlag.test_bit_r8(proc, Bit.three, &proc.A),

        // BIT 4, B
        0x60 => instructions.bitFlag.test_bit_r8(proc, Bit.four, &proc.B),

        // BIT 4, C
        0x61 => instructions.bitFlag.test_bit_r8(proc, Bit.four, &proc.C),

        // BIT 4, D
        0x62 => instructions.bitFlag.test_bit_r8(proc, Bit.four, &proc.D),

        // BIT 4, E
        0x63 => instructions.bitFlag.test_bit_r8(proc, Bit.four, &proc.E),

        // BIT 4, H
        0x64 => instructions.bitFlag.test_bit_r8(proc, Bit.four, &proc.H),

        // BIT 4, L
        0x65 => instructions.bitFlag.test_bit_r8(proc, Bit.four, &proc.L),

        // BIT 4, (HL)
        0x66 => instructions.bitFlag.test_bit_hlMem(proc, Bit.four),

        // BIT 4, A
        0x67 => instructions.bitFlag.test_bit_r8(proc, Bit.four, &proc.A),

        // BIT 5, B
        0x68 => instructions.bitFlag.test_bit_r8(proc, Bit.five, &proc.B),

        // BIT 5, C
        0x69 => instructions.bitFlag.test_bit_r8(proc, Bit.five, &proc.C),

        // BIT 5, D
        0x6A => instructions.bitFlag.test_bit_r8(proc, Bit.five, &proc.D),

        // BIT 5, E
        0x6B => instructions.bitFlag.test_bit_r8(proc, Bit.five, &proc.E),

        // BIT 5, H
        0x6C => instructions.bitFlag.test_bit_r8(proc, Bit.five, &proc.H),

        // BIT 5, L
        0x6D => instructions.bitFlag.test_bit_r8(proc, Bit.five, &proc.L),

        // BIT 5, (HL)
        0x6E => instructions.bitFlag.test_bit_hlMem(proc, Bit.five),

        // BIT 5, A
        0x6F => instructions.bitFlag.test_bit_r8(proc, Bit.five, &proc.A),

        // BIT 6, B
        0x70 => instructions.bitFlag.test_bit_r8(proc, Bit.six, &proc.B),

        // BIT 6, C
        0x71 => instructions.bitFlag.test_bit_r8(proc, Bit.six, &proc.C),

        // BIT 6, D
        0x72 => instructions.bitFlag.test_bit_r8(proc, Bit.six, &proc.D),

        // BIT 6, E
        0x73 => instructions.bitFlag.test_bit_r8(proc, Bit.six, &proc.E),

        // BIT 6, H
        0x74 => instructions.bitFlag.test_bit_r8(proc, Bit.six, &proc.H),

        // BIT 6, L
        0x75 => instructions.bitFlag.test_bit_r8(proc, Bit.six, &proc.L),

        // BIT 6, (HL)
        0x76 => instructions.bitFlag.test_bit_hlMem(proc, Bit.six),

        // BIT 6, A
        0x77 => instructions.bitFlag.test_bit_r8(proc, Bit.six, &proc.A),

        // BIT 7, B
        0x78 => instructions.bitFlag.test_bit_r8(proc, Bit.seven, &proc.B),

        // BIT 7, C
        0x79 => instructions.bitFlag.test_bit_r8(proc, Bit.seven, &proc.C),

        // BIT 7, D
        0x7A => instructions.bitFlag.test_bit_r8(proc, Bit.seven, &proc.D),

        // BIT 7, E
        0x7B => instructions.bitFlag.test_bit_r8(proc, Bit.seven, &proc.E),

        // BIT 7, H
        0x7C => instructions.bitFlag.test_bit_r8(proc, Bit.seven, &proc.H),

        // BIT 7, L
        0x7D => instructions.bitFlag.test_bit_r8(proc, Bit.seven, &proc.L),

        // BIT 7, (HL)
        0x7E => instructions.bitFlag.test_bit_hlMem(proc, Bit.seven),

        // BIT 7, A
        0x7F => instructions.bitFlag.test_bit_r8(proc, Bit.seven, &proc.A),

        // RES 0, B
        0x80 => instructions.bits.reset_bit_r8(.zero, &proc.B),

        // RES 0, C
        0x81 => instructions.bits.reset_bit_r8(.zero, &proc.C),

        // RES 0, D
        0x82 => instructions.bits.reset_bit_r8(.zero, &proc.D),

        // RES 0, E
        0x83 => instructions.bits.reset_bit_r8(.zero, &proc.E),

        // RES 0, H
        0x84 => instructions.bits.reset_bit_r8(.zero, &proc.H),

        // RES 0, L
        0x85 => instructions.bits.reset_bit_r8(.zero, &proc.L),

        // RES 0, (HL)
        0x86 => instructions.bits.reset_bit_hlMem(proc, .zero),

        // RES 0, A
        0x87 => instructions.bits.reset_bit_r8(.zero, &proc.A),

        // RES 1, B
        0x88 => instructions.bits.reset_bit_r8(.one, &proc.B),

        // RES 1, C
        0x89 => instructions.bits.reset_bit_r8(.one, &proc.C),

        // RES 1, D
        0x8A => instructions.bits.reset_bit_r8(.one, &proc.D),

        // RES 1, E
        0x8B => instructions.bits.reset_bit_r8(.one, &proc.E),

        // RES 1, H
        0x8C => instructions.bits.reset_bit_r8(.one, &proc.H),

        // RES 1, L
        0x8D => instructions.bits.reset_bit_r8(.one, &proc.L),

        // RES 1, (HL)
        0x8E => instructions.bits.reset_bit_hlMem(proc, .one),

        // RES 1, A
        0x8F => instructions.bits.reset_bit_r8(.two, &proc.A),

        // RES 2, B
        0x90 => instructions.bits.reset_bit_r8(.two, &proc.B),

        // RES 2, C
        0x91 => instructions.bits.reset_bit_r8(.two, &proc.C),

        // RES 2, D
        0x92 => instructions.bits.reset_bit_r8(.two, &proc.D),

        // RES 2, E
        0x93 => instructions.bits.reset_bit_r8(.two, &proc.E),

        // RES 2, H
        0x94 => instructions.bits.reset_bit_r8(.two, &proc.H),

        // RES 2, L
        0x95 => instructions.bits.reset_bit_r8(.two, &proc.L),

        // RES 2, (HL)
        0x96 => instructions.bits.reset_bit_hlMem(proc, .two),

        // RES 2, A
        0x97 => instructions.bits.reset_bit_r8(.two, &proc.A),

        // RES 3, B
        0x98 => instructions.bits.reset_bit_r8(.three, &proc.B),

        // RES 3, C
        0x99 => instructions.bits.reset_bit_r8(.three, &proc.C),

        // RES 3, D
        0x9A => instructions.bits.reset_bit_r8(.three, &proc.D),

        // RES 3, E
        0x9B => instructions.bits.reset_bit_r8(.three, &proc.E),

        // RES 3, H
        0x9C => instructions.bits.reset_bit_r8(.three, &proc.H),

        // RES 3, L
        0x9D => instructions.bits.reset_bit_r8(.three, &proc.L),

        // RES 3, (HL)
        0x9E => instructions.bits.reset_bit_hlMem(proc, .three),

        // RES 3, A
        0x9F => instructions.bits.reset_bit_r8(.three, &proc.A),

        // RES 4, B
        0xA0 => instructions.bits.reset_bit_r8(.four, &proc.B),

        // RES 4, C
        0xA1 => instructions.bits.reset_bit_r8(.four, &proc.C),

        // RES 4, D
        0xA2 => instructions.bits.reset_bit_r8(.four, &proc.D),

        // RES 4, E
        0xA3 => instructions.bits.reset_bit_r8(.four, &proc.E),

        // RES 4, H
        0xA4 => instructions.bits.reset_bit_r8(.four, &proc.H),

        // RES 4, L
        0xA5 => instructions.bits.reset_bit_r8(.four, &proc.L),

        // RES 4, (HL)
        0xA6 => instructions.bits.reset_bit_hlMem(proc, .four),

        // RES 4, A
        0xA7 => instructions.bits.reset_bit_r8(.four, &proc.A),

        // RES 5, B
        0xA8 => instructions.bits.reset_bit_r8(.five, &proc.B),

        // RES 5, C
        0xA9 => instructions.bits.reset_bit_r8(.five, &proc.C),

        // RES 5, D
        0xAA => instructions.bits.reset_bit_r8(.five, &proc.D),

        // RES 5, E
        0xAB => instructions.bits.reset_bit_r8(.five, &proc.E),

        // RES 5, H
        0xAC => instructions.bits.reset_bit_r8(.five, &proc.H),

        // RES 5, L
        0xAD => instructions.bits.reset_bit_r8(.five, &proc.L),

        // RES 5, (HL)
        0xAE => instructions.bits.reset_bit_hlMem(proc, .five),

        // RES 5, A
        0xAF => instructions.bits.reset_bit_r8(.five, &proc.A),

        // RES 6, B
        0xB0 => instructions.bits.reset_bit_r8(.six, &proc.B),

        // RES 6, C
        0xB1 => instructions.bits.reset_bit_r8(.six, &proc.C),

        // RES 6, D
        0xB2 => instructions.bits.reset_bit_r8(.six, &proc.D),

        // RES 6, E
        0xB3 => instructions.bits.reset_bit_r8(.six, &proc.E),

        // RES 6, H
        0xB4 => instructions.bits.reset_bit_r8(.six, &proc.H),

        // RES 6, L
        0xB5 => instructions.bits.reset_bit_r8(.six, &proc.L),

        // RES 6, (HL)
        0xB6 => instructions.bits.reset_bit_hlMem(proc, .six),

        // RES 6, A
        0xB7 => instructions.bits.reset_bit_r8(.six, &proc.A),

        // RES 7, B
        0xB8 => instructions.bits.reset_bit_r8(.seven, &proc.B),

        // RES 7, C
        0xB9 => instructions.bits.reset_bit_r8(.seven, &proc.C),

        // RES 7, D
        0xBA => instructions.bits.reset_bit_r8(.seven, &proc.D),

        // RES 7, E
        0xBB => instructions.bits.reset_bit_r8(.seven, &proc.E),

        // RES 7, H
        0xBC => instructions.bits.reset_bit_r8(.seven, &proc.H),

        // RES 7, L
        0xBD => instructions.bits.reset_bit_r8(.seven, &proc.L),

        // RES 7, (HL)
        0xBE => instructions.bits.reset_bit_hlMem(proc, .seven),

        // RES 7, A
        0xBF => instructions.bits.reset_bit_r8(.seven, &proc.A),

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
        0x01 => instructions.load.rr_imm16(proc, .BC),

        // LD (BC), A
        0x02 => instructions.load.rrMem_reg(proc, .BC, &proc.A),

        // INC BC
        0x03 => instructions.arithmetic.inc_rr(proc, .BC),

        // INC B
        0x04 => instructions.arithmetic.inc_r8(proc, &proc.B),

        // DEC B
        0x05 => instructions.arithmetic.dec_reg(proc, &proc.B),

        // LD B, d8
        0x06 => instructions.load.reg_imm8(proc, &proc.B),

        // RLCA
        0x07 => instructions.bitShift.rotate_left_circular_a(&proc),

        // LD (a16), SP
        0x08 => instructions.load.imm16Mem_spr(proc, proc.SP),

        // ADD HL, BC
        0x09 => instructions.arithmetic.add16_rr_rr(proc, .HL, .BC),

        // LD A, (BC)
        0x0A => instructions.load.reg_rrMem(proc, &proc.A, .BC),

        // DEC BC
        0x0B => instructions.arithmetic.dec_rr(proc, .BC),

        // INC C
        0x0C => instructions.arithmetic.inc_r8(proc, &proc.C),

        // DEC C
        0x0D => instructions.arithmetic.dec_reg(proc, &proc.C),

        // LD C, d8
        0x0E => instructions.load.reg_imm8(proc, &proc.C),

        // RRCA
        0x0F => instructions.bitShift.rotate_right_circular_a(proc),

        // LD DE, d16
        0x11 => instructions.load.rr_imm16(proc, .DE),

        // LD (DE), A
        0x12 => instructions.load.rrMem_reg(proc, .DE, &proc.A),

        // INC DE
        0x13 => instructions.arithmetic.inc_rr(proc, .DE),

        // INC D
        0x14 => instructions.arithmetic.inc_r8(proc, &proc.D),

        // DEC D
        0x15 => instructions.arithmetic.dec_reg(proc, &proc.D),

        // LD D, d8
        0x16 => instructions.load.reg_imm8(proc, &proc.D),

        // RLA
        0x17 => instructions.bitShift.rotate_left_a(&proc),

        // JR s8
        0x18 => instructions.controlFlow.jump_rel_imm8(proc),

        // ADD HL, DE
        0x19 => instructions.arithmetic.add16_rr_rr(proc, .HL, .DE),

        // DEC DE
        0x1B => instructions.arithmetic.dec_rr(proc, .DE),

        // INC E
        0x1C => instructions.arithmetic.inc_r8(proc, &proc.E),

        // DEC E
        0x1D => instructions.arithmetic.dec_reg(proc, &proc.E),

        // RRA
        0x1F => instructions.bitShift.rotate_right_a(proc),

        // JR NZ, s8
        0x20 => instructions.controlFlow.jump_rel_cc_imm8(proc, .NZ),

        // LD HL, d16
        0x21 => instructions.load.rr_imm16(proc, .HL),

        // INC HL
        0x23 => instructions.arithmetic.inc_rr(proc, .HL),

        // INC H
        0x24 => instructions.arithmetic.inc_r8(proc, &proc.H),

        // DEC H
        0x25 => instructions.arithmetic.dec_reg(proc, &proc.H),

        // JR Z, s8
        0x28 => instructions.controlFlow.jump_rel_cc_imm8(proc, .Z),

        // ADD HL, HL
        0x29 => instructions.arithmetic.add16_rr_rr(proc, .HL, .HL),

        // DEC HL
        0x2B => instructions.arithmetic.dec_rr(proc, .HL),

        // INC L
        0x2C => instructions.arithmetic.inc_r8(proc, &proc.L),

        // DEC L
        0x2D => instructions.arithmetic.dec_reg(proc, &proc.L),

        // CPL
        0x2F => instructions.misc.complement_a8(proc),

        // JR NC, s8
        0x30 => instructions.controlFlow.jump_rel_cc_imm8(proc, .NC),

        // INC SP
        0x33 => instructions.arithmetic.inc_sp(proc),

        // INC (HL)
        0x34 => instructions.arithmetic.inc_rr(proc, .HL),

        // DEC (HL)
        0x35 => instructions.arithmetic.dec_rr(proc, .HL),

        // SCF
        0x37 => instructions.misc.set_carry_flag(proc),

        // JR C, s8
        0x38 => instructions.controlFlow.jump_rel_cc_imm8(proc, .C),

        // ADD HL, SP
        0x39 => instructions.arithmetic.add16_hl_sp(proc),

        // DEC SP
        0x3B => instructions.arithmetic.dec_sp(proc),

        // INC A
        0x3C => instructions.arithmetic.inc_r8(proc, &proc.A),

        // DEC A
        0x3D => instructions.arithmetic.dec_reg(proc, &proc.A),

        // CCF
        0x3F => instructions.misc.complement_carry_flag(proc),

        // LD A, (DE)
        0x1A => instructions.load.reg_rrMem(proc, &proc.A, .DE),

        // LD E, d8
        0x1E => instructions.load.reg_imm8(proc, &proc.E),

        // LD (HL+), A
        0x22 => instructions.load.hlMem_inc_reg(proc, &proc.A),

        // LD H, d8
        0x26 => instructions.load.reg_imm8(proc, &proc.H),

        // LD A, (HL+)
        0x2A => instructions.load.reg_hlMem_inc(proc, &proc.A),

        // LD L, d8
        0x2E => instructions.load.reg_imm8(proc, &proc.L),

        // LD SP, d16
        0x31 => instructions.load.spr_imm16(proc, &proc.SP),

        // LD (HL-), A
        0x32 => instructions.load.hlMem_dec_reg(proc, &proc.A),

        // LD (HL), d8
        0x36 => instructions.load.rrMem_imm8(proc, .HL),

        // LD A, (HL-)
        0x3A => instructions.load.reg_hlMem_dec(proc, &proc.A),

        // LD A, d8
        0x3E => instructions.load.reg_imm8(proc, &proc.A),

        // LD B, B
        0x40 => instructions.load.reg_reg(&proc.B, &proc.B),

        // LD B, C
        0x41 => instructions.load.reg_reg(&proc.B, &proc.C),

        // LD B, D
        0x42 => instructions.load.reg_reg(&proc.B, &proc.D),

        // LD B, E
        0x43 => instructions.load.reg_reg(&proc.B, &proc.E),

        // LD B, H
        0x44 => instructions.load.reg_reg(&proc.B, &proc.H),

        // LD B, L
        0x45 => instructions.load.reg_reg(&proc.B, &proc.L),

        // LD B, (HL)
        0x46 => instructions.load.reg_rrMem(proc, &proc.B, .HL),

        // LD B, A
        0x47 => instructions.load.reg_reg(&proc.B, &proc.A),

        // LD C, B
        0x48 => instructions.load.reg_reg(&proc.C, &proc.B),

        // LD C, C
        0x49 => instructions.load.reg_reg(&proc.C, &proc.C),

        // LD C, D
        0x4A => instructions.load.reg_reg(&proc.C, &proc.D),

        // LD C, E
        0x4B => instructions.load.reg_reg(&proc.C, &proc.E),

        // LD C, H
        0x4C => instructions.load.reg_reg(&proc.C, &proc.H),

        // LD C, L
        0x4D => instructions.load.reg_reg(&proc.C, &proc.L),

        // LD C, (HL)
        0x4E => instructions.load.reg_rrMem(proc, &proc.C, .HL),

        // LD C, A
        0x4F => instructions.load.reg_reg(&proc.C, &proc.A),

        // LD D, B
        0x50 => instructions.load.reg_reg(&proc.D, &proc.B),

        // LD D, C
        0x51 => instructions.load.reg_reg(&proc.D, &proc.C),

        // LD D, D
        0x52 => instructions.load.reg_reg(&proc.D, &proc.D),

        // LD D, E
        0x53 => instructions.load.reg_reg(&proc.D, &proc.E),

        // LD D, H
        0x54 => instructions.load.reg_reg(&proc.D, &proc.H),

        // LD D, L
        0x55 => instructions.load.reg_reg(&proc.D, &proc.L),

        // LD D, (HL)
        0x56 => instructions.load.reg_rrMem(proc, &proc.D, .HL),

        // LD D, A
        0x57 => instructions.load.reg_reg(&proc.D, &proc.A),

        // LD E, B
        0x58 => instructions.load.reg_reg(&proc.E, &proc.B),

        // LD E, C
        0x59 => instructions.load.reg_reg(&proc.E, &proc.C),

        // LD E, D
        0x5A => instructions.load.reg_reg(&proc.E, &proc.D),

        // LD E, E
        0x5B => instructions.load.reg_reg(&proc.E, &proc.E),

        // LD E, H
        0x5C => instructions.load.reg_reg(&proc.E, &proc.H),

        // LD E, L
        0x5D => instructions.load.reg_reg(&proc.E, &proc.L),

        // LD E, (HL)
        0x5E => instructions.load.reg_rrMem(proc, &proc.E, .HL),

        // LD E, A
        0x5F => instructions.load.reg_reg(&proc.E, &proc.A),

        // LD H, B
        0x60 => instructions.load.reg_reg(&proc.H, &proc.B),

        // LD H, C
        0x61 => instructions.load.reg_reg(&proc.H, &proc.C),

        // LD H, D
        0x62 => instructions.load.reg_reg(&proc.H, &proc.D),

        // LD H, E
        0x63 => instructions.load.reg_reg(&proc.H, &proc.E),

        // LD H, H
        0x64 => instructions.load.reg_reg(&proc.H, &proc.H),

        // LD H, L
        0x65 => instructions.load.reg_reg(&proc.H, &proc.L),

        // LD H, (HL)
        0x66 => instructions.load.reg_rrMem(proc, &proc.H, .HL),

        // LD H, A
        0x67 => instructions.load.reg_reg(&proc.H, &proc.A),

        // LD L, B
        0x68 => instructions.load.reg_reg(&proc.L, &proc.B),

        // LD L, C
        0x69 => instructions.load.reg_reg(&proc.L, &proc.C),

        // LD L, D
        0x6A => instructions.load.reg_reg(&proc.L, &proc.D),

        // LD L, E
        0x6B => instructions.load.reg_reg(&proc.L, &proc.E),

        // LD L, H
        0x6C => instructions.load.reg_reg(&proc.L, &proc.H),

        // LD L, L
        0x6D => instructions.load.reg_reg(&proc.L, &proc.L),

        // LD L, (HL)
        0x6E => instructions.load.reg_rrMem(proc, &proc.L, .HL),

        // LD L, A
        0x6F => instructions.load.reg_reg(&proc.L, &proc.A),

        // LD (HL), B
        0x70 => instructions.load.hlMem_reg(proc, &proc.B),

        // LD (HL), C
        0x71 => instructions.load.hlMem_reg(proc, &proc.C),

        // LD (HL), D
        0x72 => instructions.load.hlMem_reg(proc, &proc.D),

        // LD (HL), E
        0x73 => instructions.load.hlMem_reg(proc, &proc.E),

        // LD (HL), H
        0x74 => instructions.load.hlMem_reg(proc, &proc.H),

        // LD (HL), L
        0x75 => instructions.load.hlMem_reg(proc, &proc.L),

        // HALT
        0x76 => { proc.isHalted = true; },

        // LD (HL), A
        0x77 => instructions.load.hlMem_reg(proc, &proc.A),

        // LD A, B
        0x78 => instructions.load.reg_reg(&proc.A, &proc.B),

        // LD A, C
        0x79 => instructions.load.reg_reg(&proc.A, &proc.C),

        // LD A, D
        0x7A => instructions.load.reg_reg(&proc.A, &proc.D),

        // LD A, E
        0x7B => instructions.load.reg_reg(&proc.A, &proc.E),

        // LD A, H
        0x7C => instructions.load.reg_reg(&proc.A, &proc.H),

        // LD A, L
        0x7D => instructions.load.reg_reg(&proc.A, &proc.L),

        // LD A, (HL)
        0x7E => instructions.load.reg_rrMem(proc, &proc.A, .HL),

        // LD A, A
        0x7F => instructions.load.reg_reg(&proc.A, &proc.A),

        // ADD B
        0x80 => instructions.arithmetic.add_reg(proc, &proc.B),

        // ADD C
        0x81 => instructions.arithmetic.add_reg(proc, &proc.C),

        // ADD D
        0x82 => instructions.arithmetic.add_reg(proc, &proc.D),

        // ADD E
        0x83 => instructions.arithmetic.add_reg(proc, &proc.E),

        // ADD H
        0x84 => instructions.arithmetic.add_reg(proc, &proc.H),

        // ADD L
        0x85 => instructions.arithmetic.add_reg(proc, &proc.L),

        // ADD A, (HL)
        0x86 => instructions.arithmetic.add_hlMem(proc),

        // ADD A ,A
        0x87 => instructions.arithmetic.add_reg(proc, &proc.A),

        // ADC B
        0x88 => instructions.arithmetic.addc_reg(proc, &proc.B),

        // ADC C
        0x89 => instructions.arithmetic.addc_reg(proc, &proc.C),

        // ADC D
        0x8A => instructions.arithmetic.addc_reg(proc, &proc.D),

        // ADC E
        0x8B => instructions.arithmetic.addc_reg(proc, &proc.E),

        // ADC H
        0x8C => instructions.arithmetic.addc_reg(proc, &proc.H),

        // ADC H
        0x8D => instructions.arithmetic.addc_reg(proc, &proc.L),

        // ADC (HL)
        0x8E => instructions.arithmetic.addc_hlMem(proc),

        // ADC A
        0x8F => instructions.arithmetic.addc_reg(proc, &proc.A),

        // SUB B
        0x90 => instructions.arithmetic.sub_reg(proc, &proc.B),

        // SUB C
        0x91 => instructions.arithmetic.sub_reg(proc, &proc.C),

        // SUB D
        0x92 => instructions.arithmetic.sub_reg(proc, &proc.D),

        // SUB E
        0x93 => instructions.arithmetic.sub_reg(proc, &proc.E),

        // SUB H
        0x94 => instructions.arithmetic.sub_reg(proc, &proc.H),

        // SUB L
        0x95 => instructions.arithmetic.sub_reg(proc, &proc.L),

        // SUB (HL)
        0x96 => instructions.arithmetic.sub_hlMem(proc),

        // SUB A, A
        0x97 => instructions.arithmetic.sub_reg(proc, &proc.A),

        // SBC B
        0x98 => instructions.arithmetic.subc_reg(proc, &proc.B),

        // SBC C
        0x99 => instructions.arithmetic.subc_reg(proc, &proc.C),

        // SBC D
        0x9A => instructions.arithmetic.subc_reg(proc, &proc.D),

        // SBC E
        0x9B => instructions.arithmetic.subc_reg(proc, &proc.E),

        // SBC H
        0x9C => instructions.arithmetic.subc_reg(proc, &proc.H),

        // SBC L
        0x9D => instructions.arithmetic.subc_reg(proc, &proc.L),

        // SBC A, (HL)
        0x9E => instructions.arithmetic.subc_hlMem(proc),

        // SBC A, A
        0x9F => instructions.arithmetic.subc_reg(proc, &proc.A),

        // AND B
        0xA0 => instructions.arithmetic.And(proc, &proc.B),

        // AND C
        0xA1 => instructions.arithmetic.And(proc, &proc.C),

        // AND D
        0xA2 => instructions.arithmetic.And(proc, &proc.D),

        // AND E
        0xA3 => instructions.arithmetic.And(proc, &proc.E),

        // AND H
        0xA4 => instructions.arithmetic.And(proc, &proc.H),

        // AND L
        0xA5 => instructions.arithmetic.And(proc, &proc.L),

        // AND A, (HL)
        0xA6 => instructions.arithmetic.and_hlMem(proc),

        // AND A, A
        0xA7 => instructions.arithmetic.And(proc, &proc.A),

        // XOR B
        0xA8 => instructions.arithmetic.Xor(proc, &proc.B),

        // XOR C
        0xA9 => instructions.arithmetic.Xor(proc, &proc.C),

        // XOR D
        0xAA => instructions.arithmetic.Xor(proc, &proc.D),

        // XOR E
        0xAB => instructions.arithmetic.Xor(proc, &proc.E),

        // XOR H
        0xAC => instructions.arithmetic.Xor(proc, &proc.H),

        // XOR L
        0xAD => instructions.arithmetic.Xor(proc, &proc.L),

        // XOR (HL)
        0xAE => instructions.arithmetic.xor_hlMem(proc),

        // XOR A, A
        0xAF => instructions.arithmetic.Xor(proc, &proc.A),

        // OR B
        0xB0 => instructions.arithmetic.Or(proc, &proc.B),

        // OR C
        0xB1 => instructions.arithmetic.Or(proc, &proc.C),

        // OR D
        0xB2 => instructions.arithmetic.Or(proc, &proc.D),

        // OR E
        0xB3 => instructions.arithmetic.Or(proc, &proc.E),

        // OR H
        0xB4 => instructions.arithmetic.Or(proc, &proc.H),

        // OR L
        0xB5 => instructions.arithmetic.Or(proc, &proc.L),

        // OR (HL)
        0xB6 => instructions.arithmetic.or_hlMem(proc),

        // OR A, A
        0xB7 => instructions.arithmetic.Or(proc, &proc.A),

        // CP B
        0xB8 => instructions.arithmetic.compare_reg(proc, &proc.B),

        // CP C
        0xB9 => instructions.arithmetic.compare_reg(proc, &proc.C),

        // CP D
        0xBA => instructions.arithmetic.compare_reg(proc, &proc.D),

        // CP E
        0xBB => instructions.arithmetic.compare_reg(proc, &proc.E),

        // CP H
        0xBC => instructions.arithmetic.compare_reg(proc, &proc.H),

        // CP L
        0xBD => instructions.arithmetic.compare_reg(proc, &proc.L),

        // CP (HL)
        0xBE => instructions.arithmetic.compare_hlMem(proc),

        // CP A, A
        0xBF => instructions.arithmetic.compare_reg(proc, &proc.A),

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
        0xC6 => instructions.arithmetic.add_imm8(proc),

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
        0xCE => instructions.arithmetic.addc_imm8(proc),

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
        0xD6 => instructions.arithmetic.sub_imm8(proc),

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
        0xDE => instructions.arithmetic.subc_imm8(proc),

        // LD (a8), A
        0xE0 => instructions.load.imm8Mem_reg(proc, &proc.A),

        // POP HL
        0xE1 => instructions.controlFlow.pop_rr(proc, .HL),

        // LD (C), A
        0xE2 => instructions.load.regMem_reg(proc, &proc.C, &proc.A),

        // PUSH HL
        0xE5 => instructions.controlFlow.push_rr(proc, .HL),

        // AND d8
        0xE6 => instructions.arithmetic.and_imm8(proc),

        // RST 4
        0xE7 => instructions.controlFlow.rst(proc, 4),

        // ADD SP s8
        0xE8 => instructions.arithmetic.add16_sp_offset(proc),

        // JP HL
        0xE9 => instructions.controlFlow.jump_rr(proc, .HL),

        // LD (a16), A
        0xEA => instructions.load.imm16Mem_reg(proc, &proc.A),

        // XOR d8
        0xEE => instructions.arithmetic.xor_imm8(proc),

        // RST 5
        0xEF => instructions.controlFlow.rst(proc, 5),

        // LD A, (a8)
        0xF0 => instructions.load.reg_imm8Mem(proc, &proc.A),

        // POP AF
        0xF1 => instructions.controlFlow.pop_rr(proc, .AF),

        // LD A, (C)
        0xF2 => instructions.load.reg_regMem(proc, &proc.A, &proc.C),

        // DI
        0xF3 => { proc.IME = false; },

        // PUSH AF
        0xF5 => instructions.controlFlow.push_rr(proc, .AF),

        // OR d8
        0xF6 => instructions.arithmetic.or_imm8(proc),

        // RST 6
        0xF7 => instructions.controlFlow.rst(proc, 6),

        // LD HL, SP+s8
        0xF8 => instructions.load.hl_sp_imm8(proc),

        // LD SP, HL
        0xF9 => instructions.load.spr_rr(proc, &proc.SP, .HL),

        // LD A, (a16)
        0xFA => instructions.load.reg_imm16Mem(proc, &proc.A),

        // EI
        0xFB => { proc.IME = true; },

        // CP d8
        0xFE => instructions.arithmetic.compare_imm8(proc),

        // RST 7
        0xFF => instructions.controlFlow.rst(proc, 7),

        else => {
            std.debug.print("op_code: {any} not implemented!", .{op_code});
        },
    }
}

const expectEqual = std.testing.expectEqual;

test "getRegisterPair" {
    var memory: Memory = .init();
    const H: u8 = 0x45;
    const L: u8 = 0x7F;
    var processor = Processor.init(&memory, .{ .H = H, .L = L });

    try expectEqual(utils.fromTwoBytes(L, H), Processor.getRegisterPair(&processor.H, &processor.L));
}

test "setRegisterPair" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{});

    const D: u8 = 0x91;
    const E: u8 = 0xC2;
    Processor.setRegisterPair(&processor.D, &processor.E, utils.fromTwoBytes(E, D));

    try expectEqual(D, processor.D.value);
    try expectEqual(E, processor.E.value);
}

test "isFlagSet, Z" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .F = Z_MASK });

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "isFlagSet, N" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .F = N_MASK });

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "isFlagSet, H" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .F = H_MASK });

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "isFlagSet, C" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .F = C_MASK });

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "setFlag, Z" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});
    processor.setFlag(.Z);

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}
//
test "setFlag, N" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});
    processor.setFlag(.N);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "setFlag, H" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});
    processor.setFlag(.H);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "setFlag, C" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});
    processor.setFlag(.C);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "unsetFlag, Z" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});
    processor.setFlag(.Z);
    processor.setFlag(.N);
    processor.setFlag(.H);
    processor.setFlag(.C);

    processor.unsetFlag(.Z);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "unsetFlag, N" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});
    processor.setFlag(.Z);
    processor.setFlag(.N);
    processor.setFlag(.H);
    processor.setFlag(.C);

    processor.unsetFlag(.N);

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "unsetFlag, H" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});
    processor.setFlag(.Z);
    processor.setFlag(.N);
    processor.setFlag(.H);
    processor.setFlag(.C);

    processor.unsetFlag(.H);

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "unsetFlag, C" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});
    processor.setFlag(.Z);
    processor.setFlag(.N);
    processor.setFlag(.H);
    processor.setFlag(.C);

    processor.unsetFlag(.C);

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
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

test "getFlag" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});
    processor.setFlag(.Z);

    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));

    processor.setFlag(.N);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(1, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));

    processor.setFlag(.H);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(1, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));

    processor.setFlag(.C);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(1, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));

    processor.resetFlags();
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));

    processor.setFlag(.N);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(1, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    processor.resetFlags();

    processor.setFlag(.H);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    processor.resetFlags();

    processor.setFlag(.C);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    processor.resetFlags();
}
