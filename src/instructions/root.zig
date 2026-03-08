pub const arithmetic = @import("arithmetic.zig");
pub const bitFlag = @import("bitFlag.zig");
pub const bitShift = @import("bitShift.zig");
pub const bits = @import("bits.zig");
pub const controlFlow = @import("controlFlow.zig");
pub const load = @import("load.zig");
pub const misc = @import("misc.zig");

test "all instructions" {
    // _ = @import("bitFlag.zig");
    // _ = @import("bitShift.zig");
    // _ = @import("bits.zig");
    // _ = @import("controlFlow.zig");
    // _ = @import("load.zig");
    // _ = @import("misc.zig");
}

test "run arithmetic instructions" {
    _ = @import("arithmetic.zig");
}
