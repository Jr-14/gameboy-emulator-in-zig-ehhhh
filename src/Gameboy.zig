const std = @import("std");
const Processor = @import("Processor.zig");
const Memory = @import("Memory.zig");
const Cartridge = @import("Cartridge.zig");

pub const RAM_SIZE: u16 = 4096;
pub const VRAM_SIZE: u16 = 4096;

const GameboyState = @This();

cartridge: ?*Cartridge = null,
processor: *Processor,
memory: *Memory,
ram: []u8,
vram: []u8,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !GameboyState {
    const memory = try allocator.create(Memory);
    errdefer allocator.destroy(memory);
    memory.* = Memory.init();

    const processor = try allocator.create(Processor);
    errdefer allocator.destroy(processor);
    processor.* = Processor.init(memory, .{});

    const ram = try allocator.alloc(u8, RAM_SIZE);
    errdefer allocator.free(ram);

    const vram = try allocator.alloc(u8, VRAM_SIZE);
    errdefer allocator.free(vram);

    return .{
        .allocator = allocator,
        .memory = memory,
        .processor = processor,
        .ram = ram,
        .vram = vram,
    };
}

pub fn insertCartridge(self: *GameboyState, io: std.Io, allocator: std.mem.Allocator, rom_file: []const u8) !void {
    var cartridge = try allocator.create(Cartridge);
    cartridge.* = try Cartridge.init(io, allocator, rom_file);
    cartridge.printDebug();
    self.cartridge = cartridge;
}

pub fn removeCartridge(self: *GameboyState, allocator: std.mem.Allocator) void {
    const cartridge = self.cartridge orelse return;
    allocator.destroy(cartridge);
}

pub fn deinit(self: *GameboyState) void {
    self.allocator.free(self.ram);
    self.allocator.free(self.vram);
    self.allocator.destroy(self.memory);
    self.allocator.destroy(self.processor);
    if (self.cartridge) |cart| {
        self.allocator.destroy(cart);
    }
}

test "init" {
    var dbga = std.heap.DebugAllocator(.{}){};
    defer _ = dbga.deinit();

    const allocator = dbga.allocator();

    var gb = try GameboyState.init(allocator);
    defer gb.deinit();

    std.debug.print("somethign cool\n", .{});
}
