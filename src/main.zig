const std = @import("std");

pub const RegisterFile = struct {
    A: u8 = 0, // Accumulator
    F: u8 = 0, // Flags

    // General Purpose Registers
    B: u8 = 0,
    C: u8 = 0,
    D: u8 = 0,
    E: u8 = 0,
    H: u8 = 0,
    L: u8 = 0,

    // Special Registers
    IR: u8 = 0, // Instruction Register
    IE: u8 = 0, // Interrupt Enable

    // Others
    PC: u16 = 0, // Program Counter
    SP: u16 = 0, // Stack Pointer

    const Self = @This();

    pub inline fn getBC(self: Self) u16 {
        return (@as(u16, self.B) << 8) | self.C;
    }

    pub inline fn incBC(self: *Self) u16 {
        if (self.C == 0xff) {
            self.C = 0;
            self.B += 1;
        } else {
            self.C += 1;
        }

        return self.getBC();
    }

    pub inline fn decBC(self: *Self) u16 {
        if (self.C == 0x00) {
            self.C = 0xff;
            self.B -= 1;
        } else {
            self.C -= 1;
        }
        return self.getBC();
    }

    pub inline fn getDE(self: Self) u16 {
        return (@as(u16, self.D) << 8) | self.E;
    }

    pub inline fn getHL(self: Self) u16 {
        return (@as(u16, self.H) << 8) | self.L;
    }

    pub inline fn incHL(self: *Self) u16 {
        if (self.L == 0xff) {
            self.L = 0;
            self.H += 1;
        } else {
            self.L += 1;
        }
        return self.getHL();
    }

    pub inline fn decHL(self: *Self) u16 {
        if (self.L == 0x00) {
            self.L = 0xff;
            self.H -= 1;
        } else {
            self.L -= 1;
        }
        return self.getHL();
    }
};

// 65,536 positions inlcuding 0x00 and 0xffff
const ARRAY_SIZE: u32 = 0xffff + 1;

pub const Memory = struct {
    memory_array: [ARRAY_SIZE]u8 = undefined,

    const Self = @This();

    pub fn init() Self {
        var memory: [ARRAY_SIZE]u8 = undefined;
        @memset(&memory, 0);
        const self: Memory = .{
            .memory_array = memory,
        };
        return self;
    }

    pub inline fn get(self: Self, index: u32) u8 {
        return self.memory_array[index];
    }

    pub inline fn set(self: *Self, index: u32, value: u8) void {
        self.memory_array[index] = value;
    }
};

pub fn main() !void {
    // We use to have a StringHashMap with allocated memory
    // but looking at it, structs are probably better
    // var register = createRegister();
}

pub fn fetch() void {}

