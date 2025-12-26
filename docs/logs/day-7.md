# Day 7 - December 25th 9:54PM
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
