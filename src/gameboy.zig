const Processor = @import("processor.zig");

const GameboyState = @This();

processor: Processor,

pub fn init() GameboyState {
    return .{
        .processor = Processor.init()
    };
}
