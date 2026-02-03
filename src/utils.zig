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

pub inline fn fromTwoBytes(lo: u8, hi: u8) u16 {
    return (@as(u16, hi) << 8) | lo;
}

pub fn getHiByte(val: u16) u8 {
    return @truncate((val & masks.HI_MASK) >> 8);
}

pub fn getLoByte(val: u16) u8 {
    return @truncate(val);
}

pub fn Arithmetic(comptime T: type) type {
    if (T != u8 and T != u16) {
        @compileError("Only supporting u8 and u16 at the moment.");
    }

    return struct {
        value: T,
        half_carry: u1,
        carry: u1,

        const Self = @This();

        pub fn add(opts: struct {
            a: T,
            b: T,
            carry: u1 = 0,
        }) Self {
            const FS = if (T == u8) u16 else u32;
            const hc_mask: T = if (T == u8) 0x10 else 0x100;
            const lower_byte: T = hc_mask - 1;

            const sum: FS = @as(FS, opts.a) + @as(FS, opts.b) + opts.carry;

            return .{
                .value = @truncate(sum),
                .carry = if (sum > std.math.maxInt(T)) 1 else 0,
                .half_carry = if ((((opts.a & lower_byte) + (opts.b & lower_byte) + opts.carry) & hc_mask) == hc_mask) 1 else 0,
            };
        }

        pub fn subtract(opts: struct {
            a: T,
            b: T,
            carry: u1 = 0,
        }) Self {
            const FS = if (T == u8) u16 else u32;
            const hc_mask: T = if (T == u8) 0x10 else 0x100;
            const lower_byte: T = hc_mask - 1;

            const remainder: FS = @as(FS, opts.a) -% @as(FS, opts.b) -% opts.carry;
            const hc: u1 = if ((((opts.a & lower_byte) -% (opts.b & lower_byte) -% opts.carry) & hc_mask) == hc_mask) 1 else 0;

            return .{
                .value = @truncate(remainder),
                .carry = if (remainder > std.math.maxInt(T)) 1 else 0,
                .half_carry = hc,
            };
        }
    };
}

const ByteResult = struct {
    result: u8,
    half_carry: u1,
    carry: u1,
};

pub fn byteAdd(opts: struct {
    a: u8,
    b: u8,
    carry: u1 = 0,
}) ByteResult {
    const sum: u16 = @as(u16, opts.a) + @as(u16, opts.b) + opts.carry;
    const cy: u1 = if ((sum & 0x0100) == 0x0100) 1 else 0;
    const hc: u1 = if ((((opts.a & 0xF) +% (opts.b & 0xF) +% opts.carry) & 0x10) == 0x10) 1 else 0;
    return .{
        .result = @truncate(sum),
        .half_carry = hc,
        .carry = cy,
    };
}

pub fn byteSub(opts: struct {
    a: u8,
    b: u8,
    carry: u1 = 0,
}) ByteResult {
    const remainder: u16 = @as(u16, opts.a) -% @as(u16, opts.b) +% opts.carry;
    const cy: u1 = if ((remainder & 0x0100) == 0x0100) 1 else 0;
    const hc: u1 = if ((((opts.a & 0xF) -% (opts.b & 0xF) -% opts.carry) & 0x10) == 0x10) 1 else 0;
    return .{
        .result = @truncate(remainder),
        .half_carry = hc,
        .carry = cy,
    };
}

const expectEqual = std.testing.expectEqual;

test "byteAdd" {
    var sum = byteAdd(.{
        .a = 0x0F,
        .b = 0x01
    });
    try expectEqual(0x10, sum.result);
    try expectEqual(1, sum.half_carry);
    try expectEqual(0, sum.carry);

    sum = byteAdd(.{
        .a = 0x0F,
        .b = 0x0F
    });
    try expectEqual(0x1E, sum.result);
    try expectEqual(1, sum.half_carry);
    try expectEqual(0, sum.carry);

    sum = byteAdd(.{
        .a = 0x0E,
        .b = 0x01
    });
    try expectEqual(0x0F, sum.result);
    try expectEqual(0, sum.half_carry);
    try expectEqual(0, sum.carry);

    sum = byteAdd(.{
        .a = 0xFF,
        .b = 0xFF
    });
    try expectEqual(0xFE, sum.result);
    try expectEqual(1, sum.half_carry);
    try expectEqual(1, sum.carry);
}

