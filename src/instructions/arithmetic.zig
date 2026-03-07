const std = @import("std");

const Processor = @import("../processor_new.zig");
const Memory = @import("../memory.zig");
const utils = @import("../utils.zig");

const expectEqual = std.testing.expectEqual;

/// Increment the contents of register reg by 1.
/// Example: 0x05 -> DEC B
pub fn inc_reg8(
    proc: *Processor,
    registerValue: *u8,
) void {
    const sum = utils.Arithmetic(u8).add(.{
        .a = registerValue.*,
        .b = 1
    });
    registerValue.* = sum.value;
    // proc.unsetFlag(.N);
    proc.flags.negative = 0;
    proc.flags.zero = sum.value;
    proc.flags.half_carry = sum.half_carry;
}

test "inc_reg8" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{});

    inc_reg8(&processor, &processor.B);

    try expectEqual(0x01, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    inc_reg8(&processor, &processor.B);

    try expectEqual(0x02, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.B.value = 0xFF;
    inc_reg8(&processor, &processor.B);

    try expectEqual(0x00, processor.B.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.B.value = 0x0F;
    inc_reg8(&processor, &processor.B);
    try expectEqual(0x10, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.E.value = 0x0F;
    inc_reg8(&processor, &processor.E);
    try expectEqual(0x10, processor.E.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

/// Decrement the contents of register reg by 1
/// Example: 0x0D -> DEC C
pub fn dec_reg8(
    proc: *Processor,
    registerValue: *u8,
) void {
    const remainder = utils.Arithmetic(u8).subtract(.{
        .a = registerValue.value,
        .b = 1
    });
    registerValue.* = remainder.value;
    proc.flags.negative = 1;
    proc.flags.zero = remainder.value;
    proc.flags.half_carry = remainder.half_carry;
}

test "dec_reg8" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .D = 0x02 });

    dec_reg8(&processor, &processor.D);
    try expectEqual(0x01, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    dec_reg8(&processor, &processor.D);
    try expectEqual(0x00, processor.D.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    dec_reg8(&processor, &processor.D);
    try expectEqual(0xFF, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

/// Increment the contents of register pair rr by 1
pub fn inc_reg16(registerValue: *u16) void {
    registerValue.* +%= 1;
}

test "inc_reg16" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    inc_reg16(&processor, .AF);
    try expectEqual(1, processor.getAF());

    processor.setAF(0xFFFF);
    inc_reg16(&processor, .AF);
    try expectEqual(0, processor.getAF());

    processor.setBC(0x00FF);
    inc_reg16(&processor, .BC);
    try expectEqual(0x0100, processor.getBC());

    processor.setDE(0x0101);
    inc_reg16(&processor, .DE);
    try expectEqual(0x0102, processor.getDE());

    processor.setHL(0x0FFF);
    inc_reg16(&processor, .HL);
    try expectEqual(0x1000, processor.getHL());
}

/// Decrement the contents of register pair rr by 1
pub fn dec_reg16(registerValue: *u16) void {
    registerValue.* -%= 1;
}

test "dec_reg16" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    dec_reg16(&processor, .AF);
    try expectEqual(0xFFFF, processor.getAF());

    processor.setBC(0x0100);
    dec_reg16(&processor, .BC);
    try expectEqual(0x00FF, processor.getBC());

    processor.setDE(0x0102);
    dec_reg16(&processor, .DE);
    try expectEqual(0x0101, processor.getDE());

    processor.setHL(0x1000);
    dec_reg16(&processor, .HL);
    try expectEqual(0x0FFF, processor.getHL());
}

pub fn inc_sp(proc: *Processor) void {
    proc.SP +%= 1;
}

pub fn dec_sp(proc: *Processor) void {
    proc.SP -%= 1;
}

/// Add to HL the value of SP
pub fn add_hl_sp(proc: *Processor) void {
    const result = utils.Arithmetic(u16).add(.{
        .a = proc.getHL(),
        .b = proc.SP,
    });

    proc.HL.value = result.value;

    proc.flags.negative = 1;
    proc.flags.carry = result.carry;
    proc.flags.half_carry = result.half_carry;
}

pub fn add_sp_offset(proc: *Processor) void {
    const imm = proc.fetch();
    const result = utils.Arithmetic(u16).add_offset(proc.SP, imm);

    proc.SP = result.value;

    proc.flags.zero = 0;
    proc.flags.negative = 0;
    proc.flags.carry =  result.carry;
    proc.flags.half_carry = result.half_carry;
}

fn add_aux(proc: *Processor, values: struct {
    b: u8,
    carry: u1 = 0,
}) void {
    const sum = utils.Arithmetic(u8).add(.{
        .a = proc.accumulator,
        .b = values.b,
        .carry = values.carry,
    });
    proc.accumulator = sum.value;
    proc.flags.negative = 0;
    proc.flags.zero = sum.value;
    proc.flags.carry = sum.carry;
    proc.flags.half_carry = sum.half_carry;
}

/// Add the contents of register reg to the contents of accumulator (A) register,
/// and store the results in the accumulator (A) register.
/// Example: 0x80 ADD A, B
pub fn add_reg8(proc: *Processor, registerValue: *u8) void {
    add_aux(proc, .{ .b = registerValue.* });
}

test "add_reg8" {
    const PC: u16 = 0x0100;
    const A: u8 = 0x14;
    const B: u8 = 0x07;
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .PC = PC, .A = A, .B = B });

    add_reg8(&processor, &processor.B);
    try expectEqual(0x1B, processor.A.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.C));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.A.value = 0xFF;
    processor.C.value = 0xFF;
    add_reg8(&processor, &processor.C);
    try expectEqual(0xFE, processor.A.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.C));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.D.value = 0x02;
    add_reg8(&processor, &processor.D);
    try expectEqual(0x00, processor.A.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.C));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.E.value = 0x01;
    add_reg8(&processor, &processor.E);
    try expectEqual(0x01, processor.A.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.C));
    try expectEqual(false, processor.isFlagSet(.H));
}

