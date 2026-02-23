const std = @import("std");
const Register = @import("register.zig");
const PackedRegister = @import("register_packed.zig").PackgedRegisterPair;
const Processor = @import("processor_new.zig");
const Memory = @import("memory.zig");
const mask = @import("masks.zig");
const utils = @import("utils.zig");

const Bit = utils.Bit;

const FlagCondition = enum(u1) {
    is_not_set,
    is_set,
};

pub const arithmetic = struct {
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
        // proc.setFlag(.N);
        // if (remainder.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        // if (remainder.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    /// Increment the contents of register pair rr by 1
    pub fn inc_reg16(registerValue: *u16) void {
        registerValue.* +%= 1;
    }

    /// Decrement the contents of register pair rr by 1
    pub fn dec_reg16(registerValue: *u16) void {
        registerValue.* -%= 1;
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

        // proc.setHL(result.value);
        proc.HL.value = result.value;
        proc.flags.negative = 1;
        proc.flags.carry = result.carry;
        proc.flags.half_carry = result.half_carry;
        // proc.setFlag(.N);
        // if (result.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        // if (result.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    pub fn add_sp_offset(proc: *Processor) void {
        const imm = proc.fetch();
        const result = utils.Arithmetic(u16).add_offset(proc.SP, imm);
        proc.SP = result.value;
        proc.flags.zero = 0;
        proc.flags.negative = 0;
        proc.flags.carry =  result.carry;
        proc.flags.half_carry = result.half_carry;
        // proc.unsetFlag(.Z);
        // proc.unsetFlag(.N);
        // if (result.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        // if (result.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
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
        // proc.unsetFlag(.N);
        // if (sum.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        // if (sum.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        // if (sum.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    /// Add the contents of register reg to the contents of accumulator (A) register,
    /// and store the results in the accumulator (A) register.
    /// Example: 0x80 ADD A, B
    pub fn add_reg8(proc: *Processor, registerValue: *u8) void {
        add_aux(proc, .{ .b = registerValue.* });
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
        // dest_setter(proc, result.value);
        // proc.unsetFlag(.N);
        // if (result.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        // if (result.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
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
        // proc.setFlag(.N);
        // if (remainder.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        // if (remainder.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        // if (remainder.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
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
        // if (proc.A.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        // proc.unsetFlag(.N);
        // proc.setFlag(.H);
        // proc.unsetFlag(.C);
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
        // if (proc.A.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        // proc.unsetFlag(.N);
        // proc.unsetFlag(.H);
        // proc.unsetFlag(.C);
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
        // if (proc.A.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        // proc.unsetFlag(.N);
        // proc.unsetFlag(.H);
        // proc.unsetFlag(.C);
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
};

pub const load = struct {
    /// Load the 8-bit immediate operand d8 into register reg.
    /// Example: 0x06 -> LD B, d8
    pub fn reg_imm8(proc: *Processor, registerValue: *u8) void {
        registerValue.* = proc.fetch();
    }

    /// Load to the 8-bit register reg, data from the address specified by the 8-bit immediate data a8. The full
    /// 16-bit absolute address is obtained by setting the most significant byte to 0xff and the least
    /// significant byte to the value of a8, so the possible range is 0xff0-0xffff.
    /// Example: 0xF0 -> LD A, (a8)
    pub fn reg_imm8_indirect(proc: *Processor, registerValue: *u8) void {
        const addr: u16 = 0xFF00 | proc.fetch();
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
        // dest.value = proc.memory.read(utils.fromTwoBytes(src.value, 0xFF));
        const addr: u16 = 0xFF00 | src.*;
        dest.* = proc.memory.read(addr);
    }

    /// Load to the 8-bit register reg, data from the absolute address specified by the 16-bit operand (a16).
    /// Example: 0xFA -> LD A, (a16)
    pub fn reg8_imm16_indirect(proc: *Processor, dest: *u8) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        const addr = (@as(u16, hi) << 8) | lo;

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
        const addr: u16 = 0xFF00 | proc.fetch();
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
        // proc.setHL(hl -% 1);
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
};

pub const controlFlow = struct {
    /// Jump s8 steps relative from the current address in the program counter (PC).
    /// Example: 0x18 -> JR s8
    pub fn jump_rel_imm8(proc: *Processor) void {
        const offset = proc.fetch();
        proc.PC = utils.addOffset(proc.PC, offset);
    }

    /// If the flag condition is met, jump s8 steps from the current address stored in the program counter (PC). If not, the
    /// instruction following the current JP instruction is executed (as usual).
    /// Example: 0x20 -> JR NZ, s8
    pub fn jump_rel_cc_imm8(proc: *Processor, flag: *u1, condition: FlagCondition) void {
        const offset = proc.fetch();
        if (flag.* == @intFromEnum(condition)) {
            proc.PC = utils.addOffset(proc.PC, offset);
        }
    }

    /// Load the 16-bit immediate operand a16 into the program counter (PC). a16 specifies the address of the
    /// subsequently executed instruction.
    /// The second byte of the object code (immediately following the opcode) corresponds to the lower-order
    /// byte of a16 (bits 0-7), and the third byte of the object code corresponds to the higher-order byte
    /// (bits 8-15).
    /// Example: 0xC3 -> JP a16
    pub fn jump_imm16(proc: *Processor) void {
        const lo: u8 = proc.fetch();
        const hi: u16 = proc.fetch() << 8;
        const addr: u16 = hi | lo;
        proc.PC = addr;
    }


    /// Load the 16-bit immediate operand a16 into the program counter PC if the flag condition cc is met. If the
    /// condition is met, then the subsequent instruction starts at address a16. If not, the contents of PC are
    /// incremented, and the next instruction following the current JP instruction is executed (as usual).
    ///
    /// The second byte of the object code (immediately following the opcode) corresponds to the lower-order
    /// byte of a16 (bits 0-7), and the third byte of the object code corresponds to the higher-order byte
    /// (bits 8-15).
    /// Example: 0xC2 -> JP NZ, a16
    pub fn jump_cc_imm16(proc: *Processor, flag: *u1, condition: FlagCondition) void {
        const lo = proc.fetch();
        const hi: u16 = proc.fetch() << 8;
        if (flag.* == @intFromEnum(condition)) {
            proc.PC = hi | lo;
        }
    }

    /// Load the contents of register pair HL into the program counter PC. The next instruction is fetched from
    /// the location specified by the new value of PC.
    /// Example: 0xE9 -> JP HL
    pub fn jump_hl(proc: *Processor) void {
        proc.PC = proc.HL.value;
    }

    /// Pop from the memory stack the program counter PC value pushed when the subroutine was called, returning
    /// control to the source program.
    /// The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC,
    /// and the contents of SP are incremented by 1. The contents of the address specified by the new SP value
    /// are then loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again.
    /// (The value of SP is 2 larger than before instruction execution.) The next instruction is fetched from
    /// the address specified by the content of PC (as usual).
    /// Example: 0xC9 -> RET
    pub fn ret(proc: *Processor) void {
        const lo: u8 = proc.popStack();
        const hi: u16 = proc.popStack() << 8;
        proc.PC = hi | lo;
    }


    /// If condition flag cc is met, control is returned to the source program by popping from the memory stack the program
    /// counter PC value that was pushed to the stack when the subroutine was called.
    ///
    /// The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC, and
    /// the contents of SP are incremented by 1. The contents of the address specified by the new SP value are then
    /// loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again. (The value of SP
    /// is 2 larger than before instruction execution.) The next instruction is fetched from the address specified
    /// by the content of PC (as usual).
    /// Example: 0xC0 -> RET NZ
    pub fn ret_cc(proc: *Processor, flag: *u1, condition: FlagCondition) void {
        if (flag.* == @intFromEnum(condition)) {
            ret(proc);
        }
    }

    /// Used when an interrupt-service routine finishes. The address for the return from the interrupt is loaded
    /// in the program counter PC. The master interrupt enable flag is returned to its pre-interrupt status.
    /// The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC,
    /// and the contents of SP are incremented by 1. The contents of the address specified by the new SP value
    /// are then loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again. 
    /// (The value of SP is 2 larger than before instruction execution.) The next instruction is fetched from
    /// the address specified by the content of PC (as usual).
    /// Example: 0xD9 -> RETI
    pub fn reti(proc: *Processor) void {
        ret(proc);
        proc.IME = true;
    }

    /// Pop the contents from the memory stack into register pair rr by doing the following:
    /// 1. Load the contents of memory specified by stack pointer SP into the lower portion of rr.
    /// 2. Add 1 to SP and load the contents from the new memory location into the upper portion rr.
    /// 3. By the end, SP should be 2 more than its initial value.
    /// Example: 0xC1 -> POP BC
    pub fn pop_rr(proc: *Processor, regPair: *PackedRegister) void {
        regPair.bytes.low = proc.popStack();
        regPair.bytes.high = proc.popStack();
    }

    /// Push the contents of register pair rr onto the memory stack by doing the following:
    /// 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of register pair
    /// BC on on the stack.
    /// 2. Subtract 1 from SP, and put the lower portion of register pair BC on the stack.
    /// Example: 0xC5 -> PUSH BC
    pub fn push_rr(proc: *Processor, regPair: *PackedRegister) void {
        proc.pushStack(regPair.bytes.high);
        proc.pushStack(regPair.bytes.low);
    }

    /// In memory, push the program counter PC value corresponding to the address following the CALL instruction
    /// to the 2 bytes following the byte specified by the current stack pointer SP. Then load the 16-bit
    /// immediate operand a16 into PC.
    /// The subroutine is placed after the location specified by the new PC value. When the subroutine finishes,
    /// control is returned to the source program using a return instruction and by popping the starting address
    /// of the next instruction (which was just pushed) and moving it to the PC.
    /// With the push, the current value of SP is decremented by 1, and the higher-order byte of PC is loaded in
    /// the memory address specified by the new SP value. The value of SP is then decremented by 1 again, and
    /// the lower-order byte of PC is loaded in the memory address specified by that value of SP.
    /// The lower-order byte of a16 is placed in byte 2 of the object code, and the higher-order byte is placed
    /// in byte 3.
    /// Example: 0xCD -> CALL a16
    pub fn call_imm16(proc: *Processor) void {
        const lo: u8 = proc.fetch();
        const hi: u16 = proc.fetch() << 8;
        proc.pushStack(utils.getHiByte(proc.PC));
        proc.pushStack(utils.getLoByte(proc.PC));
        proc.PC = hi | lo;
    }

    /// If condition flag is met, the program counter PC value corresponding to the memory location of the instruction
    /// following the CALL instruction is pushed to the 2 bytes following the memory byte specified by the stack
    /// pointer SP. The 16-bit immediate operand a16 is then loaded into PC.
    ///
    /// The lower-order byte of a16 is placed in byte 2 of the object code, and the higher-order byte is placed
    /// in byte 3.
    /// Example: 0xC4 -> CALL NZ, a16
    pub fn call_cc_imm16(proc: *Processor, flag: *u1, condition: FlagCondition) void {
        const lo: u8 = proc.fetch();
        const hi: u16 = proc.fetch() << 8;

        if (flag.* == @intFromEnum(condition)) {
            proc.pushStack(utils.getHiByte(proc.PC));
            proc.pushStack(utils.getLoByte(proc.PC));
            proc.PC = hi | lo;
        }
    }

    /// Push the current value of the program counter PC onto the memory stack, and load into PC the 1th byte
    /// of page 0 memory addresses, 0x00. The next instruction is fetched from the address specified by the new
    /// content of PC (as usual).
    /// With the push, the contents of the stack pointer SP are decremented by 1, and the higher-order byte of
    /// PC is loaded in the memory address specified by the new SP value. The value of SP is then again
    /// decremented by 1, and the lower-order byte of the PC is loaded in the memory address specified by that
    /// value of SP.
    /// The RST instruction can be used to jump to 1 of 8 addresses. Because all of the addresses are held in
    /// page 0 memory, 0x00 is loaded in the higher-order byte of the PC, and 0x00 + (8 * index) is loaded in
    /// the lower-order byte.
    /// Example: 0xC7 -> RST 0 will load the address 0x0000
    /// Example: 0xEF -> RST 5 will load the address 0x0028
    pub fn rst(proc: *Processor, index: u3) void {
        proc.pushStack(utils.getHiByte(proc.PC));
        proc.pushStack(utils.getLoByte(proc.PC));
        proc.PC = mask.HI_MASK | (0x08 * @as(u8, index));
    }

};

pub const bitShift = struct {
    /// Rotates the 8-bit A register value left through the carry flag.
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). The carry flag is copied to bit
    /// 0, and bit 7 is copied to the carry flag. Note that unlike the related RL r instruction, RLA always
    /// sets the zero flag to 0 without looking at the resulting value of the calculation.
    pub fn rotate_left_a(proc: *Processor) void {
        const bit_7: u1 = @truncate(proc.accumulator >> 7);
        const carry = proc.flags.carry;

        proc.accumulator <<= 1;
        proc.accumulator |= carry;

        proc.flags.carry = bit_7;
        proc.flags.zero = 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
    }

    /// Rotates the 8-bit A register value left in a circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). Bit 7 is copied both to bit
    /// 0 and the carry flag. Note that unlike the related RLC r instruction, RLCA always sets the zero
    /// flag to 0 without looking at the resulting value of the calculation.
    pub fn rotate_left_circular_a(proc: *Processor) void {
        // const bit_7_mask: u8 = 0x80;
        // const bit_7: u1 = if ((proc.A.value & bit_7_mask) == bit_7_mask) 1 else 0;
        // if (bit_7 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        // proc.unsetFlag(.Z);
        // proc.unsetFlag(.N);
        // proc.unsetFlag(.H);
        // proc.A.value <<= 1;
        // proc.A.value |= bit_7;
        const bit_7: u1 = @truncate(proc.accumulator >> 7);

        proc.accumulator <<= 1;
        proc.accumulator |= bit_7;

        proc.flags.zero = 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotate the contents of register A to the right, through the carry (CY) flag.
    /// That is, the contents of bit 7 are copied to bit 6, and the previous contents of bit 6 (before the copy) are
    /// copied to bit 5. The same operation is repeated in sequence for the rest of the register.
    /// The previous contents of the carry flag are copied to bit 7.
    pub fn rotate_right_a(proc: *Processor) void {
        const bit_0: u1 = @truncate(proc.accumulator);

        proc.accumulator >>= 1;
        if (proc.isFlagSet(.carry)) {
            proc.accumulator |= 0x80;
        }

        proc.flags.zero = 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotate the contents of register A to the right.
    /// That is, the contents of bit 7 are copied to bit 6, and the previous contents of bit 6 (before the copy) are
    /// copied to bit 5. The same operation is repeated in sequence for the rest of the register.
    /// The contents of bit 0 are placed in both the CY flag and bit 7 of register A.
    pub fn rotate_right_circular_a(proc: *Processor) void {
        // const bit_0: u1 = @truncate(proc.A.value);
        // const carry_mask: u8 = if (bit_0 == 1) 0x80 else 0x00;
        // proc.unsetFlag(.Z);
        // proc.unsetFlag(.N);
        // proc.unsetFlag(.H);
        // if (bit_0 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        // proc.A.value >>= 1;
        // proc.A.value |= carry_mask;

        const bit_0: u1 = @truncate(proc.accumulator);

        proc.accumulator >>= 1;
        if (bit_0 == 1) {
            proc.accumulator |= 0x80;
        }

        proc.flags.zero = 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotates the 8-bit register r value left in a circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). Bit 7 is copied both to bit 0
    /// and the carry flag.
    pub fn rotate_left_circular_r8(proc: *Processor, registerValue: *u8) void {
        const bit_7: u1 = @truncate(registerValue.* >> 7);

        registerValue.* <<= 1;
        registerValue.* |= bit_7;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotates the 8-bit register r value right in a circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). Bit 0 is copied both to bit 7
    /// and the carry flag.
    pub fn rotate_right_circular_r8(proc: *Processor, registerValue: *u8) void {
        const bit_0: u1 = @truncate(registerValue.* >> 7);

        registerValue.* >>= 1;
        if (bit_0 == 1) {
            registerValue |= 0x80;
        }

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, left in a
    /// circular manner (carry flag is updated but not used).
    /// Every bit is shifted t
    pub fn rotate_left_circular_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_7: u1 = @truncate(contents.* >> 7);

        contents.* <<= 1;
        contents.* |= bit_7;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, right in a
    /// circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). Bit 0 is copied both to bit 7
    /// and the carry flag.
    pub fn rotate_right_circular_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_0: u1 = @truncate(contents.*);

        contents.* >>= 1;
        if (bit_0 == 1) {
            contents |= 0x80;
        }

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotates the 8-bit register r value left through the carry flag.
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). The carry flag is copied to bit
    /// 0, and bit 7 is copied to the carry flag.{
    pub fn rotate_left_arithmetic_r8(proc: *Processor, registerValue: *u8) void {
        const bit_7: u1 = @truncate(registerValue.* >> 7);
        const carry = proc.flags.carry;

        registerValue.* <<= 1;
        registerValue.* |= carry;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, left through
    /// the carry flag.
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). The carry flag is copied to bit
    /// 0, and bit 7 is copied to the carry flag.
    pub fn rotate_left_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_7: u1 = @truncate(contents.* >> 7);
        const carry = proc.flags.carry;

        contents.* <<= 1;
        contents.* |= carry;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Rotates the 8-bit register r value right through the carry flag.
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). The carry flag is copied to bit
    /// 7, and bit 0 is copied to the carry flag
    pub fn rotate_right_r8(proc: *Processor, registerValue: *u8) void {
        const bit_0: u1 = @truncate(registerValue.*);

        registerValue.* >>= 1;
        if (proc.flags.carry == 1) {
            registerValue.* |= 0x80;
        }

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, right through
    /// the carry flag.
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). The carry flag is copied to bit
    /// 7, and bit 0 is copied to the carry flag.
    pub fn rotate_right_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_0: u1 = @truncate(contents.*);

        contents.* >>= 1;
        if (proc.flags.carry == 1) {
            contents.* |= 0x80;
        }

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Shifts the 8-bit register r value left by one bit using an arithmetic shift.
    /// Bit 7 is shifted to the carry flag, and bit 0 is set to a fixed value of 0.
    pub fn shift_left_arithmetic_r8(proc: *Processor, registerValue: *u8) void {
        const bit_7: u1 = @truncate(registerValue.* >> 7);

        registerValue.* <<= 1;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Shifts, the 8-bit value at the address specified by the HL register, left by one bit using an
    /// arithmetic shift.
    /// Bit 7 is shifted to the carry flag, and bit 0 is set to a fixed value of 0.
    pub fn shift_left_arithmetic_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_7: u1 = @truncate(contents.* >> 7);

        contents.* <<= 1;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_7;
    }

    /// Shifts the 8-bit register r value right by one bit using an arithmetic shift.
    /// Bit 7 retains its value, and bit 0 is shifted to the carry flag.
    pub fn shift_right_arithmetic_r8(proc: *Processor, registerValue: *u8) void {
        const bit_0: u1 = @truncate(registerValue.*);
        const bit_7: u1 = @truncate(registerValue.* >> 7);

        registerValue.* >>= 1;
        registerValue.* |= bit_7;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Shifts, the 8-bit value at the address specified by the HL register, right by one bit using an
    /// arithmetic shift.
    /// Bit 7 retains its value, and bit 0 is shifted to the carry flag.
    pub fn shift_right_arithmetic_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_0: u1 = @truncate(contents.*);
        const bit_7: u1 = @truncate(contents.* >> 7);

        contents.* >>= 1;
        contents.* |= bit_7;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Swaps the high and low 4-bit nibbles of the 8-bit register r.
    pub fn swap_r8(proc: *Processor, registerValue: *u8) void {
        const lo_nibble_mask: u8 = (registerValue.* & 0xF) << 4;
        registerValue.* >>= 4;
        registerValue.* |= lo_nibble_mask;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = 0;
    }

    /// Swaps the high and low 4-bit nibbles of the 8-bit data at the absolute address specified by the
    /// 16-bit register HL
    pub fn swap_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const lo_nibble_mask: u8 = (contents.* & 0xF) << 4;
        contents.* >>= 4;
        contents.* |= lo_nibble_mask;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = 0;
    }

    /// Shifts the 8-bit register r value right by one bit using a logical shift.
    /// Bit 7 is set to a fixed value of 0, and bit 0 is shifted to the carry flag.
    pub fn shift_right_logical_r8(proc: *Processor, registerValue: *u8) void {
        const bit_0: u1 = @truncate(registerValue.*);

        registerValue.* >>= 1;

        proc.flags.zero = if (registerValue.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }

    /// Shifts, the 8-bit value at the address specified by the HL register, right by one bit using a logical
    /// shift.
    /// Bit 7 is set to a fixed value of 0, and bit 0 is shifted to the carry flag.
    pub fn shift_right_logical_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const bit_0: u1 = @truncate(contents.*);

        contents.* >>= 1;

        proc.flags.zero = if (contents.* == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = bit_0;
    }
};

pub const bitFlag = struct {
    /// Tests the bit b of the 8-bit register r.
    /// The zero flag is set to 1 if the chosen bit is 0, and 0 otherwise.
    pub fn test_bit_r8(proc: *Processor, bit: Bit, register: *Register) void {
        const b: u1 = @truncate(register.value >> @intFromEnum(bit));

        proc.flags.zero = b;
        proc.flags.negative = 0;
        proc.flags.half_carry = 1;
    }

    /// Tests the bit b of the 8-bit data at the absolute address specified by the 16-bit register HL.
    /// The zero flag is set to 1 if the chosen bit is 0, and 0 otherwise.
    pub fn test_bit_hlMem(proc: *Processor, bit: Bit) void {
        const contents: *u8 = &proc.memory.address[proc.HL.value];
        const b: u1 = @truncate(contents.* >> @intFromEnum(bit));

        proc.flags.zero = if (b == 0) 1 else 0;
        proc.flags.negative = 0;
        proc.flags.half_carry = 1;
    }
};

pub const bits = struct {
    /// Resets the bit b of the 8-bit register r to 0.
    pub fn reset_bit_r8(bit: Bit, registerValue: *u8) void {
        const bit_mask: u8 = ~(@as(u8, 1) << @intFromEnum(bit));
        registerValue.* &= bit_mask;
    }

    /// Resets the bit b of the 8-bit data at the absolute address specified by the 16-bit register HL, to 0.
    pub fn reset_bit_hlMem(proc:* Processor, bit: Bit) void {
        const content: *u8 = &proc.memory.address[proc.HL.value];
        const bit_mask: u8 = ~(@as(u8, 1) << @intFromEnum(bit));
        content.* &= bit_mask;
    }

    /// Sets the bit b of the 8-bit register r to 1
    pub fn set_bit_r8(bit: Bit, registerValue: *u8) void {
        const bit_mask: u8 = @as(u8, 1) << @intFromEnum(bit);
        registerValue.* |= bit_mask;
    }

    /// Sets the bit b of the 8-bit data at the absolute address specified by the 16-bit register HL, to 1.
    pub fn set_bit_hlMem(proc: *Processor, bit: Bit) void {
        const content: *u8 = &proc.memory.address[proc.HL.value];
        const bit_mask: u8 = @as(u8, 1) << @intFromEnum(bit);
        content.* |= bit_mask;
    }
};

pub const misc = struct {
    /// Set Carry Flag.
    pub fn set_carry_flag(proc: *Processor) void {
        proc.flags.carry = 1;
    }

    /// Complement Carry Flag.
    pub fn complement_carry_flag(proc: *Processor) void {
        proc.flags.negative = 0;
        proc.flags.half_carry = 0;
        proc.flags.carry = ~proc.flags.carry;
    }

    /// ComPLement accumulator (A = ~A); also called bitwise NOT.
    pub fn complement_a8(proc: *Processor) void {
        proc.accumulator = ~proc.accumulator;
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
};

const expectEqual = std.testing.expectEqual;

// Arithmetic Instructions
test "arithmetic.inc_reg8" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{});

    arithmetic.inc_reg8(&processor, &processor.B);

    try expectEqual(0x01, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    arithmetic.inc_reg8(&processor, &processor.B);

    try expectEqual(0x02, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.B.value = 0xFF;
    arithmetic.inc_reg8(&processor, &processor.B);

    try expectEqual(0x00, processor.B.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.B.value = 0x0F;
    arithmetic.inc_reg8(&processor, &processor.B);
    try expectEqual(0x10, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.E.value = 0x0F;
    arithmetic.inc_reg8(&processor, &processor.E);
    try expectEqual(0x10, processor.E.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "arithmetic.dec_reg8" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .D = 0x02 });

    arithmetic.dec_reg8(&processor, &processor.D);
    try expectEqual(0x01, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    arithmetic.dec_reg8(&processor, &processor.D);
    try expectEqual(0x00, processor.D.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    arithmetic.dec_reg8(&processor, &processor.D);
    try expectEqual(0xFF, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "arithmetic.inc_reg16" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    arithmetic.inc_reg16(&processor, .AF);
    try expectEqual(1, processor.getAF());

    processor.setAF(0xFFFF);
    arithmetic.inc_reg16(&processor, .AF);
    try expectEqual(0, processor.getAF());

    processor.setBC(0x00FF);
    arithmetic.inc_reg16(&processor, .BC);
    try expectEqual(0x0100, processor.getBC());

    processor.setDE(0x0101);
    arithmetic.inc_reg16(&processor, .DE);
    try expectEqual(0x0102, processor.getDE());

    processor.setHL(0x0FFF);
    arithmetic.inc_reg16(&processor, .HL);
    try expectEqual(0x1000, processor.getHL());
}

test "arithmetic.dec_reg16" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    arithmetic.dec_reg16(&processor, .AF);
    try expectEqual(0xFFFF, processor.getAF());

    processor.setBC(0x0100);
    arithmetic.dec_reg16(&processor, .BC);
    try expectEqual(0x00FF, processor.getBC());

    processor.setDE(0x0102);
    arithmetic.dec_reg16(&processor, .DE);
    try expectEqual(0x0101, processor.getDE());

    processor.setHL(0x1000);
    arithmetic.dec_reg16(&processor, .HL);
    try expectEqual(0x0FFF, processor.getHL());
}

test "arithmetic.add_reg8" {
    const PC: u16 = 0x0100;
    const A: u8 = 0x14;
    const B: u8 = 0x07;
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .PC = PC, .A = A, .B = B });

    arithmetic.add_reg8(&processor, &processor.B);
    try expectEqual(0x1B, processor.A.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.C));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.A.value = 0xFF;
    processor.C.value = 0xFF;
    arithmetic.add_reg8(&processor, &processor.C);
    try expectEqual(0xFE, processor.A.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.C));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.D.value = 0x02;
    arithmetic.add_reg8(&processor, &processor.D);
    try expectEqual(0x00, processor.A.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.C));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.E.value = 0x01;
    arithmetic.add_reg8(&processor, &processor.E);
    try expectEqual(0x01, processor.A.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.C));
    try expectEqual(false, processor.isFlagSet(.H));
}

test "arithmetic.add_reg16_reg16" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{
        .B = 0x11,
        .C = 0x5E,
    });
    
    arithmetic.add_reg16_reg16(&processor, .HL, .BC);
    try expectEqual(0x115E, processor.getHL());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.C));
    try expectEqual(false, processor.isFlagSet(.H));
}

