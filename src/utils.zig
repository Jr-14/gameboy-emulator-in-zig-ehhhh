const std = @import("std");

const NEG_SIGN_MASK: u16 = 0x80; // 0b1000_0000
const NEG_SIGN_EXT_MASK: u16 = 0xFF00;
const POST_SIGN_EXT_MASK: u16 = 0x0000;

const masks = @import("masks.zig");

pub fn signExtend(value: u16) u16 {
    const sign: u16 = if ((value & NEG_SIGN_MASK) == NEG_SIGN_MASK) NEG_SIGN_EXT_MASK else POST_SIGN_EXT_MASK;
    return (value | sign);
}

pub fn addOffset(value: u16, offset: u16) u16 {
    const signExtendedOffset: u16 = signExtend(offset);
    return @bitCast(@as(i16, @bitCast(value)) + @as(i16, @bitCast(signExtendedOffset)));
}

pub fn toTwoBytes(lo: u8, hi: u8) u16 {
    return (@as(u16, hi) << 8) | lo;
}

pub fn getHiByte(val: u16) u8 {
    return @truncate((val & masks.HI_MASK) >> 8);
}

pub fn getLoByte(val: u16) u8 {
    return @truncate(val);
}

const ByteAdditionResult = struct {
    result: u8,
    half_carry: u1,
    carry: u1,
};

pub fn byteAdd(a: u8, b: u8) ByteAdditionResult {
    const sum: u16 = a +% b;
    const c: u1 = if ((sum & 0x100) == 0x100) 1 else 0;
    const hc: u1 = if ((((a & 0xF) + (b & 0xF)) & 0x10) == 0x10) 1 else 0;
    return .{
        .result = @truncate(sum),
        .half_carry = hc,
        .carry = c,
    };
}

const expectEqual = std.testing.expectEqual;

test "byteAdd - half carry" {
    var sum = byteAdd(0x0F, 0x01);
    try expectEqual(sum.result, 0x10);
    try expectEqual(sum.half_carry, 1);
    try expectEqual(sum.carry, 0);

    sum = byteAdd(0x0F, 0x0F);
    try expectEqual(sum.result, 0x1E);
    try expectEqual(sum.half_carry, 1);
    try expectEqual(sum.carry, 0);

    sum = byteAdd(0x0E, 0x01);
    try expectEqual(sum.result, 0x0F);
    try expectEqual(sum.half_carry, 0);
    try expectEqual(sum.carry, 0);
}

test "byteAdd - overflow" {
    const sum = byteAdd(0xFF, 0x01);
    try expectEqual(sum.result, 0x00);
    try expectEqual(sum.half_carry, 1);
    try expectEqual(sum.carry, 1);
}

test "sign extend - negative two's complement" {
    const negative_three_u8: u8 = 0b1111_1101;
    const negative_three_i16: i16 = @bitCast(signExtend(negative_three_u8));

    try expectEqual(-3, negative_three_i16);
}

test "sign extend - positive two's complement" {
    const positive_two_u8: u8 = 0b0000_00010;
    const positive_two_i16: i16 = @bitCast(signExtend(positive_two_u8));

    try expectEqual(2, positive_two_i16);
}

test "addOffset - negative offset" {
    const negative_three_u8: u8 = 0b1111_1101; // -3
    const initial_PC: u16 = 0b0000_0001_0000_0000; // 256

    try expectEqual(253, addOffset(initial_PC, negative_three_u8));
}

test "addOffset - positive offset" {
    const positive_three_u8: u8 = 0b11; // 3
    const initial_PC: u16 = 0b0000_0000_1111_1111; // 255

    try expectEqual(258, addOffset(initial_PC, positive_three_u8));
}

test "toTwoBytes" {
    const hi: u8 = 0x34;
    const lo: u8 = 0xA0;
    try expectEqual(0x34A0, toTwoBytes(lo, hi));
}

test "getHiByte" {
    const val: u16 = 0xFACE;
    try expectEqual(0xFA, getHiByte(val));
}

test "getLoByte" {
    const val: u16 = 0xFACE;
    try expectEqual(0xCE, getLoByte(val));
}
