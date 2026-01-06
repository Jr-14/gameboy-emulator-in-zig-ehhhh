const std = @import("std");
const main = @import("main.zig");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const Memory = main.Memory;
const RegisterFile = main.RegisterFile;

const STOP_OP_CODE: u8 = 0x010;

test "decode and execute 0x00 [NOP]" {
    const op_code: u8 = 0x00;
    const start_mem_location: u16 = 0x0100;

    var registers = RegisterFile{
        .IR = op_code,
        .PC = start_mem_location,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&registers, &memory);

    try expect(registers.PC == start_mem_location + 1);
    try expect(registers.A == 0);
    try expect(registers.B == 0);
    try expect(registers.C == 0);
    try expect(registers.D == 0);
    try expect(registers.E == 0);
    try expect(registers.H == 0);
    try expect(registers.L == 0);
    try expect(registers.IR == STOP_OP_CODE);
}

test "decode and execute 0x01 [LD BC, d16]" {
    const op_code: u8 = 0x01;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x1d);
    memory.set(start_mem_location + 2, 0x49);
    memory.set(start_mem_location + 3, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 3);
    try expect(register.A == 0);
    try expect(register.B == 0x49);
    try expect(register.C == 0x1d);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

// test "decode and execute 0x01 [LD BC, d16]" {
//     var registers = main.createRegisterFile();
//
//     // The number in base 10 is 5614 which is 00010101 11101110 in binary
//     // so in hex this is 0x15 0xee
//     try main.decodeAndExecute([_]u8{0x01, 0x15, 0xee}, &registers);
//
//     try expect(registers.PC == 1);
//     try expect(registers.A == 0);
//     try expect(registers.B == 0x15);
//     try expect(registers.C == 0xee);
//     try expect(registers.D == 0);
//     try expect(registers.E == 0);
//     try expect(registers.H == 0);
//     try expect(registers.L == 0);
//
//     // We will now load 100 which is 01100100 in binary and 0x64 in hex
//     try main.decodeAndExecute([_]u8{0x01, 0x00, 0x64}, &registers);
//
//     try expect(registers.PC == 2);
//     try expect(registers.A == 0);
//     try expect(registers.B == 0x00);
//     try expect(registers.C == 0x64);
//     try expect(registers.D == 0);
//     try expect(registers.E == 0);
//     try expect(registers.H == 0);
//     try expect(registers.L == 0);
// }

// Store the contents of register A in the memory location specified by register pair BC
test "decode and execute 0x02 [LD (BC), A]" {
    const op_code: u8 = 0x02;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x01,
        .B = 0xff,
        .C = 0xff,
    };
    var memory = Memory.init();
    memory.set(0x0100, op_code);
    memory.set(0x0101, op_code);
    memory.set(0x0102, op_code);
    memory.set(0x0103, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x01);
    try expect(register.B == 0xff);
    try expect(register.C == 0xff);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == op_code);
    try expect(memory.get(0xffff) == 0x01);
    try expect(memory.get(0xfffe) == 0x00);

    register.A = 0xfa;
    register.B = 0x00;
    register.C = 0x00;

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == start_mem_location + 2);
    try expect(register.A == 0xfa);
    try expect(register.B == 0x00);
    try expect(register.C == 0x00);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == op_code);
    try expect(memory.get(0x0000) == 0xfa);
    try expect(memory.get(0x0001) == 0x00);

    register.A = 0xfe;
    register.B = 0x1a;
    register.C = 0x56;

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == start_mem_location + 3);
    try expect(register.C == 0x56);
    try expect(register.B == 0x1a);
    try expect(register.A == 0xfe);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(0x1a56) == 0xfe);
    try expect(memory.get(0x1a57) == 0x00);
    try expect(memory.get(0x1a55) == 0x00);
}

