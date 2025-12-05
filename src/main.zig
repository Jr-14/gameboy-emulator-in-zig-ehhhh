const std = @import("std");

pub fn main() !void {
    // I didn't know we need an allocation strategy in order to create a hashmap
    // It is indeed very interesting
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // I guess I can start with declaring 8 bit registers
    // Rather than using undefined, I think we can 0 out the bits. In my mind it makes sense maybe
    // Maybe a HashMap?
    var registers = std.StringHashMap(u8).init(allocator);
    defer registers.deinit();

    try registers.put("A", 0);
    try registers.put("B", 0);
    try registers.put("C", 0);
    try registers.put("D", 0);
    try registers.put("E", 0);
    try registers.put("H", 0);
    try registers.put("L", 0);
}

pub fn decode(op_code: u8) []const u8 {
    const s = switch (op_code) {
        // NOP (No operation) Only advances the program counter by 1.
        // Performs no other operations that would have an effect
        0x00 => "NOP",
        else => "S"
    };
    
    return s;

}

// Legend
// r8  - any of the 8-bit registers (A, B, C, D, E, H, L).
// r16 - any of the general-purpose 16-bit registers (BC, DE, HL).
// n8  - 8-bit integer constant (signed or unsigned, -128 to 255).
// n16 - 16-bit integer constant (signed or unsigned, -32768 to 65535).
// e8  - 8-bit signed offset (-128 to 127)
// u3  - 3-bit unsigned bit index (0 to 7, with 0 as the least significant bit).
// cc  - A condition code:
//          Z   Execute if Z is set
//          NZ  Execute if Z is not set
//          C   Execute if C is set
//          NC  Execute if C is not set
// vec - an RST vector (0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, and 0x38)
