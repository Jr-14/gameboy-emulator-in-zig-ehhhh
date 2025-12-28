const std = @import("std");
const main = @import("main.zig");

const Memory = main.Memory;
const RegisterFile = main.RegisterFile;

const expect = std.testing.expect;

test "decode and execute 0x00 [NOP]" {
    var registers = RegisterFile{
        .IR = 0x00,
        .PC = 0x0100
    };
    var memory = Memory.init();

    try main.decodeAndExecute(&registers, &memory);

    try expect(registers.PC == 0x0101);
    try expect(registers.A == 0);
    try expect(registers.B == 0);
    try expect(registers.C == 0);
    try expect(registers.D == 0);
    try expect(registers.E == 0);
    try expect(registers.H == 0);
    try expect(registers.L == 0);
    try expect(registers.IR == 0x00);
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
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x02,
        .A = 0x01,
        .B = 0xff,
        .C = 0xff,
    };
    var memory = Memory.init();
    memory.set(0x0100, 0x02);
    memory.set(0x0101, 0x02);
    memory.set(0x0102, 0x02);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.B == 0xff);
    try expect(register.C == 0xff);
    try expect(register.A == 0x01);
    try expect(memory.get(0xffff) == 0x01);
    try expect(memory.get(0xfffe) == 0x00);

    register.B = 0x00;
    register.C = 0x00;

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0102);
    try expect(register.B == 0x00);
    try expect(register.C == 0x00);
    try expect(register.A == 0x01);
    try expect(memory.get(0x0000) == 0x01);
    try expect(memory.get(0x0001) == 0x00);

    register.B = 0x1a;
    register.C = 0x56;
    register.A = 0xfe;

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0103);
    try expect(register.B == 0x1a);
    try expect(register.C == 0x56);
    try expect(register.A == 0xfe);
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
    var register = RegisterFile{
        .IR = 0x06,
        .PC = 0x0100,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0xff);
    memory.set(0x0101, 0x02);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0102);
    try expect(register.A == 0);
    try expect(register.B == 0x02);
    try expect(register.C == 0);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x0000); // NOP
}

test "decode and execute 0x0e [LD C, d8]" {
    var register = RegisterFile{
        .IR = 0x0e,
        .PC = 0x0100,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x0e);
    memory.set(0x0101, 0x12);
    memory.set(0x0102, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0102);
    try expect(register.A == 0);
    try expect(register.B == 0);
    try expect(register.C == 0x12);
    try expect(register.D == 0);
    try expect(register.E == 0);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x0010); // STOP
}

test "decode and execute 0x12 [LD (DE), A]" {
    var register = RegisterFile{
        .PC = 0x0100,
        .IR = 0x12,
        .D = 0x6e,
        .E = 0x03,
        .A = 0xbb,
    };

    var memory = Memory.init();
    memory.set(0x0100, 0x12);
    memory.set(0x0101, 0x10);

    try main.decodeAndExecute(&register, &memory);

    try expect(register.PC == 0x0101);
    try expect(register.A == 0xbb);
    try expect(register.B == 0);
    try expect(register.C == 0);
    try expect(register.D == 0x6e);
    try expect(register.E == 0x03);
    try expect(register.H == 0);
    try expect(register.L == 0);
    try expect(register.IR == 0x10); // STOP
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
