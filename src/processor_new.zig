const std = @import("std");
const utils = @import("utils.zig");

const RegisterNew = @import("register_new.zig");
const Memory = @import("memory.zig");
const instructions = @import("instruction.zig");

const masks = @import("masks.zig");

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

const ProcessorNew = @This();

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

pub fn init(memory: *Memory, initProc: InitProcessor) ProcessorNew {
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
pub inline fn readFromPC(proc: *ProcessorNew) u8 {
    return proc.memory.read(proc.PC);
}

/// Fetches the next instruction or byte of data from the current memory address pointed at by PC
pub inline fn fetch(proc: *ProcessorNew) u8 {
    const instruction = proc.readFromPC();
    proc.PC += 1;
    return instruction;
}

/// Pop the current value from the stack pointed to by SP
pub inline fn popStack(proc: *ProcessorNew) u8 {
    const val = proc.memory.read(proc.SP);
    proc.SP += 1;
    return val;
}

/// Push a value into the stack
pub inline fn pushStack(proc: *ProcessorNew, val: u8) void {
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

pub fn setAF(proc: *ProcessorNew, value: u16) void {
    setRegisterPair(&proc.A, &proc.F, value);
}

pub fn getAF(proc: *ProcessorNew) u16 {
    return getRegisterPair(&proc.A, &proc.F);
}

pub fn setBC(proc: *ProcessorNew, value: u16) void {
    setRegisterPair(&proc.B, &proc.C, value);
}

pub fn getBC(proc: *ProcessorNew) u16 {
    return getRegisterPair(&proc.B, &proc.C);
}

pub fn setDE(proc: *ProcessorNew, value: u16) void {
    setRegisterPair(&proc.D, &proc.E, value);
}

pub fn getDE(proc: *ProcessorNew) u16 {
    return getRegisterPair(&proc.D, &proc.E);
}

pub fn setHL(proc: *ProcessorNew, value: u16) void {
    setRegisterPair(&proc.H, &proc.L, value);
}

pub fn getHL(proc: *ProcessorNew) u16 {
    return getRegisterPair(&proc.H, &proc.L);
}

pub fn incrementHL(proc: *ProcessorNew) void {
    proc.setHL(proc.getHL() +% 1);
}

pub fn decrementHL(proc: *ProcessorNew) void {
    proc.setHL(proc.getHL() -% 1);
}

pub inline fn isFlagSet(proc: *ProcessorNew, flag: Flag) bool {
    return switch (flag) {
        .Z => (proc.F.value & Z_MASK) == Z_MASK,
        .N => (proc.F.value & N_MASK) == N_MASK,
        .H => (proc.F.value & H_MASK) == H_MASK,
        .C => (proc.F.value & C_MASK) == C_MASK,
    };
}

pub inline fn setFlag(proc: *ProcessorNew, flag: Flag) void {
    switch (flag) {
        .Z => proc.F.value |= Z_MASK,
        .N => proc.F.value |= N_MASK,
        .H => proc.F.value |= H_MASK,
        .C => proc.F.value |= C_MASK,
    }
}

pub inline fn unsetFlag(proc: *ProcessorNew, flag: Flag) void {
    switch (flag) {
        .Z => proc.F.value &= ~Z_MASK,
        .N => proc.F.value &= ~N_MASK,
        .H => proc.F.value &= ~H_MASK,
        .C => proc.F.value &= ~C_MASK,
    }
}

pub inline fn resetFlags(proc: *ProcessorNew) void {
    proc.F.value = 0;
}

pub fn decodeAndExecute(proc: *ProcessorNew, op_code: u8) !void {
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
        0x04 => instructions.arithmetic.inc_reg(proc, &proc.B),

        // DEC B
        0x05 => instructions.arithmetic.dec_reg(proc, &proc.B),

        // LD B, d8
        0x06 => instructions.load.reg_imm8(proc, &proc.B),

        // LD (a16), SP
        0x08 => instructions.load.imm16Mem_spr(proc, proc.SP),

        // LD A, (BC)
        0x0A => instructions.load.reg_rrMem(proc, &proc.A, .BC),

        // INC C
        0x0C => instructions.arithmetic.inc_reg(proc, &proc.C),

        // DEC C
        0x0D => instructions.arithmetic.dec_reg(proc, &proc.C),

        // LD C, d8
        0x0E => instructions.load.reg_imm8(proc, &proc.C),

        // LD DE, d16
        0x11 => instructions.load.rr_imm16(proc, .DE),

        // LD (DE), A
        0x12 => instructions.load.rrMem_reg(proc, .DE, &proc.A),

        // INC D
        0x14 => instructions.arithmetic.inc_reg(proc, &proc.D),

        // DEC D
        0x15 => instructions.arithmetic.dec_reg(proc, &proc.D),

        // LD D, d8
        0x16 => instructions.load.reg_imm8(proc, &proc.D),

        // JR s8
        0x18 => instructions.controlFlow.jump_rel_imm8(proc),

        // INC E
        0x1C => instructions.arithmetic.inc_reg(proc, &proc.E),

        // DEC E
        0x1D => instructions.arithmetic.dec_reg(proc, &proc.E),

        // JR NZ, s8
        0x20 => instructions.controlFlow.jump_rel_cc_imm8(proc, .NZ),

        // LD HL, d16
        0x21 => instructions.load.rr_imm16(proc, .HL),

        // INC H
        0x24 => instructions.arithmetic.inc_reg(proc, &proc.H),

        // DEC H
        0x25 => instructions.arithmetic.dec_reg(proc, &proc.H),

        // JR Z, s8
        0x28 => instructions.controlFlow.jump_rel_cc_imm8(proc, .Z),

        // INC L
        0x2C => instructions.arithmetic.inc_reg(proc, &proc.L),
        
        // DEC L
        0x2D => instructions.arithmetic.dec_reg(proc, &proc.L),

        // JR NC, s8
        0x30 => instructions.controlFlow.jump_rel_cc_imm8(proc, .NC),

        // INC (HL)
        0x34 => instructions.arithmetic.inc_rr(proc, .HL),

        // DEC (HL)
        0x35 => instructions.arithmetic.dec_rr(proc, .HL),

        // JR C, s8
        0x38 => instructions.controlFlow.jump_rel_cc_imm8(proc, .C),

        // INC A
        0x3C => instructions.arithmetic.inc_reg(proc, &proc.A),

        // DEC A
        0x3D => instructions.arithmetic.dec_reg(proc, &proc.A),

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
        // TODO
        // 0x76 => {},

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

        // RST 0
        0xC7 => instructions.controlFlow.rst(proc, 0),

        // RET Z
        0xC8 => instructions.controlFlow.ret_cc(proc, .Z),

        // RET
        0xC9 => instructions.controlFlow.ret(proc),

        // JP Z, a16
        0xCA => instructions.controlFlow.jump_cc_imm16(proc, .Z),

        // CALL Z, a16
        0xCC => instructions.controlFlow.call_cc_imm16(proc, .Z),

        // CALL a16
        0xCD => instructions.controlFlow.call_imm16(proc),

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

        // LD (a8), A
        0xE0 => instructions.load.imm8Mem_reg(proc, &proc.A),

        // POP HL
        0xE1 => instructions.controlFlow.pop_rr(proc, .HL),

        // LD (C), A
        0xE2 => instructions.load.regMem_reg(proc, &proc.C, &proc.A),

        // PUSH HL
        0xE5 => instructions.controlFlow.push_rr(proc, .HL),
        
        // RST 4
        0xE7 => instructions.controlFlow.rst(proc, 4),

        // JP HL
        0xE9 => instructions.controlFlow.jump_rr(proc, .HL),

        // LD (a16), A
        0xEA => instructions.load.imm16Mem_reg(proc, &proc.A),

        // RST 5
        0xEF => instructions.controlFlow.rst(proc, 5),

        // LD A, (a8)
        0xF0 => instructions.load.reg_imm8Mem(proc, &proc.A),

        // POP AF
        0xF1 => instructions.controlFlow.pop_rr(proc, .AF),

        // LD A, (C)
        0xF2 => instructions.load.reg_regMem(proc, &proc.A, &proc.C),

        // PUSH AF
        0xF5 => instructions.controlFlow.push_rr(proc, .AF),

        // RST 6
        0xF7 => instructions.controlFlow.rst(proc, 6),

        // LD SP, HL
        0xF9 => instructions.load.spr_rr(proc, &proc.SP, .HL),

        // LD A, (a16)
        0xFA => instructions.load.reg_imm16Mem(proc, &proc.A),

        // RST 7
        0xFF => instructions.controlFlow.rst(proc, 7),

        else => {
            std.debug.print("op_code: {any} not implemented!", .{ op_code });
        },
    }
}

const expectEqual = std.testing.expectEqual;

test "getRegisterPair" {
    var memory: Memory = .init();
    const H: u8 = 0x45;
    const L: u8 = 0x7F;
    var processor = ProcessorNew.init(&memory, .{ .H = H, .L = L });

    try expectEqual(utils.fromTwoBytes(L, H), ProcessorNew.getRegisterPair(&processor.H, &processor.L));
}

test "setRegisterPair" {
    var memory: Memory = .init();
    var processor = ProcessorNew.init(&memory, .{});

    const D: u8 = 0x91;
    const E: u8 = 0xC2;
    ProcessorNew.setRegisterPair(&processor.D, &processor.E, utils.fromTwoBytes(E, D));

    try expectEqual(D, processor.D.value);
    try expectEqual(E, processor.E.value);
}

test "isFlagSet, Z" {
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, .{ .F = Z_MASK });

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "isFlagSet, N" {
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, .{ .F = N_MASK });

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "isFlagSet, H" {
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, .{ .F = H_MASK });

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "isFlagSet, C" {
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, .{ .F = C_MASK });

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "setFlag, Z" {
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, .{});
    processor.setFlag(.Z);

    try expectEqual(true,  processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}
//
test "setFlag, N" {
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, .{});
    processor.setFlag(.N);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "setFlag, H" {
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, .{});
    processor.setFlag(.H);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "setFlag, C" {
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, .{});
    processor.setFlag(.C);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(true,  processor.isFlagSet(.C));
}

test "unsetFlag, Z" {
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, .{});
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
    var processor = ProcessorNew.init(&memory, .{});
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
    var processor = ProcessorNew.init(&memory, .{});
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
    var processor = ProcessorNew.init(&memory, .{});
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
    var processor = ProcessorNew.init(&memory, . { .SP = SP});

    const content: u8 = 0x13;
    processor.memory.write(SP, content);

    try expectEqual(content, processor.popStack());
    try expectEqual(SP + 1, processor.SP);
}

test "pushStack" {
    const SP: u16 = 0x0AFF;
    var memory = Memory.init();
    var processor = ProcessorNew.init(&memory, . { .SP = SP});

    const content: u8 = 0x13;
    processor.pushStack(content);

    try expectEqual(content, processor.memory.read(SP - 1));
    try expectEqual(SP - 1, processor.SP);
}
