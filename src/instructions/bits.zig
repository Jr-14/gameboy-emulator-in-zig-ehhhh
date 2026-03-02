const std = @import("std");

const Processor = @import("../processor_new.zig");
const Memory = @import("../memory.zig");
const utils = @import("../utils.zig");
const Bit = utils.Bit;

const expectEqual = std.testing.expectEqual;

/// Resets the bit b of the 8-bit register r to 0.
pub fn reset_bit_reg8(bit: Bit, registerValue: *u8) void {
    const bit_mask: u8 = ~(@as(u8, 1) << @intFromEnum(bit));
    registerValue.* &= bit_mask;
}

test "reset_bit_reg8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .D = 0xFF });

    reset_bit_reg8(.zero, &processor.D);
    try expectEqual(0b1111_1110, processor.D.value);
    processor.D.value = 0xFF;

    reset_bit_reg8(.one, &processor.D);
    try expectEqual(0b1111_1101, processor.D.value);
    processor.D.value = 0xFF;

    reset_bit_reg8(.two, &processor.D);
    try expectEqual(0b1111_1011, processor.D.value);
    processor.D.value = 0xFF;

    reset_bit_reg8(.three, &processor.D);
    try expectEqual(0b1111_0111, processor.D.value);
    processor.D.value = 0xFF;

    reset_bit_reg8(.four, &processor.D);
    try expectEqual(0b1110_1111, processor.D.value);
    processor.D.value = 0xFF;

    reset_bit_reg8(.five, &processor.D);
    try expectEqual(0b1101_1111, processor.D.value);
    processor.D.value = 0xFF;

    reset_bit_reg8(.six, &processor.D);
    try expectEqual(0b1011_1111, processor.D.value);
    processor.D.value = 0xFF;

    reset_bit_reg8(.seven, &processor.D);
    try expectEqual(0b0111_1111, processor.D.value);
}

/// Resets the bit b of the 8-bit data at the absolute address specified by the 16-bit register HL, to 0.
// pub fn reset_bit_hlMem(proc:* Processor, bit: Bit) void {
pub fn reset_bit_hl_indirect(proc:* Processor, bit: Bit) void {
    const content: *u8 = &proc.memory.address[proc.HL.value];
    const bit_mask: u8 = ~(@as(u8, 1) << @intFromEnum(bit));
    content.* &= bit_mask;
}

test "reset_bit_hl_indirect" {
    const HL: u16 = 0x0789;
    var memory = Memory.init();
    memory.address[HL] = 0xFF;
    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    reset_bit_hl_indirect(&processor, .zero);
    try expectEqual(0b1111_1110, memory.address[HL]);
    memory.address[HL] = 0xFF;

    reset_bit_hl_indirect(&processor, .one);
    try expectEqual(0b1111_1101, memory.address[HL]);
    memory.address[HL] = 0xFF;

    reset_bit_hl_indirect(&processor, .two);
    try expectEqual(0b1111_1011, memory.address[HL]);
    memory.address[HL] = 0xFF;

    reset_bit_hl_indirect(&processor, .three);
    try expectEqual(0b1111_0111, memory.address[HL]);
    memory.address[HL] = 0xFF;

    reset_bit_hl_indirect(&processor, .four);
    try expectEqual(0b1110_1111, memory.address[HL]);
    memory.address[HL] = 0xFF;

    reset_bit_hl_indirect(&processor, .five);
    try expectEqual(0b1101_1111, memory.address[HL]);
    memory.address[HL] = 0xFF;

    reset_bit_hl_indirect(&processor, .six);
    try expectEqual(0b1011_1111, memory.address[HL]);
    memory.address[HL] = 0xFF;

    reset_bit_hl_indirect(&processor, .seven);
    try expectEqual(0b0111_1111, memory.address[HL]);
}

/// Sets the bit b of the 8-bit register r to 1
pub fn set_bit_reg8(bit: Bit, registerValue: *u8) void {
    const bit_mask: u8 = @as(u8, 1) << @intFromEnum(bit);
    registerValue.* |= bit_mask;
}

test "set_bit_reg8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .D = 0x00 });

    set_bit_reg8(.zero, &processor.D);
    try expectEqual(0b0000_0001, processor.D.value);
    processor.D.value = 0x00;

    set_bit_reg8(.one, &processor.D);
    try expectEqual(0b0000_0010, processor.D.value);
    processor.D.value = 0x00;

    set_bit_reg8(.two, &processor.D);
    try expectEqual(0b0000_0100, processor.D.value);
    processor.D.value = 0x00;

    set_bit_reg8(.three, &processor.D);
    try expectEqual(0b0000_1000, processor.D.value);
    processor.D.value = 0x00;

    set_bit_reg8(.four, &processor.D);
    try expectEqual(0b0001_0000, processor.D.value);
    processor.D.value = 0x00;

    set_bit_reg8(.five, &processor.D);
    try expectEqual(0b0010_0000, processor.D.value);
    processor.D.value = 0x00;

    set_bit_reg8(.six, &processor.D);
    try expectEqual(0b0100_0000, processor.D.value);
    processor.D.value = 0x00;

    set_bit_reg8(.seven, &processor.D);
    try expectEqual(0b1000_0000, processor.D.value);
}

/// Sets the bit b of the 8-bit data at the absolute address specified by the 16-bit register HL, to 1.
pub fn set_bit_hl_indirect(proc: *Processor, bit: Bit) void {
    const content: *u8 = &proc.memory.address[proc.HL.value];
    const bit_mask: u8 = @as(u8, 1) << @intFromEnum(bit);
    content.* |= bit_mask;
}

test "set_bit_hl_indirect" {
    const HL: u16 = 0x93A0;
    var memory = Memory.init();
    memory.address[HL] = 0x00;
    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    set_bit_hl_indirect(&processor, .zero);
    try expectEqual(0b0000_0001, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    set_bit_hl_indirect(&processor, .one);
    try expectEqual(0b0000_0010, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    set_bit_hl_indirect(&processor, .two);
    try expectEqual(0b0000_0100, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    set_bit_hl_indirect(&processor, .three);
    try expectEqual(0b0000_1000, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    set_bit_hl_indirect(&processor, .four);
    try expectEqual(0b0001_0000, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    set_bit_hl_indirect(&processor, .five);
    try expectEqual(0b0010_0000, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    set_bit_hl_indirect(&processor, .six);
    try expectEqual(0b0100_0000, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    set_bit_hl_indirect(&processor, .seven);
    try expectEqual(0b1000_0000, processor.memory.address[HL]);
}
