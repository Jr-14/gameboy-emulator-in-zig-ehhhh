const std = @import("std");
const Processor = @import("processor.zig");
const Memory = @import("memory.zig");
const Cartridge = @import("cartridge/root.zig");

pub const RAM_SIZE: u16 = 8192;
pub const VRAM_SIZE: u16 = 8192;

const GameboyState = @This();

processor: *Processor,
memory: *Memory,
ram: []u16,
vram: []u16,
allocator: std.mem.Allocator,

pub fn init(io: std.Io, allocator: std.mem.Allocator, rom_file: []const u8) !GameboyState {
    const memory = try allocator.create(Memory);
    memory.* = Memory.init();

    const processor = try allocator.create(Processor);
    processor.* = Processor.init(memory, .{});

    const cwd = std.Io.Dir.cwd();
    const file = try cwd.openFile(io, rom_file, .{ .mode = .read_only });
    defer file.close(io);

    const file_length = try file.length(io);
    std.debug.print("Rom size: {d} bytes\n", .{ file_length });

    const file_buffer = try allocator.alloc(u8, 4096);
    defer allocator.free(file_buffer);
    var file_reader = file.reader(io, file_buffer);

    const rom_data = try allocator.alloc(u8, file_length);
    defer allocator.free(rom_data);
    file_reader.interface.readSliceAll(rom_data) catch |err| {
        std.log.err("ROM read failed: {}", .{ err });
    };

    try Cartridge.createCartridge(rom_data);

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
