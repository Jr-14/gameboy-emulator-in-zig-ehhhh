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
    const cartridge = try allocator.create(Cartridge);
    cartridge.* = try Cartridge.init(io, allocator, rom_file);
    self.cartridge = cartridge;
    switch(cartridge.*.header.cartridge_type) {
        // Depending on the catridge, maybe we can try to map out the catridge contents into memory?
        .rom_only => {
            std.debug.print("ROM ONLY cartridge inserted\n", .{});
            @memmove(self.ram, cartridge.rom_data);
        },
        else => {
            std.debug.print("I guess these other types are not implemented\n", .{});
        }
    }
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

pub fn run(self: *GameboyState) !void {
    self.processor.PC = 0x0100;
    while(true) {
        const instruction = self.processor.fetch();
        std.debug.print("instruction: 0x{x}\n", .{ instruction });
        self.processor.decodeAndExecute(instruction) catch |err| {
            std.debug.print("Failed to decode and execute instruction \n", .{});
            std.debug.print("{any}\n", .{ err });
        };
    }
}

test "init" {
    var dbga = std.heap.DebugAllocator(.{}){};
    defer _ = dbga.deinit();

    const allocator = dbga.allocator();

    var gb = try GameboyState.init(allocator);
    defer gb.deinit();
}
