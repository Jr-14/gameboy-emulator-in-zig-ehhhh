const std = @import("std");

const Processor = @import("../processor_new.zig");
const PackedRegister = @import("../register_packed.zig");
const Memory = @import("../memory.zig");
const utils = @import("../utils.zig");

const expectEqual = std.testing.expectEqual;

/// Load the 8-bit immediate operand d8 into register reg.
/// Example: 0x06 -> LD B, d8
pub fn reg8_imm8(proc: *Processor, registerValue: *u8) void {
    registerValue.* = proc.fetch();
}

test "reg8_imm8" {
    const PC: u16 = 0x0100;
    const value: u8 = 0x80;

    var memory = Memory.init();
    memory.address[PC] = value;
    var processor = Processor.init(&memory, .{});
    processor.PC = PC;

    reg8_imm8(&processor, processor.B());

    try expectEqual(value, processor.BC.bytes.high);
    try expectEqual(value, processor.B().*);
}

/// Load to the 8-bit register reg, data from the address specified by the 8-bit immediate data a8. The full
/// 16-bit absolute address is obtained by setting the most significant byte to 0xff and the least
/// significant byte to the value of a8, so the possible range is 0xff0-0xffff.
/// Example: 0xF0 -> LD A, (a8)
pub fn reg8_imm8_indirect(proc: *Processor, registerValue: *u8) void {
    const imm = proc.fetch();
    const addr: u16 = 0xFF00 | imm;
    registerValue.* = proc.memory.read(addr);
}

/// Load the contents of the source register into the destination register.
pub fn reg8_reg8(dest: *u8, src: *u8) void {
    dest.* = src.*;
}

pub fn reg8_indirect_reg8(proc: *Processor, dest: *u8, src: *u8) void {
    const addr: u16 = 0xFF00 | dest.*;
    proc.memory.write(addr, src.*);
}

/// Load to the 8-bit A register, data from the address specified by the 8-bit C register. The full 16-bit
/// address is obtianed by setting the most significant byte to 0xff and the least significant byte to the
/// value of C, so the possible range is 0xff00-0xffff.
/// Example: 0xF2 -> LD A, (C)
pub fn reg8_reg8_indirect(proc: *Processor, dest: *u8, src: *u8) void {
    const addr: u16 = 0xFF00 | src.*;
    dest.* = proc.memory.read(addr);
}

/// Load to the 8-bit register reg, data from the absolute address specified by the 16-bit operand (a16).
/// Example: 0xFA -> LD A, (a16)
pub fn reg8_imm16_indirect(proc: *Processor, dest: *u8) void {
    const lo = proc.fetch();
    const hi: u16 = proc.fetch() << 8;
    const addr: u16 = hi | lo;

    dest.* = proc.memory.read(addr);
}

/// Load the 2 bytes of immediate data into register pair rr
/// The first byte of immediate data is the lower byte (i.e. bits 0-7), and
/// the second byte of immediate data is the higher byte (i.e., bits 8-15)
/// Example: 0x01 -> LD BC, d16
pub fn reg16_imm16(proc: *Processor, regPair: *PackedRegister) void {
    regPair.bytes.low = proc.fetch();
    regPair.bytes.high = proc.fetch();
}

/// Load to the address specified by the 8-bit immediate data, data from the 8-bit register. The full
/// 16-bit absolute address is obtained by setting the most significant byte to 0xff and the least significant
/// byte to the value of a8, so the possible range is 0xff00-0xffff.
pub fn imm8_indirect_reg8(proc: *Processor, registerValue: *u8) void {
    const imm = proc.fetch();
    const addr: u16 = 0xFF00 | imm;
    proc.memory.write(addr, registerValue.*);
}

/// Store the contents of a register reg into the memory location specified by the register pair rr.
/// Example: 0x12 -> LD (DE), A
pub fn hl_indirect_reg8(proc: *Processor, registerValue: *u8) void {
    proc.memory.write(proc.HL.value, registerValue.*);
}

/// Store the contents of 8-bit immediate operand d8 in the memory location
/// specified by register pair rr.
/// Example: 0x36 -> LD (HL), d8
pub fn reg16_indirect_imm8(proc: *Processor, regPair: *PackedRegister) void {
    const value = proc.fetch();
    proc.memory.write(regPair.value, value);
}

