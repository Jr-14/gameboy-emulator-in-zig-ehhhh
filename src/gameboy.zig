const std = @import("std");
const Processor = @import("processor.zig");
const Memory = @import("memory.zig");
const cart = @import("cartridge/root.zig");

const Cartridge = cart.Cartridge;
const CartridgeHeader = cart.CartridgeHeader;

pub const RAM_SIZE: u16 = 40;
pub const VRAM_SIZE: u16 = 8192;

const GameboyState = @This();

processor: *Processor,
memory: *Memory,
ram: []u8,
vram: []u8,
allocator: std.mem.Allocator,

pub fn init(io: std.Io, allocator: std.mem.Allocator, rom_file: []const u8) !GameboyState {
    const memory = try allocator.create(Memory);
    errdefer allocator.destroy(memory);
    memory.* = Memory.init();

    const processor = try allocator.create(Processor);
    errdefer allocator.destroy(processor);
    processor.* = Processor.init(memory, .{});

    var cartridge = try Cartridge.init(io, allocator, rom_file);
    defer cartridge.deinit();
    cartridge.printDebug();

    return .{
        .allocator = allocator,
        .memory = memory,
        .processor = processor,
        .ram = try allocator.alloc(u8, RAM_SIZE),
        .vram = try allocator.alloc(u8, VRAM_SIZE),
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
