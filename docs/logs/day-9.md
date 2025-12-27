# Day 9 - December 26th 7.30AM
I learnt something pretty cool in zig and in programming in general. Take this example

```zig
pub const RegisterFile = struct {
    // General Purpose Registers
    B: u8 = 0,
    C: u8 = 0,

    const Self = @This();

    pub fn getBC(self: Self) u16 {
        const bc: u16 = (self.B << 8) + self.C;
        return bc;
    }
};
```

This looks okay (to me at the time), but I get this error

```
src/main.zig:65:25: error: type 'u3' cannot represent integer value '8'
        bc = (self.B << 8) + self.C;
```

What's actually happening under the hood is that I am bitshifting the value of `self.B` 8 bits to the left
and mutating `self.B`. What I wanted was the value of `self.B` whilst preserver `self.B`.

The fix is something more like this.

```zig
pub fn getBC(self: Self) u16 {
    var bc: u16 = self.B;
    bc = (bc << 8) + self.C;
    return bc;
```

And so I've somewhat implemented LD (BC), A - but I still need to consider little endian byte ordering.

**Total time: 90 minutes**

# Day 9 Part 2 - December 26th 6.35PM
I'm finally reading through the [GameBoy Memory Map](http://gameboy.mongenel.com/dmg/asmmemmap.html) and trying to
understand the memory layout of the gameboy. I would have expected pandocs to contains this documentation.

**9:35PM**
I've started to read more of the pseudocode from the Complete Technical reference and it's helping a lot more now.
I don't know why I didn't try to read and understand that first...