// test "decode and execute 0x03 [INC BC]" {
//     var registers = main.createRegisterFile();
//
//     try main.decodeAndExecute([_]u8{0x03, 0x00, 0x00}, &registers);
//
//     try expect(registers.PC == 1);
//     try expect(registers.A == 0);
//     try expect(registers.B == 0);
//     try expect(registers.C == 1);
//     try expect(registers.D == 0);
//     try expect(registers.E == 0);
//     try expect(registers.H == 0);
//     try expect(registers.L == 0);
// }
//
// test "decode and execute 0x04 [INC B]" {
//     var registers = main.createRegisterFile();
//
//     try main.decodeAndExecute([_]u8{0x04, 0x00, 0x00}, &registers);
//
//     try expect(registers.PC == 1);
//     try expect(registers.A == 0);
//     try expect(registers.B == 1);
//     try expect(registers.C == 0);
//     try expect(registers.D == 0);
//     try expect(registers.E == 0);
//     try expect(registers.H == 0);
//     try expect(registers.L == 0);
//
//     try main.decodeAndExecute([_]u8{0x04, 0x00, 0x00}, &registers);
//     try main.decodeAndExecute([_]u8{0x04, 0x00, 0x00}, &registers);
//
//     try expect(registers.PC == 3);
//     try expect(registers.A == 0);
//     try expect(registers.B == 3);
//     try expect(registers.C == 0);
//     try expect(registers.D == 0);
//     try expect(registers.E == 0);
//     try expect(registers.H == 0);
//     try expect(registers.L == 0);
// }
//
// test "decode and execute 0x05 [DEC B]" {
//     var registers = main.createRegisterFile();
//     registers.B = 5; // If we start at 0 we might get overflow
//
//     try main.decodeAndExecute([_]u8{0x05, 0x00, 0x00}, &registers);
//
//     try expect(registers.PC == 1);
//     try expect(registers.A == 0);
//     try expect(registers.B == 4);
//     try expect(registers.C == 0);
//     try expect(registers.D == 0);
//     try expect(registers.E == 0);
//     try expect(registers.H == 0);
//     try expect(registers.L == 0);
// }

test "decode and execute 0x06 [LD B, d8]" {
    const op_code: u8 = 0x06;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .IR = op_code,
        .PC = start_mem_location,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x02);
    memory.set(start_mem_location + 2, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == start_mem_location + 2);
    try expect(register.A == 0);
    try expect(register.B == 0x02);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x08 [LD (a16), SP]" {
    const op_code: u8 = 0x08;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = 0xa930,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x14);
    memory.set(start_mem_location + 2, 0x79);
    memory.set(start_mem_location + 3, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 3);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.SP == 0xa930);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(0x7914) == 0x30);
    try expect(memory.get(0x7914 + 1) == 0xa9);
}

test "decode and execute 0x11 [LD DE, d16]" {
    const op_code: u8 = 0x11;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x1b);
    memory.set(start_mem_location + 2, 0x88);
    memory.set(start_mem_location + 3, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 3);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x88);
    try expect(register.E == 0x1b);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x0a [LD A, (BC)]" {
    const op_code: u8 = 0x0a;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .B = 0x2c,
        .C = 0x19,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(0x2c19, 0x79);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x79);
    try expect(register.B == 0x2c);
    try expect(register.C == 0x19);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x0e [LD C, d8]" {
    const op_code: u8 = 0x0e;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .IR = op_code,
        .PC = start_mem_location,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x12);
    memory.set(start_mem_location + 2, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == start_mem_location + 2);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x12);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE); // STOP
}

test "decode and execute 0x12 [LD (DE), A]" {
    const op_code: u8 = 0x12;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .D = 0x6e,
        .E = 0x03,
        .A = 0xbb,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0xbb);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x6e);
    try expect(register.E == 0x03);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(0x6e03) == 0xbb);
    try expect(memory.get(0x6e04) == 0);
    try expect(memory.get(0x6e02) == 0);
}

test "decode and execute 0x16 [LD D, d8]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x16,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x16);
    memory.set(0x0101, 0x0b);
    memory.set(0x0102, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0102);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x0b);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x010); // STOP
}

