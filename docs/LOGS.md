# Day 1 - 2025 December 4th 2025
So I have decided to create a gameboy emulator from scratch with a programming language that I have no experience in. To
be honest, I don't know where to start, but I guess I need to figure out where to start and what to start on. Ideally
I'd like to map out a small lay of the land.

## Where do I start?
I guess I got my work cutout short by this video [Building a GameBoy Emulator: Getting Started](https://www.youtube.com/watch?v=SCHlyX2sFN8&t)
but then he also mentioned that I should figure this all out. Ehhh it helps to get started with something so that I can
actually do something and get some momentum into building this thing.

## Starting with RGBASM
I guess I start with implementing the assembly code needed for the emulator.

# Day 2 - 2025 December 5th 2025 8:44PM
Maybe it makes sense to also log how many minutes I've spent on this repository.
However, there are also times spent outside of this repository for example, reading
documentation on the train about the full technical documentation for the GameBoy.
But for now it makes sense to log when I sit down in front of my device to code,
or work on the repository.

## Where was I?
I'm trying to get my ahead around implementing the assembly code needed for the emulator...
What sort of interface do I even need to create?
What are the tests I need to run?
How does an emulator even work?
What are the building blocks of the emulator?

So I have literally searched into DuckDuckGo *what's an emulator and how does it work? deep dive high level
technical details* And clicking the first search result on DuckDuckGo gave me this site [How Do Emulators Work? A Deep
Dive into Emulator Design](https://www.retroreversing.com/how-emulators-work). Thank you Retro Reversing. Continuing
to read through the article, I find a reference to a reddit article which asks if [there are any good books/resources
/guides on Emulator Architecture](https://www.reddit.com/r/EmuDev/comments/w0epiv/are_there_good_booksresourcesguides_on_emulator/)
What I then find is this:

*For simplicity, your emulation loop will probably be:*
- *Fetch opcode and target bytes*
- *Decode breaking the opcode into addressing modes*
- *Have a giant uber switch acting on the opcode with 256 (0x00 .. 0xFF) cases.
- *Execute the instruction*
- *Adjust PC (Program Counter)*
*For the 6502 you'll probably want to break the 56 instruction set down into categories:*
- *Load/Store - LDA, LDX, LDY, STA, STX, STY, TAX, TAY, TXA, TYA*
- *Arithmetic - ADC, SBC, CLC, SEC, INC, DEC, INX, INY, DEX, DEY, CMP, CPY, CPX*
- *Branching - BCC, BCS, BEQ, BNE, BMI, BPL, BVC, BVS*
- *Logic - AND, ORA, EOR*
- *Bit manipulation - ASL, LSR, ROL, ROR, BIT, CLC, SEC*
- *Misc - NOP*
- *Modes - CLD, SED, CLI, SEI, CLV*
- *Stack - PHA, PLA, PHP, PLP*
- *Flow Control - JSR, JMP, RTS, RTI, BRK*
- *Undocumented instructions*

The above is for the 6502 CPU, however, with this, I understand what now what I can start to emulate; the question now
is how do I emulate the CPU?

## Aside stuff
- Learning about memory allocators [What's a Memory Allocator Anyway? - Benjamin Feng](https://www.youtube.com/watch?v=vHWiDx_l4V0)

# Day 3 - 2025 December 6th 2025 8:59AM
So I had to learn some zig, especially around memory allocation strategies.
Very cool watch. Now I gotta get down to writing some code

## Emulating The CPU - Instructions
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

## Hashmaps
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

## Structs and Pointers
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

## Byte Ordering and Endianness
I'm currently implementing the instruction LD BC, d16 with the following description

*Load the 2 bytes of immediate data into register pair BC.*
*The first byte of immediate data is the lower byte (i.e., bits 0-7), and the second byte of*
*immediate data is the higher byte (i.e., bits 8-15).*

So it looks like the following bits are in this order

For example the number 197 base 10 is the binary `11000101`, however this is using the big endian system. Notice that
the most significant byte is the very left number. If we were to use little endian, then the same number would be
in reverse order `10100011`;

## Moving Forward
I think I should read the entirety of the [Game Boy: Complete Technical Reference](https://gekkio.fi/files/gb-docs/gbctr.pdf).
It actually gave good insight to the inner workings of the CPU Core. :p

# Day 4 - 2025 December 7th 2025 9:45AM
Another day trying to implement some more instructions. I'm look at this one
**LD (BC) A** - store the content of register A in the memory location specified
by register pair BC. Maybe I can't implement this yet because I've not implemented
working memory? Or maybe I work on the memory component at the same time so that
I can have a fully working test suite?

I still need some more technical documentation for understanding the inner workings of the gameboy memory map,
and I found this resource [GameBoy Memory Map](http://gameboy.mongenel.com/dmg/asmmemmap.html). Still have to fully
read through it and see how well it goes

# Day 5 - 2025 December 15th 8:42PM
Welp, I haven't touched much of the game boy dev repo. No excuses, but I've been doing
some advent of code (using zig) so that I can be more familiar with other parts of the
language like reading IO from file, arrays, and some other fun stuff

I've been reading some technical docs, and found that there's another technical reference
[*The Pandocs*](https://gbdev.io/pandocs/)

Will be going through this today along side with [GameBoy Memory Map](http://gameboy.mongenel.com/dmg/asmmemmap.html)
to implement memory. From my knowledge of OS, virtual memory is implemented via [page tables and
page frames](https://www.baeldung.com/cs/virtual-pages-page-frames). I wonder how I'll be going to implement that

Oh yea, I also managed to get myself the `.gb` file for tetris. I think it's a good idea to understand and disassemble
this.

# Day 6 - 2025 December 16th 9:40PM
So I only read like an hour-ish yesterday, will try to write some code with array memory. From GameBoy Memory Map, it
has a 16bits addressable memory, how will I emulate that?

# Day 7 - 2025 December 25th 9:54PM
I'm trying to understand how memory and memory address works. I may have the misconception that memory addresses and
their corresponding memory width is like an array that has a bit associated to it. Here's the diagram below.

MemAddr | Stored?
0x0000  | 1
0x0001  | 0
0x0002  | 1
0x0003  | 0
0x0004  | 1
0x0005  | 1
0x0006  | 0
0x0007  | 1

I need to sharpen my understanding, and in doing so I stumbled upon this stackoverflow article about
[How many bytes of data can be stored in a single memory address](https://stackoverflow.com/questions/62867683/how-many-bytes-of-data-can-be-stored-in-a-single-memory-address)
and [What in a computer determines how much memory a memory address holds?](https://superuser.com/questions/692825/what-in-a-computer-determines-how-much-memory-a-memory-address-holds)

So in reality this is a more accurate representation of (physical) memory addresses

MemAddr | Stored?
0x0000  | 10011101
0x0001  | 00001101
0x0002  | 01101001
0x0003  | 10010010
0x0004  | 10010001
0x0005  | 10101010
0x0006  | 00001001
0x0007  | 10010101

So now I have to read through the specs to determine how many bytes a memory location holds. Alas there's no mention
of how many bits/bytes a reference to memory address holds.

# Day 8 - 2025 December 26th 8:34PM
I'm going to attempt to implement the instruction for loading and storing at a memory address now.

**9:18PM**
Reading through the Gameboy complete technical reference - I see that we should probably be reading from the
IR register to determine the instruction

**10:56PM**
Didn't get through too much but trying to understand zig unions and structs again

Total time: 50 minutes

# Day 9 - 2025 December 26th 7.30AM
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

# Day 10 - 2025 December 27th 9.35PM
I've started to read more of the pseudocode from the Complete Technical reference and it's helping a lot more now.
I don't know why I didn't try to read and understand that first...

I think implemented the 8 bits load is pretty doable now.

**Update - completed at December 28th *12:45AM***
I implemented a lot of 8 bit load instructions. Forgot to update this log at least and how many minutes

**Total time: 123 minutes**

# Day 11 - 2025 December 28th 9.45AM
I'll do a lot more load instructions today. I need to get better at time keeping.

Train of thought - why are load instructions much easier to implement? I don't have to worry about the
flags register, and with further understanding memory, reading the operand makes sense.

**Total time: 120 minutes** Still a lot more 8-bit load instructions to go! :D

# Day 11 Part 2 - 2025 December 28th 5:32PM
Just some more load instructions. I've been thinking and reading about how flags register works and came across this
article [Flag register in 8085 microprocessor](https://www.geeksforgeeks.org/computer-organization-architecture/flag-register-8085-microprocessor/)

I'll need to implement flags register as part of the other instructions.

**Total time: 25 minutes**

# Day 12 - 2025 December 29th 9.02AM
And more load instructions today

**Total time: 105 minutes**

# Day 12 Part 2 - 2025 December 28th 6.13PM
More loading 8-bit load instructions still, we're nearly therte

**Total time: 37 minutes**

# Day 13 - 2025 December 30th 9.09AM
Let's lock in, more load instructions, I wanna finish it already...

Total time: 130 minutes

# Day 13 Part 2 - 2025 December 30th 8.40PM
And with that I think I have completed all 8-bit load instructions and with tests :)
Let's just hope I don't have to refactor too much hehe.

Maybe time for 16 bit load instructions?

Total time: 33 minutes

# Day 14 - 2025 December 30th 10.31AM
Let's do a lot more of the 16-bit load instructions :)

It's also going to be my first time implementing and trying to understand the registers flags since I'll have to
implement this instruction 0xf8 - LD HL, SP+s8.

# Day 15 - 2026 January 1st 6.15AM
Happy new year! More 16-bit load instructions

It's going to be my first time implementing and trying to understand the flags register as we'll need to implement
0xf8 - LD HL, SP+s8 - this instruction. It is also a signed integer :O.

Total time 127 minutes

Gotta learn about flag registers [Ep 083: Introduction to the Flags Register](https://www.youtube.com/watch?v=7eaTT8PekE0)
Some more resources [Game boy dealing with carry flags when
handling](https://www.reddit.com/r/EmuDev/comments/y51i1c/game_boy_dealing_with_carry_flags_when_handling/)

# Day 16 - 2026 January 2nd 9.59PM
Trying to impelement addign a signed integer to an unsigned interger based on the LD HL, SP+s8 instruction

A bit stumped but I think I have the resources required.

Just an aside, I've finally understood about [zig's funky syntax](https://www.openmymind.net/Zigs-weird-syntax/#) `(.{}){}`.

And more resources I've found about carry bits
[Gameboy Half Carry](https://www.robm.dev/articles/gameboy-half-carry/)
[game-boy-what-constitutes-a-half-carry](https://stackoverflow.com/questions/8868396/game-boy-what-constitutes-a-half-carry/8874607#8874607)

It's really fun going through the searches and reading them. I can probably find it much quicker through LLM's
but the point of it going through the struggle is to really really think deeply, and struggle through the problem
before getting through a solution.

Total time: 132 minutes

# Day 17 - 2026 January 3rd 9.19AM
Still implementing the LD HL, SP+s8 instruction, trying to find my way around zigs boolean
and u8 type especially it's truthy/falsey values used in an if expression.

Total time: 93 minutes

# Day 18 - 2026 January 4th 1.59PM
Been looking at how to do signed and unsigned arithmetic in zig.
Here's one resource I've come across [adding a signed integer to an unsigned integer](https://ziggit.dev/t/adding-a-signed-integer-to-an-unsigned-integer/5803)
It's mainly got to do with the `LD HL, SP+s8` instruction where we do signed and unsigned arithmetic.

Some other resources
- [what's the simplest way of mixing signedness calculation in zig](https://stackoverflow.com/questions/76293230/whats-the-simple-way-of-mixing-signed-ness-calculation-in-zig)

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

# Day 20 - 2026 January 6th 9.08PM
I want to completely finish implementing `LD HL, SP+s8` instruction tonight!

10.26PM I think I've completed all 8-bit and 16-bit load instructions :D

I've started on 0x18 JR s8 instruction, going to be doing more of the control flow instructions :D

** Total time: 112 minutes**

# Day 21 - 2026 - January 8th 8.13AM
Just playing around with sign extension, `@bitCast()` and `@as()` built in functions,
and I think I've somehow got a good framework and understanding on how to do unsigned
relative offsets now.

**Total time: 120 minutes**

Found this pretty cool resource as well
[Bit Twiddling Hacks](https://graphics.stanford.edu/~seander/bithacks.html)

# Day 22 - 2026 January 10th 9.51PM

[Conditional Jumps and Loops](https://www.tatungbytes.co.uk/z80-module/conditional-jumps-and-loops) Trying to
understand the JR NZ, s8 instruction.

Total time: *60 minutes*

# Day 23 - 2026 January 11th 9.52AM
I did some more control flow instructions, and I am understanding conditional and unconditional jumps a lot more,
along with signed offset from the PC.

Total time: 63 minutes

## Part 2
I've read through some implementations, I'm not sure if that's cheating or not, but I think it's a good way to compare
how different projects have organised their implementation.

Here are some implementations
- [Gearboy](https://github.com/drhelius/Gearboy)
- [Gbemu](https://github.com/isaachier/gbemu/tree/master)

It's also because I believe the way I've implemented the instructions, there's an implicit connection to 
fetching the next instruction from the PC into the IR after every instruction; which now I think is the wrong
implementation after reading through some of the pseudocode.

Likewise with how the registers are implemented in the CPU; they are paired with teh Lo and Hi registers.
Hmmm maybe now is a good time to refactor?

Also I thought I was cool writing hexadecimal with lowercase, but I find it more annoying to read now...
Maybe it's time to refactor aye?

I've started to refactor them now into interesting components, Did I refactor too early? I'm not too sure but we'll see

Total time: 123 minutes

# Day 24 - 2026 January 12th 7.51PM

I guess some more refactoring.

## 11.09PM
And some general programming
- [Dynamic Dispatch](https://en.wikipedia.org/wiki/Dynamic_dispatch);
- [Zig Function Pointers](https://zigtoolbox.com/zig-function-pointers)

Total time: 43 minutes

# Day 25 - 2026 - January 16th 8.20AM

I've been slacking and wanting to tdo something else, but that's okay.
I'm back now to properly refactor things. I'd also like to get some feedback
from the zig community after this refactor.

Total time: 85 minutes

## Part two
Just some more refactoring

Total time: 31 minutes

# Day 26 - 2026 January 18th 7.29PM
More refactoring let's goo.

Total time: 60 minutes

# Day 27 - 2026 January 20th 8.09AM
More refactoring or is it a rewrite?

Total time: 40 minutes

# Day 28 - 2026 January 21st
Still refactoring/rewriting

Total time: 109 minutes

# Day 29 - 2026 January 22nd 5.43AM
More refactoring, but this time I try to oneshot writing and running the tests.
In other words, it needs to pass the first time I write the test and implementation.

Total time: 28 minutes

8.08AM - 8.52AM I guess another 54 minutes? :D

+ 30 minutes

8.59PM - 10.57PM But some breaks 90 minutes

Cumulative time: 202 minutes

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

# Day 31 - 2026 January 24th 10.57AM
Doing some control flow instructions now finally.

10.40PM
I think all control flow instructions are done. Nice.

# Day 32 - 2026 January 25 11.10AM
It's time for 8-bit arithmetic instructions :D

A bit concerned whether my implementation for addOffset is correct, and
whether I'll be able to implement a decent abstraction for addition with carry and half carry for now. But I know that
refactoring will always happen later.

For the first time, I've also asked for a code review of my current code as of the commit previous to this! Thank you
to the zig community in Discord. Looking to also ask around in ziggit. :)

Total time: 124 minutes

# Day 33 - 2026 January 26 10.10AM
Looking at arithmetic logic properly now. Maybe it'll be time to refactor the instructions again from the code review.

Here's one of the recommendation summarised 
A packed struct can be used to represent the encoding of the instruction so we could just bitcast the instructions to
it. It's nice as long as the encoding is not too complex and even then you can use methods for more complex
encodings. For the registers I used an std.EnumArray

Learning about [`anytype`](https://ziglang.org/documentation/0.15.2/#Function-Parameter-Type-Inference) for function
type inference.

Learning about function pointers and dynamic dispatch.

When implementing the half-carry logic for subtraction operation, I wasn't sure how the half-carry was generated. A bit
of searching online lead me to [Gameboy Half Carry flag during subtract operation. ](https://www.reddit.com/r/EmuDev/comments/knm196/gameboy_half_carry_flag_during_subtract_operation/)
in reddit. Now I understand that half-carry regardless of the instruction is just the carry from the 3rd bit to the 4th
regardless of what instruction generated it.

# Day 34 - 2026 January 28 8.10AM
More instructions and more refactoring.

Total time: 50 minutes

9.28PM
More instructions were refactored. I think I refactored all of them that I've initially written.

Total time: 120 minutes

# Day 35 - 2026 Janaury 30th 10.12AM
Doing some more 8-bit arithmetics :D Implemented some of the base for the instructions.
This has been fun after the refactor.

Total time: 80 minutes

# Day 36 - 2026 January 31st 9.47AM

Working on 16-bit arithmetic now

Total time : 40 minutes

# Day 37 - February 3rd 10.39 PM
Finally completed u8 and u16 arithmetic. Pretty cool working with zig comptime.

Total time: 60 minutes.

# Day 38 - 2026 February 4th 8.28AM
Guess finishing off some instructions

Total time: 45 minutes

# Day 39 - 2026 February 9th 12.03PM
I think I've finally completed all 16 bit arithmetic instructions.
Took a while since I've not been prioritising this project. Just losing some motivation, but I want to pick it back up
again.

## 10PM
Finally working on some bit shift operations

Total time: 40 minutes

# Day 40 - 2026 February 10th 12.04PM
Got some more bit shift operations to do

# Day 41 - 2026 February 11th 9.59PM
I did some more instructions during the train and some of my spare time

Total time: 60 minutes

# Day 42 - 2026 February 13th 6.30AM

Refactored shift right arithmetic as my understanding of bit_7 was unfounded. I think I've done the correctly now with
tests too.

Total time:

# Day 43 - 2026 February 14th 7.11AM
Looking and implementing the bit flag instructions. What is a program status word (PSW)?.

Total time: 100 minutes

# Day 44 - 2026 February 15 11.26AM
More bitwise and arithmetic instructions prefixed by CB! Lets goo! 

I think I've done the CB prefixes and all rotates, shifts, and bit operations

2:23 PM
I don't understand how to implement instructions like `STOP` or `HALT` since they dont really change
tangible states in the CPU such as Loading into registers.

[DMG-01: How to Emulate a Game Boy - Finishing Up the
CPU](https://rylev.github.io/DMG-01/public/book/cpu/conclusion.html) I saw that an implementation here merely halts the
CPU, but an actual production grade one from [Gearboy](https://github.com/drhelius/Gearboy/blob/7150a032e0bb4dcd2652d7baacfdfea51c38910d/src/opcodes.cpp#L851-L873)
has other "stuff" which I don't understand :(.

Looks like I've yet to properly learn interrupt flags, and interrupt in general to see how they're used in Gameboy.
[FFF - IE: Interrupt enable](https://gbdev.io/pandocs/Interrupts.html#ffff--ie-interrupt-enable)

Total time: 300 minutes

# Day 45 - 2026 February 16th 9.41PM
Trying to understand the (DAA) [Decimal Adjust Accumulator](https://blog.ollien.com/posts/gb-daa/)
Instruction and stumbled upon this article linked.

Total time: 120 minutes

# Day 46 - 2026 February 18 8.29AM
Tackling DAA instruction for binary coded decimals. It's not as intimidating as I thought it initially was.

Total time: 60 minutes

# Day 47 - 2026 February 20th 7.27AM
Committing the DAA instruciton, I need ot update the tests though.

I really think I should learn more about structure packing, found an interesting article called
[The Lost Art of Structure Packing](http://www.catb.org/esr/structure-packing/) since I remember
from my code review about packed unions, packed structs, as well as enum array.

Total time: 40 minutes

# Day 48 - 2026 February 23rd 7.53AM
I want to do some more refactoring, mainly around using packed unions and using pointers for u8.

And it looks like I now need to look into the [zig build system](https://ziglang.org/learn/build-system/) about modules :)

Total time: 240 minutes

# Day 49 - 2026 February 24 9.29PM

I really need to learn how to structure my zig projects for unit tests. Here's one I found online
[Recommendations for structuring project with library and unit tests](https://ziggit.dev/t/recommendations-for-structuring-project-with-library-and-unit-tests/5745/2)

# Day 50 - 2026 February 26 2.05PM

Did some refactoring/rewriting still with a new module pattern and hopefully tests pattern too.

# Day 51 - 2026 March 2nd 9.33PM
Still refactoring away. It's properly slow now since I'm changing the interface.

# Day 52 - 2026 March 3rd 9.07PM
Still some more refactoring since manually doing stuff takes a while.

Total time: 80 minutes

# Day 53 - 2026 March 6 9.57AM
Really I am still doing a lot of refactor... taking a lot of time. Why did I do it?

# Day 54 - 2026 March 8th 8.59PM
So the past few days I've lacked motivation (essentially I've also been procrastinating trying to complete the
refactor). But after reading some gameboy code for [zigboy](https://github.com/otaleghani/zigboy) I realise how
important machine cycles are for correctness [The Cycle-Accurate Game Boy
Docs](https://github.com/geaz/emu-gameboy/blob/master/docs/The%20Cycle-Accurate%20Game%20Boy%20Docs.pdf)

As a result, I think I'll also be reading this book cover-to-cover where I can. I wish there was a better pdf reader for
text books in my android device. Perhaps this is an app idea that will span years maybe.

Total time: 130 minutes

# Day 55 - 2026 March 10th 5.41PM
Still refactoring but also going through a text book about computer hardware and architecture :)

Total time: 80 minutes

# Day 56 - 2026 March 11th 9.33AM
Still refactoring by adding tests

Total time: 45 minutes

Did some more load instructions tests

Total time: 40 minutes

# Day 57 - 2026 March 12th 10.01PM
Still refactoring, but at least completed the 0xCB prefixs

Total time: 50 minutes

# Day 58 - 2026 March 15th 9.56 AM
Some more refactoring still.

Total time: 30 minutes

