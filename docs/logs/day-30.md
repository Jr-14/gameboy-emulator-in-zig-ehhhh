# Day 30 - 2026 January 23rd 9.01AM.
You can say that 30 days is approximately a month. Maybe worth writing a blog
post about my experience with tackling a difficult long project?

I think I've misunderstood the little endian and big endian of load instructions? [Endianness](https://en.wikipedia.org/wiki/Endianness)

1.38PM
I wasn't too familiar with the CALL instruction and how it works, but I think I have an understanding
now.

2.15PM
[Zig result locations](https://ziglang.org/documentation/0.15.2/#Result-Location-Semantics) as a result of
looking into random number generation and seeing some zig code I was unfamiliar with.

E.g.

```zig
test "random numbers" {
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.int(u8);
    const d = rand.intRangeAtMost(u8, 0, 255);

    //suppress unused constant compile error
    _ = .{ a, b, c, d };
}
```

To me this reads as `prng` has the type std.Random.DefaultPrng which is its result type and therefore has
a static method `.init` which we can call shorthand. The blk expression then resolves to a u64 value.

2.53PM
Also learnt about [`@This()` file scope](https://ziglang.org/documentation/master/#This) which I've used first
in register.zig. Therefore, I can now use source file stuct [Source-File-Structs](https://ziglang.org/documentation/0.15.2/#Source-File-Structs)

Before I had to explicitly declare the Register and Memory namespaces within the file as
```zig
const Register = @import("register.zig").Register;
const Memory = @import("memory.zig").Memory;
```

After using `@This()` file scoping

```zig
const Register = @import("register.zig");
const Memory = @import("memory.zig");
```

Total time: 212 minutes
