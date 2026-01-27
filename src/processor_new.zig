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
        // Performs no other operations that would have an effect
        0x00 => {},

        // LD BC, d16
        // Load the 2 bytes of immediate data into register pair BC
        // The first byte of immediate data is the lower byte (i.e. bits 0-7), and
        // the second byte of immediate data is the higher byte (i.e., bits 8-15)
        0x01 => instructions.load.rrImm16(proc, .BC),

        // LD (BC), A
        // Store the contents of register A in the memory location specified by
        // register pair BC
        0x02 => instructions.load.rrMemReg(proc, .BC, proc.A.value),

        // INC BC
        // Increment the contents of register pair BC by 1
        0x03 => instructions.incRR(proc, .BC),

        // INC B
        // Increment the contents of register B by 1.
        0x04 => instructions.incReg(proc, &proc.B),

        // DEC B
        // Decrement the contents of register B by 1
        0x05 => instructions.decReg(proc, &proc.B),

        // LD B, d8
        // Load the 8-bit immediate operand d8 into register B.
        0x06 => instructions.loadFromImm8(proc, &proc.B),

        // LD (a16), SP
        // Store the lower byte of stack pointer SP at the address specified by the 16-bit
        // immediate operand 16, and store the upper byte of SP at address a16 + 1.
        0x08 => instructions.load.imm16MemSPR(proc, proc.SP),

        // LD A, (BC)
        // Load the 8-bit contents of memory specified by register pair BC into register A.
        0x0A => instructions.load.regRRMem(proc, &proc.A, .BC),

        // INC C
        // Increment the contents of register C by 1.
        0x0C => instructions.incReg(proc, &proc.C),

        // DEC C
        // Decrement the contents of register C by 1
        0x0D => instructions.decReg(proc, &proc.C),

        // LD C, d8
        // Load the 8-bit immediate operand d8 into register C
        0x0E => instructions.load.imm8(proc, &proc.C),

        // LD DE, d16
        // Load the 2 bytes of immediate data into register pair DE.
        // The first byte of immediate data is the lower byte (i.e., bit 0-7), and the second byte
        // of immediate data is the higher byte (i.e., bits 8-15)
        0x11 => instructions.load.rrImm16(proc, .DE),
        // LD (DE), A
        // Store the contents of register A in the memory location specified by register pair DE.
        0x12 => instructions.load.rrMemReg(proc, &proc.A),

        // LD D, d8
        // Load the 8-bit immediate operand d8 into register D.
        0x16 => instructions.load.imm8(proc, &proc.D),

        // JR s8
        // Jump s8 steps from the current address in the program counter (PC). (Jump relative.)
        0x18 => instructions.controlFlow.jumpImmOffset(proc),

        // JR NZ, s8
        // If the Z flag is 0, jump s8 steps from the current address stored in the program counter (PC). If not, the
        // instruction following the current JP instruction is executed (as usual).
        0x20 => instructions.controlFlow.jumpCondImmOffset(proc, .NZ),
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