// Load instructions
test "load.reg16_imm16" {
    const PC: u16 = 0x0100;
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .PC = PC });
    const immLo: u8 = 0x03;
    const immHi: u8 = 0xA5;

    processor.memory.write(PC, immLo);
    processor.memory.write(PC + 1, immHi);

    load.reg16_imm16(&processor, .BC);
    try expectEqual(immHi, processor.B.value);
    try expectEqual(immLo, processor.C.value);
}

test "bitShift.rotate_left_a" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .A = 0xFF });

    bitShift.rotate_left_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.A.value);

    bitShift.rotate_left_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1101, processor.A.value);

    processor.unsetFlag(.C);
    bitShift.rotate_left_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1010, processor.A.value);
}

test "bitShift.rotate_left_circular_a" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .A = 0xF0 });

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1110_0001, processor.A.value);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1100_0011, processor.A.value);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1000_0111, processor.A.value);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b0000_1111, processor.A.value);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0001_1110, processor.A.value);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0011_1100, processor.A.value);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0111_1000, processor.A.value);

    bitShift.rotate_left_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_0000, processor.A.value);
}

test "bitShift.rotate_right_a" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .A = 0xFE }); // 0b1111_1110

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0111_1111, processor.A.value);

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b0011_1111, processor.A.value);

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1001_1111, processor.A.value);

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1100_1111, processor.A.value);

    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1110_0111, processor.A.value);

    processor.unsetFlag(.C);
    bitShift.rotate_right_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b0111_0011, processor.A.value);
}