test "decode and execute 0x18 [JR s8]" {
    const op_code: u8 = 0x18;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x10); // -128
    memory.set(start_mem_location + 2, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expectEqual(register.PC, 0x007f); // 127
}

test "decode and execute 0x21 [LD HL, d16]" {
    const op_code: u8 = 0x21;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x89);
    memory.set(start_mem_location + 2, 0x13);
    memory.set(start_mem_location + 3, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 3);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x13);
    try expect(register.L == 0x89);
    try expect(register.IR == STOP_OP_CODE);

}

test "decode and execute 0x1a [LD A, (DE)]" {
    const op_code: u8 = 0x1a;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .D = 0x20,
        .E = 0xa9,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(0x20a9, 0x59);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x59);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x20);
    try expect(register.E == 0xa9);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x1e [LD E, d8]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x1e,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x1e);
    memory.set(0x0101, 0x67);
    memory.set(0x0102, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0102);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x67);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x010); // STOP
}

test "decode and execute 0x22 [LD (HL+), A]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x22,
        .A = 0x9a,
        .H = 0x09,
        .L = 0x5d,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x22);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0x9a);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x09);
    try expect(register.L == 0x5e);
    try expect(register.IR == 0x10); // STOP
    try expect(memory.get(0x095d) == 0x9a);
}

test "decode and execute 0x26 [LD H, d8]" {
    var register = RegisterFile{
        .IR = 0x26,
        .PC = 0x0100,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x26);
    memory.set(0x0101, 0x12);
    memory.set(0x0102, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0102);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x12);
    try expect(register.L == 0);
    try expect(register.IR == 0x10); // STOP
}

test "decode and execute 0x2a [LD A, (HL+)]" {
    var register = RegisterFile{
        .IR = 0x2a,
        .PC = 0x0100,
        .H = 0xa5,
        .L = 0x44,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x2a);
    memory.set(0x0101, 0x10);
    memory.set(0xa544, 0xcc);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0xcc);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0xa5);
    try expect(register.L == 0x45);
    try expect(register.IR == 0x10); // STOP
    try expect(memory.get(0xa544) == 0xcc);
}

test "decode and execute 0x2e [LD L, d8]" {
    var register = RegisterFile{
        .IR = 0x2e,
        .PC = 0x0100,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x2e);
    memory.set(0x0101, 0x1a);
    memory.set(0x0102, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0102);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0x1a);
    try expect(register.IR == 0x10); // STOP
}

test "decode and execute 0x31 [LD SP, d16]" {
    const op_code: u8 = 0x31;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x3a);
    memory.set(start_mem_location + 2, 0x09);
    memory.set(start_mem_location + 3, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 3);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.SP == 0x093a);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x32 [LD (HL-), A]" {
    var register = RegisterFile{
        .IR = 0x32,
        .PC = 0x0100,
        .A = 0xb4,
        .H = 0x11,
        .L = 0x22,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x32);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0xb4);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x11);
    try expect(register.L == 0x21);
    try expect(register.IR == 0x10); // STOP
    try expect(memory.get(0x1122) == 0xb4);
}

test "decode and execute 0x36 [LD (HL), d8]" {
    var register = RegisterFile{
        .IR = 0x36,
        .PC = 0x0100,
        .H = 0x00,
        .L = 0x12,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x36);
    memory.set(0x0101, 0x8e);
    memory.set(0x0102, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0102);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x00);
    try expect(register.L == 0x12);
    try expect(register.IR == 0x10); // STOP
    try expect(memory.get(0x0012) == 0x8e);
}

test "decode and execute 0x3a [LD A, (HL-)]" {
    var register = RegisterFile{
        .IR = 0x3a,
        .PC = 0x0100,
        .H = 0x00,
        .L = 0x88,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x3a);
    memory.set(0x0101, 0x10);
    memory.set(0x0088, 0xba);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0xba);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x00);
    try expect(register.L == 0x87);
    try expect(register.IR == 0x10); // STOP
    try expect(memory.get(0x0088) == 0xba);
}

