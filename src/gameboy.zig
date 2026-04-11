const std = @import("std");
const Processor = @import("processor.zig");
const Memory = @import("memory.zig");

pub const RAM_SIZE: u8 = 8192;
pub const VRAM_SIZE: u8 = 8192;

const GameboyState = @This();

processor: Processor,
memory: Memory,
ram: []u8,
vram: []u8,
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
        .ram = allocator.alloc(u8, RAM_SIZE),
        .vram = allocator.alloc(u8, VRAM_SIZE),
    };
}

pub fn deinit(self: *GameboyState) void {
    self.allocator.free(self.ram);
    self.allocator.free(self.vram);
    self.allocator.free(self.memory);
    self.allocator.free(self.processor);
}
