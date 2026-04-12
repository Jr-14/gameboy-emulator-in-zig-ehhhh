const std = @import("std");
const Gameboy = @import("gameboy.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    // const rom_file: []const u8 = "rom/tetris.gb";
    const rom_file: []const u8 = "rom/Tetris (World) (Rev 1).gb";
    // const rom_file: []const u8 = "rom/Donkey Kong (World) (Rev 1) (SGB Enhanced).gb";
    var gb = try Gameboy.init(io, arena, rom_file);
    defer gb.deinit();
}
