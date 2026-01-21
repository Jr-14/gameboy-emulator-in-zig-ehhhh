const std = @import("std");
const register = @import("register.zig");
const Register = register.Register;
const Processor = @import("processor.zig").Processor;
const Memory = @import("memory.zig").Memory;

const masks = @import("masks.zig");

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

test "decode and execute 0x18 [JR s8] - negative offset" {
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

test "decode and execute 0x18 [JR s8] - positive offset" {
    const op_code: u8 = 0x18;
    const initial_PC: u16 = 0x00FF;
    const offset: u8 = 0b0000_0011; // +3

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, offset);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x0104, processor.PC.get());
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
    processor.setFlag(.Z);
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

test "decode and execute 0x21 [LD HL, d16]" {
    const op_code: u8 = 0x21;
    const initial_PC: u16 = 0x0100;
    const lo: u8 = 0x13;
    const hi: u8 = 0xC7;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x0103, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0xC713, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x28 [JR Z, s8] Z, negative s8" {
    const op_code: u8 = 0x28;
    const initial_PC: u16 = 0x100;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.setFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, 0b1000_0000); // -127

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x0082, processor.PC.get());
    try expectEqual(masks.Z_MASK, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x28 [JR Z, s8] Z, postive s8" {
    const op_code: u8 = 0x28;
    const initial_PC: u16 = 0x100;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.setFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, 0b0111_1111); // 127

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x0181, processor.PC.get());
    try expectEqual(masks.Z_MASK, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x30 [JR NC, s8], NC" {
    const op_code: u8 = 0x30;
    const initial_PC: u16 = 0x0100;
    const offset: u8 = 0b1111_1101; // -3

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, offset);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);

   try expectEqual(0x00FF, processor.PC.get());
   try expectEqual(0x0000, processor.AF.get());
   try expectEqual(0x0000, processor.BC.get());
   try expectEqual(0x0000, processor.DE.get());
   try expectEqual(0x0000, processor.HL.get());
   try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x30 [JR NC, s8], C" {
    const op_code: u8 = 0x30;
    const initial_PC: u16 = 0x0100;
    const offset: u8 = 0b0111_1111; // 127

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.setFlag(.C);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, offset);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);

   try expectEqual(0x0102, processor.PC.get());
   try expectEqual(masks.C_MASK, processor.AF.get());
   try expectEqual(0x0000, processor.BC.get());
   try expectEqual(0x0000, processor.DE.get());
   try expectEqual(0x0000, processor.HL.get());
   try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x38 [JR C, s8], NC" {
    const op_code: u8 = 0x38;
    const initial_PC: u16 = 0x0100;
    const offset: u8 = 0b0111_1111; // 127

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, offset);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x38 [JR C, s8], C" {
    const op_code: u8 = 0x38;
    const initial_PC: u16 = 0x0100;
    const offset: u8 = 0b0111_1111; // 127

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.setFlag(.C);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, offset);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2 + offset, processor.PC.get());
    try expectEqual(masks.C_MASK, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x1A [LD A, (DE)]" {
    const op_code: u8 = 0x1A;
    const initial_PC: u16 = 0x0100;
    const DE: u16 = 0x1A39;
    const contents: u8 = 0x7F;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.set(DE);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(DE, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(contents, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(DE, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x1E [LD E, d8]" {
    const op_code: u8 = 0x1E;
    const initial_PC: u16 = 0x0100;
    const imm: u8 = 0x13;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, imm);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(imm, processor.DE.getLo());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x22 [LD (HL+), A]" {
    const op_code: u8 = 0x22;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x91;
    const HL: u16 = 0x368D;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(HL + 1, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(A, processor.memory.read(HL));
}

test "decode and execute 0x26 [LD H, d8]" {
    const op_code: u8 = 0x26;
    const initial_PC: u16 = 0x0100;
    const imm: u8 = 0x45;

    var memory = Memory.init();
    var procesor = Processor.init(&memory);
    procesor.PC.set(initial_PC);
    procesor.memory.write(initial_PC, op_code);
    procesor.memory.write(initial_PC + 1, imm);

    const instruction = procesor.fetch();
    try procesor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, procesor.PC.get());
    try expectEqual(0x00, procesor.AF.get());
    try expectEqual(0x00, procesor.BC.get());
    try expectEqual(0x00, procesor.DE.get());
    try expectEqual(imm, procesor.HL.getHi());
    try expectEqual(0x00, procesor.HL.getLo());
    try expectEqual(0x00, procesor.SP.get());
}

test "decode and execute 0x2A [LD A, (HL+)]" {
    const op_code: u8 = 0x2A;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x76A2;
    const contents: u8 = 0x06;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(HL, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(contents, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(HL + 1, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x2E [LD L, d8]" {
    const op_code: u8 = 0x2E;
    const initial_PC: u16 = 0x0100;
    const imm: u8 = 0x4A;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, imm);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(imm, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x31 [LD SP, d16]" {
    const op_code: u8 = 0x31;
    const initial_PC: u16 = 0x0100;
    const lo: u8 = 0x98;
    const hi: u8 = 0x1A;

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
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
    try expectEqual(0x1A98, processor.SP.get());
}