test "bitShift.rotate_right_circular_a" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .A = 0xFE }); // 0b1111_1110

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0111_1111, processor.A.value);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1011_1111, processor.A.value);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1101_1111, processor.A.value);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1110_1111, processor.A.value);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_0111, processor.A.value);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1011, processor.A.value);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1101, processor.A.value);

    bitShift.rotate_right_circular_a(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.A.value);
}

test "bitShift.rotate_left_circular_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0x7F });

    bitShift.rotate_left_circular_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.B.value);

    bitShift.rotate_left_circular_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1101, processor.B.value);

    bitShift.rotate_left_circular_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1011, processor.B.value);

    processor.C.value = 0x00;
    bitShift.rotate_left_circular_r8(&processor, &processor.C);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.C.value);
}

test "bitShift.rotate_right_circular_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0xFE });

    bitShift.rotate_right_circular_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0111_1111, processor.B.value);

    bitShift.rotate_right_circular_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1011_1111, processor.B.value);

    bitShift.rotate_right_circular_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1101_1111, processor.B.value);

    processor.C.value = 0x00;
    bitShift.rotate_right_circular_r8(&processor, &processor.C);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.C.value);
}

test "bitShift.rotate_left_circular_hlMem" {
    const HL: u16 = 0xAC13;
    const contents = 0x7F; // 0b0111_1111
    var memory = Memory.init();
    memory.write(HL, contents);

    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.memory.read(HL));

    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1101, processor.memory.read(HL));

    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1011, processor.memory.read(HL));

    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_0111, processor.memory.read(HL));

    memory.write(HL, 0x00);
    bitShift.rotate_left_circular_hlMem(&processor);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.memory.read(HL));
}

