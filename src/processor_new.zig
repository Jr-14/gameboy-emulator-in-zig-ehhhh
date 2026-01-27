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
    };
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
