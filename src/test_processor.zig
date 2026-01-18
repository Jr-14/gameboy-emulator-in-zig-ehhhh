const std = @import("std");
const register = @import("register.zig");
const Register = register.Register;
const Processor = @import("processor.zig").Processor;
const Memory = @import("memory.zig").Memory;

const expectEqual = std.testing.expectEqual;

const STOP_OP_CODE: u8 = 0x10;

test "decode and execute 0x01 [LD BC, d16]" {
    const op_code: u8 = 0x01;
    const initial_PC: u16 = 0x0100;
    const hi: u8 = 0x89;
    const lo: u8 = 0xc4;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);

    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(0x89c4, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
}

test "decode and execute 0x02 [LD (BC), A]" {
    const op_code: u8 = 0x02;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x93;
    const F: u8 = 0x00;
    const BC: u16 = 0x1d49;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.memory.write(initial_PC, op_code);
    processor.AF.setHi(A);
    processor.AF.setLo(F);
    processor.BC.set(BC);
    processor.PC.set(initial_PC);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(F, processor.AF.getLo());
    try expectEqual(BC, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(A, processor.memory.read(processor.BC.get()));
}

test "decode and execute 0x03 [INC BC]" {
    const op_code: u8 = 0x03;
    const initial_PC: u16 = 0x0100;
    const BC: u16 = 0xc379;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.set(BC);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);

    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(BC + 1, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
}

test "decode and execute 0x06 [LD B, d8]" {
    const op_code: u8 = 0x06;
    const initial_PC: u16 = 0x0100;
    const d: u8 = 0x02;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, d);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(d, processor.BC.getHi());
    try expectEqual(0x0000, processor.BC.getLo());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
}

test "decode and execute 0x08 [LD (a16), SP]" {
    const op_code: u8 = 0x08;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0xA930;
    const lo: u8 = 0x14;
    const hi: u8 = 0x79;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(SP, processor.SP.get());
    try expectEqual(0x0030, processor.memory.read(0x7914));
    try expectEqual(0x00A9, processor.memory.read(0x7914 + 1));
}

test "decode and execute 0x0A [LD A, (BC)]" {
    const op_code: u8 = 0x0a;
    const initial_PC: u16 = 0x0100;
    const BC: u16 = 0x2C19;
    const contents: u8 = 0x79;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.set(BC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, op_code);
    processor.memory.write(processor.BC.get(), contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(contents, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(BC, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0x0E [LD C, d8]" {
    const op_code: u8 = 0x0E;
    const initial_PC: u16 = 0x0100;
    const d: u8 = 0x12;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, d);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(0x0000, processor.BC.getHi());
    try expectEqual(d, processor.BC.getLo());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
}

test "decode and execute 0x11 [LD DE, d16]" {
    const op_code: u8 = 0x11;
    const initial_PC: u16 = 0x0100;
    const hi: u8 = 0x88;
    const lo: u8 = 0x1B;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    memory.write(initial_PC + 1, lo);
    memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x881B, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
}

test "decode and execute 0x12 [LD (DE), A]" {
    const op_code: u8 = 0x12;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0xBB;
    const DE: u16 = 0x1367;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.set(DE);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(DE, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(A, processor.memory.read(processor.DE.get()));
}

test "decode and execute 0x16 [LD D, d8]" {
    const op_code: u8 = 0x16;
    const initial_PC: u16 = 0x0100;
    const d: u8 = 0x0B;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, d);

    const instruction = processor.fetch();

    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(d, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0x18 [JR s8]" {
    const op_code: u8 = 0x18;
    const initial_PC: u16 = 0x00FD;
    const offset: u8 = 0b1111_1101; // -3

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, offset);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x00FC, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x20 [JR NZ, s8] NZ" {
    const op_code: u8 = 0x20;
    const initial_PC: u16 = 0x00FF;
    const offset: u8 = 0b1111_1101; // -3

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, offset);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC - 1, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x20 [JR NZ, s8] Z" {
    const op_code: u8 = 0x20;
    const initial_PC: u16 = 0x00FF;
    const offset: u8 = 0b1111_1101; // -3

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    register.setFlag(&processor.AF, .Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, offset);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(0x0080, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}