test "bitShift.rotate_right_circular_hlMem" {
    const HL: u16 = 0xAC13;
    const contents = 0xFE; // 0b1111_1110
    var memory = Memory.init();
    memory.write(HL, contents);

    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0111_1111, processor.memory.read(HL));

    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1011_1111, processor.memory.read(HL));

    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1101_1111, processor.memory.read(HL));

    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1110_1111, processor.memory.read(HL));

    memory.write(HL, 0x00);
    bitShift.rotate_right_circular_hlMem(&processor);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.memory.read(HL));
}

test "bitShift.rotate_left_arithmetic_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0x7F });

    bitShift.rotate_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.B.value);

    bitShift.rotate_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1100, processor.B.value);

    bitShift.rotate_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1001, processor.B.value);

    bitShift.rotate_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_0011, processor.B.value);

    processor.unsetFlag(.C);
    processor.H.value = 0x00;
    bitShift.rotate_left_arithmetic_r8(&processor, &processor.H);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.H.value);

    processor.setFlag(.C);
    bitShift.rotate_left_arithmetic_r8(&processor, &processor.H);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0000_0001, processor.H.value);
}

test "bitShift.rotate_left_hlMem" {
    var HL: u16 = 0x17C2;
    var memory = Memory.init();
    memory.address[HL] = 0x7F;
    var processor = Processor.init(&memory, .{
        .H = 0x17,
        .L = 0xC2,
    });

    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.memory.address[HL]);

    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1100, processor.memory.address[HL]);
    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1001, processor.memory.address[HL]);

    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_0011, processor.memory.address[HL]);

    HL = 0x0100;
    processor.memory.address[HL] = 0;
    processor.setHL(HL);
    processor.unsetFlag(.C);
    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.memory.address[HL]);

    processor.setFlag(.C);
    bitShift.rotate_left_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0000_0001, processor.memory.address[HL]);
}

