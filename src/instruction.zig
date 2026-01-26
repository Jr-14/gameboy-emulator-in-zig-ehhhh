const std = @import("std");
const Register = @import("register.zig");
const Processor = @import("processor.zig").Processor;
const Memory = @import("memory.zig");

const byteAdd = @import("utils.zig").byteAdd;

pub fn incrReg(
    p: *Processor,
    r: *Register,
    set: anytype,
    get: anytype,
) void {
    const sum = byteAdd(get(r), 1);
    set(r, sum.result);
    p.unsetFlag(.N);
    if (sum.result == 0) p.setFlag(.Z) else p.unsetFlag(.Z);
    if (sum.half_carry == 1) p.setFlag(.H) else p.unsetFlag(.H);
}

pub fn incrHiReg(p: *Processor, r: *Register) void {
    incrReg(p, r, Register.setHi, Register.getHi);
}

pub fn incrLoReg(p: *Processor, r: *Register) void {
    incrReg(p, r, Register.setLo, Register.getLo);
}

const expectEqual = std.testing.expectEqual;

test "incrReg, BC" {
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);

    incrReg(&processor, &processor.BC, Register.setHi, Register.getHi);

    try expectEqual(0x01, processor.BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    incrReg(&processor, &processor.BC, Register.setHi, Register.getHi);
    try expectEqual(0x02, processor.BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.BC.setHi(0xFF);
    incrReg(&processor, &processor.BC, Register.setHi, Register.getHi);

    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.BC.setHi(0x0F);
    incrReg(&processor, &processor.BC, Register.setHi, Register.getHi);
    try expectEqual(0x10, processor.BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.DE.setLo(0x0F);
    incrReg(&processor, &processor.DE, Register.setLo, Register.getLo);
    try expectEqual(0x10, processor.DE.getLo());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "incrHiReg, AF" {
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);

    processor.AF.setHi(0x0F);
    incrHiReg(&processor, &(processor.AF));

    try expectEqual(0x10, processor.AF.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}
