const std = @import("std");

const RegisterNew = @This();

value: u8 = 0,

/// Increment the register value. If it is greater than what an 8-bit register can represent
/// (0xFF) it will wrap back around to zero without any overflow;
pub inline fn increment(r: *RegisterNew) void {
    r.value +%= 1;
}

/// Decrement the register value. If it is less 0, it will wrap back to the maximum 8-bit
/// (0xFF) representation without any overflow.
pub inline fn decrement(r: *RegisterNew) void {
    r.value -%= 1;
}

const expectEqual = std.testing.expectEqual;

test "increment" {
    var B: RegisterNew = .{ .value = 0 };

    RegisterNew.increment(&B);

    try expectEqual(1, B.value);

    B.value = 0xFF;
    RegisterNew.increment(&B);

    try expectEqual(0, B.value);
}

test "decrement" {
    var C: RegisterNew = .{ .value = 0 };

    RegisterNew.decrement(&C);

    try expectEqual(0xFF, C.value);

    RegisterNew.decrement(&C);

    try expectEqual(0xFE, C.value);
}
