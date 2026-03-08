pub const arithmetic = @import("arithmetic.zig");
pub const bitFlag = @import("bitFlag.zig");
pub const bitShift = @import("bitShift.zig");
pub const bits = @import("bits.zig");
pub const controlFlow = @import("controlFlow.zig");
pub const load = @import("load.zig");
pub const misc = @import("misc.zig");

test "all instructions" {
    // _ = @import("bits.zig");
    // _ = @import("controlFlow.zig");
    // _ = @import("load.zig");
    // _ = @import("misc.zig");
}

test "arithmetic instructions" {
    _ = @import("arithmetic.zig");
}

test "bitFlag instructions" {
    _ = @import("bitFlag.zig");
}

test  "bitShift instructions" {
    _ = @import("bitShift.zig");
}

// test "bit instructions" {}
