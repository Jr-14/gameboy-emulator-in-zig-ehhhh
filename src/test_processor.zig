const std = @import("std");
const Register = @import("register.zig").Register;
const Processor = @import("processor.zig").Processor;
const Memory = @import("memory.zig").Memory;

const expectEqual = std.testing.expectEqual;

test "decode and execute 0x01 [LD BC, d16]" {
    const op_code: u8 = 0x01;
    const start_mem_location: u16 = 0x0100;
    const hi: u8 = 0x89;
    const lo: u8 = 0xc4;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(start_mem_location);
    processor.memory.write(start_mem_location, op_code);
    processor.memory.write(start_mem_location + 1, lo);
    processor.memory.write(start_mem_location + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);

    try expectEqual(start_mem_location + 3, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x89c4, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0x02 [LD (BC), A]" {
    const op_code: u8 = 0x02;
    const start_mem_location: u16 = 0x0100;
    const A: u8 = 0x93;
    const F: u8 = 0x00;
    const BC: u16 = 0x1d49;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.memory.write(start_mem_location, op_code);
    processor.AF.setHi(A);
    processor.AF.setLo(F);
    processor.BC.set(BC);
    processor.PC.set(start_mem_location);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(start_mem_location + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(F, processor.AF.getLo());
    try expectEqual(BC, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(A, processor.memory.read(processor.BC.get()));
}

test "decode and execute 0x03 [INC BC]" {
    const op_code: u8 = 0x03;
    const start_mem_location: u16 = 0x0100;
    const BC: u16 = 0xc379;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.BC.set(BC);
    processor.memory.set(start_mem_location, op_code);

    const instruction = processor.fetch();
    
    try processor.decodeAndExecute(instruction);

    try expectEqual(start_mem_location + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(BC + 1, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0x06 [LD B, d8]" {
    const op_code: u8 = 0x06;
    const start_mem_location: u16 = 0x0100;
    const d: u8 = 0x02;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(start_mem_location);
    processor.memory.write(start_mem_location, op_code);
    processor.memory.write(start_mem_location + 1, d);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(start_mem_location + 2, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(d, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0x08 [LD (a16), SP]" {
    const op_code: u8 = 0x08;
    const start_mem_location: u16 = 0x0100;
    const SP: u16 = 0xA930;
    const lo: u8 = 0x14;
    const hi: u8 = 0x79;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(start_mem_location);
    processor.SP.set(SP);
    processor.memory.write(start_mem_location, op_code);
    processor.memory.write(start_mem_location + 1, lo);
    processor.memory.write(start_mem_location + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(start_mem_location + 3, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(SP, processor.SP.get());
    try expectEqual(0x30, processor.memory.read(0x7914));
    try expectEqual(0xA9, processor.memory.read(0x7914 + 1));
}
