const Memory = @This();
const GameboyState = @import("Gameboy.zig");

// 65,536 positions inlcuding 0x00 and 0xffff
pub const ARRAY_SIZE: u32 = 0xFFFF + 1;

address: [ARRAY_SIZE]u8 = undefined,

pub fn init() Memory {
    return .{
        .address = @splat(0),
    };
}

pub inline fn read(m: *Memory, index: u32) u8 {
    return m.address[index];
}

pub inline fn write(m: *Memory, index: u32, value: u8) void {
    m.address[index] = value;
}

pub fn readByte(gameboy: *GameboyState, address: u16) !u8 {
    switch (address) {
        // ROM Bank 00
        0x0000...0x3FFF => {
            return gameboy.ram[address];
        },
        // ROM Bank 01-NN
        0x4000...0x7FFF => {
            // TODO
            return gameboy.ram[address];
        },
        // VRAM
        0x8000...0x9FFF => {
            // TODO
            @panic("VRAM address not implemented (0x4000...0x7FFF)");
        },
        // External RAM
        0xA000...0xBFFF => {
            @panic("External RAM address not implemented (0xA000...0xBFFF)");
        },
        // WRAM
        0xC000...0xCFFF => {
            @panic("WRAM address not implemented (0xC000...0xCFFF)");
        },
        // WRAM
        0xD000...0xDFFF => {
            @panic("WRAM address not implemented (0xC000...0xCFFF)");
        },
        // Echo RAM - unused
        0xE000...0xFDFF => unreachable,
        // Object attribute memory
        0xFE00...0xFE9F => {
            @panic("OAM address not implemented (0xFE00...0xFE9F)");
        },
        // Not Usable - Nintendo says use of this area is prohibited
        0xFEA0...0xFEFF => unreachable,
        // I/O Registers
        0xFF00...0xFF7F => {
            @panic("Registers address not implemented (0xFF00...0xFF7F)");
        },
        // High RAM (HRAM)
        0xFF80...0xFFFE => {
            @panic("HRAM address not implemented (0xFF80...0xFFFE)");
        },
        // Interrupt Enable Register (IE)
        0xFFFF...0xFFFF => {
            @panic("IE address not implemented (0xFFFF...0xFFFF)");
        },
    }
}

pub fn writeByte(gameboy: *GameboyState, address: u16, byte: u8) void {
    switch (address) {
        // ROM Bank 00
        0x0000...0x3FFF => {
            gameboy.ram[address] = byte;
        },
        // ROM Bank 01-NN
        0x4000...0x7FFF => {
            gameboy.ram[address] = byte;
        },
        // VRAM
        0x8000...0x9FFF => {
            // TODO
            @panic("VRAM address not implemented (0x4000...0x7FFF)");
        },
        // External RAM
        0xA000...0xBFFF => {
            @panic("External RAM address not implemented (0xA000...0xBFFF)");
        },
        // WRAM
        0xC000...0xCFFF => {
            @panic("WRAM address not implemented (0xC000...0xCFFF)");
        },
        // WRAM
        0xD000...0xDFFF => {
            @panic("WRAM address not implemented (0xC000...0xCFFF)");
        },
        // Echo RAM - unused
        0xE000...0xFDFF => unreachable,
        // Object attribute memory
        0xFE00...0xFE9F => {
        },
        // Not Usable - Nintendo says use of this area is prohibited
        0xFEA0...0xFEFF => unreachable,
        // I/O Registers
        0xFF00...0xFF7F => {},
        // High RAM (HRAM)
        0xFF80...0xFFFE => {},
        // Interrupt Enable Register (IE)
        0xFFFF...0xFFFF => {},
    }
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;

test "reading and writing boundaries" {
    var memory = Memory.init();

    memory.write(0xFFFF, 0xAC);
    memory.write(0x0000, 0x7F);

    try expectEqual(0xAC, memory.read(0xFFFF));
    try expectEqual(0x00, memory.read(0xFFFE));
    try expectEqual(0x7F, memory.read(0x0000));
    try expectEqual(0x00, memory.read(0x0001));
}

test "reading and writing" {
    var memory = Memory.init();

    memory.write(0x1004, 0xAC);
    memory.write(0x7AC0, 0x7F);

    try expectEqual(0xAC, memory.read(0x1004));
    try expectEqual(0x00, memory.read(0x1005));
    try expectEqual(0x00, memory.read(0x1003));
    try expectEqual(0x7F, memory.read(0x7AC0));
    try expectEqual(0x00, memory.read(0x7AC1));
    try expectEqual(0x00, memory.read(0x7ABF));
}
