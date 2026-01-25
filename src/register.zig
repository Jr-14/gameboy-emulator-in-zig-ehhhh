const Register = @This();

const std = @import("std");
const masks = @import("masks.zig");

const HI_MASK = masks.HI_MASK;
const LO_MASK = masks.LO_MASK;

const Z_MASK = masks.Z_MASK;
const N_MASK = masks.N_MASK;
const H_MASK = masks.H_MASK;
const C_MASK = masks.C_MASK;

pub const Flag = enum {
    Z,
    N,
    H,
    C,
};

value: u16 = 0,

pub fn init(hi: u8, lo: u8) Register {
    const value: u16 = (@as(u16, hi) << 8) | lo;
    return .{
        .value = value,
    };
}

pub inline fn get(r: Register) u16 {
    return r.value;
}

pub inline fn getHi(r: Register) u8 {
    return @truncate((r.value & HI_MASK) >> 8);
}

pub inline fn getLo(r: Register) u8 {
    return @truncate((r.value & LO_MASK));
}

pub inline fn set(r: *Register, val: u16) void {
    r.value = val;
}

pub inline fn setHi(r: *Register, val: u8) void {
    const new_hi: u16 = @as(u16, val) << 8;
    const curr_lo: u16 = (r.value & LO_MASK);
    r.value = new_hi | curr_lo;
}

pub inline fn setLo(r: *Register, val: u8) void {
    r.value = (r.value & HI_MASK) | val;
}

pub inline fn increment(r: *Register) void {
    r.value +%= 1;
}

pub inline fn decrement(r: *Register) void {
    r.value -%= 1;
}

const expectEqual = std.testing.expectEqual;

test "init" {
    const hi: u8 = 0x31;
    const lo: u8 = 0x7b;
    var AF = Register.init(hi, lo);

    try expectEqual(0x317b, AF.get());
}

test "getting an initialised register" {
    var AF = Register {
        .value = 0xffdd
    };

    try expectEqual(0xff, AF.getHi());
    try expectEqual(0xdd, AF.getLo());
    try expectEqual(0xffdd, AF.get());

    AF.set(0x1023);
    try expectEqual(0x10, AF.getHi());
    try expectEqual(0x23, AF.getLo());
}

test "setting and getting hi register" {
    var AF = Register{};
    AF.setHi(0xff);

    try expectEqual(0xff, AF.getHi());
    try expectEqual(0x00, AF.getLo());
    try expectEqual(0xff00, AF.get());
}

test "setting and getting lo register" {
    var AF = Register{};
    AF.setLo(0x1c);

    try expectEqual(0x1c, AF.getLo());
    try expectEqual(0x00, AF.getHi());
}

test "setting and getting 16 bit register" {
    var AF = Register{};
    AF.set(0x1c3b);

    try expectEqual(0x1c3b, AF.get());
    try expectEqual(0x1c, AF.getHi());
    try expectEqual(0x3b, AF.getLo());

    AF.set(0x67f9);

    try expectEqual(0x67f9, AF.get());
    try expectEqual(0x67, AF.getHi());
    try expectEqual(0xf9, AF.getLo());
}

test "increment" {
    var AF = Register{
        .value = 0xF000,
    };

    AF.increment();

    try expectEqual(0xf001, AF.value);

    AF.increment();
    AF.increment();

    try expectEqual(0xf003, AF.value);
    try expectEqual(0xf003, AF.get());
}

test "wrapping increment" {
    var AF = Register{
        .value = 0xFFFF,
    };

    AF.increment();
    try expectEqual(0x0000, AF.value);

    AF.increment();
    try expectEqual(0x0001, AF.value);
}

test "decrement" {
    var AF = Register{
        .value = 0xf000,
    };

    AF.decrement();

    try expectEqual(0xefff, AF.value);

    AF.decrement();
    AF.decrement();

    try expectEqual(0xeffd, AF.value);
    try expectEqual(0xeffd, AF.get());
}

test "wrapping decrement" {
    var AF = Register{
        .value = 0x0000,
    };

    AF.decrement();
    try expectEqual(0xFFFF, AF.value);

    AF.decrement();
    try expectEqual(0x0FFFE, AF.value);
}
