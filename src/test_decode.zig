const std = @import("std");
const main = @import("main.zig");

const expect = std.testing.expect;

test "decode and execute 0x00 [NOP]" {
    var registers = main.RegisterFile{
        .IR = 0x00,
    };
    var memory = main.Memory.init();

    try main.decodeAndExecute(&registers, &memory);
    try main.decodeAndExecute(&registers, &memory);

    try expect(registers.PC == 2);
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

// test "decode and execute 0x02 [LD (BC), A]" {
//     var registers = main.createRegisterFile();
// }



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
//
// test "decode and execute 0x06 [LD B, d8]" {
//     var registers = main.createRegisterFile();
//
//     try main.decodeAndExecute([_]u8{0x06, 0xF1, 0x00}, &registers);
//
//     try expect(registers.PC == 1);
//     try expect(registers.A == 0);
//     try expect(registers.B == 0xf1);
//     try expect(registers.C == 0);
//     try expect(registers.D == 0);
//     try expect(registers.E == 0);
//     try expect(registers.H == 0);
//     try expect(registers.L == 0);
// }
