const std = @import("std");
const Register = @import("register.zig").Register;
const Processor = @import("processor.zig").Processor;
const Memory = @import("memory.zig").Memory;

const expectEqual = std.testing.expectEqual;

test "decode and execute 0x01 [LD BC, d16]" {
    const op_code: u8 = 0x01;
    const start_mem_location: u16 = 0x0100;
    const hi: u8 = 0x1d;
    const lo: u8 = 0x49;

    var memory = Memory.init();
    memory.write(start_mem_location, op_code);
    memory.write(start_mem_location + 1, lo); // lo
    memory.write(start_mem_location + 2, hi); // hi

    var processor = Processor.init(&memory);
    processor.PC.set(start_mem_location);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(start_mem_location + 2, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(hi, processor.BC.getHi());
    try expectEqual(lo, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}
