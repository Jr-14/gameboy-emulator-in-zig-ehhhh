# Day 18 - 2026 January 4th 1.59PM
Been looking at how to do signed and unsigned arithmetic in zig.
Here's one resource I've come across [adding a signed integer to an unsigned integer](https://ziggit.dev/t/adding-a-signed-integer-to-an-unsigned-integer/5803)
It's mainly got to do with the `LD HL, SP+s8` instruction where we do signed and unsigned arithmetic.

Some other resources
- [what's the simplest way of mixing signedness calculation in zig](https://stackoverflow.com/questions/76293230/whats-the-simple-way-of-mixing-signed-ness-calculation-in-zig)
