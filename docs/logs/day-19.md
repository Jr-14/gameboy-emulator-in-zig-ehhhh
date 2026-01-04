# Day 19 - 2026 January 5th 8.56AM
I've been playing around with zigs bit representation of signed and unsigned numbers

```zig
test "signed integer addition to unsigned integer" {
    const s: i8 = -1;
    const us: u8 = @bitCast(s);

    const base: u8 = 255;
    const val: u8 = base +% us;

    std.debug.print("\nimmediate - dec: {}, bit_rep: 0b{b}", .{ s, @as(u8, @bitCast(s))});
    std.debug.print("\ntotal: - dec:{}, bit_rep: 0b{b}", .{ val, @as(u8, @bitCast(val))});
}
```

I learnt about the [*wrapping arithmetic*](https://ziglang.org/documentation/0.15.2/#Runtime-Integer-Values) to guard
against illegal integer overflow behaviour.