test "bitShift.rotate_right_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0xFE });

    bitShift.rotate_right_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0111_1111, processor.B.value);

    bitShift.rotate_right_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b0011_1111, processor.B.value);

    bitShift.rotate_right_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1001_1111, processor.B.value);

    bitShift.rotate_right_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1100_1111, processor.B.value);

    processor.unsetFlag(.C);
    processor.H.value = 0x00;
    bitShift.rotate_right_r8(&processor, &processor.H);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.H.value);

    processor.setFlag(.C);
    bitShift.rotate_right_r8(&processor, &processor.H);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1000_0000, processor.H.value);
}

test "bitShift.rotate_right_hlMem" {
    var HL: u16 = 0x80C3;
    var memory = Memory.init();
    memory.address[HL] = 0xFE;
    var processor = Processor.init(&memory, .{
        .H = 0x80,
        .L = 0xC3,
    });

    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0111_1111, processor.memory.address[HL]);

    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b0011_1111, processor.memory.address[HL]);

    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1001_1111, processor.memory.address[HL]);

    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1100_1111, processor.memory.address[HL]);

    HL = 0x0100;
    processor.setHL(HL);
    processor.memory.address[HL] = 0;
    processor.unsetFlag(.C);
    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.memory.address[HL]);

    processor.setFlag(.C);
    bitShift.rotate_right_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1000_0000, processor.memory.address[HL]);
}

