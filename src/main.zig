const std = @import("std");

const RegisterError = error{
    RegisterNotFound
};

const Register = struct {
    A: u8 = 0,
    B: u8 = 0,
    C: u8 = 0,
    D: u8 = 0,
    E: u8 = 0,
    H: u8 = 0,
    L: u8 = 0,
    BC: u16 = 0,
    DE: u16 = 0,
    HL: u16 = 0,
};

pub fn main() !void {
    // We use to have a StringHashMap with allocated memory
    // but looking at it, structs are probably better
    // var register = createRegister();
}

pub fn createRegister() Register {
    return Register {
        .A = 0,
        .B = 0,
        .C = 0,
        .D = 0,
        .E = 0,
        .H = 0,
        .L = 0,
        .BC = 0,
        .DE = 0,
        .HL = 0,
    };
}

pub fn fetch() void {}

pub fn decodeAndExecute(word: [3]u8, registers: *Register, pc: *u32) !void {
    const op_code = word[0];
    const first_byte = word[1];
    const second_byte = word[2];
    // TODO:
    // state all the different instructions for 8-bit opcodes
    //
    // TODO:
    // Look at 16-bit opcodes? Is this required?
    switch (op_code) {
        // NOP (No operation) Only advances the program counter by 1.
        // Performs no other operations that would have an effect
        0x00 => pc.* += 1,

        // LD BC, d16
        // Load the 2 bytes of immediate data into register pair BC
        // The first byte of immediate data is the lower byte (i.e. bits 0-7), and 
        // the second byte of immediate data is the higher byte (i.e., bits 8-15)
        0x01 => {
            registers.BC = (second_byte << 8) + first_byte;
            pc.* += 1;
        },

        // LD (BC), A
        // Store the contents of register A in the memory location specified by
        // register pair BC
        0x02 => pc.* += 1,

        // INC BC
        // Increment the contents of register pair BC by 1
        0x03 => {
            registers.BC += 1;
            pc.* += 1;
        },

        // INC B
        // Increment the contents of register B by 1.
        // TODO:
        // This has some flags? e.g. Z 0 8-bit -
        0x04 => {
            registers.B += 1;
            pc.* += 1;
        },

        // Decrement the contents of register B by 1
        // TODO:
        // Flags: Z 1 8-bit -
        // 0x05 => "DEC B",

        // Load the 8-bit immediate operand d8 into register B.
        // 0x06 => "LD B, d8",

        // Rotate the contents of register A to the left. That is, the contents of bit 0
        // are copied to bit 1, and the previous contents of bit 1 (before the copy operation)
        // are copied to bit 2. The same operation is repeated oin sequence for the rest
        // of the register. The contents of bit 7 are placed in both the CY flag and bit 0 of
        // register A.
        // TODO:
        // Flags: 0 0 0 A7
        // 0x07 => "RLCA",

        // Store the lower byte of stack pointer SP at the address specified by the 16-bit
        // immediate operand 16, and store the upper byte of SP at address a16 + 1.
        // 0x08 => "LD (a16), SP",

        // Add the contents of register pair BC t othe contents of register pair HL, and
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

        // Load the 8-bit immediate operand d8 into register C
        // 0x0e => "LD C, d8",

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

        // Store the contents of register A in the memory location specified by register pair DE.
        // 0x12 => "LD (DE), A",

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

        // Load the 8-bit immediate operand d8 into register D.
        // 0x16 => "LD D, d8",

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

        // Load the 8-bit immediate operand d8 into register E.
        // 0x1e => "LD E, d8",

        // Rotate the contents of register A to the right, through the carry (CY) flag. That is, the contents
        // of bit 7 are copied to bit 6, and the previous contents of bit 6 (before the copy) are copied to bit
        // 5. The same operation is repeated in sequence for the rest of the register. The previous contents of
        // the carry flag are copied to bit 7.
        // 0x1f => "RRA",

        else => pc.* += 1,
    }
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