test "decode and execute 0x3e [LD A, d8]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x3e,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x3e);
    memory.set(0x0101, 0x59);
    memory.set(0x0102, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.A == 0x59);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x10); // STOP
}

test "decode and execute 0x40 [LD B, B]" {
    var register = RegisterFile {
        .PC = 0x0100,
        .IR = 0x40,
        .B = 0x05,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x40);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0x05);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR  == 0x10); // STOP
}

test "decode and execute 0x41 [LD B, C]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x41,
        .C = 0x02,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x41);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);
    
    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0x02);
    try expect(register.C == 0x02);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x10); // STOP
}

test "decode and execute 0x42 [LD B, D]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x42,
        .D = 0x0f,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x42);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0x0f);
    try expect(register.C == 0);
    try expect(register.D == 0x0f);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x10); // STOP
}

test "decode and execute 0x43 [LD B, E]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x43,
        .E = 0xa5,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x43);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0xa5);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0xa5);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x10); // STOP
}

test "decode and execute 0x44 [LD B, H]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x44,
        .H = 0x4a
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x44);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0x4a);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x4a);
    try expect(register.L == 0);
    try expect(register.IR == 0x10); // STOP
}

test "decode and execute 0x45 [LD B, L]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x45,
        .L = 0x39,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x45);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0x39);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0x39);
    try expect(register.IR == 0x10);
}

test "decode and execute 0x46 [LD B, (HL)]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x46,
        .H = 0x01,
        .L = 0x72,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x46);
    memory.set(0x0101, 0x10);
    memory.set(0x0172, 0x31);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0x31);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x01);
    try expect(register.L == 0x72);
    try expect(register.IR == 0x10);
    try expect(memory.get(0x0172) == 0x31);
}

test "decode and execute 0x47 [LD B, A]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x47,
        .A = 0x06,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x47);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == 0x0101);
    try expect(register.A == 0x06);
    try expect(register.B == 0x06);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x10);
}

test "decode and execute 0x48 [LD C, B]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x48,
        .B = 0x77,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x48);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0x77);
    try expect(register.C == 0x77);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x10);
}

test "decode and execute 0x49 [LD C, C]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x49,
        .C = 0x6e,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x49);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x6e);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x10);
}

test "decode and execute 0x4a [LD C, D]" {
    const op_code: u8 = 0x4a;
    const stop_code: u8 = 0x10;

    var register = RegisterFile{
        .PC = 0x0100,
        .IR = op_code,
        .D = 0xb2,
    };

    var memory = Memory.init();
    memory.set(0x0100, op_code);
    memory.set(0x0101, stop_code);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == 0x0101);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0xb2);
    try expect(register.D == 0xb2);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == stop_code);
}

test "decode and execute 0x4b [LD C, E]" {
    const op_code: u8 = 0x4b;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .E = 0x43,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x43);
    try expect(register.D == 0);
    try expect(register.E == 0x43);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x4c [LD C, H]" {
    const op_code: u8 = 0x4c;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x30,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x30);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x30);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x4d [LD C, L]" {
    const op_code: u8 = 0x4d;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .IR = op_code,
        .PC = start_mem_location,
        .L = 0x0a,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x0a);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0x0a);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x4e [LD C, (HL)]" {
    const op_code: u8 = 0x4e;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x0a,
        .L = 0x0c,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(0x0a0c, 0x07);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x07);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x0a);
    try expect(register.L == 0x0c);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(0x0a0c) == 0x07);
}

