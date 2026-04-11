const std = @import("std");
const Processor = @import("processor.zig");
const Memory = @import("memory.zig");

pub const RAM_SIZE: u16 = 8192;
pub const VRAM_SIZE: u16 = 8192;

const GameboyState = @This();

processor: *Processor,
memory: *Memory,
ram: []u16,
vram: []u16,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !GameboyState {
    const memory = try allocator.create(Memory);
    memory.* = Memory.init();

    const processor = try allocator.create(Processor);
    processor.* = Processor.init(memory, .{});

    return .{
        .allocator = allocator,
        .memory = memory,
        .processor = processor,
        .ram = try allocator.alloc(u16, RAM_SIZE),
        .vram = try allocator.alloc(u16, VRAM_SIZE),
    };
}

pub fn deinit(self: *GameboyState) void {
    self.allocator.free(self.ram);
    self.allocator.free(self.vram);
    self.allocator.destroy(self.memory);
    self.allocator.destroy(self.processor);
}

test "init" {
    var dbga = std.heap.DebugAllocator(.{}){};
    defer _ = dbga.deinit();

    const allocator = dbga.allocator();

    var gb = try GameboyState.init(allocator);
    defer gb.deinit();

    std.debug.print("somethign cool\n", .{});
}
