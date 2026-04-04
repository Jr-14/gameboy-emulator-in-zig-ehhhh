const std = @import("std");
const Processor = @import("processor.zig");

const GameboyState = @This();

processor: Processor,

pub fn init(allocator: std.mem.Allocator) GameboyState {
    return .{
        .processor = Processor.init()
    };
}