test "decode and execute 0x4f [LD C, A]" {
    const op_code: u8 =0x4f;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x73,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x73);
    try expect(register.B == 0);
    try expect(register.C == 0x73);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x50 [LD D, B]" {
    const op_code: u8 = 0x50;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .B = 0x0c,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0x0c);
    try expect(register.C == 0);
    try expect(register.D == 0x0c);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x51 [LD D, C]" {
    const op_code: u8 = 0x51;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .C = 0x05,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x05);
    try expect(register.D == 0x05);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x52 [LD D, D]" {
    const op_code: u8 = 0x52;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .D = 0x01,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x01);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x53 [LD D, E]" {
    const op_code: u8 = 0x53;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .E = 0x64,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x64);
    try expect(register.E == 0x64);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x54 [LD D, H]" {
    const op_code: u8 = 0x54;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x2f,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x2f);
    try expect(register.E == 0);
    try expect(register.H == 0x2f);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x55 [LD D, L]" {
    const op_code: u8 = 0x55;
    const start_mem_location: u16  = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .L = 0x51,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x51);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0x51);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x56 [LD D, (HL)]" {
    const op_code: u8 = 0x56;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x05,
        .L = 0x1a,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(0x051a, 0x17);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x17);
    try expect(register.E == 0);
    try expect(register.H == 0x05);
    try expect(register.L == 0x1a);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(0x051a) == 0x17);
}

test "decode and execute 0x57 [LD D, A]" {
    const op_code: u8 = 0x57;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x31,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x31);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x31);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x58 [LD E, B]" {
    const op_code: u8 = 0x58;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .B = 0x43,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0x43);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x43);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x59 [LD E, C]" {
    const op_code: u8 = 0x59;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .C = 0x91,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x91);
    try expect(register.D == 0);
    try expect(register.E == 0x91);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x5a [LD E, D]" {
    const op_code: u8 = 0x5a;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .D = 0x84,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x84);
    try expect(register.E == 0x84);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x5b [LD E, E]" {
    const op_code: u8 = 0x5b;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .E = 0x17,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x17);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x5c [LD E, H]" {
    const op_code: u8 = 0x5c;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x84,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x84);
    try expect(register.H == 0x84);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x5d [LD E, L]" {
    const op_code: u8 = 0x5d;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .L = 0x5a,
    };

    var memory= Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x5a);
    try expect(register.H == 0);
    try expect(register.L == 0x5a);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x5e [LD E, (HL)]" {
    const op_code: u8 = 0x5e;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x0c,
        .L = 0x49,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(0x0c49, 0x3b);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x3b);
    try expect(register.H == 0x0c);
    try expect(register.L == 0x49);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x5f [LD E, A]" {
    const op_code: u8 = 0x5f;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x8e,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x8e);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x8e);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x60 [LD H, B]" {
    const op_code: u8 = 0x60;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .B = 0x6c,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0x6c);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x6c);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x61 [LD H, C]" {
    const op_code: u8 = 0x61;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .C = 0x3d,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x3d);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x3d);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x62 [LD H, D]" {
    const op_code: u8 = 0x62;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = 0x62,
        .D = 0x73,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x73);
    try expect(register.E == 0);
    try expect(register.H == 0x73);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x63 [LD H, E]" {
    const op_code: u8 = 0x63;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .E = 0x0e,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x0e);
    try expect(register.H == 0x0e);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x64 [LD H, H]" {
    const op_code: u8 = 0x64;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x1c,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x1c);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x65 [LD H, L]" {
    const op_code: u8 = 0x65;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .L = 0x73,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x73);
    try expect(register.L == 0x73);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x66 [LD H, (HL)]" {
    const op_code: u8 = 0x66;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR =op_code,
        .H = 0x12,
        .L = 0x34,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(0x1234, 0x37);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x37);
    try expect(register.L == 0x34);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x67 [LD H, A]" {
    const op_code: u8 = 0x67;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x5a
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x5a);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x5a);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x68 [LD L, B]" {
    const op_code: u8 = 0x68;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .B = 0xd8,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0xd8);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0xd8);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x69 [LD L, C]" {
    const op_code: u8 = 0x69;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .C = 0x49
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x49);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0x49);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x6a [LD L, D]" {
    const op_code: u8 = 0x6a;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .D = 0x14,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x14);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0x14);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x6b [LD L, E]" {
    const op_code: u8 = 0x6b;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .E = 0x55,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x55);
    try expect(register.H == 0);
    try expect(register.L == 0x55);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x6c [LD L, H]" {
    const op_code: u8 = 0x6c;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x38,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x38);
    try expect(register.L == 0x38);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x6d [LD L, L]" {
    const op_code: u8 = 0x6d;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .L = 0x7f,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0x7f);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x6e [LD L, (HL)]" {
    const op_code: u8 = 0x6e;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0xc8,
        .L = 0x10,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(0xc810, 0x70);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0xc8);
    try expect(register.L == 0x70);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x6f [LD L, A]" {
    const op_code: u8 = 0x6f;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x89,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x89);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0x89);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x70 [LD (HL), B]" {
    const op_code: u8 = 0x70;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .B = 0x40,
        .H = 0x07,
        .L = 0x11,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0x40);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x07);
    try expect(register.L == 0x11);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(register.getHL()) == register.B);
}

