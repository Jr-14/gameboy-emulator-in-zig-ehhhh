# Day 3 - December 6th 2025 8:59AM
So I had to learn some zig, especially around memory allocation strategies.
Very cool watch. Now I gotta get down to writing some code

# Emulating The CPU - Instructions
I guess we can emulate part of the CPU instructions by using a large switch
statement based on the op code.

When coding, these questions are always on my mind.

Is the implementation correct?
What's the best way to test?
What are the assertions for my test?

I guess I've written the first 32 8-bit instructions. I'm going to try to implement
them and write some tests. For the implementation, does it make sense to do the decoding
and execution inside the switch statement? I'm not sure since there are multiple bytes.
For example the `DEC B` which decrements the contents of register B by 1, has a 1byte
opcode, and some flags associated with it (another story to implement flags, not even sure
how to at the moment)
Should the interface for decode use an array of bytes? hmmm or maybe a 3 byte unsigned int and
should this be little endian or big endian?

I guess I'll read more about the [fetch-decode-execute cycle](https://www.baeldung.com/cs/fetch-execute-cycle)

I think I've settled with an array of unsigned 8-bit integers with a length of 3.

# Hashmaps
I'm having difficulty understanding how to guard against `null` for StringHashMaps

```zig
    0x04 => {
        const b = register.get("B");
        if (b == null) {
            return RegisterError.RegisterNotFound;
        } else {
            try register.put("B", b + 1);
            return pc + 1;
        }
    },
```

This results in this error

```
src/main.zig:64:41: error: invalid operands to binary expression: 'optional' and 'comptime_int'
                try register.put("B", b + 1);
                                      ~~^~~
src/test_decode.zig:18:69: error: operator == not allowed for type '@typeInfo(@typeInfo(@TypeOf(main.decode)).@"fn".return_type.?).error_union.error_set!u32'
    try expect(main.decode([_]u8{0x00, 0x00, 0x00}, &registers, pc) == 0);
               ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~
```

I don't understand it, but I will eventually.

Well now today I learnt about [Payload Captures](https://zig.guide/language-basics/payload-captures/). Here's the
proper way

```zig
    0x04 => {
        const b = register.get("B");
        if (b) |value| {
            try register.put("B", value + 1);
            return pc + 1;
        } else {
            return RegisterError.RegisterNotFound;
        }
    },
```

# Structs and Pointers
Now that I'm starting to get a feel for how zig does things, a struct is probably a better structure for referencing
registers. I thought it was very odd how trying to find a register would fail since they're inside a HashMap, so a
struct is a better datastructure for this.

Defining a *type* of the struct. I don't know why we would use `const` for this.

```zig
const Register = struct {
    A: u8 = 0,
    B: u8 = 0,
    C: u8 = 0,
    D: u8 = 0,
    E: u8 = 0,
    H: u8 = 0,
    L: u8 = 0,
    BC: u16 = 0,
    DE: u16 = 0,
    HL: u16 = 0,
};
```

And the usage

```zig
pub fn createRegister() Register {
    return Register {
        .A = 0,
        .B = 0,
        .C = 0,
        .D = 0,
        .E = 0,
        .H = 0,
        .L = 0,
        .BC = 0,
        .DE = 0,
        .HL = 0,
    };
}
```

Dereferencing a pointer has a weird syntax. I just have to get used to it.

```zig
pub fn decodeAndExecute(word: [3]u8, registers: *Register, pc: *u32) !void {
    // everything else ...
    pc.* += 1;
    // ...
}
```

# Byte Ordering and Endianness
I'm currently implementing the instruction LD BC, d16 with the following description

*Load the 2 bytes of immediate data into register pair BC.*
*The first byte of immediate data is the lower byte (i.e., bits 0-7), and the second byte of*
*immediate data is the higher byte (i.e., bits 8-15).*

So it looks like the following bits are in this order

For example the number 394 base 10 is the binary 110001010, however this is using the big endian system
