const std = @import("std");
const utils = @import("utils.zig");
const register = @import("register.zig");
const Register = register.Register;
const Processor = @import("processor.zig").Processor;
const Memory = @import("memory.zig");

const TestError = @import("testing.zig").TestError;
const masks = @import("masks.zig");

const expectEqual = std.testing.expectEqual;

const STOP_OP_CODE: u8 = 0x10;

const SEED: u64 = 0xBCDE_1234_FE3D_89A0;
var prng = std.Random.DefaultPrng.init(SEED);
const rand = prng.random();

test "decode and execute 0x01 [LD BC, d16]" {
    const op_code: u8 = 0x01;
    const initial_PC: u16 = 0x0100;
    const hi = rand.int(u8);
    const lo = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);

    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(0x0000, processor.AF.get());
    try expectEqual(hi, processor.BC.getHi());
    try expectEqual(lo, processor.BC.getLo());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(0x0000, processor.HL.get());
}

test "decode and execute 0x02 [LD (BC), A]" {
    const op_code: u8 = 0x02;
    const initial_PC: u16 = 0x0100;
    const A: u8 = rand.int(u8);
    const F: u8 = rand.int(u8);
    const BC: u16 = rand.int(u16);

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

test "decode and execute 0x32 [LD (HL-), A]" {
    const op_code: u8 = 0x32;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x37A2;
    const A: u8 = 0x0E;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x0E00, processor.AF.get());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(HL - 1, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
    try expectEqual(A, processor.memory.read(HL));
}

test "decode and execute 0x36 [LD (HL), d8]" {
    const op_code: u8 = 0x36;
    const initial_PC: u16 = 0x0100;
    const imm: u8 = 0xA5;
    const HL: u16 = 0xB855;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, imm);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(imm, processor.memory.read(HL));
}

test "decode and execute 0x3A [LD A, (HL-)]" {
    const op_code: u8 = 0x3A;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x1C30;
    const content: u8 = 0x99;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(HL, content);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(content, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x0000, processor.BC.get());
    try expectEqual(0x0000, processor.DE.get());
    try expectEqual(HL - 1, processor.HL.get());
    try expectEqual(0x0000, processor.SP.get());
}