test "decode and execute 0x71 [LD (HL), C]" {
    const op_code: u9 = 0x71;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .C = 0x40,
        .H = 0x07,
        .L = 0x11,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x40);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x07);
    try expect(register.L == 0x11);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(register.getHL()) == register.C);
}

test "decode and execute 0x72 [LD (HL), D]" {
    const op_code: u9 = 0x72;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .D = 0x40,
        .H = 0x07,
        .L = 0x11,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x40);
    try expect(register.E == 0);
    try expect(register.H == 0x07);
    try expect(register.L == 0x11);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(register.getHL()) == register.D);
}

test "decode and execute 0x73 [LD (HL), E]" {
    const op_code: u9 = 0x73;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .E = 0x40,
        .H = 0x07,
        .L = 0x11,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x40);
    try expect(register.H == 0x07);
    try expect(register.L == 0x11);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(register.getHL()) == register.E);
}

test "decode and execute 0x74 [LD (HL), H]" {
    const op_code: u9 = 0x74;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x07,
        .L = 0x11,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x07);
    try expect(register.L == 0x11);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(register.getHL()) == register.H);
}

test "decode and execute 0x75 [LD (HL), L]" {
    const op_code: u9 = 0x75;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x07,
        .L = 0x11,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x07);
    try expect(register.L == 0x11);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(register.getHL()) == register.L);
}

test "decode and execute 0x77 [LD (HL), A]" {
    const op_code: u9 = 0x77;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x40,
        .H = 0x07,
        .L = 0x11,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x40);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x07);
    try expect(register.L == 0x11);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(register.getHL()) == register.A);
}

test "decode and execute 0x78 [LD A, B]" {
    const op_code: u8 = 0x78;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .B = 0x93
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x93);
    try expect(register.B == 0x93);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x79 [LD A, C]" {
    const op_code: u8 = 0x79;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .C = 0x93
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x93);
    try expect(register.B == 0);
    try expect(register.C == 0x93);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x7a [LD A, D]" {
    const op_code: u8 = 0x7a;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .D = 0x93
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x93);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x93);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x7b [LD A, E]" {
    const op_code: u8 = 0x7b;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .E = 0x93
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x93);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0x93);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x7c [LD A, H]" {
    const op_code: u8 = 0x7c;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x93
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x93);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x93);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x7d [LD A, L]" {
    const op_code: u8 = 0x7d;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .L = 0x93
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x93);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0x93);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x7e [LD A, (HL)]" {
    const op_code: u8 = 0x7e;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x1c,
        .L = 0x03,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(0x1c03, 0x11);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x11);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x1c);
    try expect(register.L == 0x03);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0x7f [LD A, A]" {
    const op_code: u8 = 0x7f;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x93
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x93);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0xc1 [POP BC]" {
    const op_code: u8 = 0xc1;
    const start_mem_location: u16 = 0x0100;
    const start_stack_pointer: u16 = 0x0700;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(start_stack_pointer, 0x90);
    memory.set(start_stack_pointer + 1, 0x3c);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0x3c);
    try expect(register.C == 0x90);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.getBC() == 0x3c90);
    try expect(register.SP == start_stack_pointer + 2);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0xc5 [PUSH BC]" {
    const op_code: u8 = 0xc5;
    const start_mem_location: u16 = 0x0100;
    const start_stack_pointer: u16 = 0x702;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = start_stack_pointer,
        .B = 0x79,
        .C = 0x1d,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0x79);
    try expect(register.C == 0x1d);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(start_stack_pointer - 1) == register.B);
    try expect(memory.get(start_stack_pointer - 2) == register.C);
}

