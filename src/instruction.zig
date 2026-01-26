const std = @import("std");
const Register = @import("register.zig");
const Processor = @import("processor.zig").Processor;
const Memory = @import("memory.zig");

const utils = @import("utils.zig");

fn incReg(
    proc: *Processor,
    reg: *Register,
    set: anytype,
    get: anytype,
) void {
    const sum = utils.byteAdd(get(reg), 1);
    set(reg, sum.result);
    proc.unsetFlag(.N);
    if (sum.result == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
    if (sum.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
}

pub fn incHiReg(proc: *Processor, reg: *Register) void {
    incReg(proc, reg, Register.setHi, Register.getHi);
}

pub fn incLoReg(proc: *Processor, reg: *Register) void {
    incReg(proc, reg, Register.setLo, Register.getLo);
}

fn decReg(
    proc: *Processor,
    reg: *Register,
    set: anytype,
    get: anytype,
) void {
    const remainder = utils.byteSub(get(reg), 1);
    set(reg, remainder.result);
    proc.setFlag(.N);
    if (remainder.result == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
    if (remainder.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
}

pub fn decHiReg(proc: *Processor, reg: *Register) void {
    decReg(proc, reg, Register.setHi, Register.getHi);
}

pub fn decLoReg(proc: *Processor, reg: *Register) void {
    decReg(proc, reg, Register.setLo, Register.getLo);
}

pub fn loadHiFromImm(proc: *Processor, reg: *Register) void {
    reg.setHi(proc.fetch());
}

pub fn loadLoFromImm(proc: *Processor, reg: *Register) void {
    reg.setLo(proc.fetch());
}

// Load into two byte registers immediate two byte data.
pub fn loadRRFromImm16(proc: *Processor, reg: *Register) void {
    reg.setLo(proc.fetch());
    reg.setHi(proc.fetch());
}

const expectEqual = std.testing.expectEqual;

test "incReg, BC" {
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);

    incReg(&processor, &processor.BC, Register.setHi, Register.getHi);

    try expectEqual(0x01, processor.BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    incReg(&processor, &processor.BC, Register.setHi, Register.getHi);
    try expectEqual(0x02, processor.BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.BC.setHi(0xFF);
    incReg(&processor, &processor.BC, Register.setHi, Register.getHi);

    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.BC.setHi(0x0F);
    incReg(&processor, &processor.BC, Register.setHi, Register.getHi);
    try expectEqual(0x10, processor.BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.DE.setLo(0x0F);
    incReg(&processor, &processor.DE, Register.setLo, Register.getLo);
    try expectEqual(0x10, processor.DE.getLo());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "decReg, DE" {
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.DE.setHi(0x02);

    decReg(&processor, &processor.DE, Register.setHi, Register.getHi);
    try expectEqual(0x01, processor.DE.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    decReg(&processor, &processor.DE, Register.setHi, Register.getHi);
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    decReg(&processor, &processor.DE, Register.setHi, Register.getHi);
    try expectEqual(0xFF, processor.DE.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "decHiReg, DE" {
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);

    const reg = &processor.DE;
    reg.setHi(0x0F);
    decHiReg(&processor, reg);

    try expectEqual(0xE, reg.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
}

test "decLoReg, DE" {
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);

    const reg = &processor.DE;
    reg.setLo(0x0F);
    decLoReg(&processor, reg);

    try expectEqual(0xE, reg.getLo());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
}

test "incHiReg, AF" {
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);

    const reg = &processor.AF;
    reg.setHi(0x0F);
    incHiReg(&processor, reg);

    try expectEqual(0x10, reg.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "incLoReg, BC" {
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);

    const reg = &processor.BC;
    reg.setLo(0x0F);
    incLoReg(&processor, reg);

    try expectEqual(0x10, reg.getLo());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}
