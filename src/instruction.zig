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
    if (sum.result == 0) {
        p.setFlag(.Z);
    }
    if (sum.half_carry == 1) {
        p.setFlag(.H);
    }
}

const expectEqual = std.testing.expectEqual;

test "incrementRegister" {
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);

    var BC = &processor.BC;
    incrementRegister(&processor, BC, Register.setHi, Register.getHi);

    try expectEqual(1, BC.getHi());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
}
