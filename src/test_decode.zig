const std = @import("std");
const main = @import("main.zig");

const expect = std.testing.expect;

test "decode and execute 0x00 (NOP)" {
    var registers = main.createRegister();
    var pc: u32 = 0;

    pc = try main.decodeAndExecute([_]u8{0x00, 0x00, 0x00}, &registers, pc);
    pc = try main.decodeAndExecute([_]u8{0x00, 0x00, 0x00}, &registers, pc);

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

test "decode and execute 0x03 (INC BC)" {
    var registers = main.createRegister();
    var pc: u32 = 0;

    pc = try main.decodeAndExecute([_]u8{0x03, 0x00, 0x00}, &registers, pc);

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

    pc = try main.decodeAndExecute([_]u8{0x04, 0x00, 0x00}, &registers, pc);

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