test "byteSub" {
    var remainder = byteSub(. {
        .a = 0x01,
        .b = 0x0F
    });
    try expectEqual(0xF2, remainder.result);
    try expectEqual(0x01, remainder.half_carry);
    try expectEqual(0x01, remainder.carry);

    remainder = byteSub(.{
        .a = 0x0F,
        .b = 0x0F
    });
    try expectEqual(0x00, remainder.result);
    try expectEqual(0x00, remainder.half_carry);
    try expectEqual(0x00, remainder.carry);
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

test "fromTwoBytes" {
    const hi: u8 = 0x34;
    const lo: u8 = 0xA0;
    try expectEqual(0x34A0, fromTwoBytes(lo, hi));
}

test "getHiByte" {
    const val: u16 = 0xFACE;
    try expectEqual(0xFA, getHiByte(val));
}

test "getLoByte" {
    const val: u16 = 0xFACE;
    try expectEqual(0xCE, getLoByte(val));
}

test "Arithmetic(u8).add" {
    var result = Arithmetic(u8).add(.{
        .a = 0xF,
        .b = 0xF,
    });
    try expectEqual(0x1E, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(0, result.carry);

    result = Arithmetic(u8).add(.{
        .a = 0x0F,
        .b = 0x01
    });
    try expectEqual(0x10, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(0, result.carry);

    result = Arithmetic(u8).add(.{
        .a = 0x0F,
        .b = 0x0F
    });
    try expectEqual(0x1E, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(0, result.carry);

    result = Arithmetic(u8).add(.{
        .a = 0x0E,
        .b = 0x01
    });
    try expectEqual(0x0F, result.value);
    try expectEqual(0, result.half_carry);
    try expectEqual(0, result.carry);

    result = Arithmetic(u8).add(.{
        .a = 0xFF,
        .b = 0xFF
    });
    try expectEqual(0xFE, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(1, result.carry);

    result = Arithmetic(u8).add(.{
        .a = 0xFF,
        .b = 0xFF,
        .carry = 1,
    });
    try expectEqual(0xFF, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(1, result.carry);

    result = Arithmetic(u8).add(.{
        .a = 0x0F,
        .b = 0x00,
        .carry = 1,
    });
    try expectEqual(0x10, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(0, result.carry);
}

test "Arithmetic(u16).add" {
    var result = Arithmetic(u16).add(.{
        .a = 0xFFFF,
        .b = 0xFFFF,
    });
    try expectEqual(0xFFFE, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(1, result.carry);

    result = Arithmetic(u16).add(.{
        .a = 0xFFFF,
        .b = 0xFFFF,
        .carry = 1,
    });
    try expectEqual(0xFFFF, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(1, result.carry);

    result = Arithmetic(u16).add(.{
        .a = 0x00FE,
        .b = 0x0001,
    });
    try expectEqual(0x00FF, result.value);
    try expectEqual(0, result.half_carry);
    try expectEqual(0, result.carry);

    result = Arithmetic(u16).add(.{
        .a = 0x00FF,
        .b = 0x0001,
    });
    try expectEqual(0x0100, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(0, result.carry);

    result = Arithmetic(u16).add(.{
        .a = 0x00FF,
        .b = 0x0000,
        .carry = 1,
    });
    try expectEqual(0x0100, result.value);
    try expectEqual(1, result.half_carry);
    try expectEqual(0, result.carry);

    result = Arithmetic(u16).add(.{
        .a = 0x0000,
        .b = 0x0005,
        .carry = 1,
    });
    try expectEqual(0x0006, result.value);
    try expectEqual(0, result.half_carry);
    try expectEqual(0, result.carry);
}

test "Arithmetic(u8).subtract" {
    var remainder = Arithmetic(u8).subtract(. {
        .a = 0x01,
        .b = 0x0F
    });
    try expectEqual(0xF2, remainder.value);
    try expectEqual(0x01, remainder.half_carry);
    try expectEqual(0x01, remainder.carry);

    remainder = Arithmetic(u8).subtract(.{
        .a = 0x0F,
        .b = 0x0F
    });
    try expectEqual(0x00, remainder.value);
    try expectEqual(0x00, remainder.half_carry);
    try expectEqual(0x00, remainder.carry);

    remainder = Arithmetic(u8).subtract(.{
        .a = 0x00,
        .b = 0x00,
        .carry = 1,
    });
    try expectEqual(0xFF, remainder.value);
    try expectEqual(1, remainder.half_carry);
    try expectEqual(1, remainder.carry);

    remainder = Arithmetic(u8).subtract(.{
        .a = 0x10,
        .b = 0x0F
    });
    try expectEqual(0x01, remainder.value);
    try expectEqual(1, remainder.half_carry);
    try expectEqual(0, remainder.carry);
}

test "Arithmetic(u16).subtract" {
    var remainder = Arithmetic(u16).subtract(. {
        .a = 0x0100,
        .b = 0x0FFF,
    });
    try expectEqual(0xF101, remainder.value);
    try expectEqual(1, remainder.half_carry);
    try expectEqual(1, remainder.carry);

    remainder = Arithmetic(u16).subtract(.{
        .a = 0x00FF,
        .b = 0x00FF
    });
    try expectEqual(0x0000, remainder.value);
    try expectEqual(0, remainder.half_carry);
    try expectEqual(0, remainder.carry);

    remainder = Arithmetic(u16).subtract(.{
        .a = 0x0000,
        .b = 0x0000,
        .carry = 1,
    });
    try expectEqual(0xFFFF, remainder.value);
    try expectEqual(1, remainder.half_carry);
    try expectEqual(1, remainder.carry);

    remainder = Arithmetic(u16).subtract(.{
        .a = 0x0100,
        .b = 0x000F,
    });
    try expectEqual(0x00F1, remainder.value);
    try expectEqual(1, remainder.half_carry);
    try expectEqual(0, remainder.carry);
}
