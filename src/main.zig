const std = @import("std");
const Gameboy = @import("Gameboy.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    // const rom_path: []const u8 = "rom/tetris.gb";
    const rom_path: []const u8 = "rom/Donkey Kong (World) (Rev 1) (SGB Enhanced).gb";
    // const rom_path: []const u8 = "rom/Tetris (World) (Rev 1).gb";
    var gb = try Gameboy.init(arena);
    defer gb.deinit();

    gb.insertCartridge(io, arena, rom_path) catch |err| {
        std.debug.print("Failed to insert rom: {s}\n", .{ rom_path });
        std.debug.print("{}\n", .{ err });
    };
}
