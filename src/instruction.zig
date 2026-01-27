const std = @import("std");
const Register = @import("register_new.zig");
const Processor = @import("processor_new.zig");
const Memory = @import("memory.zig");

const FlagCondition = enum {
    Z,
    NZ,
    N,
    NN,
    H,
    NH,
    C,
    NC
};

const utils = @import("utils.zig");

pub fn incReg(
    proc: *Processor,
    reg: *Register,
) void {
    const sum = utils.byteAdd(reg.value, 1);
    reg.value = sum.result;
    proc.unsetFlag(.N);
    if (sum.result == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
    if (sum.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
}

pub fn decReg(
    proc: *Processor,
    reg: *Register,
) void {
    const remainder = utils.byteSub(reg.value, 1);
    reg.value = remainder.result;
    proc.setFlag(.N);
    if (remainder.result == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
    if (remainder.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
}

/// Increment register pair RR by 1
pub fn incRR(proc: *Processor, regPair: Processor.RegisterPair) void {
    switch (regPair) {
        .AF => proc.setAF(proc.getAF() + 1),
        .BC => proc.setBC(proc.getBC() + 1),
        .DE => proc.setDE(proc.getDE() + 1),
        .HL => proc.setHL(proc.getHL() + 1),
    }
}

pub const load = struct {
    pub fn imm8(proc: *Processor, reg: *Register) void {
        reg.value = proc.fetch();
    }

    /// Load into two byte registers immediate two byte data.
    pub fn rrImm16(proc: *Processor, regPair: Processor.RegisterPair) void {
        switch (regPair) {
            .AF => {
                proc.F.value = proc.fetch();
                proc.A.value = proc.fetch();
            },
            .BC => {
                proc.C.value = proc.fetch();
                proc.B.value = proc.fetch();
            },
            .DE => {
                proc.E.value = proc.fetch();
                proc.D.value = proc.fetch();
            },
            .HL => {
                proc.L.value = proc.fetch();
                proc.H.value = proc.fetch();
            }
        }
    }

    /// Store the contents of a Register into the memory location specified by the register pair RR
    pub fn rrMemReg(proc: *Processor, regPair: Processor.RegisterPair, value: u8) void {
        switch (regPair) {
            .AF => proc.memory.write(proc.getAF(), value),
            .BC => proc.memory.write(proc.getBC(), value),
            .DE => proc.memory.write(proc.getDE(), value),
            .HL => proc.memory.write(proc.getHL(), value),
        }
    }

    /// Store into the immediate address the contents of register pair RR.
    pub fn imm16MemRR(proc: *Processor, regPair: Processor.RegisterPair) void {
        const addr: u16 = utils.fromTwoBytes(proc.fetch(), proc.fetch());
        switch (regPair) {
            .AF => {
                proc.memory.write(addr, proc.F.value);
                proc.memory.write(addr + 1, proc.A.value);
            },
            .BC => {
                proc.memory.write(addr, proc.C.value);
                proc.memory.write(addr + 1, proc.B.value);
            },
            .DE => {
                proc.memory.write(addr, proc.E.value);
                proc.memory.write(addr + 1, proc.D.value);
            },
            .HL => {
                proc.memory.write(addr, proc.L.value);
                proc.memory.write(addr + 1, proc.H.value);
            },
        }
    }

    /// Store into the immediate address the contents of special purpose registers
    pub fn imm16MemSPR(proc: *Processor, val: u16) void {
        const addr: u16 = utils.fromTwoBytes(proc.fetch(), proc.fetch());
        proc.memory.write(addr, utils.getLoByte(val));
        proc.memory.write(addr + 1, utils.getHiByte(val));
    }

    /// Load the 8-bit contents of memory specified by register pair into register
    pub fn regRRMem(proc: *Processor, reg: *Register, regPair: Processor.RegisterPair) void {
        switch (regPair) {
            .AF => reg.value = proc.memory.read(proc.getAF()),
            .BC => reg.value = proc.memory.read(proc.getBC()),
            .DE => reg.value = proc.memory.read(proc.getDE()),
            .HL => reg.value = proc.memory.read(proc.getHL()),
        }
    }
};

pub const controlFlow = struct {
    /// Jump s8 steps fetch from immediate operand in the program counter (PC).
    pub fn jumpImmOffset(proc: *Processor) void {
        const offset = proc.fetch();
        proc.PC = utils.addOffset(proc.PC, offset);
    }

    pub fn jumpCondImmOffset(proc: *Processor, condition: FlagCondition) void {
        const offset = proc.fetch();
        const cc: bool = switch(condition) {
            .Z => proc.isFlagSet(.Z),
            .NZ => !proc.isFlagSet(.Z),
            .N => proc.isFlagSet(.N),
            .NN => !proc.isFlagSet(.N),
            .H => proc.isFlagSet(.H),
            .NH => !proc.isFlagSet(.H),
            .C => proc.isFlagSet(.C),
            .NC => !proc.isFlagSet(.C),
        };
        if (cc) {
            proc.PC = utils.addOffset(proc.PC, offset);
        }
    }
};

const expectEqual = std.testing.expectEqual;

test "incReg" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{});

    incReg(&processor, &processor.B);

    try expectEqual(0x01, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    incReg(&processor, &processor.B);

    try expectEqual(0x02, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.B.value = 0xFF;
    incReg(&processor, &processor.B);

    try expectEqual(0x00, processor.B.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.B.value = 0x0F;
    incReg(&processor, &processor.B);
    try expectEqual(0x10, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.E.value = 0x0F;
    incReg(&processor, &processor.E);
    try expectEqual(0x10, processor.E.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "decReg" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .D = 0x02 });

    decReg(&processor, &processor.D);
    try expectEqual(0x01, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    decReg(&processor, &processor.D);
    try expectEqual(0x00, processor.D.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    decReg(&processor, &processor.D);
    try expectEqual(0xFF, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "load.rrImm16" {
    const PC: u16 = 0x0100;
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .PC = PC });
    const immLo: u8 = 0x03;
    const immHi: u8 = 0xA5;

    processor.memory.write(PC, immLo);
    processor.memory.write(PC + 1, immHi);

    load.rrImm16(&processor, .BC);
    try expectEqual(immHi, processor.B.value);
    try expectEqual(immLo, processor.C.value);
}
