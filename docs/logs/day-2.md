# Day 2 - December 5th 2025 8:44PM
Maybe it makes sense to also log how many minutes I've spent on this repository.
However, there are also times spent outside of this repository for example, reading
documentation on the train about the full technical documentation for the GameBoy.
But for now it makes sense to log when I sit down in front of my device to code,
or work on the repository.

# Where was I?
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

# Aside stuff
- Learning about memory allocators [What's a Memory Allocator Anyway? - Benjamin Feng](https://www.youtube.com/watch?v=vHWiDx_l4V0)
