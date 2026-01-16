const std = @import("std");

pub const HI_MASK: u16 = 0xFF00;
pub const LO_MASK: u8 = 0x00FF;

pub const Z_MASK: u8 = 0x80; // 0b1000_0000
pub const N_MASK: u8 = 0x40; // 0b0100_0000
pub const H_MASK: u8 = 0x20; // 0b0010_0000
pub const C_MASK: u8 = 0x10; // 0b0001_0000

pub const Flag = enum {
    Z,
    N,
    H,
    C,
};

pub const Register = struct {
    const Self = @This();

    value: u16 = 0,

    pub fn init(hi: u8, lo: u8) Self {
        const value: u16 = (@as(u16, hi) << 8) | lo;
        return .{
            .value = value,
        };
    }

    pub inline fn get(self: Self) u16 {
        return self.value;
    }

    pub inline fn getHi(self: Self) u8 {
        return @truncate((self.value & HI_MASK) >> 8);
    }

    pub inline fn getLo(self: Self) u8 {
        return @truncate((self.value & LO_MASK));
    }

    pub inline fn set(self: *Self, val: u16) void {
        self.value = val;
    }

    pub inline fn setHi(self: *Self, val: u8) void {
        const new_hi: u16 = @as(u16, val) << 8;
        const curr_lo: u16 = (self.value & LO_MASK);
        self.value = new_hi | curr_lo;
    }

    pub inline fn setLo(self: *Self, val: u8) void {
        self.value = (self.value & HI_MASK) | val;
    }

    pub inline fn increment(self: *Self) void {
        self.value += 1;
    }

    pub inline fn decrement(self: *Self) void {
        self.value -= 1;
    }
};

pub fn isFlagSet(register: *Register, flag: Flag) bool {
    return switch (flag) {
        .Z => (register.getLo() & Z_MASK) == Z_MASK,
        .N => (register.getLo() & N_MASK) == N_MASK,
        .H => (register.getLo() & H_MASK) == H_MASK,
        .C => (register.getLo() & C_MASK) == C_MASK,
    };
}

pub fn setFlag(register: *Register, flag:  Flag) void {
    const hi = register.getLo();
    switch (flag) {
        .Z => register.setLo(hi | Z_MASK),
        .N => register.setLo(hi | N_MASK),
        .H => register.setLo(hi | H_MASK),
        .C => register.setLo(hi | C_MASK),
    }
}

pub fn unsetFlag(register: *Register, flag: Flag) void {
    const hi = register.getLo();
    switch (flag) {
        .Z => register.setLo(hi & ~Z_MASK),
        .N => register.setLo(hi & ~N_MASK),
        .H => register.setLo(hi & ~H_MASK),
        .C => register.setLo(hi & ~C_MASK),
    }
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
        .value = 0xf000,
    };

    AF.increment();

    try expectEqual(0xf001, AF.value);

    AF.increment();
    AF.increment();

    try expectEqual(0xf003, AF.value);
    try expectEqual(0xf003, AF.get());
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

test "isFlagSet, Z" {
    var AF = Register{
        .value = 0b1000_0000,
    };

    try expectEqual(true, isFlagSet(&AF, .Z));
    try expectEqual(false, isFlagSet(&AF, .N));
    try expectEqual(false, isFlagSet(&AF, .H));
    try expectEqual(false, isFlagSet(&AF, .C));
}

test "isFlagSet, N" {
    var AF = Register{
        .value = 0b0100_0000,
    };

    try expectEqual(false, isFlagSet(&AF, .Z));
    try expectEqual(true, isFlagSet(&AF, .N));
    try expectEqual(false, isFlagSet(&AF, .H));
    try expectEqual(false, isFlagSet(&AF, .C));
}

test "isFlagSet, H" {
    var AF = Register{
        .value = 0b0010_0000,
    };

    try expectEqual(false, isFlagSet(&AF, .Z));
    try expectEqual(false, isFlagSet(&AF, .N));
    try expectEqual(true, isFlagSet(&AF, .H));
    try expectEqual(false, isFlagSet(&AF, .C));
}

test "isFlagSet, C" {
    var AF = Register{
        .value = 0b0001_0000,
    };

    try expectEqual(false, isFlagSet(&AF, .Z));
    try expectEqual(false, isFlagSet(&AF, .N));
    try expectEqual(false, isFlagSet(&AF, .H));
    try expectEqual(true, isFlagSet(&AF, .C));
}

test "setFlag, Z" {
    var AF = Register{};
    setFlag(&AF, .Z);

    try expectEqual(true, isFlagSet(&AF, .Z));
    try expectEqual(false, isFlagSet(&AF, .N));
    try expectEqual(false, isFlagSet(&AF, .H));
    try expectEqual(false, isFlagSet(&AF, .C));
}

test "setFlag, N" {
    var AF = Register{};
    setFlag(&AF, .N);

    try expectEqual(false, isFlagSet(&AF, .Z));
    try expectEqual(true, isFlagSet(&AF, .N));
    try expectEqual(false, isFlagSet(&AF, .H));
    try expectEqual(false, isFlagSet(&AF, .C));
}

test "setFlag, H" {
    var AF = Register{};
    setFlag(&AF, .H);

    try expectEqual(false, isFlagSet(&AF, .Z));
    try expectEqual(false, isFlagSet(&AF, .N));
    try expectEqual(true, isFlagSet(&AF, .H));
    try expectEqual(false, isFlagSet(&AF, .C));
}

test "setFlag, C" {
    var AF = Register{};
    setFlag(&AF, .C);

    try expectEqual(false, isFlagSet(&AF, .Z));
    try expectEqual(false, isFlagSet(&AF, .N));
    try expectEqual(false, isFlagSet(&AF, .H));
    try expectEqual(true, isFlagSet(&AF, .C));
}

test "unsetFlag, Z" {
    var AF = Register{
        .value = 0b1111_0000,
    };
    unsetFlag(&AF, .Z);

    try expectEqual(false, isFlagSet(&AF, .Z));
    try expectEqual(true, isFlagSet(&AF, .N));
    try expectEqual(true, isFlagSet(&AF, .H));
    try expectEqual(true, isFlagSet(&AF, .C));
}

test "unsetFlag, N" {
    var AF = Register{
        .value = 0b1111_0000,
    };
    unsetFlag(&AF, .N);

    try expectEqual(true, isFlagSet(&AF, .Z));
    try expectEqual(false, isFlagSet(&AF, .N));
    try expectEqual(true, isFlagSet(&AF, .H));
    try expectEqual(true, isFlagSet(&AF, .C));
}

test "unsetFlag, H" {
    var AF = Register{
        .value = 0b1111_0000,
    };
    unsetFlag(&AF, .H);

    try expectEqual(true, isFlagSet(&AF, .Z));
    try expectEqual(true, isFlagSet(&AF, .N));
    try expectEqual(false, isFlagSet(&AF, .H));
    try expectEqual(true, isFlagSet(&AF, .C));
}

test "unsetFlag, C" {
    var AF = Register{
        .value = 0b1111_0000,
    };
    unsetFlag(&AF, .C);

    try expectEqual(true, isFlagSet(&AF, .Z));
    try expectEqual(true, isFlagSet(&AF, .N));
    try expectEqual(true, isFlagSet(&AF, .H));
    try expectEqual(false, isFlagSet(&AF, .C));
}
