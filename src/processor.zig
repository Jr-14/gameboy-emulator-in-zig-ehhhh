const std = @import("std");
const utils = @import("utils.zig");

const Register = @import("register.zig");
const Memory = @import("memory.zig");
const Flag = Register.Flag;
const instructions = @import("instruction.zig");

const masks = @import("masks.zig");

const HI_MASK = masks.HI_MASK;
const LO_MASK = masks.LO_MASK;

const Z_MASK = masks.Z_MASK;
const N_MASK = masks.N_MASK;
const H_MASK = masks.H_MASK;
const C_MASK = masks.C_MASK;

pub const Processor = struct {
    AF: Register = .{},
    BC: Register = .{},
    DE: Register = .{},
    HL: Register = .{},
    PC: Register = .{},
    SP: Register = .{},

    // Interupt Master Enable Flag
    IME: bool = false,

    memory: *Memory = undefined,

    const Self = @This();

    pub fn init(memory: *Memory) Processor {
        return .{
            .memory = memory,
            .IME = false,
        };
    }

    // Read from memory the value pointed to by PC
    pub inline fn readFromPC(self: *Self) u8 {
        return self.memory.read(self.PC.value);
    }

    // Fetches the next instruction to be executed from the current memory address pointed at by PC
    pub inline fn fetch(self: *Self) u8 {
        const instruction = self.readFromPC();
        self.PC.increment();
        return instruction;
    }

    // Pop the current value from the stack pointed to by SP
    pub inline fn popStack(self: *Self) u8 {
        const val = self.memory.read(self.SP.value);
        self.SP.increment();
        return val;
    }

    // Push a value into the stack
    pub inline fn pushStack(self: *Self, val: u8) void {
        self.SP.decrement();
        self.memory.write(self.SP.get(), val);
    }

    pub inline fn isFlagSet(self: *Self, flag: Flag) bool {
        return switch (flag) {
            .Z => (self.AF.getLo() & Z_MASK) == Z_MASK,
            .N => (self.AF.getLo() & N_MASK) == N_MASK,
            .H => (self.AF.getLo() & H_MASK) == H_MASK,
            .C => (self.AF.getLo() & C_MASK) == C_MASK,
        };
    }

    pub inline fn setFlag(self: *Self, flag: Flag) void {
        const lo = self.AF.getLo();
        switch (flag) {
            .Z => self.AF.setLo(lo | Z_MASK),
            .N => self.AF.setLo(lo | N_MASK),
            .H => self.AF.setLo(lo | H_MASK),
            .C => self.AF.setLo(lo | C_MASK),
        }
    }

    pub inline fn unsetFlag(self: *Self, flag: Flag) void {
        const lo = self.AF.getLo();
        switch (flag) {
            .Z => self.AF.setLo(lo & ~Z_MASK),
            .N => self.AF.setLo(lo & ~N_MASK),
            .H => self.AF.setLo(lo & ~H_MASK),
            .C => self.AF.setLo(lo & ~C_MASK),
        }
    }

    pub inline fn resetFlags(self: *Self) void {
        self.AF.setLo(0);
    }

    pub fn decodeAndExecute(self: *Self, op_code: u16) !void {
        // TODO:
        // state all the different instructions for 8-bit opcodes
        //
        // TODO:
        // Look at 16-bit opcodes? Is this required?
        switch (op_code) {
            // NOP (No operation) Only advances the program counter by 1.
            // Performs no other operations that would have an effect
            0x00 => {},

            // LD BC, d16
            // Load the 2 bytes of immediate data into register pair BC
            // The first byte of immediate data is the lower byte (i.e. bits 0-7), and
            // the second byte of immediate data is the higher byte (i.e., bits 8-15)
            0x01 => {
                self.BC.setLo(self.fetch());
                self.BC.setHi(self.fetch());
            },

            // LD (BC), A
            // Store the contents of register A in the memory location specified by
            // register pair BC
            0x02 => self.memory.write(self.BC.get(), self.AF.getHi()),

            // INC BC
            // Increment the contents of register pair BC by 1
            0x03 => self.BC.increment(),

            // INC B
            // Increment the contents of register B by 1.
            0x04 => instructions.incHiReg(self, &self.BC),

            // DEC B
            // Decrement the contents of register B by 1
            0x05 => instructions.decHiReg(self, &self.BC),

            // LD B, d8
            // Load the 8-bit immediate operand d8 into register B.
            0x06 => self.BC.setHi(self.fetch()),

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
                const addr: u16 = utils.toTwoBytes(self.fetch(), self.fetch());
                self.memory.write(addr, utils.getLoByte(self.SP.get()));
                self.memory.write(addr + 1, utils.getHiByte(self.SP.get()));
            },

            // Add the contents of register pair BC to the contents of register pair HL, and
            // store the results in register pair HL.
            // TODO:
            // Flags: - 0 16-bit 16-bit
            // 0x09 => "ADD HL, BC",

            // LD A, (BC)
            // Load the 8-bit contents of memory specified by register pair BC into register A.
            0x0A => self.AF.setHi(self.memory.read(self.BC.get())),

            // Decrement the contents of register pair BC by 1.
            // 0x0b => "DEC BC",

            // INC C
            // Increment the contents of register C by 1.
            0x0C => instructions.incLoReg(self, &self.BC),

            // DEC C
            // Decrement the contents of register C by 1
            0x0D => instructions.decLoReg(self, &self.BC),

            // LD C, d8
            // Load the 8-bit immediate operand d8 into register C
            0x0E => instructions.loadLoFromImm(self, &self.BC),

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
            0x11 => instructions.loadRRFromImm16(self, &self.DE),

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
            0x16 => self.DE.setHi(self.fetch()),

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
                const offset = self.fetch();
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
                const offset = self.fetch();
                if (!self.isFlagSet(.Z)) {
                    self.PC.set(utils.addOffset(self.PC.get(), offset));
                }
            },

            // LD HL, d16
            // Load the 2 bytes of immediate data into register pair HL.
            // The first byte of immediate data is the lower byte (i.e., bits 0-7), and the second byte of immediate data
            // is the higher byte (i.e., bits 8-15)
            0x21 => {
                self.HL.setLo(self.fetch());
                self.HL.setHi(self.fetch());
            },

            // JR Z, s8
            // If the Z flag is 1, jump s8 steps from the current address stored in the program counter (PC). If not, the
            // instruction following the current JP instruction is executed (as usual).
            0x28 => {
                const offset: u8 = self.fetch();
                if (self.isFlagSet(.Z)) {
                    self.PC.set(utils.addOffset(self.PC.get(), offset));
                }
            },

            // JR NC, s8
            // If the CY flag is 0, jump s8 steps from the current address stored in the program counter (PC). If not, the
            // instruction following the current JP instruction is executed (as usual).
            0x30 => {
                const offset: u8 = self.fetch();
                if (!self.isFlagSet(.C)) {
                    self.PC.set(utils.addOffset(self.PC.get(), offset));
                }
            },

            // JR C, s8
            // IF the CY flag is 1, jump s8 steps from the current address stored in the program counter (PC). If not, the
            // instruction following the current JP instruction is executed (as usual).
            0x38 => {
                const offset: u8 = self.fetch();
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
            0x1E => self.DE.setLo(self.fetch()),

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
            0x26 => self.HL.setHi(self.fetch()),

            // LD A, (HL+)
            // Load the contents of memory specified by register pair HL into register A, and simultaneously
            // increment the contents of HL.
            0x2A => {
                self.AF.setHi(self.memory.read(self.HL.get()));
                self.HL.increment();
            },

            // LD L, d8
            // Load the 8-bit immediate operand d8 into register L.
            0x2E => self.HL.setLo(self.fetch()),

            // LD SP, d16
            // Load the 2 bytes of immediate data into register pair SP.
            // The first byte of immedaite data is the lower byte (i.e., bits 0-7), and the second byte of immediate data
            // is the higher byte (i.e., bits 8-15).
            0x31 => {
                self.SP.setLo(self.fetch());
                self.SP.setHi(self.fetch());
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
            0x36 => self.memory.write(self.HL.get(), self.fetch()),

            // LD A, (HL-)
            // Load the contents of memory specified by register pair HL into register A, and
            // simultaneously decrement the contents of HL.
            0x3A => {
                self.AF.setHi(self.memory.read(self.HL.get()));
                self.HL.decrement();
            },

            // LD A, d8
            // Load the 8-bit immediate operand d8 into register A.
            0x3E => self.AF.setHi(self.fetch()),

            // LD B, B
            // Load the contents of register B into register B
            // What's the point?? weird
            0x40 => self.BC.setHi(self.BC.getHi()),

            // LD B, C
            // Load the contents of register C into register B.
            0x41 => self.BC.setHi(self.BC.getLo()),

            // LD B, D
            // Load the contents of register D into register B.
            0x42 => self.BC.setHi(self.DE.getHi()),

            // LD B, E
            // Load the contents of register E into register B.
            0x43 => self.BC.setHi(self.DE.getLo()),

            // LD B, H
            // Load the contents of register H into register B.
            0x44 => self.BC.setHi(self.HL.getHi()),

            // LD B, L
            // Load the contents of register L into register B.
            0x45 => self.BC.setHi(self.HL.getLo()),

            // LD B, (HL)
            // Load the 8-bit contents of memory specified by register pair HL
            // into register B.
            0x46 => self.BC.setHi(self.memory.read(self.HL.get())),

            // LD B, A
            // Load the contents of register A into register B.
            0x47 => self.BC.setHi(self.AF.getHi()),

            // LD C, B
            // Load the contents of register B into register C.
            0x48 => self.BC.setLo(self.BC.getHi()),

            // LD C, C
            // Load the contents of register C into register C.
            0x49 => self.BC.setLo(self.BC.getLo()),

            // LD C, D
            // Load the contents of register D into register C.
            0x4A => self.BC.setLo(self.DE.getHi()),

            // LD C, E
            // Load the contents of register E into register C.
            0x4B => self.BC.setLo(self.DE.getLo()),

            // LD C, H
            // Load the contents of register H into register C.
            0x4C => self.BC.setLo(self.HL.getHi()),

            // LD C, L
            // Load the contents of register L into register C.
            0x4D => self.BC.setLo(self.HL.getLo()),

            // LD C, (HL)
            // Load the 8-bit contents of memory specified by register pair HL
            // into register C.
            0x4E => self.BC.setLo(self.memory.read(self.HL.get())),

            // LD C, A
            // Load the contents of register A into register C.
            0x4F => self.BC.setLo(self.AF.getHi()),

            // LD D, B
            // Load the contents of register B into register D.
            0x50 => self.DE.setHi(self.BC.getHi()),

            // LD D, C
            // Load the contents of register C into register D.
            0x51 => self.DE.setHi(self.BC.getLo()),

            // LD D, D
            // Load the contents of register D into register D.
            0x52 => self.DE.setHi(self.DE.getHi()),

            // LD D, E
            // Load the contents of register E into register D.
            0x53 => self.DE.setHi(self.DE.getLo()),

            // LD D, H
            // Load the contents of register H into register D.
            0x54 => self.DE.setHi(self.HL.getHi()),

            // LD D, L
            // Load the contents of register L into register D.
            0x55 => self.DE.setHi(self.HL.getLo()),

            // LD D, (HL)
            // Load the 8-bit contents of memory specified by register pair HL into register D.
            0x56 => self.DE.setHi(self.memory.read(self.HL.get())),

            // LD D, A
            // Load the contents of register A into register D.
            0x57 => self.DE.setHi(self.AF.getHi()),

            // LD E, B
            // Load the contents of register B into register E.
            0x58 => self.DE.setLo(self.BC.getHi()),

            // LD E, C
            // Load the contents of register C into register E.
            0x59 => self.DE.setLo(self.BC.getLo()),

            // LD E, D
            // Load the contents of register D into register E.
            0x5A => self.DE.setLo(self.DE.getHi()),

            // LD E, E
            // Load the contents of register E into register E.
            0x5B => self.DE.setLo(self.DE.getLo()),

            // LD E, H
            // Load the contents of register H into register E.
            0x5C => self.DE.setLo(self.HL.getHi()),

            // LD E, L
            // Load the contents of register L into register E.
            0x5D => self.DE.setLo(self.HL.getLo()),

            // LD E, (HL)
            // Load the 8-bit contents of memory specified by register pair HL
            // into register E.
            0x5E => self.DE.setLo(self.memory.read(self.HL.get())),

            // LD E, A
            // Load the contents of register A into register E.
            0x5F => self.DE.setLo(self.AF.getHi()),

            // LD H, B
            // Load the contents of register B into register H.
            0x60 => self.HL.setHi(self.BC.getHi()),

            // LD H, C
            // Load the contents of register C into register H.
            0x61 => self.HL.setHi(self.BC.getLo()),

            // LD H, D
            // Load the contents of register D into register H.
            0x62 => self.HL.setHi(self.DE.getHi()),

            // LD H, E
            // Load the contents of register E into register H.
            0x63 => self.HL.setHi(self.DE.getLo()),

            // LD H, H
            // Load the contents of register H into register H.
            0x64 => self.HL.setHi(self.HL.getHi()),

            // LD H, L
            // Load the contents of register L into register H.
            0x65 => self.HL.setHi(self.HL.getLo()),

            // LD H, (HL)
            // Load the 8-bit contents of memory specified by register pair HL
            // into register H.
            0x66 => self.HL.setHi(self.memory.read(self.HL.get())),

            // LD H, A
            // Load the contents of register A into register H.
            0x67 => self.HL.setHi(self.AF.getHi()),

            // LD L, B
            // Load the contents of register B into register L.
            0x68 => self.HL.setLo(self.BC.getHi()),

            // LD L, C
            // Load the contents of register C into register L.
            0x69 => self.HL.setLo(self.BC.getLo()),

            // LD L, D
            // Load the contents of register D into register L.
            0x6A => self.HL.setLo(self.DE.getHi()),

            // LD L, E
            // Load the contents of register E into register L.
            0x6B => self.HL.setLo(self.DE.getLo()),

            // LD L, H
            // Load the contents of register H into register L.
            0x6C => self.HL.setLo(self.HL.getHi()),

            // LD L, L
            // Load the contents of register L into register L.
            0x6D => self.HL.setLo(self.HL.getLo()),

            // LD L, (HL)
            // Load the 8-bit contents of memory specified by register pair HL
            // into register L.
            0x6E => self.HL.setLo(self.memory.read(self.HL.get())),

            // LD L, A
            // Load the contents of register A into register L.
            0x6F => self.HL.setLo(self.AF.getHi()),

            // LD (HL), B
            // Store the contents of register B in the memory location specified by
            // register pair HL.
            0x70 => self.memory.write(self.HL.get(), self.BC.getHi()),

            // LD (HL), C
            // Store the contents of register C in the memory location specified by
            // register pair HL.
            0x71 => self.memory.write(self.HL.get(), self.BC.getLo()),

            // LD (HL), D
            // Store the contents of register D in the memory location specified by
            // register pair HL.
            0x72 => self.memory.write(self.HL.get(), self.DE.getHi()),

            // LD (HL), E
            // Store the contents of register E in the memory location specified by
            // register pair HL.
            0x73 => self.memory.write(self.HL.get(), self.DE.getLo()),

            // LD (HL), H
            // Store the contents of register H in the memory location specified by
            // register pair HL.
            0x74 => self.memory.write(self.HL.get(), self.HL.getHi()),

            // LD (HL), L
            // Store the contents of register L in the memory location specified by
            // register pair HL.
            0x75 => self.memory.write(self.HL.get(), self.HL.getLo()),

            // HALT
            // TODO
            // 0x76 => {},

            // LD (HL), A
            // Store the contents of register A in the memory location specified by
            // register pair HL.
            0x77 => self.memory.write(self.HL.get(), self.AF.getHi()),

            // LD A, B
            // Load the contents of register B into register A.
            0x78 => self.AF.setHi(self.BC.getHi()),

            // LD A, C
            // Load the contents of register C into register A.
            0x79 => self.AF.setHi(self.BC.getLo()),

            // LD A, D
            // Load the contents of register D into register A.
            0x7A => self.AF.setHi(self.DE.getHi()),

            // LD A, E
            // Load the contents of register E into register A.
            0x7B => self.AF.setHi(self.DE.getLo()),

            // LD A, H
            // Load the contents of register H into register A.
            0x7C => self.AF.setHi(self.HL.getHi()),

            // LD A, L
            // Load the contents of register L into register A.
            0x7D => self.AF.setHi(self.HL.getLo()),

            // LD A, (HL)
            // Load the 8-bit contents of memory specified by register pair HL
            // into register A.
            0x7E => self.AF.setHi(self.memory.read(self.HL.get())),

            // LD A, A
            // Load the contents of register A into register A.
            0x7F => self.AF.setHi(self.AF.getHi()),

            // RET NZ
            // If the Z flag is 0, control is returned to the source program by popping from the memory stack the program
            // counter PC value that was pushed to the stack when the subroutine was called.
            //
            // The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC, and
            // the contents of SP are incremented by 1. The contents of the address specified by the new SP value are then
            // loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again. (The value of SP
            // is 2 larger than before instruction execution.) The next instruction is fetched from the address specified
            // by the content of PC (as usual).
            0xC0 => {
                if (!self.isFlagSet(.Z)) {
                    self.PC.setLo(self.popStack());
                    self.PC.setHi(self.popStack());
                }
            },

            // POP BC
            // Pop the contents from the memory stack into register pair BC by doing the following:
            // 1. Load the contents of memory specified by stack pointer SP into the lower portion of BC.
            // 2. Add 1 to SP and load the contents from the new memory location into the upper portion BC.
            // 3. By the end, SP should be 2 more than its initial value.
            0xC1 => {
                self.BC.setLo(self.popStack());
                self.BC.setHi(self.popStack());
            },

            // JP NZ, a16
            // Load the 16-bit immediate operand a16 into the program counter PC if the Z flag is 0. If the Z flag is
            // 0, then the subsequent instruction starts at address a16. If not, the contents of PC are incremented,
            // and the next instruction following the current JP instruction is executed (as usual).
            //
            // The second byte of the object code (immediately following the opcode) corresponds to the lower-order
            // byte of a16 (bits 0-7), and the third byte of the object code corresponds to the higher-order byte
            // (bits 8-15).
            0xC2 => {
                var addr: u16 = self.memory.read(self.PC.get());
                self.PC.increment();
                addr |= (@as(u16, self.memory.read(self.PC.get())) << 8);
                self.PC.increment();

                if (!self.isFlagSet(.Z)) {
                    self.PC.set(addr);
                }
            },

            // JP a16
            // Load the 16-bit immediate operand a16 into the program counter (PC). a16 specifies the address of the
            // subsequently executed instruction.
            // The second byte of the object code (immediately following the opcode) corresponds to the lower-order
            // byte of a16 (bits 0-7), and the third byte of the object code corresponds to the higher-order byte
            // (bits 8-15).
            0xC3 => {
                var addr: u16 = self.memory.read(self.PC.get());
                self.PC.increment();
                addr |= (@as(u16, self.memory.read(self.PC.get())) << 8);
                self.PC.increment();
                self.PC.set(addr);
            },

            // CALL NZ, a16
            // If the Z flag is 0, the program counter PC value corresponding to the memory location of the instruction
            // following the CALL instruction is pushed to the 2 bytes following the memory byte specified by the stack
            // pointer SP. The 16-bit immediate operand a16 is then loaded into PC.
            //
            // The lower-order byte of a16 is placed in byte 2 of the object code, and the higher-order byte is placed
            // in byte 3.
            0xC4 => {
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                if (!self.isFlagSet(.Z)) {
                    self.pushStack(self.PC.getHi());
                    self.pushStack(self.PC.getLo());
                    self.PC.set(addr);
                }
            },

            // PUSH BC
            // Push the contents of register pair BC onto the memory stack by doing the following:
            // 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of register pair
            // BC on on the stack.
            // 2. Subtract 1 from SP, and put the lower portion of register pair BC on the stack.
            0xC5 => {
                self.pushStack(self.BC.getHi());
                self.pushStack(self.BC.getLo());
            },

            // RST 0
            // Push the current value of the program counter PC onto the memory stack, and load into PC the 1th byte
            // of page 0 memory addresses, 0x00. The next instruction is fetched from the address specified by the new
            // content of PC (as usual).
            // With the push, the contents of the stack pointer SP are decremented by 1, and the higher-order byte of
            // PC is loaded in the memory address specified by the new SP value. The value of SP is then again
            // decremented by 1, and the lower-order byte of the PC is loaded in the memory address specified by that
            // value of SP.
            // The RST instruction can be used to jump to 1 of 8 addresses. Because all of the addresses are held in
            // page 0 memory, 0x00 is loaded in the higher-order byte of the PC, and 0x00 is loaded in the lower-order 
            // byte.
            0xC7 => {
                self.pushStack(self.PC.getHi());
                self.pushStack(self.PC.getLo());
                self.PC.set(0x0000);
            },

            // RET Z
            // If the Z flag is 1, control is returned to the source program by popping from the memory stack the
            // program counter PC value that was pushed to the stack when the subroutine was called.
            // The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC,
            // and the contents of SP are incremented by 1. The contents of the address specified by the new SP value
            // are then loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again.
            // (The value of SP is 2 larger than before instruction execution.) The next instruction is fetched from
            // the address specified by the content of PC (as usual).
            0xC8 => {
                if (self.isFlagSet(.Z)) {
                    self.PC.setLo(self.popStack());
                    self.PC.setHi(self.popStack());
                }
            },

            // RET
            // Pop from the memory stack the program counter PC value pushed when the subroutine was called, returning
            // control to the source program.
            // The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC,
            // and the contents of SP are incremented by 1. The contents of the address specified by the new SP value
            // are then loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again.
            // (The value of SP is 2 larger than before instruction execution.) The next instruction is fetched from
            // the address specified by the content of PC (as usual).
            0xC9 => {
                self.PC.setLo(self.popStack());
                self.PC.setHi(self.popStack());
            },

            // JP Z, a16
            // Load the 16-bit immediate operand a16 into the program counter PC if the Z flag is 1. If the Z flag is
            // 1, then the subsequent instruction starts at address a16. If not, the contents of PC are incremented,
            // and the next instruction following the current JP instruction is executed (as usual).
            // The second byte of the object code (immediately following the opcode) corresponds to the lower-order byte
            // of a16 (bits 0-7), and the third byte of the object code corresponds to the higher-order byte
            // (bits 8-15).
            0xCA => {
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                if (self.isFlagSet(.Z)) {
                    self.PC.set(addr);
                }
            },

            // CALL Z, a16
            // If the Z flag is 1, the program counter PC value corresponding to the memory location of the instruction following the
            // CALL instruction is pushed to the 2 bytes following the memory byte specified by the stack pointer SP. The 16-bit immediate
            // operand a16 is then loaded into PC.
            // The lower-order byte of a16 is placed in byte 2 of the object code, and the higher-order byte is placed in byte 3.
            0xCC => {
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                if (self.isFlagSet(.Z)) {
                    self.pushStack(self.PC.getHi());
                    self.pushStack(self.PC.getLo());
                    self.PC.set(addr);
                }
            },

            // CALL a16
            // In memory, push the program counter PC value corresponding to the address following the CALL instruction
            // to the 2 bytes following the byte specified by the current stack pointer SP. Then load the 16-bit
            // immediate operand a16 into PC.
            // The subroutine is placed after the location specified by the new PC value. When the subroutine finishes,
            // control is returned to the source program using a return instruction and by popping the starting address
            // of the next instruction (which was just pushed) and moving it to the PC.
            // With the push, the current value of SP is decremented by 1, and the higher-order byte of PC is loaded in
            // the memory address specified by the new SP value. The value of SP is then decremented by 1 again, and
            // the lower-order byte of PC is loaded in the memory address specified by that value of SP.
            // The lower-order byte of a16 is placed in byte 2 of the object code, and the higher-order byte is placed
            // in byte 3.
            0xCD => {
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                self.pushStack(self.PC.getHi());
                self.pushStack(self.PC.getLo());
                self.PC.set(addr);
            },

            // RST 1
            // Push the current value of the program counter PC onto the memory stack, and load into PC the 2th byte of
            // page 0 memory addresses, 0x08. The next instruction is fetched from the address specified by the new
            // content of PC (as usual).
            // With the push, the contents of the stack pointer SP are decremented by 1, and the higher-order byte of
            // PC is loaded in the memory address specified by the new SP value. The value of SP is then again
            // decremented by 1, and the lower-order byte of the PC is loaded in the memory address specified by that
            // value of SP.
            // The RST instruction can be used to jump to 1 of 8 addresses. Because all of the addresses are held in
            // page 0 memory, 0x00 is loaded in the higher-order byte of the PC, and 0x08 is loaded in the lower-order
            // byte.
            0xCF => {
                self.pushStack(self.PC.getHi());
                self.pushStack(self.PC.getLo());
                self.PC.set(0x0008);
            },

            // RET NC
            // If the CY flag is 0, control is returned to the source program by popping from the memory stack the
            // program counter PC value that was pushed to the stack when the subroutine was called.
            // The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC,
            // and the contents of SP are incremented by 1. The contents of the address specified by the new SP value
            // are then loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again.
            // (The value of SP is 2 larger than before instruction execution.) The next instruction is fetched from
            // the address specified by the content of PC (as usual).
            0xD0 => {
                if (!self.isFlagSet(.C)) {
                    self.PC.setLo(self.popStack());
                    self.PC.setHi(self.popStack());
                }
            },

            // POP DE
            // Pop the contents from the memory stack into register pair DE by doing the following:
            // 1. Load the contents of memory specified by stack pointer SP into the lower portion of DE.
            // 2. Add 1 to SP and load the contents from the new memory location into the upper portion of DE.
            // 3. By the end, SP should be 2 more than its initial value.
            0xD1 => {
                self.DE.setLo(self.popStack());
                self.DE.setHi(self.popStack());
            },

            // JP NC, a16
            0xD2 => {
                // Would a better implementation be to only read the operands
                // and then write to lo and hi for PC so that we get away with
                // bit operations
                // And if it is C, then we just increment PC by 2 without
                // reading from memory?
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                if (!self.isFlagSet(.C)) {
                    self.PC.set(addr);
                }
            },

            // CALL NC, a16
            // If the CY flag is 0, the program counter PC value corresponding to the memory location of the
            // instruction following the CALL instruction is pushed to the 2 bytes following the memory byte specified
            // by the stack pointer SP. The 16-bit immediate operand a16 is then loaded into PC.
            // The lower-order byte of a16 is placed in byte 2 of the object code, and the higher-order byte is placed
            // in byte 3.
            0xD4 => {
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                if (!self.isFlagSet(.C)) {
                    self.pushStack(self.PC.getHi());
                    self.pushStack(self.PC.getLo());
                    self.PC.set(addr);
                }
            },

            // PUSH DE
            // Push the contents of register pair DE onto the memory stack by doing the following:
            // 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of regiser pair DE on
            // the stack.
            // 2. Subtract 1 from SP, and put the lower portion of register pair DE on the stack.
            // 3. By the end, SP should be 2 less than its initial value.
            0xD5 => {
                self.pushStack(self.DE.getHi());
                self.pushStack(self.DE.getLo());
            },

            // RST 2
            // Push the current value of the program counter PC onto the memory stack, and load into PC the 3th byte of
            // page 0 memory addresses, 0x10. The next instruction is fetched from the address specified by the new
            // content of PC (as usual).
            // With the push, the contents of the stack pointer SP are decremented by 1, and the higher-order byte of
            // PC is loaded in the memory address specified by the new SP value. The value of SP is then again
            // decremented by 1, and the lower-order byte of the PC is loaded in the memory address specified by that
            // value of SP.
            // The RST instruction can be used to jump to 1 of 8 addresses. Because all of the addresses are held in
            // page 0 memory, 0x00 is loaded in the higher-order byte of the PC, and 0x10 is loaded in the lower-order
            // byte.
            0xD7 => {
                self.pushStack(self.PC.getHi());
                self.pushStack(self.PC.getLo());
                self.PC.set(0x0010);
            },

            // RET C
            // If the CY flag is 1, control is returned to the source program by popping from the memory stack the
            // program counter PC value that was pushed to the stack when the subroutine was called.
            // The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC,
            // and the contents of SP are incremented by 1. The contents of the address specified by the new SP value
            // are then loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again.
            // (The value of SP is 2 larger than before instruction execution.) The next instruction is fetched from
            // the address specified by the content of PC (as usual).
            0xD8 => {
                if (self.isFlagSet(.C)) {
                    self.PC.setLo(self.popStack());
                    self.PC.setHi(self.popStack());
                }
            },

            // RETI
            // Used when an interrupt-service routine finishes. The address for the return from the interrupt is loaded
            // in the program counter PC. The master interrupt enable flag is returned to its pre-interrupt status.
            // The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC,
            // and the contents of SP are incremented by 1. The contents of the address specified by the new SP value
            // are then loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again. 
            // (THe value of SP is 2 larger than before instruction execution.) The next instruction is fetched from
            // the address specified by the content of PC (as usual).
            0xD9 => {
                self.PC.setLo(self.popStack());
                self.PC.setHi(self.popStack());
                self.IME = true;
            },

            // JP C, a16
            // Load the 16-bit immediate operand a16 into the program counter PC if the CY flag is 1. If the CY flag is
            // 1, then the subsequent instruction starts at address a16. If not, the contents of PC are incremented,
            // and the next instruction following the current JP instruction is executed (as usual).
            // The second byte of the object code (immediately following the opcode) corresponds to the lower-order
            // byte of a16 (bits 0-7), and the third byte of the object code corresponds to the higher-order byte
            // (bits 8-15).
            0xDA => {
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                if (self.isFlagSet(.C)) {
                    self.PC.set(addr);
                }
            },

            // CALL C, a16
            // If the CY flag is 1, the program counter PC value corresponding to the memory location of the instruction
            // following the CALL instruction is pushed to the 2 bytes following the memory byte specified by the stack
            // pointer SP. The 16-bit immediate operand a16 is then loaded into PC.
            // The lower-order byte of a16 is placed in byte 2 of the object code, and the higher-order byte is placed
            // in byte 3.
            0xDC => {
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                if (self.isFlagSet(.C)) {
                    self.pushStack(self.PC.getHi());
                    self.pushStack(self.PC.getLo());
                    self.PC.set(addr);
                }
            },

            // RST 3
            // Push the current value of the program counter PC onto the memory stack, and load into PC the 4th byte of
            // page 0 memory addresses, 0x18. The next instruction is fetched from the address specified by the new
            // content of PC (as usual).
            // With the push, the contents of the stack pointer SP are decremented by 1, and the higher-order byte of PC
            // is loaded in the memory address specified by the new SP value. The value of SP is then again decremented
            // by 1, and the lower-order byte of the PC is loaded in the memory address specified by that value of SP.
            // The RST instruction can be used to jump to 1 of 8 addresses. Because all of the addresses are held in
            // page
            // 0 memory, 0x00 is loaded in the higher-order byte of the PC, and 0x18 is loaded in the lower-order byte.
            0xDF => {
                self.pushStack(self.PC.getHi());
                self.pushStack(self.PC.getLo());
                self.PC.set(0x0018);
            },

            // LD (a8), A
            // Load to the address specified by the 8-bit immediate data a8, data from the 8-bit A register. The full
            // 16-bit absolute address is obtained by setting the most significant byte to 0xff and the least significant
            // byte to the value of a8, so the possible range is 0xff00-0xffff.
            0xE0 => {
                const addr: u16 = HI_MASK | self.fetch();
                self.memory.write(addr, self.AF.getHi());
            },

            // POP HL
            // Pop the contents from the memory stack into register pair HL by doing the following:
            // 1. Load the contents of memory specified by stack pointer SP into the lower portion of HL.
            // 2. Add 1 to SP and load the contents from thew new memory location into the upper portion of HL.
            // 3. By the end, SP should be 2 more than its initial value.
            0xE1 => {
                self.HL.setLo(self.popStack());
                self.HL.setHi(self.popStack());
            },

            // LD (C), A
            // Load to the address specified by the 8-bit C register, data from the 8-bit A register. The full 16-bit
            // address is obtained by setting the most significant byte to 0xff and the least significant byte to the
            // value of C, so the possible range is 0xff00-0xffff.
            0xE2 => {
                const addr: u16 = HI_MASK | self.BC.getLo();
                self.memory.write(addr, self.AF.getHi());
            },

            // PUSH HL
            // Push the contents of register pair HL onto the memory stack by doing the following:
            // 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of register pair
            // HL on the stack.
            // 2. Subtract 1 from SP, and put the lower portion of register pair HL on the stack.
            // 3. By the end, SP should be 2 less than its initial value.
            0xE5 => {
                self.SP.decrement();
                self.memory.write(self.SP.get(), self.HL.getHi());
                self.SP.decrement();
                self.memory.write(self.SP.get(), self.HL.getLo());
            },

            // RST 4
            // Push the current value of the program counter PC onto the memory stack, and load into PC the 5th byte of
            // page 0 memory addresses, 0x20. The next instruction is fetched from the address specified by the new
            // content of PC (as usual).
            // With the push, the contents of the stack pointer SP are decremented by 1, and the higher-order byte of PC
            // is loaded in the memory address specified by the new SP value. The value of SP is then again decremented
            // by 1, and the lower-order byte of the PC is loaded in the memory address specified by that value of SP.
            // The RST instruction can be used to jump to 1 of 8 addresses. Because all of the addresses are held in
            // page 0 memory, 0x00 is loaded in the higher-order byte of the PC, and 0x20 is loaded in the lower-order
            // byte.
            0xE7 => {
                self.pushStack(self.PC.getHi());
                self.pushStack(self.PC.getLo());
                self.PC.set(0x0020);
            },

            // JP HL
            // Load the contents of register pair HL into the program counter PC. The next instruction is fetched from
            // the location specified by the new value of PC.
            0xE9 => self.PC.set(self.HL.get()),

            // LD (a16), A
            // Store the contents of register A in the internal RAM or register specified by the 16-bit immediate
            // operand a16.
            0xEA => {
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                self.memory.write(addr, self.AF.getHi());
            },

            // RST 5
            0xEF => {
                self.pushStack(self.PC.getHi());
                self.pushStack(self.PC.getLo());
                self.PC.set(0x0028);
            },

            // LD A, (a8)
            // Load to the 8-bit A register, data from the address specified by the 8-bit immediate data a8. The full
            // 16-bit absolute address is obtained by setting the most significant byte to 0xff and the least
            // significant byte to the value of a8, so the possible range is 0xff0-0xffff.
            0xF0 => {
                const addr: u16 = HI_MASK | self.fetch();
                self.AF.setHi(self.memory.read(addr));
            },

            // POP AF
            // Pop the contents from the memory stack into register pair AF by doing the following:
            // 1. Load the contents of memory specified by stack pointer SP into the lower portion of AF.
            // 2. Add 1 to SP and load the contents from the new memory location into the upper portion AF.
            // 3. By the end, SP should be 2 more than its initial value.
            0xF1 => {
                self.AF.setLo(self.popStack());
                self.AF.setHi(self.popStack());
            },

            // LD A, (C)
            // Load to the 8-bit A register, data from the address specified by the 8-bit C register. The full 16-bit
            // address is obtianed by setting the most significant byte to 0xff and the least significant byte to the
            // value of C, so the possible range is 0xff00-0xffff.
            0xF2 => {
                const addr: u16 = HI_MASK | self.BC.getLo();
                self.AF.setHi(self.memory.read(addr));
            },

            // PUSH AF
            // Push the contents of register pair AF onto the memory stack by doing the following:
            // 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of register pair
            // BC on on the stack.
            // 2. Subtract 1 from SP, and put the lower portion of register pair AF on the stack.
            0xF5 => {
                self.pushStack(self.AF.getHi());
                self.pushStack(self.AF.getLo());
            },
            //
            // // LD HL, SP+s8
            // // Add the 8-bit signed operand s8 (values -128 to +127) to the stack pointer SP, and
            // // store the result in register pair HL.
            // Flags: 0 0 H CY
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

            // RST 6
            // Push the current value of the program counter PC onto the memory stack, and load into PC the 7th byte of
            // page 0 memory addresses, 0x30. The next instruction is fetched from the address specified by the new
            // content of PC (as usual).
            // With the push, the contents of the stack pointer SP are decremented by 1, and the higher-order byte of
            // PC is loaded in the memory address specified by the new SP value. The value of SP is then again
            // decremented by 1, and the lower-order byte of the PC is loaded in the memory address specified by that
            // value of SP.
            // The RST instruction can be used to jump to 1 of 8 addresses. Because all of the addresses are held in
            // page 0 memory, 0x00 is loaded in the higher-order byte of the PC, and 0x30 is loaded in the lower-order
            // byte.
            0xF7 => {
                self.pushStack(self.PC.getHi());
                self.pushStack(self.PC.getLo());
                self.PC.set(0x0030);
            },

            // LD SP, HL
            // Load the contents of register pair HL into the stack pointer SP.
            0xF9 => self.SP.set(self.HL.get()),

            // LD A, (a16)
            // Load to the 8-bit A register, data from the absolute address specified by the 16-bit operand (a16).
            0xFA => {
                const addr = utils.toTwoBytes(self.fetch(), self.fetch());
                self.AF.setHi(self.memory.read(addr));
            },

            // RST 7
            // Push the current value of the program counter PC onto the memory stack, and load into PC the 8th byte of
            // page 0 memory addresses, 0x38. The next instruction is fetched from the address specified by the new
            // content of PC (as usual).
            // With the push, the contents of the stack pointer SP are decremented by 1, and the higher-order byte of
            // PC is loaded in the memory address specified by the new SP value. The value of SP is then again
            // decremented by 1, and the lower-order byte of the PC is loaded in the memory address specified by that
            // value of SP.
            // The RST instruction can be used to jump to 1 of 8 addresses. Because all of the addresses are held in
            // page 0 memory, 0x00 is loaded in the higher-order byte of the PC, and 0x38 is loaded in the lower-order
            // byte.
            0xFF => {
                self.pushStack(self.PC.getHi());
                self.pushStack(self.PC.getLo());
                self.PC.set(0x0038);
            },

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

test "popStack" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    const SP: u16 = 0x0AFF;
    const content: u8 = 0x13;

    processor.SP.set(SP);
    processor.memory.write(SP, content);

    const val = processor.popStack();
    try expectEqual(content, val);
    try expectEqual(SP + 1, processor.SP.get());
}

test "pushStack" {
    var memory = Memory.init();
    var processor = Processor.init(&memory);
    const SP: u16 = 0x0AFF;
    const content: u8 = 0x13;

    processor.SP.set(SP);

    processor.pushStack(content);
    try expectEqual(content, processor.memory.read(SP - 1));
    try expectEqual(SP - 1, processor.SP.get());
}
