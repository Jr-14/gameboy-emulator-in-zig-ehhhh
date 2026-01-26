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
