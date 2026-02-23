const std = @import("std");

const ZERO_MASK: u8 = 0x80; // 0b1000_0000
const NEGATIVE_MASK: u8 = 0x40; // 0b0100_0000
const HALF_CARRY_MASK: u8 = 0x20; // 0b0010_0000
const CARRY_MASK: u8 = 0x10; // 0b0001_0000

pub const HI_MASK: u16 = 0xFF00;
pub const LO_MASK: u8 = 0x00FF;

pub const ProcessorFlag = enum {
    zero,
    negative,
    half_carry,
    carry,
};

pub const FlagMasks = std.EnumArray(ProcessorFlag, u8).init(.{
    .zero = ZERO_MASK,
    .negative = NEGATIVE_MASK,
    .half_carry = HALF_CARRY_MASK,
    .carry = CARRY_MASK,
});
