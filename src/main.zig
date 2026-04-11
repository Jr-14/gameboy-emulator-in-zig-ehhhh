const std = @import("std");
const Gameboy = @import("gameboy.zig");

pub fn main(init: std.process.Init) !void {
    _ = init;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const gb = Gameboy.init(allocator);
    _ = gb;
}