test "decode and execute 0xd1 [POP DE]" {
    const op_code: u8 = 0xd1;
    const start_mem_location: u16 = 0x0100;
    const start_stack_pointer: u16 = 0x0700;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(start_stack_pointer, 0x83);
    memory.set(start_stack_pointer + 1, 0x0d);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x0d);
    try expect(register.E == 0x83);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
    try expect(register.SP == start_stack_pointer + 2);
}

test "decode and execute 0x5d [PUSH DE]" {
    const op_code: u8 = 0xd5;
    const start_mem_location: u16 = 0x0100;
    const start_stack_pointer: u16 = 0x0700;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = start_stack_pointer,
        .D = 0xe9,
        .E = 0x37,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0xe9);
    try expect(register.E == 0x37);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
    try expect(register.SP == start_stack_pointer - 2);
    try expect(memory.get(start_stack_pointer - 1) == register.D);
    try expect(memory.get(start_stack_pointer - 2) == register.E);
}

test "decode and execute 0xe0 [LD (a8), A]" {
    const op_code: u8 = 0xe0;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x10,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x7a);
    memory.set(start_mem_location + 2, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 2);
    try expect(register.A == 0x10);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(0xff7a) == 0x10);
}

test "decode and execute 0xe1 [POP HL]" {
    const op_code: u8 = 0xe1;
    const start_mem_location: u16 = 0x0100;
    const start_stack_pointer: u16 = 0x0700;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(start_stack_pointer, 0x9a);
    memory.set(start_stack_pointer + 1, 0x71);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x71);
    try expect(register.L == 0x9a);
    try expect(register.IR == STOP_OP_CODE);
    try expect(register.SP == start_stack_pointer + 2);
}

test "decode and execute 0xe5 [PUSH HL]" {
    const op_code: u8 = 0xe5;
    const start_mem_location: u16 = 0x0100;
    const start_stack_pointer: u16 = 0x0700;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x12,
        .L = 0x22,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x12);
    try expect(register.L == 0x22);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(start_stack_pointer - 1) == register.H);
    try expect(memory.get(start_stack_pointer - 2) == register.L);
}

test "decode and execute 0xe2 [LD (C), A]" {
    const op_code: u8 = 0xe2;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x83,
        .C = 0x17,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x83);
    try expect(register.B == 0);
    try expect(register.C == 0x17);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(0xff17) == 0x83);
}

test "decode and execute 0xea [LD (a16), A]" {
    const op_code: u8 = 0xea;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x12,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x3c);
    memory.set(start_mem_location + 2, 0x17);
    memory.set(start_mem_location + 3, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 3);
    try expect(register.A == 0x12);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(0x3c17) == register.A);
}

test "decode and execute 0xf0 [LD A, (a8)]" {
    const op_code: u8 = 0xf0;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0xc7);
    memory.set(start_mem_location + 2, STOP_OP_CODE);
    memory.set(0xffc7, 0x8e);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 2);
    try expect(register.A == 0x8e);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0xf1 [POP AF]" {
    const op_code: u8 = 0xf1;
    const start_mem_location: u16 = 0x0100;
    const start_stack_pointer: u16 = 0x0700;

    var register = RegisterFile{
        .IR = op_code,
        .PC = start_mem_location,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(start_stack_pointer, 0x07);
    memory.set(start_stack_pointer - 1, 0xa8);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0xa8);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.F == 0x07);
    try expect(register.IR == STOP_OP_CODE);
    try expect(register.SP == start_stack_pointer - 2);
}

