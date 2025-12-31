# Day 14 - December 30th 10.31AM
Let's do a lot more of the 16-bit load instructions :)

The instruction doesn't really tell you which operand is the lower byte and which operand is the upper byte
for a 16-bit address, but reading the pseudocode has helped determine this. E.g. for the instruction LD (nn), SP
from the Game Boy: Complete Technical reference (or if reading the interactive opcode LD (a16), SP)


```
# M2
if IR == 0x08:
    Z = read_memory(addr=PC); PC = PC + 1
    # M3
    W = read_memory(addr=PC); PC = PC + 1
    # M4
    write_memory(addr=WZ, data=lsb(SP)); WZ = WZ + 1
    # M5
    write_memory(addr=WZ, data=msb(SP))
    # M6/M1
    IR, intr = fetch_cycle(addr=PC); PC = PC + 1
```

We can determine the `Z` is the least significant byte and `W` the most significant byte respectively and thus
the first and second operand follow this.

**Total time: 110 minutes**