test "decode and execute 0x3E [LD A, d8]" {
    const op_code: u8 = 0x3E;
    const initial_PC: u16 = 0x0100;
    const imm: u8 = 0x81;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, imm);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(imm, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x40 [LD B, B]" {
    const op_code: u8 = 0x40;
    const initial_PC: u16 = 0x0100;
    const B: u8 = 0x02;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setHi(B);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(B, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x41 [LD B, C]" {
    const op_code: u8 = 0x41;
    const initial_PC: u16 = 0x0100;
    const C: u8 = 0x0D;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setLo(C);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(C, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x42 [LD B, D]" {
    const op_code: u8 = 0x42;
    const initial_PC: u16 = 0x0100;
    const D: u8 = 0xD4;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setHi(D);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(D, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(D, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x43 [LD B, E]" {
    const op_code: u8 = 0x43;
    const initial_PC: u16 = 0x0100;
    const E: u8 = 0xE9;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setLo(E);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(E, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(E, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x44 [LD B, H]" {
    const op_code: u8 = 0x44;
    const initial_PC: u16 = 0x0100;
    const H: u8 = 0x15;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setHi(H);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(H, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(H, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x45 [LD B, L]" {
    const op_code: u8 = 0x45;
    const initial_PC: u16 = 0x0100;
    const L: u8 = 0x15;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setLo(L);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(L, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(L, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x46 [LD B, (HL)]" {
    const op_code: u8 = 0x46;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x1905;
    const contents: u8 = 0xF0;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(HL, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(contents, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(contents, processor.memory.read(HL));
}

test "decode and execute 0x47 [LD B, A]" {
    const op_code: u8 = 0x47;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(A, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x48 [LD C, B]" {
    const op_code: u8 = 0x48;
    const initial_PC: u16 = 0x0100;
    const B: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setHi(B);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(B, processor.BC.getHi());
    try expectEqual(B, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x49 [LD C, C]" {
    const op_code: u8 = 0x49;
    const initial_PC: u16 = 0x0100;
    const C: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setLo(C);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x4A [LD C, D]" {
    const op_code: u8 = 0x4A;
    const initial_PC: u16 = 0x0100;
    const D: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setHi(D);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(D, processor.BC.getLo());
    try expectEqual(D, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x4B [LD C, E]" {
    const op_code: u8 = 0x4B;
    const initial_PC: u16 = 0x0100;
    const E: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setLo(E);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(E, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(E, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x4C [LD C, H]" {
    const op_code: u8 = 0x4C;
    const initial_PC: u16 = 0x0100;
    const H: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setHi(H);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(H, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(H, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x4D [LD C, L]" {
    const op_code: u8 = 0x4D;
    const initial_PC: u16 = 0x0100;
    const L: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setLo(L);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(L, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(L, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x4E [LD C, (HL)]" {
    const op_code: u8 = 0x4E;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x053E;
    const contents: u8 = 0xBB;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(HL, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(contents, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(contents, processor.memory.read(HL));
}

test "decode and execute 0x4F [LD C, A]" {
    const op_code: u8 = 0x4F;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(A, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x50 [LD D, B]" {
    const op_code: u8 = 0x50;
    const initial_PC: u16 = 0x0100;
    const B: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setHi(B);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(B, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(B, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x51 [LD D, C]" {
    const op_code: u8 = 0x51;
    const initial_PC: u16 = 0x0100;
    const C: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setLo(C);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(C, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x52 [LD D, D]" {
    const op_code: u8 = 0x52;
    const initial_PC: u16 = 0x0100;
    const D: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setHi(D);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(D, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x53 [LD D, E]" {
    const op_code: u8 = 0x53;
    const initial_PC: u16 = 0x0100;
    const E: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setLo(E);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(E, processor.DE.getHi());
    try expectEqual(E, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x54 [LD D, H]" {
    const op_code: u8 = 0x54;
    const initial_PC: u16 = 0x0100;
    const H: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setHi(H);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(H, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(H, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x55 [LD D, L]" {
    const op_code: u8 = 0x55;
    const initial_PC: u16 = 0x0100;
    const L: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setLo(L);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(L, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(L, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x56 [LD D, (HL)]" {
    const op_code: u8 = 0x56;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x3A95;
    const contents: u8 = 0x1E;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(HL, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(contents, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(contents, processor.memory.read(HL));
}

test "decode and execute 0x57 [LD D, A]" {
    const op_code: u8 = 0x57;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(A, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x58 [LD E, B]" {
    const op_code: u8 = 0x58;
    const initial_PC: u16 = 0x0100;
    const B: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setHi(B);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(B, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(B, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x59 [LD E, C]" {
    const op_code: u8 = 0x59;
    const initial_PC: u16 = 0x0100;
    const C: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setLo(C);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(C, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x5A [LD E, D]" {
    const op_code: u8 = 0x5A;
    const initial_PC: u16 = 0x0100;
    const D: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setHi(D);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(D, processor.DE.getHi());
    try expectEqual(D, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x5B [LD E, E]" {
    const op_code: u8 = 0x5B;
    const initial_PC: u16 = 0x0100;
    const E: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setLo(E);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(E, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x5C [LD E, H]" {
    const op_code: u8 = 0x5C;
    const initial_PC: u16 = 0x0100;
    const H: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setHi(H);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(H, processor.DE.getLo());
    try expectEqual(H, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x5D [LD E, L]" {
    const op_code: u8 = 0x5D;
    const initial_PC: u16 = 0x0100;
    const L: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setLo(L);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(L, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(L, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x5E [LD E, (HL)]" {
    const op_code: u8 = 0x5E;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0xD0C7;
    const contents: u8 = 0xDD;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(HL, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(contents, processor.DE.getLo());
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(contents, processor.memory.read(HL));
}

test "decode and execute 0x5F [LD E, A]" {
    const op_code: u8 = 0x5F;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(A, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x60 [LD H, B]" {
    const op_code: u8 = 0x60;
    const initial_PC: u16 = 0x0100;
    const B: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setHi(B);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(B, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(B, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x61 [LD H, C]" {
    const op_code: u8 = 0x61;
    const initial_PC: u16 = 0x0100;
    const C: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setLo(C);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(C, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x62 [LD H, D]" {
    const op_code: u8 = 0x62;
    const initial_PC: u16 = 0x0100;
    const D: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setHi(D);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(D, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(D, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x63 [LD H, E]" {
    const op_code: u8 = 0x63;
    const initial_PC: u16 = 0x0100;
    const E: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setLo(E);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(E, processor.DE.getLo());
    try expectEqual(E, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x64 [LD H, H]" {
    const op_code: u8 = 0x64;
    const initial_PC: u16 = 0x0100;
    const H: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setHi(H);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(H, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x65 [LD H, L]" {
    const op_code: u8 = 0x65;
    const initial_PC: u16 = 0x0100;
    const L: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setLo(L);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(L, processor.HL.getHi());
    try expectEqual(L, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x66 [LD H, (HL)]" {
    const op_code: u8 = 0x66;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x4478;
    const contents: u8 = 0x0A;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(HL, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(contents, processor.HL.getHi());
    try expectEqual(0x78, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(contents, processor.memory.read(HL));
}

test "decode and execute 0x67 [LD H, A]" {
    const op_code: u8 = 0x67;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(A, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x68 [LD L, B]" {
    const op_code: u8 = 0x68;
    const initial_PC: u16 = 0x0100;
    const B: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setHi(B);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(B, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(B, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x69 [LD L, C]" {
    const op_code: u8 = 0x69;
    const initial_PC: u16 = 0x0100;
    const C: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setLo(C);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(C, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x6A [LD L, D]" {
    const op_code: u8 = 0x6A;
    const initial_PC: u16 = 0x0100;
    const D: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setHi(D);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(D, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(D, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x6B [LD L, E]" {
    const op_code: u8 = 0x6B;
    const initial_PC: u16 = 0x0100;
    const E: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setLo(E);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(E, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(E, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x6C [LD L, H]" {
    const op_code: u8 = 0x6C;
    const initial_PC: u16 = 0x0100;
    const H: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setHi(H);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(H, processor.HL.getHi());
    try expectEqual(H, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x6D [LD L, L]" {
    const op_code: u8 = 0x6D;
    const initial_PC: u16 = 0x0100;
    const L: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setLo(L);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(L, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x6E [LD L, (HL)]" {
    const op_code: u8 = 0x6E;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x7142;
    const contents: u8 = 0xE0;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(HL, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x71, processor.HL.getHi());
    try expectEqual(contents, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(contents, processor.memory.read(HL));
}

test "decode and execute 0x6F [LD L, A]" {
    const op_code: u8 = 0x6F;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(A, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x70 [LD (HL), B]" {
    const op_code: u8 = 0x70;
    const initial_PC: u16 = 0x0100;
    const B: u8 = 0x05;
    const HL: u16 = 0x4E74;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setHi(B);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(B, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(B, processor.memory.read(HL));
}

test "decode and execute 0x71 [LD (HL), C]" {
    const op_code: u8 = 0x71;
    const initial_PC: u16 = 0x0100;
    const C: u8 = 0x05;
    const HL: u16 = 0x4E74;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setLo(C);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(C, processor.memory.read(HL));
}

test "decode and execute 0x72 [LD (HL), D]" {
    const op_code: u8 = 0x72;
    const initial_PC: u16 = 0x0100;
    const D: u8 = 0x05;
    const HL: u16 = 0x4E74;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setHi(D);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(D, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(D, processor.memory.read(HL));
}

test "decode and execute 0x73 [LD (HL), E]" {
    const op_code: u8 = 0x73;
    const initial_PC: u16 = 0x0100;
    const E: u8 = 0x05;
    const HL: u16 = 0x4E74;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setLo(E);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(E, processor.DE.getLo());
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(E, processor.memory.read(HL));
}

test "decode and execute 0x74 [LD (HL), H]" {
    const op_code: u8 = 0x74;
    const initial_PC: u16 = 0x0100;
    const H: u8 = 0x4E;
    const L: u8 = 0x74;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setHi(H);
    processor.HL.setLo(L);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(H, processor.HL.getHi());
    try expectEqual(L, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(H, processor.memory.read(0x4E74));
}

test "decode and execute 0x75 [LD (HL), L]" {
    const op_code: u8 = 0x75;
    const initial_PC: u16 = 0x0100;
    const H: u8 = 0x4E;
    const L: u8 = 0x74;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setHi(H);
    processor.HL.setLo(L);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(H, processor.HL.getHi());
    try expectEqual(L, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(L, processor.memory.read(0x4E74));
}

test "decode and execute 0x77 [LD (HL), A]" {
    const op_code: u8 = 0x77;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x4E74;
    const A: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(A, processor.memory.read(HL));
}

test "decode and execute 0x78 [LD A, B]" {
    const op_code: u8 = 0x78;
    const initial_PC: u16 = 0x0100;
    const B: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setHi(B);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(B, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(B, processor.BC.getHi());
    try expectEqual(0x00, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x79 [LD A, C]" {
    const op_code: u8 = 0x79;
    const initial_PC: u16 = 0x0100;
    const C: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setLo(C);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(C, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x7A [LD A, D]" {
    const op_code: u8 = 0x7A;
    const initial_PC: u16 = 0x0100;
    const D: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setHi(D);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(D, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(D, processor.DE.getHi());
    try expectEqual(0x00, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x7B [LD A, E]" {
    const op_code: u8 = 0x7B;
    const initial_PC: u16 = 0x0100;
    const E: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.DE.setLo(E);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(E, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.getHi());
    try expectEqual(E, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x7C [LD A, H]" {
    const op_code: u8 = 0x7C;
    const initial_PC: u16 = 0x0100;
    const H: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setHi(H);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(H, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(H, processor.HL.getHi());
    try expectEqual(0x00, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x7D [LD A, L]" {
    const op_code: u8 = 0x7D;
    const initial_PC: u16 = 0x0100;
    const L: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.setLo(L);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(L, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.getHi());
    try expectEqual(L, processor.HL.getLo());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0x7E [LD A, (HL)]" {
    const op_code: u8 = 0x7E;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0x22A5;
    const contents: u8 = 0x13;

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
    try expectEqual(HL, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(contents, processor.memory.read(HL));
}

test "decode and execute 0x7F [LD A, A]" {
    const op_code: u8 = 0x7F;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0xC0 [RET NZ]" {
    return TestError.NotImplemented;
}

test "decode and execute 0xC1 [POP BC]" {
    const op_code: u8 = 0xC1;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0xAFFF;
    const hi: u8 = 0x14;
    const lo: u8 = 0xFA;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(SP, lo);
    processor.memory.write(SP + 1, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(hi, processor.BC.getHi());
    try expectEqual(lo, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(SP + 2, processor.SP.get());
}

test "decode and execute 0xC2 [JP NZ, a16], NZ" {
    const op_code: u8 = 0xC2;
    const initial_PC: u16 = 0x0100;
    const hi: u8 = 0x78;
    const lo: u8 = 0x3D;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.unsetFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x783D, processor.PC.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xC2 [JP NZ, a16], Z" {
    const op_code: u8 = 0xC2;
    const initial_PC: u16 = 0x0100;
    const hi: u8 = 0x78;
    const lo: u8 = 0x3D;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.setFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(0x00, processor.AF.getHi());
    try expectEqual(masks.Z_MASK, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}


test "decode and execute 0xC3 [JP a16]" {
    const op_code: u8 = 0xC3;
    const initial_PC: u16 = 0x0100;
    const hi: u8 = 0x0E;
    const lo: u8 = 0xE3;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x0EE3, processor.PC.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xC4 [CALL NZ, a16]" {
    const op_code: u8 = 0xC4;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi = rand.int(u8);
    const lo = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.unsetFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const PC_hi: u8 = @truncate(((initial_PC + 3) & masks.HI_MASK) >> 8);
    const PC_lo: u8 = @truncate((initial_PC + 3) & masks.LO_MASK);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(hi, processor.PC.getHi());
    try expectEqual(lo, processor.PC.getLo());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(PC_hi, processor.memory.read(SP - 1));
    try expectEqual(PC_lo, processor.memory.read(SP - 2));
}

test "decode and execute 0xC5 [PUSH BC]" {
    const op_code: u8 = 0xC5;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0xAFFF;
    const BC: u16 = 0x14FA;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.BC.set(BC);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(BC, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(0x14, processor.memory.read(SP - 1));
    try expectEqual(0xFA, processor.memory.read(SP - 2));
}

test "decode and execute 0xC7 [RST 0]" {
    const op_code: u8 = 0xC7;
    const initial_PC: u16 = 0x0102;
    const SP: u16 = 0x0AFF;

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x0000, processor.PC.get());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(0x01, processor.memory.read(SP - 1));
    try expectEqual(0x03, processor.memory.read(SP - 2));
}

test "decode and execute 0xC8 [RET Z], Z" {
    const op_code: u8 = 0xC8;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi: u8 = rand.int(u8);
    const lo: u8 = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.setFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(SP, lo);
    processor.memory.write(SP + 1, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(hi, processor.PC.getHi());
    try expectEqual(lo, processor.PC.getLo());
    try expectEqual(SP + 2, processor.SP.get());
    try expectEqual(masks.Z_MASK, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xC8 [RET Z], NZ" {
    const op_code: u8 = 0xC8;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi: u8 = rand.int(u8);
    const lo: u8 = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.unsetFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(SP, lo);
    processor.memory.write(SP + 1, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(SP, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xC9 [RET]" {
    const op_code: u8 = 0xC9;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi = rand.int(u8);
    const lo = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(SP, lo);
    processor.memory.write(SP + 1, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(hi, processor.PC.getHi());
    try expectEqual(lo, processor.PC.getLo());
    try expectEqual(SP + 2, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xCA [JP Z, a16], Z" {
    const op_code: u8 = 0xCA;
    const initial_PC: u16 = 0x0100;
    const hi = rand.int(u8);
    const lo = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.setFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(hi, processor.PC.getHi());
    try expectEqual(lo, processor.PC.getLo());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(masks.Z_MASK, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xCA [JP Z, a16], NZ" {
    const op_code: u8 = 0xCA;
    const initial_PC: u16 = 0x0100;
    const hi = rand.int(u8);
    const lo = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.unsetFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xCC [CALL Z, a16], Z" {
    const op_code: u8 = 0xCC;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi: u8 = rand.int(u8);
    const lo: u8 = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.setFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const PC_hi: u8 = @truncate(((initial_PC + 3) & masks.HI_MASK) >> 8);
    const PC_lo: u8 = @truncate((initial_PC + 3) & masks.LO_MASK);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(hi, processor.PC.getHi());
    try expectEqual(lo, processor.PC.getLo());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(masks.Z_MASK, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(PC_hi, processor.memory.read(SP - 1));
    try expectEqual(PC_lo, processor.memory.read(SP - 2));
}

test "decode and execute 0xCC [CALL Z, a16], NZ" {
    const op_code: u8 = 0xCC;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi: u8 = rand.int(u8);
    const lo: u8 = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.unsetFlag(.Z);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(SP, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.memory.read(SP - 1));
    try expectEqual(0x00, processor.memory.read(SP - 2));
}

test "decode and execute 0xCD [CALL a16]" {
    const op_code: u8 = 0xCD;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0xAFF;
    const hi: u8 = rand.int(u8);
    const lo: u8 = rand.int(u8);

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const PC_hi: u8 = @truncate(((initial_PC + 3) & masks.HI_MASK) >> 8);
    const PC_lo: u8 = @truncate((initial_PC + 3) & masks.LO_MASK);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(hi, processor.PC.getHi());
    try expectEqual(lo, processor.PC.getLo());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(PC_hi, processor.memory.read(SP - 1));
    try expectEqual(PC_lo, processor.memory.read(SP - 2));
}

test "decode and execute 0xCF [RST 1]" {
    const op_code: u8 = 0xCF;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);

    const PC_hi: u8 = @truncate(((initial_PC + 1) & masks.HI_MASK) >> 8);
    const PC_lo: u8 = @truncate((initial_PC + 1) & masks.LO_MASK);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x0008, processor.PC.get());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(PC_hi, processor.memory.read(SP - 1));
    try expectEqual(PC_lo, processor.memory.read(SP - 2));
}

test "decode and execute 0xD0 [RET NC]" {
    const op_code: u8 = 0xD0;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi: u8 = rand.int(u8);
    const lo: u8 = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(SP, lo);
    processor.memory.write(SP + 1, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(utils.toTwoBytes(hi, lo), processor.PC.get());
    try expectEqual(SP + 2, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xD1 [POP DE]" {
    const op_code: u8 = 0xD1;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0xAFFF;
    const hi: u8 = 0x14;
    const lo: u8 = 0xBA;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(SP, lo);
    processor.memory.write(SP + 1, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(hi, processor.DE.getHi());
    try expectEqual(lo, processor.DE.getLo());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(SP + 2, processor.SP.get());
}

test "decode and execute 0xD2 [JP NC, a16], NC" {
    const op_code: u8 = 0xD2;
    const initial_PC: u16 = 0x0100;
    const hi: u8 = rand.int(u8);
    const lo: u8 = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.unsetFlag(.C);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(utils.toTwoBytes(hi, lo), processor.PC.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xD2 [JP NC, a16], C" {
    const op_code: u8 = 0xD2;
    const initial_PC: u16 = 0x0100;
    const hi: u8 = rand.int(u8);
    const lo: u8 = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.setFlag(.C);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(masks.C_MASK, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xD4 [CALL NC, a16], NC" {
    const op_code: u8 = 0xD4;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi = rand.int(u8);
    const lo = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.unsetFlag(.C);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(hi, processor.PC.getHi());
    try expectEqual(lo, processor.PC.getLo());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xD4 [CALL NC, a16], C" {
    const op_code: u8 = 0xD4;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi = rand.int(u8);
    const lo = rand.int(u8);

    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.setFlag(.C);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(SP, processor.SP.get());
    try expectEqual(masks.C_MASK, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xD5 [PUSH DE]" {
    const op_code: u8 = 0xD5;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0xAFFF;
    const hi: u8 = 0x14;
    const lo: u8 = 0xBA;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.DE.setHi(hi);
    processor.DE.setLo(lo);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x14BA, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(hi, processor.memory.read(SP - 1));
    try expectEqual(lo, processor.memory.read(SP - 2));
}

test "decode and execute 0xD7 [RST 2]" {
    const op_code: u8 = 0xD7;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    
    var memory: Memory = .init();
    var processor: Processor = .init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(0x0010, processor.PC.get());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xE0 [LD (a8), A]" {
    const op_code: u8 = 0xE0;
    const initial_PC: u16 = 0x0100;
    const imm: u8 = 0x8C;
    const A: u8 = 0x13;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, imm);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(A, processor.memory.read(0xFF8C));
}

test "decode and execute 0xE1 [POP HL]" {
    const op_code: u8 = 0xE1;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi: u8 = 0x59;
    const lo: u8 = 0x83;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(SP, lo);
    processor.memory.write(SP + 1, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(hi, processor.HL.getHi());
    try expectEqual(lo, processor.HL.getLo());
    try expectEqual(SP + 2, processor.SP.get());
}

test "decode and execute 0xE2 [LD (C), A]" {
    const op_code: u8 = 0xE2;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x03;
    const C: u8 = 0x3E;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.BC.setLo(C);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(A, processor.memory.read(0xFF3E));
}

test "decode and execute 0xE5 [PUSH HL]" {
    const op_code: u8 = 0xE5;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi: u8 = 0x59;
    const lo: u8 = 0x83;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.HL.setHi(hi);
    processor.HL.setLo(lo);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(hi, processor.HL.getHi());
    try expectEqual(lo, processor.HL.getLo());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(hi, processor.memory.read(SP - 1));
    try expectEqual(lo, processor.memory.read(SP - 2));
}

test "decode and execute 0xEA [LD (a16), A]" {
    const op_code: u8 = 0xEA;
    const initial_PC: u16 = 0x0100;
    const A: u8 = 0x35;
    const hi: u8 = 0x78;
    const lo: u8 = 0xA2;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.AF.setHi(A);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(A, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
    try expectEqual(A, processor.memory.read(0x78A2));
}

test "decode and execute 0xF0 [LD A, (a8)]" {
    const op_code: u8 = 0xF0;
    const initial_PC: u16 = 0x0100;
    const imm: u8 = 0x53;
    const contents: u8 = 0x05;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, imm);
    processor.memory.write(0xFF53, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 2, processor.PC.get());
    try expectEqual(contents, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0xF1 [POP AF]" {
    const op_code: u8 = 0xF1;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0xAFF;
    const hi: u8 = 0x30;
    const lo: u8 = 0x4C;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(SP, lo);
    processor.memory.write(SP - 1, hi);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(hi, processor.AF.getHi());
    try expectEqual(lo, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
}

test "decode and execute 0xF2" {
    const op_code: u8 = 0xF2;
    const initial_PC: u16 = 0x0100;
    const C: u8 = 0x70;
    const contents: u8 = 0x0C;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.BC.setLo(C);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(0xFF70, contents);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(contents, processor.AF.getHi());
    try expectEqual(0x00, processor.AF.getLo());
    try expectEqual(0x00, processor.BC.getHi());
    try expectEqual(C, processor.BC.getLo());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(0x00, processor.SP.get());
}

test "decode and execute 0xF5 [PUSH AF]" {
    const op_code: u8 = 0xF5;
    const initial_PC: u16 = 0x0100;
    const SP: u16 = 0x0AFF;
    const hi: u8 = 0x07;
    const lo: u8 = 0x5B;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.SP.set(SP);
    processor.AF.setHi(hi);
    processor.AF.setLo(lo);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(SP - 2, processor.SP.get());
    try expectEqual(0x075B, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(0x00, processor.HL.get());
    try expectEqual(hi, processor.memory.read(SP - 1));
    try expectEqual(lo, processor.memory.read(SP - 2));
}

test "decode and execute 0xF8 [LD HL, SP+s8]" {
    return TestError.NotImplemented;
}

test "decode and execute 0xF9 [LD SP, HL]" {
    const op_code: u8 = 0xF9;
    const initial_PC: u16 = 0x0100;
    const HL: u16 = 0xB41C;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.HL.set(HL);
    processor.memory.write(initial_PC, op_code);

    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 1, processor.PC.get());
    try expectEqual(HL, processor.SP.get());
    try expectEqual(0x00, processor.AF.get());
    try expectEqual(0x00, processor.BC.get());
    try expectEqual(0x00, processor.DE.get());
    try expectEqual(HL, processor.HL.get());
}

test "decode and execute 0xFA [LD A, (a16)]" {
    const op_code: u8 = 0xFA;
    const initial_PC: u16 = 0x0100;
    const hi: u8 = 0x01;
    const lo: u8 = 0x43;
    const contents: u8 = 0x2A;

    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.PC.set(initial_PC);
    processor.memory.write(initial_PC, op_code);
    processor.memory.write(initial_PC + 1, lo);
    processor.memory.write(initial_PC + 2, hi);
    processor.memory.write(0x0143, contents);
    
    const instruction = processor.fetch();
    try processor.decodeAndExecute(instruction);
    try expectEqual(initial_PC + 3, processor.PC.get());
    try expectEqual(contents, processor.AF.getHi());
}