test "decode and execute 0xf2 [LD A, (C)]" {
    const op_code: u8 = 0xf2;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .C = 0x7f,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    memory.set(0xff7f, 0x1a);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x1a);
    try expect(register.B == 0);
    try expect(register.C == 0x7f);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0xf5 [PUSH AF]" {
    const op_code: u8 = 0xf5;
    const start_mem_location: u16 = 0x0100;
    const start_stack_pointer: u16 = 0x0700;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .A = 0x63,
        .F = 0x6b,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);
    
    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0x63);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.F == 0x6b);
    try expect(register.IR == STOP_OP_CODE);
    try expect(memory.get(start_stack_pointer - 1) == register.A);
    try expect(memory.get(start_stack_pointer - 2) == register.F);
}

test "decode and execute 0xf8 [LD HL, SP+s8] - hi-lo overflow" {
    const op_code: u8 = 0xf8;
    const start_mem_location: u16 = 0x017f;
    const start_stack_pointer: u16 = 0x00ff;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x01);
    memory.set(start_mem_location + 2, op_code);
    memory.set(start_mem_location + 3, 0x08);
    memory.set(start_mem_location + 4, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 2);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x01);
    try expect(register.L == 0x00);
    try expect(register.F == 0b0011_0000);
    try expect(register.IR == op_code);

    register.SP = start_stack_pointer - 4;
    register.F = 0;
    register.H = 0;
    register.L = 0;

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 4);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x01);
    try expect(register.L == 0x03);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0xf8 [LD HL, SP+s8] - carry flag" {
    const op_code: u8 = 0xf8;
    const start_mem_location: u16 = 0x017f;
    const start_stack_pointer: u16 = 0x00f0;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x20);
    memory.set(start_mem_location + 2, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 2);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x01);
    try expect(register.L == 0x10);
    try expect(register.F == 0b0001_0000);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0xf8 [LD HL, SP+s8] - negative" {
    const op_code: u8 = 0xf8;
    const start_mem_location: u16 = 0x017f;
    const start_stack_pointer: u16 = 0x00f0;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0xff); // -1
    memory.set(start_mem_location + 2, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 2);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x00);
    try expect(register.L == 0xef);
    try expect(register.F == 0b0001_0000);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0xf8 [LD HL, SP+s8] - no half carry or carry flags" {
    const op_code: u8 = 0xf8;
    const start_mem_location: u16 = 0x017f;
    const start_stack_pointer: u16 = 0x00f0;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .SP = start_stack_pointer,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x0f);
    memory.set(start_mem_location + 2, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 2);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x00);
    try expect(register.L == 0xff);
    try expect(register.F == 0b0000_0000);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0xf9 [LD SP, HL]" {
    const op_code: u8 = 0xf9;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
        .H = 0x10,
        .L = 0x4b,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, STOP_OP_CODE);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 1);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0x10);
    try expect(register.L == 0x4b);
    try expect(register.IR == STOP_OP_CODE);
}

test "decode and execute 0xfa [LD A, (a16)]" {
    const op_code: u8 = 0xfa;
    const start_mem_location: u16 = 0x0100;

    var register = RegisterFile{
        .PC = start_mem_location,
        .IR = op_code,
    };

    var memory = Memory.init();
    memory.set(start_mem_location, op_code);
    memory.set(start_mem_location + 1, 0x09);
    memory.set(start_mem_location + 2, 0xd8);
    memory.set(start_mem_location + 3, STOP_OP_CODE);
    memory.set(0x09d8, 0x2a);

    try main.decodeAndExecute(&register, &memory);
    try expect(register.PC == start_mem_location + 3);
    try expect(register.A == 0x2a);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == STOP_OP_CODE);
}