/// Store the contents of the accumulator register in the memory location specified by
/// register pair rr
/// Example: 0x02 -> LD (BC), A
pub fn reg16_indirect_acc8(proc: *Processor, regPair: *PackedRegister) void {
    proc.memory.write(regPair.value, proc.accumulator);
}

/// Store the contents of register A in the internal RAM or register specified by the 16-bit immediate
/// operand a16.
/// Example: 0xEA -> LD (a16), A
pub fn imm16Mem_reg(proc: *Processor, registerValue: *u8) void {
    const lo: u8 = proc.fetch();
    const hi: u16 = proc.fetch() << 8;
    const addr: u16 = hi | lo;
    proc.memory.write(addr, registerValue.*);
}

/// Store the lower byte of Special Purpose Register (SPR) at the address specified by the 16-bit
/// immediate operand a16, and store the upper byte of SPR at address a16 + 1.
/// Example: 0x08 -> LD (a16), SP
pub fn imm16Mem_spr(proc: *Processor, val: u16) void {
    const lo: u8 = proc.fetch();
    const hi: u16 = proc.fetch() << 8;
    const addr: u16 = hi | lo;
    proc.memory.write(addr, utils.getLoByte(val));
    proc.memory.write(addr + 1, utils.getHiByte(val));
}

/// Load the 2 bytes of immediate data into special purpose register (SPR).
/// The first byte of immedaite data is the lower byte (i.e., bits 0-7), and the second byte of
/// immediate data is the higher byte (i.e., bits 8-15).
pub fn spr_imm16(proc: *Processor, spr: *u16) void {
    const lo: u8 = proc.fetch();
    const hi: u16 = proc.fetch() << 8;
    spr.* = hi | lo;
}

/// Load the contents of register pair rr into the Special Purpose Register.
/// Example: 0xF9 -> LD SP, HL
pub fn spr_rr(spr: *u16, regPair: *PackedRegister) void {
    spr.* = regPair.value;
}

/// Load the 8-bit contents of memory specified by register pair rr into register reg
/// Example: 0x0A -> LD A, (BC)
pub fn reg8_reg16_indirect(proc: *Processor, reg: *u8, regPair: *PackedRegister) void {
    reg.* = proc.memory.read(regPair.value);
}

/// Store the contents of register reg into the memory location specified by register pair
/// HL, and simultaneously increment the contents of HL
/// Example: 0x22 -> LD (HL+), A
pub fn hl_indirect_inc_reg8(proc: *Processor, registerValue: *u8) void {
    proc.memory.write(proc.HL.value, registerValue.*);
    proc.HL.value +%= 1;
}

/// Store the contents of register reg into the memory location specified by register pair
/// HL, and simultaneously decrement the contents of HL.
pub fn hl_indirect_dec_reg8(proc: *Processor, registerValue: *u8) void {
    proc.memory.write(proc.HL.value, registerValue.*);
    proc.HL.value -%= 1;
}

/// Load the contents of memory specified by register pair rr into register reg, and simultaneously
/// increment the contents of HL.
/// Example: 0x2A -> LD A, (HL+)
pub fn reg8_hl_indirect_inc(proc: *Processor, registerValue: *u8) void {
    registerValue.* = proc.memory.read(proc.HL.value);
    proc.HL.vaue +%= 1;
}

/// Load the contents of memory specified by register pair HL into register reg, and
/// simultaneously decrement the contents of HL.
/// Example: 0x3A -> LD A, (HL-)
pub fn reg8_hl_indirect_dec(proc: *Processor, registerValue: *u8) void {
    registerValue.* = proc.memory.read(proc.HL.value);
    proc.HL.value -%= 1;
}

// Add the 8-bit signed operand s8 (values -128 to +127) to the stack pointer SP, and store the result in
// register pair HL.
pub fn hl_sp_imm8(proc: *Processor) void {
    const imm = proc.fetch();
    const result = utils.Arithmetic(u16).add_offset(proc.SP, imm);

    proc.SP = result.value;

    proc.flags.zero = 0;
    proc.flags.negative = 0;
    proc.flags.half_carry = result.half_carry;
    proc.flags.carry = result.carry;
}

test "reg16_imm16" {
    const PC: u16 = 0x0100;
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .PC = PC });
    const immLo: u8 = 0x03;
    const immHi: u8 = 0xA5;

    processor.memory.write(PC, immLo);
    processor.memory.write(PC + 1, immHi);

    reg16_imm16(&processor, .BC);
    try expectEqual(immHi, processor.B.value);
    try expectEqual(immLo, processor.C.value);
}
