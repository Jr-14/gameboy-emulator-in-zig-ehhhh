# Day 23 - 2026 January 11th 9.52AM
I did some more control flow instructions, and I am understanding conditional and unconditional jumps a lot more,
along with signed offset from the PC.

Total time: 63 minutes

# Part 2
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
