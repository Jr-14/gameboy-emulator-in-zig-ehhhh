const std = @import("std");

const Processor = @import("../processor_new.zig");
const Memory = @import("../memory.zig");

const expectEqual = std.testing.expectEqual;

/// Set Carry Flag.
pub fn set_carry_flag(proc: *Processor) void {
    proc.flags.carry = 1;
}

test "set_carry_flag" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    set_carry_flag(&processor);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
}

/// Complement Carry Flag.
pub fn complement_carry_flag(proc: *Processor) void {
    proc.flags.negative = 0;
    proc.flags.half_carry = 0;
    proc.flags.carry = ~proc.flags.carry;
}

test "complement_carry_flag" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    complement_carry_flag(&processor);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);

    complement_carry_flag(&processor);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);

    complement_carry_flag(&processor);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.negative);
    try expectEqual(0, processor.flags.half_carry);
}

/// ComPLement accumulator (A = ~A); also called bitwise NOT.
pub fn complement_accumulator(proc: *Processor) void {
    proc.accumulator = ~proc.accumulator;
}

test "complement_accumulator" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{
        .accumulator = 0xF0,
    });

    complement_accumulator(&processor);
    try expectEqual(0x0F, processor.accumulator);

    complement_accumulator(&processor);
    try expectEqual(0xF0, processor.accumulator);
}

/// Decimal Adjust Accumulator.
/// Designed to be used after performing an arithmetic instruction (ADD, ADC, SUB, SBC) whose inputs were in
/// Binary-Coded Decimal (BCD), adjusting the result to likewise be in BCD.
/// The exact behavior of this instruction depends on the state of the subtract flag N:
pub fn decimal_adjust_accumulator(proc: *Processor) void {
    var adjustment: u8 = 0;
    switch (proc.flags.negative) {
        0 => {
            if (proc.isFlagSet(.half_carry) or proc.accumulator & 0x0F > 0x09) adjustment += 0x06;
            if (proc.isFlagSet(.carry) or proc.A.value > 0x99) {
                adjustment += 0x60;
                proc.flags.carry = 1;
            } else {
                proc.flags.carry = 0;
            }
            proc.accumulator +%= adjustment;
        },
        1 => {
            if (proc.isFlagSet(.half_carry)) adjustment += 0x06;
            if (proc.isFlagSet(.carry)) adjustment += 0x60;
            proc.accumulator -%= adjustment;
        },
    }
    proc.flags.zero = if (proc.accumulator == 0) 1 else 0;
    proc.flags.half_carry = 0;
}

test "decimal_adjust_accumulator" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .accumulator = 0x1F });

    processor.unsetFlag(.N);
    decimal_adjust_accumulator(&processor);
    try expectEqual(0x25, processor.accumulator);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0, processor.flags.half_carry);

    processor.unsetFlag(.C);
    processor.unsetFlag(.N);
    processor.accumulator = 0x60;
    decimal_adjust_accumulator(&processor);
    try expectEqual(0x60, processor.accumulator);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0, processor.flags.half_carry);

    processor.unsetFlag(.C);
    processor.unsetFlag(.N);
    processor.accumulator = 0xC3;
    decimal_adjust_accumulator(&processor);
    try expectEqual(0x23, processor.accumulator);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(1, processor.flags.carry);
    try expectEqual(0, processor.flags.half_carry);

    processor.unsetFlag(.C);
    processor.setFlag(.N);
    processor.accumulator = 0x60;
    decimal_adjust_accumulator(&processor);
    try expectEqual(0x60, processor.accumulator);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0, processor.flags.half_carry);

    processor.unsetFlag(.C);
    processor.setFlag(.H);
    processor.setFlag(.N);
    processor.accumulator = 0x6A;
    decimal_adjust_accumulator(&processor);
    try expectEqual(0x64, processor.accumulator);
    try expectEqual(0, processor.flags.zero);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0, processor.flags.half_carry);

    processor.unsetFlag(.H);
    processor.unsetFlag(.N);
    processor.accumulator = 0x00;
    decimal_adjust_accumulator(&processor);
    try expectEqual(0x00, processor.accumulator);
    try expectEqual(1, processor.flags.zero);
    try expectEqual(0, processor.flags.carry);
    try expectEqual(0, processor.flags.half_carry);
}

