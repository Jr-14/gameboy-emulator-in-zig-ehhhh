const std = @import("std");

const HI_MASK: u16 = 0xFF00;
const LO_MASK: u8 = 0x00FF;

const Register = struct {
    const Self = @This();

    reg: u16 = 0,

    pub inline fn read(self: Self) u16 {
        return self.reg;
    }

    pub inline fn readHi(self: Self) u8 {
        return @truncate((self.reg & HI_MASK) >> 8);
    }

    pub inline fn readLo(self: Self) u8 {
        return @truncate((self.reg & LO_MASK));
    }

    pub inline fn write(self: *Self, val: u16) void {
        self.reg = val;
    }

    pub inline fn writeHi(self: *Self, val: u8) void {
        const new_hi: u16 = @as(u16, val) << 8;
        const curr_lo: u16 = (self.reg & LO_MASK);
        self.reg = new_hi | curr_lo;
    }

    pub inline fn writeLo(self: *Self, val: u8) void {
        self.reg = (self.reg & HI_MASK) | val;
    }
};

const expectEqual = std.testing.expectEqual;

test "reading an initialised register" {
    var AF = Register {
        .reg = 0xffdd
    };

    try expectEqual(0xff, AF.readHi());
    try expectEqual(0xdd, AF.readLo());
    try expectEqual(0xffdd, AF.read());

    AF.write(0x1023);
    try expectEqual(0x10, AF.readHi());
    try expectEqual(0x23, AF.readLo());
}

test "writing and reading hi register" {
    var AF = Register{};
    AF.writeHi(0xff);

    try expectEqual(0xff, AF.readHi());
    try expectEqual(0x00, AF.readLo());
    try expectEqual(0xff00, AF.read());
}

test "writing and reading lo register" {
    var AF = Register{};
    AF.writeLo(0x1c);

    try expectEqual(0x1c, AF.readLo());
    try expectEqual(0x00, AF.readHi());
}

test "writing and reading 16 bit register" {
    var AF = Register{};
    AF.write(0x1c3b);

    try expectEqual(0x1c3b, AF.read());
    try expectEqual(0x1c, AF.readHi());
    try expectEqual(0x3b, AF.readLo());

    AF.write(0x67f9);

    try expectEqual(0x67f9, AF.read());
    try expectEqual(0x67, AF.readHi());
    try expectEqual(0xf9, AF.readLo());
}
