const std = @import("std");
const Processor = @import("processor.zig");

const GameboyState = @This();

processor: Processor,
ram: []u8,
vram: []u8,

pub fn init(allocator: std.mem.Allocator) GameboyState {
    return .{
        .processor = Processor.init()
    };
}