/// Add the contents of memory specified by register pair HL to the contents of register A, and store the results
/// in register A.
/// Example: 0x86 -> ADD A, (HL)
pub fn add_hl_indirect(proc: *Processor) void {
    add_aux(proc, .{ .b = proc.memory.read(proc.HL.value) });
}

pub fn add_imm8(proc: *Processor) void {
    const imm = proc.fetch();
    add_aux(proc, .{ .b =  imm });
}

/// Add the contents of register reg and the CY flag to the contents of the accumulator (A) register, and
/// store the results in accumulator (A) register.
/// Example: 0x88 -> ADC A, B
pub fn addc_reg8(proc: *Processor, registerValue: *u8) void {
    add_aux(proc, .{
        .b =  registerValue.*,
        .carry = proc.flags.carry,
    });
}

/// Add the contents of memory specified by register pair HL and the CY flag to the contents of
/// accumulator (A) register and store the results in the accumulator (A) register.
/// Example: 0x8E -> ADC A, (HL)
pub fn addc_hl_indirect(proc: *Processor) void {
    add_aux(proc, .{
        .b = proc.memory.read(proc.HL.value),
        .carry = proc.flags.carry,
    });
}

pub fn add_reg16_reg16(proc: *Processor, dest: *u16, src: *u16) void {
    const result = utils.Arithmetic(u16).add(.{
        .a = dest.*,
        .b = src.*,
    });
    dest.* = result.value;
    proc.flags.negative = 0;
    proc.flags.carry = result.carry;
    proc.flags.half_carry = result.half_carry;
}

test "add_reg16_reg16" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{
        .B = 0x11,
        .C = 0x5E,
    });
    
    add_reg16_reg16(&processor, .HL, .BC);
    try expectEqual(0x115E, processor.getHL());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.C));
    try expectEqual(false, processor.isFlagSet(.H));
}

pub fn addc_imm8(proc: *Processor) void {
    add_aux(proc, .{
        .b = proc.memory.read(proc.fetch()),
        .carry = proc.flags.carry,
    });
}

fn sub_aux(proc: *Processor, values: struct{
    b: u8,
    carry: u1 = 0,
}) void {
    const remainder = utils.Arithmetic(u8).subtract(.{
        .a = proc.accumulator,
        .b = values.b,
        .carry = values.carry,
    });
    proc.accumulator = remainder.value;
    proc.flags.negative = 1;
    proc.flags.zero = remainder.value;
    proc.flags.half_carry = remainder.half_carry;
    proc.flags.car = remainder.carry;
}

/// Subtract the contents of register reg to the contents of accumulator (A) register,
/// and store the results in the accumulator (A) register.
/// Example: 0x93 -> SUB E
pub fn sub_reg8(proc: *Processor, registerValue: *u8) void {
    sub_aux(proc, .{
        .b = registerValue.*,
    });
}

