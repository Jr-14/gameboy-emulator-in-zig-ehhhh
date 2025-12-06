const std = @import("std");
const main = @import("main.zig");

const expect = std.testing.expect;

test "testing decode nop" {
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
    try expect(registers.BD == 0);
    try expect(registers.DE == 0);
    try expect(registers.HL == 0);
}