test "bitShift.shift_left_arithmetic_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0x7F });

    bitShift.shift_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.B.value);

    bitShift.shift_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1100, processor.B.value);

    bitShift.shift_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1000, processor.B.value);

    bitShift.shift_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_0000, processor.B.value);

    bitShift.shift_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1110_0000, processor.B.value);

    processor.B.value = 0x0;
    bitShift.shift_left_arithmetic_r8(&processor, &processor.B);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x0, processor.B.value);
}

test "bitShift.shift_left_arithmetic_hlMem" {
    const HL = 0x01B2;
    var memory = Memory.init();
    memory.address[HL] = 0x7F;
    var processor = Processor.init(&memory, .{
        .H = 0x01,
        .L = 0xB2,
    });

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.memory.address[HL]);

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1100, processor.memory.address[HL]);

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1000, processor.memory.address[HL]);

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_0000, processor.memory.address[HL]);

    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1110_0000, processor.memory.address[HL]);

    processor.memory.address[HL] = 0;
    bitShift.shift_left_arithmetic_hlMem(&processor);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x0, processor.memory.address[HL]);
}

test "bitShift.shift_right_arithmetic_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0xF7 }); // 0b1111_0111

    bitShift.shift_right_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1011, processor.B.value);

    bitShift.shift_right_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1101, processor.B.value);

    bitShift.shift_right_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.B.value);

    bitShift.shift_right_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_1111, processor.B.value);

    bitShift.shift_right_arithmetic_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1111, processor.B.value);

    processor.B.value = 0x0;
    bitShift.shift_right_arithmetic_r8(&processor, &processor.B);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x0, processor.B.value);

    bitShift.shift_right_arithmetic_r8(&processor, &processor.B);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x0, processor.B.value);
}

