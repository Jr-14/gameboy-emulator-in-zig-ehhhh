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
