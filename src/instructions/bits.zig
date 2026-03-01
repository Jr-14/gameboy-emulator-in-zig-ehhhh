const std = @import("std");

const Processor = @import("../processor_new.zig");

const utils = @import("../utils.zig");
const Bit = utils.Bit;

pub const bits = struct {
    /// Resets the bit b of the 8-bit register r to 0.
    pub fn reset_bit_r8(bit: Bit, registerValue: *u8) void {
        const bit_mask: u8 = ~(@as(u8, 1) << @intFromEnum(bit));
        registerValue.* &= bit_mask;
    }

    /// Resets the bit b of the 8-bit data at the absolute address specified by the 16-bit register HL, to 0.
    pub fn reset_bit_hlMem(proc:* Processor, bit: Bit) void {
        const content: *u8 = &proc.memory.address[proc.HL.value];
        const bit_mask: u8 = ~(@as(u8, 1) << @intFromEnum(bit));
        content.* &= bit_mask;
    }

    /// Sets the bit b of the 8-bit register r to 1
    pub fn set_bit_r8(bit: Bit, registerValue: *u8) void {
        const bit_mask: u8 = @as(u8, 1) << @intFromEnum(bit);
        registerValue.* |= bit_mask;
    }

    /// Sets the bit b of the 8-bit data at the absolute address specified by the 16-bit register HL, to 1.
    pub fn set_bit_hlMem(proc: *Processor, bit: Bit) void {
        const content: *u8 = &proc.memory.address[proc.HL.value];
        const bit_mask: u8 = @as(u8, 1) << @intFromEnum(bit);
        content.* |= bit_mask;
    }
};

const expectEqual = std.testing.expectEqual;

