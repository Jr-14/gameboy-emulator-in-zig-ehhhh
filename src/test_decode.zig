const std = @import("std");
const main = @import("main.zig");

const expect = std.testing.expect;

test "decode and execute 0x00 [NOP]" {
    var registers = main.createRegister();
    var pc: u32 = 0;

    try main.decodeAndExecute([_]u8{0x00, 0x00, 0x00}, &registers, &pc);
    try main.decodeAndExecute([_]u8{0x00, 0x00, 0x00}, &registers, &pc);

    try expect(pc == 2);
    try expect(registers.A == 0);
    try expect(registers.B == 0);
    try expect(registers.C == 0);
    try expect(registers.D == 0);
    try expect(registers.E == 0);
    try expect(registers.H == 0);
    try expect(registers.L == 0);
    try expect(registers.BC == 0);
    try expect(registers.DE == 0);
    try expect(registers.HL == 0);
}

test "decode and execute 0x01 [LD BC, d16]" {
    var registers = main.createRegister();
    var pc: u32 = 0;

    // The number in base 10 is 5614 which is 00010101 11101110 in binary
    // so in hex this is 0x15 0xee
    try main.decodeAndExecute([_]u8{0x01, 0x15, 0xee}, &registers, &pc);

    try expect(pc == 1);
    try expect(registers.A == 0);
    try expect(registers.B == 0);
    try expect(registers.C == 0);
    try expect(registers.D == 0);
    try expect(registers.E == 0);
    try expect(registers.H == 0);
    try expect(registers.L == 0);
    try expect(registers.BC == 5614);
    try expect(registers.DE == 0);
    try expect(registers.HL == 0);

    // We will now load 100 which is 01100100 in binary and 0x64 in hex
    try main.decodeAndExecute([_]u8{0x01, 0x00, 0x64}, &registers, &pc);

    try expect(pc == 2);
    try expect(registers.A == 0);
    try expect(registers.B == 0);
    try expect(registers.C == 0);
    try expect(registers.D == 0);
    try expect(registers.E == 0);
    try expect(registers.H == 0);
    try expect(registers.L == 0);
    try expect(registers.BC == 100);
    try expect(registers.DE == 0);
    try expect(registers.HL == 0);
}

test "decode and execute 0x03 [INC BC]" {
    var registers = main.createRegister();
    var pc: u32 = 0;

    try main.decodeAndExecute([_]u8{0x03, 0x00, 0x00}, &registers, &pc);

    try expect(pc == 1);
    try expect(registers.A == 0);
    try expect(registers.B == 0);
    try expect(registers.C == 0);
    try expect(registers.D == 0);
    try expect(registers.E == 0);
    try expect(registers.H == 0);
    try expect(registers.L == 0);
    try expect(registers.BC == 1);
    try expect(registers.DE == 0);
    try expect(registers.HL == 0);
}

test "decode and execute 0x04 (INC B)" {
    var registers = main.createRegister();
    var pc: u32 = 0;

    try main.decodeAndExecute([_]u8{0x04, 0x00, 0x00}, &registers, &pc);

    try expect(pc == 1);
    try expect(registers.A == 0);
    try expect(registers.B == 1);
    try expect(registers.C == 0);
    try expect(registers.D == 0);
    try expect(registers.E == 0);
    try expect(registers.H == 0);
    try expect(registers.L == 0);
    try expect(registers.BC == 0);
    try expect(registers.DE == 0);
    try expect(registers.HL == 0);
}
