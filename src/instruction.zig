const std = @import("std");
const utils = @import("utils.zig");
const Register = @import("register.zig");
const Processor = @import("processor.zig").Processor;
const Memory = @import("memory.zig");

const ByteAdditionResult = utils.ByteAdditionResult;

pub fn incrementRegister(
    p: *Processor,
    r: *Register,
    set: anytype,
    get: anytype,
) void {
    const sum = utils.byteAdd(get(r), 1);
    set(r, sum.result);
    p.unsetFlag(.N);
    if (sum.result == 0) p.setFlag(.Z) else p.unsetFlag(.Z);
    if (sum.half_carry == 1) p.setFlag(.H) else p.unsetFlag(.H);
}

const expectEqual = std.testing.expectEqual;

test "incrementRegister, BC" {

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);

    incrementRegister(&processor, &processor.BC, Register.setHi, Register.getHi);

    try expectEqual(0x01, processor.BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    incrementRegister(&processor, &processor.BC, Register.setHi, Register.getHi);
    try expectEqual(0x02, processor.BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.BC.setHi(0xFF);
    incrementRegister(&processor, &processor.BC, Register.setHi, Register.getHi);

    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.BC.setHi(0x0F);
    incrementRegister(&processor, &processor.BC, Register.setHi, Register.getHi);
    try expectEqual(0x10, processor.BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}