test "bitShift.shift_right_arithmetic_hlMem" {
    const HL: u16 = 0x74F0;
    var memory = Memory.init();
    memory.address[HL] = 0xF7;
    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1011, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1101, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_1111, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1111, processor.memory.address[HL]);

    processor.memory.address[HL] = 0x0;
    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x0, processor.memory.address[HL]);

    bitShift.shift_right_arithmetic_hlMem(&processor);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x0, processor.memory.address[HL]);
}

test "bitShift.swap_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{
        .B = 0x93,
        .C = 0x00,
    });

    bitShift.swap_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x39, processor.B.value);

    bitShift.swap_r8(&processor, &processor.C);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.C.value);
}

test "bitShift.swap_hlMem" {
    const HL: u16 = 0x95A2;
    var memory = Memory.init();
    memory.address[HL] = 0xA2;
    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bitShift.swap_hlMem(&processor);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x2A, processor.memory.address[HL]);

    memory.address[HL] = 0x00;
    bitShift.swap_hlMem(&processor);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.memory.address[HL]);
}

test "bitFlag.test_bit_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .D = 0xF0 });

    bitFlag.test_bit_r8(&processor, .seven, &processor.D);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_r8(&processor, .six, &processor.D);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_r8(&processor, .five, &processor.D);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_r8(&processor, .four, &processor.D);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_r8(&processor, .three, &processor.D);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_r8(&processor, .two, &processor.D);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_r8(&processor, .one, &processor.D);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_r8(&processor, .zero, &processor.D);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));
}

test "bitFlag.test_bit_hlMem" {
    const HL: u16 = 0x31E7;
    var memory = Memory.init();
    memory.address[HL] = 0xF0;
    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bitFlag.test_bit_hlMem(&processor, .seven);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_hlMem(&processor, .six);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_hlMem(&processor, .five);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_hlMem(&processor, .four);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_hlMem(&processor, .three);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_hlMem(&processor, .two);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_hlMem(&processor, .one);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));

    bitFlag.test_bit_hlMem(&processor, .zero);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(1, processor.getFlag(.H));
}

test "bits.reset_bit_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .D = 0xFF });

    bits.reset_bit_r8(.zero, &processor.D);
    try expectEqual(0b1111_1110, processor.D.value);
    processor.D.value = 0xFF;

    bits.reset_bit_r8(.one, &processor.D);
    try expectEqual(0b1111_1101, processor.D.value);
    processor.D.value = 0xFF;

    bits.reset_bit_r8(.two, &processor.D);
    try expectEqual(0b1111_1011, processor.D.value);
    processor.D.value = 0xFF;

    bits.reset_bit_r8(.three, &processor.D);
    try expectEqual(0b1111_0111, processor.D.value);
    processor.D.value = 0xFF;

    bits.reset_bit_r8(.four, &processor.D);
    try expectEqual(0b1110_1111, processor.D.value);
    processor.D.value = 0xFF;

    bits.reset_bit_r8(.five, &processor.D);
    try expectEqual(0b1101_1111, processor.D.value);
    processor.D.value = 0xFF;

    bits.reset_bit_r8(.six, &processor.D);
    try expectEqual(0b1011_1111, processor.D.value);
    processor.D.value = 0xFF;

    bits.reset_bit_r8(.seven, &processor.D);
    try expectEqual(0b0111_1111, processor.D.value);
}

