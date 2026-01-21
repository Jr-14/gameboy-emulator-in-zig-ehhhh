const std = @import("std");
const utils = @import("utils.zig");

const Register = @import("register.zig").Register;
const Memory = @import("memory.zig").Memory;

const masks = @import("masks.zig");

const HI_MASK = masks.HI_MASK;
const LO_MASK = masks.LO_MASK;

const Z_MASK = masks.Z_MASK;
const N_MASK = masks.N_MASK;
const H_MASK = masks.H_MASK;
const C_MASK = masks.C_MASK;

pub const Flag = enum {
    Z,
    N,
    H,
    C,
};

pub const Processor = struct {
    AF: Register = .{},
    BC: Register = .{},
    DE: Register = .{},
    HL: Register = .{},
    PC: Register = .{},
    SP: Register = .{},

    memory: *Memory = undefined,

    const Self = @This();

    pub fn init(memory: *Memory) Processor {
        return .{
            .memory = memory,
        };
    }

    // Fetches the next instruction to be executed from the current memory address pointed at by PC
    pub inline fn fetch(self: *Self) u16 {
        const instruction: u16 = self.memory.read(self.PC.value);
        self.PC.increment();
        return instruction;
    }

    pub fn isFlagSet(self: *Self, flag: Flag) bool {
        return switch (flag) {
            .Z => (self.AF.getLo() & Z_MASK) == Z_MASK,
            .N => (self.AF.getLo() & N_MASK) == N_MASK,
            .H => (self.AF.getLo() & H_MASK) == H_MASK,
            .C => (self.AF.getLo() & C_MASK) == C_MASK,
        };
    }

    pub fn setFlag(self: *Self, flag: Flag) void {
        const lo = self.AF.getLo();
        switch (flag) {
            .Z => self.AF.setLo(lo | Z_MASK),
            .N => self.AF.setLo(lo | N_MASK),
            .H => self.AF.setLo(lo | H_MASK),
            .C => self.AF.setLo(lo | C_MASK),
        }
    }

    pub fn unsetFlag(self: *Self, flag: Flag) void {
        const lo = self.AF.getLo();
        switch (flag) {
            .Z => self.AF.setLo(lo & ~Z_MASK),
            .N => self.AF.setLo(lo & ~N_MASK),
            .H => self.AF.setLo(lo & ~H_MASK),
            .C => self.AF.setLo(lo & ~C_MASK),
        }
    }

    pub fn resetFlags(self: *Self) void {
        self.unsetFlag(.Z);
        self.unsetFlag(.H);
        self.unsetFlag(.N);
        self.unsetFlag(.C);
    }

    pub fn decodeAndExecute(self: *Self, instruction: u16) !void {
        // TODO:
        // state all the different instructions for 8-bit opcodes
        //
        // TODO:
        // Look at 16-bit opcodes? Is this required?
        switch (instruction) {
            // NOP (No operation) Only advances the program counter by 1.
            // Performs no other operations that would have an effect
            0x00 => {},

            // LD BC, d16
            // Load the 2 bytes of immediate data into register pair BC
            // The first byte of immediate data is the lower byte (i.e. bits 0-7), and
            // the second byte of immediate data is the higher byte (i.e., bits 8-15)
            0x01 => {
                self.BC.setLo(self.memory.read(self.PC.get()));
                self.PC.increment();
                self.BC.setHi(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // LD (BC), A
            // Store the contents of register A in the memory location specified by
            // register pair BC
            // TODO:
            // I may need to swap endianness as the CPU is little endian
            0x02 => self.memory.write(self.BC.get(), self.AF.getHi()),

            // INC BC
            // Increment the contents of register pair BC by 1
            0x03 => self.BC.increment(),

            // INC B
            // Increment the contents of register B by 1.
            // TODO:
            // This has some flags? e.g. Z 0 8-bit -
            // 0x04 => {
            //     register.B += 1;
            //     register.PC += 1;
            // },

            // DEC B
            // Decrement the contents of register B by 1
            // TODO:
            // Flags: Z 1 8-bit -
            // 0x05 => {
            //     register.B -= 1;
            //     register.PC += 1;
            // },

            // LD B, d8
            // Load the 8-bit immediate operand d8 into register B.
            0x06 => {
                self.BC.setHi(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // Rotate the contents of register A to the left. That is, the contents of bit 0
            // are copied to bit 1, and the previous contents of bit 1 (before the copy operation)
            // are copied to bit 2. The same operation is repeated in sequence for the rest
            // of the register. The contents of bit 7 are placed in both the CY flag and bit 0 of
            // register A.
            // TODO:
            // Flags: 0 0 0 A7
            // 0x07 => "RLCA",

            // // LD (a16), SP
            // // Store the lower byte of stack pointer SP at the address specified by the 16-bit
            // // immediate operand 16, and store the upper byte of SP at address a16 + 1.
            0x08 => {
                var z: u16 = self.memory.read(self.PC.get());
                self.PC.increment();
                z |= (@as(u16, self.memory.read(self.PC.get())) << 8);
                self.PC.increment();

                const sp_lsb: u8 = @truncate(self.SP.get() & LO_MASK);
                const sp_msb: u8 = @truncate((self.SP.get() & HI_MASK) >> 8);
                self.memory.write(z, sp_lsb);
                self.memory.write(z + 1, sp_msb);
            },

            // Add the contents of register pair BC to the contents of register pair HL, and
            // store the results in register pair HL.
            // TODO:
            // Flags: - 0 16-bit 16-bit
            // 0x09 => "ADD HL, BC",

            // LD A, (BC)
            // Load the 8-bit contents of memory specified by register pair BC into register A.
            0x0A => {
                self.AF.setHi(self.memory.read(self.BC.get()));
                self.PC.increment();
            },

            // Decrement the contents of register pair BC by 1.
            // 0x0b => "DEC BC",

            // Increment the contents of register C by 1.
            // TODO:
            // Flags: Z 0 8-bit -
            // 0x0c => "INC C",

            // Decrement the contents of register C by 1
            // TODO:
            // Flags: Z 1 8-bit -
            // 0x0d => "DEC C",

            // LD C, d8
            // Load the 8-bit immediate operand d8 into register C
            0x0E => {
                self.BC.setLo(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // Rotate the contents of register A to the right. That is, the contents of bit 7 are
            // copied to bit 6, and the previous contents of bit 6 (before the copy) are copied to
            // bit 5. The same operation is repeated in sequence for the rest of the register. The
            // contents of bit 0 are placed in both the CY flag and bit 7 are register A.
            // TODO:
            // Flags: 0 0 0 A0
            // 0x0f => "RRCA",

            // Execution of a STOP instruction stops both the system clock and oscillator circuit.
            // STOP mode is entered and the LCD controller also stops. However, the status of the
            // internal RAM register ports remains unchanged.
            //
            // STOP mode can be canelled by a reset signal
            //
            // If the rRESET terminal goes LOW in STOP mode, it becomes that of a normal reset status.
            //
            // THe following conditions should be met before a STOP instruction is executed and stop
            // mode is entered:
            // - All interrupt-enable (IE) flags are reset.
            // - Input to P10-P13 is LOW for all.
            // 0x10 => "STOP",

            // LD DE, d16
            // Load the 2 bytes of immediate data into register pair DE.
            // The first byte of immediate data is the lower byte (i.e., bit 0-7), and the second byte
            // of immediate data is the higher byte (i.e., bits 8-15)
            0x11 => {
                self.DE.setLo(self.memory.read(self.PC.get()));
                self.PC.increment();
                self.DE.setHi(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // LD (DE), A
            // Store the contents of register A in the memory location specified by register pair DE.
            0x12 => self.memory.write(self.DE.get(), self.AF.getHi()),


            // Increment the contents of register pair DE by 1.
            // 0x13 => "INC DE",

            // Increment the contents of register D by 1.
            // TODO:
            // Flags: Z 0 8-bit -
            // 0x14 => "INC D",

            // Decremenet the contents of register D by 1.
            // TODO:
            // Flags: Z 1 8-bit -
            // 0x15 => "DEC D",

            // LD D, d8
            // Load the 8-bit immediate operand d8 into register D.
            0x16 => {
                self.DE.setHi(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // Rotate the contents of register A to the left, through the carry (CY) flag. That is, the
            // contents of bit 0 are copied to bit 1, and the previous contents of bit 1 (before the copy
            // operation) are copied to bit 2. The same operation is repeated in sequence for the rest of
            // the register. The previous contents of the carry flag are copied to bit 0.
            // TODO:
            // Flags: 0 0 0 A7
            // 0x17 => "RLA",

            // JR s8
            // Jump s8 steps from the current address in the program counter (PC). (Jump relative.)
            0x18 => {
                const offset = self.memory.read(self.PC.get());
                self.PC.increment();
                const address: u16 = utils.addOffset(self.PC.get(), offset);
                self.PC.set(address);
            },

            // Add the contents of register pair DE to the contents of register pair HL, and store the results
            // in register pair HL.
            // TODO:
            // Flags: - 0 16-bit 16-bit
            // 0x19 => "ADD HL, DE",

            // JR NZ, s8
            // If the Z flag is 0, jump s8 steps from the current address stored in the program counter (PC). If not, the
            // instruction following the current JP instruction is executed (as usual).
            0x20 => {
                const offset: u8 = self.memory.read(self.PC.get());
                self.PC.increment();
                if (!self.isFlagSet(.Z)) {
                    self.PC.set(utils.addOffset(self.PC.get(), offset));
                }
            },

            // LD HL, d16
            // Load the 2 bytes of immediate data into register pair HL.
            // The first byte of immediate data is the lower byte (i.e., bits 0-7), and the second byte of immediate data
            // is the higher byte (i.e., bits 8-15)
            0x21 => {
                self.HL.setLo(self.memory.read(self.PC.get()));
                self.PC.increment();
                self.HL.setHi(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // JR Z, s8
            // If the Z flag is 1, jump s8 steps from the current address stored in the program counter (PC). If not, the
            // instruction following the current JP instruction is executed (as usual).
            0x28 => {
                const offset: u8 = self.memory.read(self.PC.get());
                self.PC.increment();
                if (self.isFlagSet(.Z)) {
                    self.PC.set(utils.addOffset(self.PC.get(), offset));
                }
            },

            // JR NC, s8
            // If the CY flag is 0, jump s8 steps from the current address stored in the program counter (PC). If not, the
            // instruction following the current JP instruction is executed (as usual).
            0x30 => {
                const offset: u8 = self.memory.read(self.PC.get());
                self.PC.increment();
                if (!self.isFlagSet(.C)) {
                    self.PC.set(utils.addOffset(self.PC.get(), offset));
                }
            },

            // JR C, s8
            // IF the CY flag is 1, jump s8 steps from the current address stored in the program counter (PC). If not, the
            // instruction following the current JP instruction is executed (as usual).
            0x38 => {
                const offset: u8 = self.memory.read(self.PC.get());
                self.PC.increment();
                if(self.isFlagSet(.C)) {
                    self.PC.set(utils.addOffset(self.PC.get(), offset));
                }
            },

            // LD A, (DE)
            // Load the 8-bit contents of memory specified by register pair DE into register A.
            0x1A => self.AF.setHi(self.memory.read(self.DE.get())),

            // Decrement the contents of register pair DE by 1.
            // 0x1b => "DEC DE",

            // Incremenet the contents of register E by 1.
            // 0x1c => "INC E",

            // Decremenet the contents of register E by 1.
            // TODO:
            // Flags: Z 1 8-bit -
            // 0x1d => "DEC E",

            // LD E, d8
            // Load the 8-bit immediate operand d8 into register E.
            0x1E => {
                self.DE.setLo(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // Rotate the contents of register A to the right, through the carry (CY) flag. That is, the contents
            // of bit 7 are copied to bit 6, and the previous contents of bit 6 (before the copy) are copied to bit
            // 5. The same operation is repeated in sequence for the rest of the register. The previous contents of
            // the carry flag are copied to bit 7.
            // 0x1f => "RRA",

            // LD (HL+), A
            // Store the contents of register A into the memory location specified by register pair
            // HL, and simultaneously increment the contents of HL
            0x22 => {
                self.memory.write(self.HL.get(), self.AF.getHi());
                self.HL.increment();
            },

            // LD H, d8
            // Load the 8-bit immediate operand d8 into register H.
            0x26 => {
                self.HL.setHi(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // LD A, (HL+)
            // Load the contents of memory specified by register pair HL into register A, and simultaneously
            // increment the contents of HL.
            0x2A => {
                self.AF.setHi(self.memory.read(self.HL.get()));
                self.HL.increment();
            },

            // LD L, d8
            // Load the 8-bit immediate operand d8 into register L.
            0x2E => {
                self.HL.setLo(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // LD SP, d16
            // Load the 2 bytes of immediate data into register pair SP.
            // The first byte of immedaite data is the lower byte (i.e., bits 0-7), and the second byte of immediate data
            // is the higher byte (i.e., bits 8-15).
            0x31 => {
                self.SP.setLo(self.memory.read(self.PC.get()));
                self.PC.increment();
                self.SP.setHi(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // LD (HL-), A
            // Store the contents of register A into the memory location specified by register pair
            // HL, and simultaneously decrement the contents of HL.
            0x32 => {
                self.memory.write(self.HL.get(), self.AF.getHi());
                self.HL.decrement();
            },

            // LD (HL), d8
            // Store the contents of 8-bit immediate operand d8 in the memory location
            // specified by register pair HL.
            0x36 => {
                self.memory.write(self.HL.get(), self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // LD A, (HL-)
            // Load the contents of memory specified by register pair HL into register A, and
            // simultaneously decrement the contents of HL.
            0x3A => {
                self.AF.setHi(self.memory.read(self.HL.get()));
                self.HL.decrement();
            },

            // LD A, d8
            // Load the 8-bit immediate operand d8 into register A.
            0x3E => {
                self.AF.setHi(self.memory.read(self.PC.get()));
                self.PC.increment();
            },

            // LD B, B
            // Load the contents of register B into register B
            // What's the point?? weird
            0x40 => {
                self.BC.setHi(self.BC.getHi());
            },
            //
            // // LD B, C
            // // Load the contents of register C into register B.
            // 0x41 => {
            //     register.B = register.C;
            //     register.PC += 1;
            // },
            //
            // // LD B, D
            // // Load the contents of register D into register B.
            // 0x42 => {
            //     register.B = register.D;
            //     register.PC += 1;
            // },
            //
            // // LD B, E
            // // Load the contents of register E into register B.
            // 0x43 => {
            //     register.B = register.E;
            //     register.PC += 1;
            // },
            //
            // // LD B, H
            // // Load the contents of register H into register B.
            // 0x44 => {
            //     register.B = register.H;
            //     register.PC += 1;
            // },
            //
            // // LD B, L
            // // Load the contents of register L into register B.
            // 0x45 => {
            //     register.B = register.L;
            //     register.PC += 1;
            // },
            //
            // // LD B, (HL)
            // // Load the 8-bit contents of memory specified by register pair HL
            // // into register B.
            // 0x46 => {
            //     register.B = memory.get(register.getHL());
            //     register.PC += 1;
            // },
            //
            // // LD B, A
            // // Load the contents of register A into register B.
            // 0x47 => {
            //     register.B = register.A;
            //     register.PC += 1;
            // },
            //
            // // LD C, B
            // // Load the contents of register B into register C.
            // 0x48 => {
            //     register.C = register.B;
            //     register.PC += 1;
            // },
            //
            // // LD C, C
            // // Load the contents of register C into register C.
            // 0x49 => {
            //     register.C = register.C;
            //     register.PC += 1;
            // },
            //
            // // LD C, D
            // // Load the contents of register D into register C.
            // 0x4a => {
            //     register.C = register.D;
            //     register.PC += 1;
            // },
            //
            // // LD C, E
            // // Load the contents of register E into register C.
            // 0x4b => {
            //     register.C = register.E;
            //     register.PC += 1;
            // },
            //
            // // LD C, H
            // // Load the contents of register H into register C.
            // 0x4c => {
            //     register.C = register.H;
            //     register.PC += 1;
            // },
            //
            // // LD C, L
            // // Load the contents of register L into register C.
            // 0x4d => {
            //     register.C = register.L;
            //     register.PC += 1;
            // },
            //
            // // LD C, (HL)
            // // Load the 8-bit contents of memory specified by register pair HL
            // // into register C.
            // 0x4e => {
            //     register.C = memory.get(register.getHL());
            //     register.PC += 1;
            // },
            //
            // // LD C, A
            // // Load the contents of register A into register C.
            // 0x4f => {
            //     register.C = register.A;
            //     register.PC += 1;
            // },
            //
            // // LD D, B
            // // Load the contents of register B into register D.
            // 0x50 => {
            //     register.D = register.B;
            //     register.PC += 1;
            // },
            //
            // // LD D, C
            // // Load the contents of register C into register D.
            // 0x51 => {
            //     register.D = register.C;
            //     register.PC += 1;
            // },
            //
            // // LD D, D
            // // Load the contents of register D into register D.
            // 0x52 => {
            //     register.D = register.D;
            //     register.PC += 1;
            // },
            //
            // // LD D, E
            // // Load the contents of register E into register D.
            // 0x53 => {
            //     register.D = register.E;
            //     register.PC += 1;
            // },
            //
            // // LD D, H
            // // Load the contents of register H into register D.
            // 0x54 => {
            //     register.D = register.H;
            //     register.PC += 1;
            // },
            //
            // // LD D, L
            // // Load the contents of register L into register D.
            // 0x55 => {
            //     register.D = register.L;
            //     register.PC += 1;
            // },
            //
            // // LD D, (HL)
            // // Load the 8-bit contents of memory specified by register pair HL into register D.
            // 0x56 => {
            //     register.D = memory.get(register.getHL());
            //     register.PC += 1;
            // },
            //
            // // LD D, A
            // // Load the contents of register A into register D.
            // 0x57 => {
            //     register.D = register.A;
            //     register.PC += 1;
            // },
            //
            // // LD E, B
            // // Load the contents of register B into register E.
            // 0x58 => {
            //     register.E = register.B;
            //     register.PC += 1;
            // },
            //
            // // LD E, C
            // // Load the contents of register C into register E.
            // 0x59 => {
            //     register.E = register.C;
            //     register.PC += 1;
            // },
            //
            // // LD E, D
            // // Load the contents of register D into register E.
            // 0x5a => {
            //     register.E = register.D;
            //     register.PC += 1;
            // },
            //
            // // LD E, E
            // // Load the contents of register E into register E.
            // 0x5b => {
            //     register.E = register.E;
            //     register.PC += 1;
            // },
            // 
            // // LD E, H
            // // Load the contents of register H into register E.
            // 0x5c => {
            //     register.E = register.H;
            //     register.PC += 1;
            // },
            //
            // // LD E, L
            // // Load the contents of register L into register E.
            // 0x5d => {
            //     register.E = register.L;
            //     register.PC += 1;
            // },
            //
            // // LD E, (HL)
            // // Load the 8-bit contents of memory specified by register pair HL
            // // into register E.
            // 0x5e => {
            //     register.E = memory.get(register.getHL());
            //     register.PC += 1;
            // },
            //
            // // LD E, A
            // // Load the contents of register A into register E.
            // 0x5f => {
            //     register.E = register.A;
            //     register.PC += 1;
            // },
            //
            // // LD H, B
            // // Load the contents of register B into register H.
            // 0x60 => {
            //     register.H = register.B;
            //     register.PC += 1;
            // },
            //
            // // LD H, C
            // // Load the contents of register C into register H.
            // 0x61 => {
            //     register.H = register.C;
            //     register.PC += 1;
            // },
            //
            // // LD H, D
            // // Load the contents of register D into register H.
            // 0x62 => {
            //     register.H = register.D;
            //     register.PC += 1;
            // },
            //
            // // LD H, E
            // // Load the contents of register E into register H.
            // 0x63 => {
            //     register.H = register.E;
            //     register.PC += 1;
            // },
            //
            // // LD H, H
            // // Load the contents of register H into register H.
            // 0x64 => {
            //     register.H = register.H;
            //     register.PC += 1;
            // },
            //
            // // LD H, L
            // // Load the contents of register L into register H.
            // 0x65 => {
            //     register.H = register.L;
            //     register.PC += 1;
            // },
            //
            // // LD H, (HL)
            // // Load the 8-bit contents of memory specified by register pair HL
            // // into register H.
            // 0x66 => {
            //     register.H = memory.get(register.getHL());
            //     register.PC += 1;
            // },
            //
            // // LD H, A
            // // Load the contents of register A into register H.
            // 0x67 => {
            //     register.H = register.A;
            //     register.PC += 1;
            // },
            //
            // // LD L, B
            // // Load the contents of register B into register L.
            // 0x68 => {
            //     register.L = register.B;
            //     register.PC += 1;
            // },
            //
            // // LD L, C
            // // Load the contents of register C into register L.
            // 0x69 => {
            //     register.L = register.C;
            //     register.PC += 1;
            // },
            //
            // // LD L, D
            // // Load the contents of register D into register L.
            // 0x6a => {
            //     register.L = register.D;
            //     register.PC += 1;
            // },
            //
            // // LD L, E
            // // Load the contents of register E into register L.
            // 0x6b => {
            //     register.L = register.E;
            //     register.PC += 1;
            // },
            //
            // // LD L, H
            // // Load the contents of register H into register L.
            // 0x6c => {
            //     register.L = register.H;
            //     register.PC += 1;
            // },
            //
            // // LD L, L
            // // Load the contents of register L into register L.
            // 0x6d => {
            //     register.L = register.L;
            //     register.PC += 1;
            // },
            //
            // // LD L, (HL)
            // // Load the 8-bit contents of memory specified by register pair HL
            // // into register L.
            // 0x6e => {
            //     register.L = memory.get(register.getHL());
            //     register.PC += 1;
            // },
            //
            // // LD L, A
            // // Load the contents of register A into register L.
            // 0x6f => {
            //     register.L = register.A;
            //     register.PC += 1;
            // },
            //
            // // LD (HL), B
            // // Store the contents of register B in the memory location specified by
            // // register pair HL.
            // 0x70 => {
            //     memory.set(register.getHL(), register.B);
            //     register.PC += 1;
            // },
            //
            // // LD (HL), C
            // // Store the contents of register C in the memory location specified by
            // // register pair HL.
            // 0x71 => {
            //     memory.set(register.getHL(), register.C);
            //     register.PC += 1;
            // },
            //
            // // LD (HL), D
            // // Store the contents of register D in the memory location specified by
            // // register pair HL.
            // 0x72 => {
            //     memory.set(register.getHL(), register.D);
            //     register.PC += 1;
            // },
            //
            // // LD (HL), E
            // // Store the contents of register E in the memory location specified by
            // // register pair HL.
            // 0x73 => {
            //     memory.set(register.getHL(), register.E);
            //     register.PC += 1;
            // },
            //
            // // LD (HL), H
            // // Store the contents of register H in the memory location specified by
            // // register pair HL.
            // 0x74 => {
            //     memory.set(register.getHL(), register.H);
            //     register.PC += 1;
            // },
            //
            // // LD (HL), L
            // // Store the contents of register L in the memory location specified by
            // // register pair HL.
            // 0x75 => {
            //     memory.set(register.getHL(), register.L);
            //     register.PC += 1;
            // },
            //
            // // HALT
            // // TODO
            // // 0x76 => {},
            //
            // // LD (HL), A
            // // Store the contents of register A in the memory location specified by
            // // register pair HL.
            // 0x77 => {
            //     memory.set(register.getHL(), register.A);
            //     register.PC += 1;
            // },
            //
            // // LD A, B
            // // Load the contents of register B into register A.
            // 0x78 => {
            //     register.A = register.B;
            //     register.PC += 1;
            // },
            //
            // // LD A, C
            // // Load the contents of register C into register A.
            // 0x79 => {
            //     register.A = register.C;
            //     register.PC += 1;
            // },
            //
            // // LD A, D
            // // Load the contents of register D into register A.
            // 0x7a => {
            //     register.A = register.D;
            //     register.PC += 1;
            // },
            //
            // // LD A, E
            // // Load the contents of register E into register A.
            // 0x7b => {
            //     register.A = register.E;
            //     register.PC += 1;
            // },
            //
            // // LD A, H
            // // Load the contents of register H into register A.
            // 0x7c => {
            //     register.A = register.H;
            //     register.PC += 1;
            // },
            //
            // // LD A, L
            // // Load the contents of register L into register A.
            // 0x7d => {
            //     register.A = register.L;
            //     register.PC += 1;
            // },
            //
            // // LD A, (HL)
            // // Load the 8-bit contents of memory specified by register pair HL
            // // into register A.
            // 0x7e => {
            //     register.A = memory.get(register.getHL());
            //     register.PC += 1;
            // },
            //
            // // LD A, A
            // // Load the contents of register A into register A.
            // 0x7f => {
            //     register.A = register.A;
            //     register.PC += 1;
            // },
            //
            // // RET NZ
            // // If the Z flag is 0, control is returned to the source program by popping from the memory stack the program
            // // counter PC value that was pushed to the stack when the subroutine was called.
            // //
            // // The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC, and
            // // the contents of SP are incremented by 1. The contents of the address specified by the new SP value are then
            // // loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again. (The value of SP
            // // is 2 larger than before instruction execution.) The next instruction is fetched from the address specified
            // // by the content of PC (as usual).
            // 0xc0 => {
            //     //                              ZNHC
            //     const z: bool = (register.F & 0b1000_0000) == 0b1000_0000;
            //     if (!z) {
            //         const y: u8 = memory.get(register.SP);
            //         register.SP += 1;
            //         const x: u8 = memory.get(register.SP);
            //         register.SP += 1;
            //         const xy: u16 = (@as(u16, @bitCast(x)) << 8) | y;
            //         register.PC = memory.get(xy);
            //     } else {
            //         register.PC += 1;
            //     }
            // },
            //
            // // POP BC
            // // Pop the contents from the memory stack into register pair BC by doing the following:
            // // 1. Load the contents of memory specified by stack pointer SP into the lower portion of BC.
            // // 2. Add 1 to SP and load the contents from the new memory location into the upper portion BC.
            // // 3. By the end, SP should be 2 more than its initial value.
            // 0xc1 => {
            //     register.C = memory.get(register.SP);
            //     register.SP += 1;
            //     register.B = memory.get(register.SP);
            //     register.SP += 1;
            //     register.PC += 1;
            // },
            //
            // // PUSH BC
            // // Push the contents of register pair BC onto the memory stack by doing the following:
            // // 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of register pair
            // // BC on on the stack.
            // // 2. Subtract 1 from SP, and put the lower portion of register pair BC on the stack.
            // 0xc5 => {
            //     register.SP -= 1;
            //     memory.set(register.SP, register.B);
            //     register.SP -= 1;
            //     memory.set(register.SP, register.C);
            //     register.PC += 1;
            // },
            //
            // // POP DE
            // // Pop the contents from the memory stack into register pair DE by doing the following:
            // // 1. Load the contents of memory specified by stack pointer SP into the lower portion of DE.
            // // 2. Add 1 to SP and load the contents from the new memory location into the upper portion of DE.
            // // 3. By the end, SP should be 2 more than its initial value.
            // 0xd1 => {
            //     register.E = memory.get(register.SP);
            //     register.SP += 1;
            //     register.D = memory.get(register.SP);
            //     register.SP += 1;
            //     register.PC += 1;
            // },
            //
            // // PUSH DE
            // // Push the contents of register pair DE onto the memory stack by doing the following:
            // // 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of regiser pair DE on
            // // the stack.
            // // 2. Subtract 1 from SP, and put the lower portion of register pair DE on the stack.
            // // 3. By the end, SP should be 2 less than its initial value.
            // 0xd5 => {
            //     register.SP -= 1;
            //     memory.set(register.SP, register.D);
            //     register.SP -= 1;
            //     memory.set(register.SP, register.E);
            //     register.PC += 1;
            // },
            //
            // // LD (a8), A
            // // Load to the address specified by the 8-bit immediate data a8, data from the 8-bit A register. The full
            // // 16-bit absolute address is obtained by setting the most significant byte to 0xff and the least significant
            // // byte to the value of a8, so the possible range is 0xff00-0xffff.
            // 0xe0 => {
            //     register.PC += 1;
            //     const z: u16 = @as(u16, 0xff00) | memory.get(register.PC);
            //     memory.set(z, register.A);
            //     register.PC += 1;
            // },
            //
            // // POP HL
            // // Pop the contents from the memory stack into register pair HL by doing the following:
            // // 1. Load the contents of memory specified by stack pointer SP into the lower portion of HL.
            // // 2. Add 1 to SP and load the contents from thew new memory location into the upper portion of HL.
            // // 3. By the end, SP should be 2 more than its initial value.
            // 0xe1 => {
            //     register.L = memory.get(register.SP);
            //     register.SP += 1;
            //     register.H = memory.get(register.SP);
            //     register.SP += 1;
            //     register.PC += 1;
            // },
            //
            // // PUSH HL
            // // Push the contents of register pair HL onto the memory stack by doing the following:
            // // 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of register pair
            // // HL on the stack.
            // // 2. Subtract 1 from SP, and put the lower portion of register pair HL on the stack.
            // // 3. By the end, SP should be 2 less than its initial value.
            // 0xe5 => {
            //     register.SP -= 1;
            //     memory.set(register.SP, register.H);
            //     register.SP -= 1;
            //     memory.set(register.SP, register.L);
            //     register.PC += 1;
            // },
            //
            // // LD (C), A
            // // Load to the address specified by the 8-bit C register, data from the 8-bit A register. The full 16-bit
            // // address is obtained by setting the most significant byte to 0xff and the least significant byte to the
            // // value of C, so the possible range is 0xff00-0xffff.
            // 0xe2 => {
            //     const z: u16 = @as(u16, 0xff00) | register.C; 
            //     memory.set(z, register.A);
            //     register.PC += 1;
            // },
            //
            // // LD (a16), A
            // // Store the contents of register A in the internal RAM or register specified by the 16-bit immediate
            // // operand a16.
            // 0xea => {
            //     register.PC += 1;
            //     var z: u16 = @as(u16, memory.get(register.PC)) << 8;
            //
            //     register.PC += 1;
            //     z |= memory.get(register.PC);
            //
            //     memory.set(z, register.A);
            //     register.PC += 1;
            // },
            //
            // // LD A, (a8)
            // // Load to the 8-bit A register, data from the address specified by the 8-bit immediate data a8. The full
            // // 16-bit absolute address is obtained by setting the most significant byte to 0xff and the least
            // // significant byte to the value of a8, so the possible range is 0xff0-0xffff.
            // 0xf0 => {
            //     register.PC += 1;
            //     const z: u16 = @as(u16, 0xff00) | memory.get(register.PC);
            //     register.A = memory.get(z);
            //     register.PC += 1;
            // },
            //
            // // POP AF
            // // Pop the contents from the memory stack into register pair AF by doing the following:
            // // 1. Load the contents of memory specified by stack pointer SP into the lower portion of AF.
            // // 2. Add 1 to SP and load the contents from the new memory location into the upper portion AF.
            // // 3. By the end, SP should be 2 more than its initial value.
            // 0xf1 => {
            //     register.F = memory.get(register.SP);
            //     register.SP -= 1;
            //     register.A = memory.get(register.SP);
            //     register.SP -= 1;
            //     register.PC += 1;
            // },
            //
            // // LD A, (C)
            // // Load to the 8-bit A register, data from the address specified by the 8-bit C register. The full 16-bit
            // // address is obtianed by setting the most significant byte to 0xff and the least significant byte to the
            // // value of C, so the possible range is 0xff00-0xffff.
            // 0xf2 => {
            //     const z: u16 = @as(u16, 0xff00) | register.C;
            //     register.A = memory.get(z);
            //     register.PC += 1;
            // },
            //
            // // PUSH AF
            // // Push the contents of register pair AF onto the memory stack by doing the following:
            // // 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of register pair
            // // BC on on the stack.
            // // 2. Subtract 1 from SP, and put the lower portion of register pair AF on the stack.
            // 0xf5 => {
            //     register.SP -= 1;
            //     memory.set(register.SP, register.A);
            //     register.SP -= 1;
            //     memory.set(register.SP, register.F);
            //     register.PC += 1;
            // },
            //
            // // LD HL, SP+s8
            // // Add the 8-bit signed operand s8 (values -128 to +127) to the stack pointer SP, and
            // // store the result in register pair HL.
            // 0xf8 => {
            //     register.PC += 1;
            //     const imm: u8 = memory.get(register.PC);
            //     const lsb: u8 = @truncate(register.SP & 0x00ff);
            //     _, const ov: u1 = @addWithOverflow(imm, lsb);
            //     register.F = 0;
            //
            //     // Half carry
            //     const hc: u8 =  if ((((lsb & 0b1111) + (imm & 0b1111)) & 0b1_0000) == 0b1_0000) 0b0010_0000 else 0;
            //     // Carry
            //     const c: u8 = if (ov == 1) 0b0001_0000 else 0;
            //     register.F |= (hc | c);
            //
            //     const s_imm: i8 = @bitCast(imm);
            //     const s_sp: i16 = @bitCast(register.SP);
            //     const res: u16 = @bitCast(s_sp + @as(i16, s_imm));
            //
            //     register.H = @truncate(res >> 8);
            //     register.L = @truncate(res);
            //     register.PC += 1;
            // },
            //
            // // LD SP, HL
            // // Load the contents of register pair HL into the stack pointer SP.
            // 0xf9 => {
            //     register.SP = register.getHL();
            //     register.PC += 1;
            // },
            //
            // // LD A, (a16)
            // // Load to the 8-bit A register, data from the absolute address specified by the 16-bit operand (a16).
            // 0xfa => {
            //     register.PC += 1;
            //     var z: u16 = @as(u16, memory.get(register.PC)) << 8;
            //
            //     register.PC += 1;
            //     z |= memory.get(register.PC);
            //
            //     register.A = memory.get(z);
            //     register.PC += 1;
            // },

            // TODO
            // We have to throw an error here to be exhaustive and have the correct error handling
            else => self.PC.increment(),
        }
    }
};

const expectEqual = std.testing.expectEqual;

test "isFlagSet, Z" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.AF.set(Z_MASK);

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "isFlagSet, N" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.AF.set(N_MASK);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "isFlagSet, H" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.AF.set(H_MASK);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "isFlagSet, C" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.AF.set(C_MASK);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "setFlag, Z" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.setFlag(.Z);

    try expectEqual(true,  processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "setFlag, N" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.setFlag(.N);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "setFlag, H" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.setFlag(.H);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}

test "setFlag, C" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.setFlag(.C);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(true,  processor.isFlagSet(.C));
}

test "unsetFlag, Z" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.setFlag(.Z);
    processor.setFlag(.N);
    processor.setFlag(.H);
    processor.setFlag(.C);

    processor.unsetFlag(.Z);

    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "unsetFlag, N" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.setFlag(.Z);
    processor.setFlag(.N);
    processor.setFlag(.H);
    processor.setFlag(.C);

    processor.unsetFlag(.N);

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "unsetFlag, H" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.setFlag(.Z);
    processor.setFlag(.N);
    processor.setFlag(.H);
    processor.setFlag(.C);

    processor.unsetFlag(.H);

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));
    try expectEqual(true, processor.isFlagSet(.C));
}

test "unsetFlag, C" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    processor.setFlag(.Z);
    processor.setFlag(.N);
    processor.setFlag(.H);
    processor.setFlag(.C);

    processor.unsetFlag(.C);

    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
    try expectEqual(false, processor.isFlagSet(.C));
}