pub fn decodeAndExecute(register: *RegisterFile, memory: *Memory) !void {
    // TODO:
    // state all the different instructions for 8-bit opcodes
    //
    // TODO:
    // Look at 16-bit opcodes? Is this required?
    switch (register.IR) {
        // NOP (No operation) Only advances the program counter by 1.
        // Performs no other operations that would have an effect
        0x00 => register.PC += 1,

        // LD BC, d16
        // Load the 2 bytes of immediate data into register pair BC
        // The first byte of immediate data is the lower byte (i.e. bits 0-7), and
        // the second byte of immediate data is the higher byte (i.e., bits 8-15)
        // 0x01 => {
        //     // Store it as it is, maybe we'll need to switch byte ordering at later stage
        //     // maybe during execution?
        //     register.B = first_byte;
        //     register.C = second_byte;
        //     register.PC += 1;
        // },

        // LD (BC), A
        // Store the contents of register A in the memory location specified by
        // register pair BC
        // TODO:
        // I may need to swap endianness as the CPU is little endian
        0x02 => {
            memory.set(register.getBC(), register.A);
            register.PC += 1;
        },

        // INC BC
        // Increment the contents of register pair BC by 1
        0x03 => {
            _ = register.incBC();
            register.PC += 1;
        },

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
            register.PC += 1;
            register.B = memory.get(register.PC);
            register.PC += 1;
        },

        // Rotate the contents of register A to the left. That is, the contents of bit 0
        // are copied to bit 1, and the previous contents of bit 1 (before the copy operation)
        // are copied to bit 2. The same operation is repeated in sequence for the rest
        // of the register. The contents of bit 7 are placed in both the CY flag and bit 0 of
        // register A.
        // TODO:
        // Flags: 0 0 0 A7
        // 0x07 => "RLCA",

        // Store the lower byte of stack pointer SP at the address specified by the 16-bit
        // immediate operand 16, and store the upper byte of SP at address a16 + 1.
        // 0x08 => "LD (a16), SP",

        // Add the contents of register pair BC to the contents of register pair HL, and
        // store the results in register pair HL.
        // TODO:
        // Flags: - 0 16-bit 16-bit
        // 0x09 => "ADD HL, BC",

        // Load the 8-bit contents of memory specified by register pair BC into register A.
        // 0x0a => "LD A, (BC)",

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
        0x0e => {
            register.PC += 1;
            register.C = memory.get(register.PC);
            register.PC += 1;
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

        // Load the 2 bytes of immediate data into register pair DE.
        //
        // The first byte of immediate data is the lower byte (i.e., bit 0-7), and the second byte
        // of immediate data is the higher byte (i.e., bits 8-15)
        // 0x11 => "LD DE, d16",

        // LD (DE), A
        // Store the contents of register A in the memory location specified by register pair DE.
        0x12 => {
            memory.set(register.getDE(), register.A);
            register.PC += 1;
        },

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
            register.PC += 1;
            register.D = memory.get(register.PC);
            register.PC += 1;
        },

        // Rotate the contents of register A to the left, through the carry (CY) flag. That is, the
        // contents of bit 0 are copied to bit 1, and the previous contents of bit 1 (before the copy
        // operation) are copied to bit 2. The same operation is repeated in sequence for the rest of
        // the register. The previous contents of the carry flag are copied to bit 0.
        // TODO:
        // Flags: 0 0 0 A7
        // 0x17 => "RLA",

        // Jump s8 steps from the current address in the program counter (PC). (Jump relative.)
        // 0x18 => "JR s8",

        // Add the contents of register pair DE to the contents of register pair HL, and store the results
        // in register pair HL.
        // TODO:
        // Flags: - 0 16-bit 16-bit
        // 0x19 => "ADD HL, DE",

        // Load the 8-bit contents of memory specified by register pair DE into register A.
        // 0x1a => "LD A, (DE)",

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
        0x1e => {
            register.PC += 1;
            register.E = memory.get(register.PC);
            register.PC += 1;
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
            memory.set(register.getHL(), register.A);
            _ = register.incHL();
            register.PC += 1;
        },

        // LD H, d8
        // Load the 8-bit immediate operand d8 into register H.
        0x26 => {
            register.PC += 1;
            register.H = memory.get(register.PC);
            register.PC += 1;
        },

        // LD A, (HL+)
        // Load the contents of memory specified by register pair HL into register A, and simultaneously
        // increment the contents of HL.
        0x2a => {
            register.A = memory.get(register.getHL());
            _ = register.incHL();
            register.PC += 1;
        },

        // LD L, d8
        // Load the 8-bit immediate operand d8 into register L.
        0x2e => {
            register.PC += 1;
            register.L = memory.get(register.PC);
            register.PC += 1;
        },

        // LD (HL-), A
        // Store the contents of register A into the memory location specified by register pair
        // HL, and simultaneously decrement the contents of HL.
        0x32 => {
            memory.set(register.getHL(), register.A);
            _ = register.decHL();
            register.PC += 1;
        },

        // LD (HL), d8
        // Store the contents of 8-bit immediate operand d8 in the memory location
        // specified by register pair HL.
        0x36 => {
            register.PC += 1;
            memory.set(register.getHL(), memory.get(register.PC));
            register.PC += 1;
        },

        // LD A, (HL-)
        // Load the contents of memory specified by register pair HL into register A, and
        // simultaneously decrement the contents of HL.
        0x3a => {
            register.A = memory.get(register.getHL());
            _ = register.decHL();
            register.PC += 1;
        },

        // LD A, d8
        // Load the 8-bit immediate operand d8 into register A.
        0x3e => {
            register.PC += 1;
            register.A = memory.get(register.PC);
            register.PC += 1;
        },

        // LD B, B
        // Load the contents of register B into register B
        // What's the point?? weird
        0x40 => {
            register.B = register.B;
            register.PC += 1;
        },

        // LD B, C
        // Load the contents of register C into register B.
        0x41 => {
            register.B = register.C;
            register.PC += 1;
        },

        // LD B, D
        // Load the contents of register D into register B.
        0x42 => {
            register.B = register.D;
            register.PC += 1;
        },

        // LD B, E
        // Load the contents of register E into register B.
        0x43 => {
            register.B = register.E;
            register.PC += 1;
        },

        // LD B, H
        // Load the contents of register H into register B.
        0x44 => {
            register.B = register.H;
            register.PC += 1;
        },

        // LD B, L
        // Load the contents of register L into register B.
        0x45 => {
            register.B = register.L;
            register.PC += 1;
        },

        // LD B, (HL)
        // Load the 8-bit contents of memory specified by register pair HL
        // into register B.
        0x46 => {
            register.B = memory.get(register.getHL());
            register.PC += 1;
        },

        // LD B, A
        // Load the contents of register A into register B.
        0x47 => {
            register.B = register.A;
            register.PC += 1;
        },

        // LD C, B
        // Load the contents of register B into register C.
        0x48 => {
            register.C = register.B;
            register.PC += 1;
        },

        // LD C, C
        // Load the contents of register C into register C.
        0x49 => {
            register.C = register.C;
            register.PC += 1;
        },

        // LD C, D
        // Load the contents of register D into register C.
        0x4a => {
            register.C = register.D;
            register.PC += 1;
        },

        // LD C, E
        // Load the contents of register E into register C.
        0x4b => {
            register.C = register.E;
            register.PC += 1;
        },

        // LD C, H
        // Load the contents of register H into register C.
        0x4c => {
            register.C = register.H;
            register.PC += 1;
        },

        // LD C, L
        // Load the contents of register L into register C.
        0x4d => {
            register.C = register.L;
            register.PC += 1;
        },

        // LD C, (HL)
        // Load the 8-bit contents of memory specified by register pair HL
        // into register C.
        0x4e => {
            register.C = memory.get(register.getHL());
            register.PC += 1;
        },

        // LD C, A
        // Load the contents of register A into register C.
        0x4f => {
            register.C = register.A;
            register.PC += 1;
        },

        // LD D, B
        // Load the contents of register B into register D.
        0x50 => {
            register.D = register.B;
            register.PC += 1;
        },

        // LD D, C
        // Load the contents of register C into register D.
        0x51 => {
            register.D = register.C;
            register.PC += 1;
        },

        // LD D, D
        // Load the contents of register D into register D.
        0x52 => {
            register.D = register.D;
            register.PC += 1;
        },

        // LD D, E
        // Load the contents of register E into register D.
        0x53 => {
            register.D = register.E;
            register.PC += 1;
        },

        // LD D, H
        // Load the contents of register H into register D.
        0x54 => {
            register.D = register.H;
            register.PC += 1;
        },

        // LD D, L
        // Load the contents of register L into register D.
        0x55 => {
            register.D = register.L;
            register.PC += 1;
        },

        // LD D, (HL)
        // Load the 8-bit contents of memory specified by register pair HL into register D.
        0x56 => {
            register.D = memory.get(register.getHL());
            register.PC += 1;
        },

        // LD D, A
        // Load the contents of register A into register D.
        0x57 => {
            register.D = register.A;
            register.PC += 1;
        },

        // LD E, B
        // Load the contents of register B into register E.
        0x58 => {
            register.E = register.B;
            register.PC += 1;
        },

        // LD E, C
        // Load the contents of register C into register E.
        0x59 => {
            register.E = register.C;
            register.PC += 1;
        },

        // LD E, D
        // Load the contents of register D into register E.
        0x5a => {
            register.E = register.D;
            register.PC += 1;
        },

        // LD E, E
        // Load the contents of register E into register E.
        0x5b => {
            register.E = register.E;
            register.PC += 1;
        },
        
        // LD E, H
        // Load the contents of register H into register E.
        0x5c => {
            register.E = register.H;
            register.PC += 1;
        },

        // LD E, L
        // Load the contents of register L into register E.
        0x5d => {
            register.E = register.L;
            register.PC += 1;
        },

        // LD E, (HL)
        // Load the 8-bit contents of memory specified by register pair HL
        // into register E.
        0x5e => {
            register.E = memory.get(register.getHL());
            register.PC += 1;
        },

        // LD E, A
        // Load the contents of register A into register E.
        0x5f => {
            register.E = register.A;
            register.PC += 1;
        },

        // LD H, B
        // Load the contents of register B into register H.
        0x60 => {
            register.H = register.B;
            register.PC += 1;
        },

        // LD H, C
        // Load the contents of register C into register H.
        0x61 => {
            register.H = register.C;
            register.PC += 1;
        },

        // LD H, D
        // Load the contents of register D into register H.
        0x62 => {
            register.H = register.D;
            register.PC += 1;
        },

        // LD H, E
        // Load the contents of register E into register H.
        0x63 => {
            register.H = register.E;
            register.PC += 1;
        },

        // LD H, H
        // Load the contents of register H into register H.
        0x64 => {
            register.H = register.H;
            register.PC += 1;
        },

        // TODO
        // We have to throw an error here to be exhaustive and have the correct error handling
        else => register.PC += 1,
    }

    register.IR = memory.get(register.PC);
}

pub fn execute() void {}

// Legend
// r8  - any of the 8-bit registers (A, B, C, D, E, H, L).
// r16 - any of the general-purpose 16-bit registers (BC, DE, HL).
// n8  - 8-bit integer constant (signed or unsigned, -128 to 255).
// n16 - 16-bit integer constant (signed or unsigned, -32768 to 65535).
// e8  - 8-bit signed offset (-128 to 127)
// u3  - 3-bit unsigned bit index (0 to 7, with 0 as the least significant bit).
// cc  - A condition code:
//          Z   Execute if Z is set
//          NZ  Execute if Z is not set
//          C   Execute if C is set
//          NC  Execute if C is not set
// vec - an RST vector (0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, and 0x38)