pub fn sub_imm8(proc: *Processor) void {
    sub_aux(proc, .{
        .b = proc.fetch(),
    });
}

/// Subtract the contents of register reg and the CY flag from the contents of accumulator (A) register,
/// and store the results in accumulator (A) register.
pub fn subc_reg8(proc: *Processor, registerValue: *u8) void {
    sub_aux(proc, .{
        .b = registerValue.*,
        .carry = proc.flags.carry,
    });
}

pub fn subc_imm8(proc: *Processor) void {
    sub_aux(proc, .{
        .b = proc.fetch(),
        .carry = proc.flags.carry,
    });
}

/// Subtract the contents of memory specified by register pair HL from the contents of accumulator (A) register
/// and store the results in accumulator (A) register.
/// Example: 0x96 -> SUB A, (HL)
pub fn sub_hl_indirect(proc: *Processor) void {
    sub_aux(proc, .{
        .b = proc.memory.read(proc.HL.value),
    });
}

pub fn subc_hl_indirect(proc: *Processor) void {
    sub_aux(proc, .{
        .b = proc.memory.read(proc.HL.value),
        .carry = proc.flags.carry,
    });
}

fn and_aux(proc: *Processor, value: u8) void {
    proc.accumulator &= value;

    if (proc.accumulator == 0) proc.flags.zero = 1 else proc.flags.zero = 0;
    proc.flags.negative = 0;
    proc.flags.half_carry = 1;
    proc.flags.carry = 0;
}

/// Take the logical AND for each bit of the contents of register reg and the contents of register A,
/// and store the results in register A.
/// Example: 0xA0 -> AND A, B
pub fn and_reg8(proc: *Processor, registerValue: *u8) void {
    and_aux(proc, registerValue.*);
}

pub fn and_imm8(proc: *Processor) void {
    const imm = proc.fetch();
    and_aux(proc, imm);
}

pub fn and_hl_indirect(proc: *Processor) void {
    const val = proc.memory.read(proc.HL.value);
    and_aux(proc, val);
}

fn or_aux(proc: *Processor, value: u8) void {
    proc.accumulator |= value;

    if (proc.accumulator == 0) proc.flags.zero = 1 else proc.flags.zero = 0;
    proc.flags.negative = 0;
    proc.flags.half_carry = 0;
    proc.flags.carry = 0;
}

pub fn or_reg8(proc: *Processor, registerValue: *u8) void {
    or_aux(proc, registerValue.*);
}

pub fn or_imm8(proc: *Processor) void {
    const imm = proc.fetch();
    or_aux(proc, imm);
}

pub fn or_hl_indirect(proc: *Processor) void {
    const val = proc.memory.read(proc.HL.value);
    or_aux(proc, val);
}

fn xor_aux(proc: *Processor, value: u8) void {
    proc.accumulator ^= value;

    if (proc.accumulator == 0) proc.flags.zero = 1 else proc.flags.zero = 0;
    proc.flags.negative = 0;
    proc.flags.half_carry = 0;
    proc.flags.carry = 0;
}

pub fn xor_reg8(proc: *Processor, registerValue: *u8) void {
    xor_aux(proc, registerValue.*);
}

pub fn xor_imm8(proc: *Processor) void {
    const imm = proc.fetch();
    xor_aux(proc, imm);
}

pub fn xor_hl_indirect(proc: *Processor) void {
    const val = proc.memory.read(proc.HL.value);
    xor_aux(proc, val);
}

fn compare_aux(proc: *Processor, value: u8) void {
    const remainder = utils.Arithmetic(u8).add(proc.A.value, value);

    if (remainder.value == 0) proc.flags.zero = 1 else proc.flags.zero = 0;
    proc.flags.negative = 0;
    proc.flags.half_carry = remainder.half_carry;
    proc.flags.carry = remainder.carry;
}

pub fn compare_reg8(proc: *Processor, registerValue: *u8) void {
    compare_aux(proc, registerValue.*);
}

pub fn compare_hl_indirect(proc: *Processor) void {
    const val = proc.memory.read(proc.HL.value);
    compare_aux(proc, val);
}

pub fn compare_imm8(proc: *Processor) void {
    const imm = proc.fetch();
    compare_aux(proc, imm);
}

