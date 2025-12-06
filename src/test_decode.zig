const std = @import("std");
const main = @import("main.zig");

const expect = std.testing.expect;

test "testing simple decode no op" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var registers = std.StringHashMap(u8).init(allocator);
    defer registers.deinit();

    const pc = 0;

    try registers.put("B", 0);

    const next_pc = try main.decode([_]u8{0x00, 0x00, 0x00}, &registers, pc);

    try expect(next_pc == 1);
}