test "bits.reset_bit_hlMem" {
    const HL: u16 = 0x0789;
    var memory = Memory.init();
    memory.address[HL] = 0xFF;
    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bits.reset_bit_hlMem(&processor, .zero);
    try expectEqual(0b1111_1110, memory.address[HL]);
    memory.address[HL] = 0xFF;

    bits.reset_bit_hlMem(&processor, .one);
    try expectEqual(0b1111_1101, memory.address[HL]);
    memory.address[HL] = 0xFF;

    bits.reset_bit_hlMem(&processor, .two);
    try expectEqual(0b1111_1011, memory.address[HL]);
    memory.address[HL] = 0xFF;

    bits.reset_bit_hlMem(&processor, .three);
    try expectEqual(0b1111_0111, memory.address[HL]);
    memory.address[HL] = 0xFF;

    bits.reset_bit_hlMem(&processor, .four);
    try expectEqual(0b1110_1111, memory.address[HL]);
    memory.address[HL] = 0xFF;

    bits.reset_bit_hlMem(&processor, .five);
    try expectEqual(0b1101_1111, memory.address[HL]);
    memory.address[HL] = 0xFF;

    bits.reset_bit_hlMem(&processor, .six);
    try expectEqual(0b1011_1111, memory.address[HL]);
    memory.address[HL] = 0xFF;

    bits.reset_bit_hlMem(&processor, .seven);
    try expectEqual(0b0111_1111, memory.address[HL]);
}

test "bits.set_bit_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .D = 0x00 });

    bits.set_bit_r8(.zero, &processor.D);
    try expectEqual(0b0000_0001, processor.D.value);
    processor.D.value = 0x00;

    bits.set_bit_r8(.one, &processor.D);
    try expectEqual(0b0000_0010, processor.D.value);
    processor.D.value = 0x00;

    bits.set_bit_r8(.two, &processor.D);
    try expectEqual(0b0000_0100, processor.D.value);
    processor.D.value = 0x00;

    bits.set_bit_r8(.three, &processor.D);
    try expectEqual(0b0000_1000, processor.D.value);
    processor.D.value = 0x00;

    bits.set_bit_r8(.four, &processor.D);
    try expectEqual(0b0001_0000, processor.D.value);
    processor.D.value = 0x00;

    bits.set_bit_r8(.five, &processor.D);
    try expectEqual(0b0010_0000, processor.D.value);
    processor.D.value = 0x00;

    bits.set_bit_r8(.six, &processor.D);
    try expectEqual(0b0100_0000, processor.D.value);
    processor.D.value = 0x00;

    bits.set_bit_r8(.seven, &processor.D);
    try expectEqual(0b1000_0000, processor.D.value);
}

test "bits.set_bit_hlMem" {
    const HL: u16 = 0x93A0;
    var memory = Memory.init();
    memory.address[HL] = 0x00;
    var processor = Processor.init(&memory, .{});
    processor.setHL(HL);

    bits.set_bit_hlMem(&processor, .zero);
    try expectEqual(0b0000_0001, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    bits.set_bit_hlMem(&processor, .one);
    try expectEqual(0b0000_0010, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    bits.set_bit_hlMem(&processor, .two);
    try expectEqual(0b0000_0100, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    bits.set_bit_hlMem(&processor, .three);
    try expectEqual(0b0000_1000, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    bits.set_bit_hlMem(&processor, .four);
    try expectEqual(0b0001_0000, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    bits.set_bit_hlMem(&processor, .five);
    try expectEqual(0b0010_0000, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    bits.set_bit_hlMem(&processor, .six);
    try expectEqual(0b0100_0000, processor.memory.address[HL]);
    processor.memory.address[HL] = 0x00;

    bits.set_bit_hlMem(&processor, .seven);
    try expectEqual(0b1000_0000, processor.memory.address[HL]);
}

test "misc.set_carry_flag" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    misc.set_carry_flag(&processor);
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
}

test "misc.complement_carry_flag" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    misc.complement_carry_flag(&processor);
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));

    misc.complement_carry_flag(&processor);
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));

    misc.complement_carry_flag(&processor);
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
}

test "misc.complement_a8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{
        .A = 0xF0,
    });

    misc.complement_a8(&processor);
    try expectEqual(0x0F, processor.A.value);

    misc.complement_a8(&processor);
    try expectEqual(0xF0, processor.A.value);
}

test "misc.decimal_adjust_accumulator" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .A = 0x1F });

    processor.unsetFlag(.N);
    misc.decimal_adjust_accumulator(&processor);
    try expectEqual(0x25, processor.A.value);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.H));

    processor.unsetFlag(.C);
    processor.unsetFlag(.N);
    processor.A.value = 0x60;
    misc.decimal_adjust_accumulator(&processor);
    try expectEqual(0x60, processor.A.value);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.H));

    processor.unsetFlag(.C);
    processor.unsetFlag(.N);
    processor.A.value = 0xC3;
    misc.decimal_adjust_accumulator(&processor);
    try expectEqual(0x23, processor.A.value);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.H));

    processor.unsetFlag(.C);
    processor.setFlag(.N);
    processor.A.value = 0x60;
    misc.decimal_adjust_accumulator(&processor);
    try expectEqual(0x60, processor.A.value);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.H));

    processor.unsetFlag(.C);
    processor.setFlag(.H);
    processor.setFlag(.N);
    processor.A.value = 0x6A;
    misc.decimal_adjust_accumulator(&processor);
    try expectEqual(0x64, processor.A.value);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.H));

    processor.unsetFlag(.H);
    processor.unsetFlag(.N);
    processor.A.value = 0x00;
    misc.decimal_adjust_accumulator(&processor);
    try expectEqual(0x00, processor.A.value);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0, processor.getFlag(.H));
}
