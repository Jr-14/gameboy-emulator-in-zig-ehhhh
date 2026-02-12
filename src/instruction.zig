const std = @import("std");
const Register = @import("register.zig");
const Processor = @import("processor.zig");
const Memory = @import("memory.zig");
const mask = @import("masks.zig");

const FlagCondition = enum {
    Z,
    NZ,
    N,
    NN,
    H,
    NH,
    C,
    NC
};

const utils = @import("utils.zig");

pub const arithmetic = struct {
    /// Increment the contents of register reg by 1.
    /// Example: 0x05 -> DEC B
    pub fn inc_r8(
        proc: *Processor,
        reg: *Register,
    ) void {
        const sum = utils.Arithmetic(u8).add(.{
            .a = reg.value,
            .b = 1
        });
        reg.value = sum.value;
        proc.unsetFlag(.N);
        if (sum.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        if (sum.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    /// Decrement the contents of register reg by 1
    /// Example: 0x0D -> DEC C
    pub fn dec_reg(
        proc: *Processor,
        reg: *Register,
    ) void {
        const remainder = utils.Arithmetic(u8).subtract(.{
            .a = reg.value,
            .b = 1
        });
        reg.value = remainder.value;
        proc.setFlag(.N);
        if (remainder.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        if (remainder.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    /// Increment the contents of register pair rr by 1
    pub fn inc_rr(proc: *Processor, regPair: Processor.RegisterPair) void {
        switch (regPair) {
            .AF => proc.setAF(proc.getAF() +% 1),
            .BC => proc.setBC(proc.getBC() +% 1),
            .DE => proc.setDE(proc.getDE() +% 1),
            .HL => proc.setHL(proc.getHL() +% 1),
        }
    }

    /// Decrement the contents of register pair rr by 1
    pub fn dec_rr(proc: *Processor, regPair: Processor.RegisterPair) void {
        switch (regPair) {
            .AF => proc.setAF(proc.getAF() -% 1),
            .BC => proc.setBC(proc.getBC() -% 1),
            .DE => proc.setDE(proc.getDE() -% 1),
            .HL => proc.setHL(proc.getHL() -% 1),
        }
    }

    pub fn inc_sp(proc: *Processor) void {
        proc.SP +%= 1;
    }

    pub fn dec_sp(proc: *Processor) void {
        proc.SP -%= 1;
    }

    /// Add to HL the value of SP
    pub fn add16_hl_sp(proc: *Processor) void {
        const result = utils.Arithmetic(u16).add(.{
            .a = proc.getHL(),
            .b = proc.SP,
        });

        proc.setHL(result.value);
        proc.setFlag(.N);
        if (result.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        if (result.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    pub fn add16_sp_offset(proc: *Processor) void {
        const imm = proc.fetch();
        const result = utils.Arithmetic(u16).add_offset(proc.SP, imm);
        proc.SP = result.value;
        proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        if (result.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        if (result.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    fn add_aux(proc: *Processor, values: struct {
        b: u8,
        carry: u1 = 0,
    }) void {
        const sum = utils.Arithmetic(u8).add(.{
            .a = proc.A.value,
            .b = values.b,
            .carry = values.carry,
        });
        proc.A.value = sum.value;
        proc.unsetFlag(.N);
        if (sum.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        if (sum.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        if (sum.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    /// Add the contents of register reg to the contents of accumulator (A) register,
    /// and store the results in the accumulator (A) register.
    /// Example: 0x80 ADD A, B
    pub fn add_reg(proc: *Processor, reg: *Register) void {
        add_aux(proc, .{ .b = reg.value });
    }

    /// Add the contents of memory specified by register pair HL to the contents of register A, and store the results
    /// in register A.
    /// Example: 0x86 -> ADD A, (HL)
    pub fn add_hlMem(proc: *Processor) void {
        const val: u8 = proc.memory.read(proc.getHL());
        add_aux(proc, .{ .b = val });
    }

    pub fn add_imm8(proc: *Processor) void {
        const imm = proc.fetch();
        add_aux(proc, .{ .b =  imm });
    }

    /// Add the contents of register reg and the CY flag to the contents of the accumulator (A) register, and
    /// store the results in accumulator (A) register.
    /// Example: 0x88 -> ADC A, B
    pub fn addc_reg(proc: *Processor, reg: *Register) void {
        const cy: u1 = if (proc.isFlagSet(.C)) 1 else 0;
        add_aux(proc, .{
            .b =  reg.value,
            .carry = cy,
        });
    }

    /// Add the contents of memory specified by register pair HL and the CY flag to the contents of
    /// accumulator (A) register and store the results in the accumulator (A) register.
    /// Example: 0x8E -> ADC A, (HL)
    pub fn addc_hlMem(proc: *Processor) void {
        const val = proc.memory.read(proc.getHL());
        const cy: u1 = if (proc.isFlagSet(.C)) 1 else 0;
        add_aux(proc, .{
            .b = val,
            .carry = cy,
        });
    }

    pub fn add16_rr_rr(proc: *Processor, dest: Processor.RegisterPair, src: Processor.RegisterPair) void {
        const dest_setter, const dest_getter = switch (dest) {
            .AF => .{ &Processor.setAF, &Processor.getAF },
            .BC => .{ &Processor.setBC, &Processor.getBC },
            .DE => .{ &Processor.setDE, &Processor.getDE },
            .HL => .{ &Processor.setHL, &Processor.getHL },
        };

        const src_getter = switch(src) {
            .AF => &Processor.getAF,
            .BC => &Processor.getBC,
            .DE => &Processor.getDE,
            .HL => &Processor.getHL,
        };

        const result = utils.Arithmetic(u16).add(.{
            .a = dest_getter(proc),
            .b = src_getter(proc),
        });

        dest_setter(proc, result.value);
        proc.unsetFlag(.N);
        if (result.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        if (result.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    pub fn addc_imm8(proc: *Processor) void {
        const val = proc.memory.read(proc.fetch());
        const cy: u1 = if (proc.isFlagSet(.C)) 1 else 0;
        add_aux(proc, .{
            .b = val,
            .carry = cy,
        });
    }

    fn sub_aux(proc: *Processor, values: struct{
        b: u8,
        carry: u1 = 0,
    }) void {
        const remainder = utils.Arithmetic(u8).subtract(.{
            .a = proc.A.value,
            .b = values.b,
            .carry = values.carry,
        });
        proc.A.value = remainder.value;
        proc.setFlag(.N);
        if (remainder.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        if (remainder.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        if (remainder.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
    }

    /// Subtract the contents of register reg to the contents of accumulator (A) register,
    /// and store the results in the accumulator (A) register.
    /// Example: 0x93 -> SUB E
    pub fn sub_reg(proc: *Processor, reg: *Register) void {
        sub_aux(proc, .{
            .b = reg.value
        });
    }

    pub fn sub_imm8(proc: *Processor) void {
        const val = proc.fetch();
        sub_aux(proc, .{
            .b = val,
        });
    }

    /// Subtract the contents of register reg and the CY flag from the contents of accumulator (A) register,
    /// and store the results in accumulator (A) register.
    pub fn subc_reg(proc: *Processor, reg: *Register) void {
        const cy: u1 = if (proc.isFlagSet(.C)) 1 else 0;
        sub_aux(proc, .{
            .b = reg.value,
            .carry = cy,
        });
    }

    pub fn subc_imm8(proc: *Processor) void {
        const val = proc.fetch();
        const cy: u1 = if (proc.isFlagSet(.C)) 1 else 0;
        sub_aux(proc, .{
            .b = val,
            .carry = cy,
        });
    }

    /// Subtract the contents of memory specified by register pair HL from the contents of accumulator (A) register
    /// and store the results in accumulator (A) register.
    /// Example: 0x96 -> SUB A, (HL)
    pub fn sub_hlMem(proc: *Processor) void {
        const val = proc.memory.read(proc.getHL());
        sub_aux(proc, .{
            .b = val
        });
    }

    pub fn subc_hlMem(proc: *Processor) void {
        const val = proc.memory.read(proc.getHL());
        const cy: u1 = if (proc.isFlagSet(.C)) 1 else 0;
        sub_aux(proc, .{
            .b = val,
            .carry = cy
        });
    }

    fn and_aux(proc: *Processor, value: u8) void {
        proc.A.value &= value;
        if (proc.A.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.setFlag(.H);
        proc.unsetFlag(.C);
    }

    /// Take the logical AND for each bit of the contents of register reg and the contents of register A,
    /// and store the results in register A.
    /// Example: 0xA0 -> AND A, B
    pub fn And(proc: *Processor, reg: *Register) void {
        and_aux(proc, reg.value);
    }

    pub fn and_imm8(proc: *Processor) void {
        const imm = proc.fetch();
        and_aux(proc, imm);
    }

    pub fn and_hlMem(proc: *Processor) void {
        const val = proc.memory.read(proc.getHL());
        and_aux(proc, val);
    }

    fn or_aux(proc: *Processor, value: u8) void {
        proc.A.value |= value;
        if (proc.A.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
        proc.unsetFlag(.C);
    }

    pub fn Or(proc: *Processor, reg: *Register) void {
        or_aux(proc, reg.value);
    }

    pub fn or_imm8(proc: *Processor) void {
        const imm = proc.fetch();
        or_aux(proc, imm);
    }

    pub fn or_hlMem(proc: *Processor) void {
        const val = proc.memory.read(proc.getHL());
        or_aux(proc, val);
    }

    fn xor_aux(proc: *Processor, value: u8) void {
        proc.A.value ^= value;
        if (proc.A.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
        proc.unsetFlag(.C);
    }

    pub fn Xor(proc: *Processor, reg: *Register) void {
        xor_aux(proc, reg.value);
    }

    pub fn xor_imm8(proc: *Processor) void {
        const imm = proc.fetch();
        xor_aux(proc, imm);
    }

    pub fn xor_hlMem(proc: *Processor) void {
        const val = proc.memory.read(proc.getHL());
        xor_aux(proc, val);
    }

    fn compare_aux(proc: *Processor, value: u8) void {
        const remainder = utils.Arithmetic(u8).add(proc.A.value, value);
        if (remainder.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.setFlag(.N);
        if (remainder.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
        if (remainder.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
    }

    pub fn compare_reg(proc: *Processor, reg: *Register) void {
        compare_aux(proc, reg.value);
    }

    pub fn compare_hlMem(proc: *Processor) void {
        const val = proc.memory.read(proc.getHL());
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
    pub fn reg_imm8(proc: *Processor, reg: *Register) void {
        reg.value = proc.fetch();
    }

    /// Load to the 8-bit register reg, data from the address specified by the 8-bit immediate data a8. The full
    /// 16-bit absolute address is obtained by setting the most significant byte to 0xff and the least
    /// significant byte to the value of a8, so the possible range is 0xff0-0xffff.
    /// Example: 0xF0 -> LD A, (a8)
    pub fn reg_imm8Mem(proc: *Processor, reg: *Register) void {
        const imm = proc.fetch();
        const addr = utils.fromTwoBytes(imm, 0xFF);
        reg.value = proc.memory.read(addr);
    }

    /// Load the contents of the source register into the destination register.
    pub fn reg_reg(dest: *Register, src: *Register) void {
        dest.value = src.value;
    }

    pub fn regMem_reg(proc: *Processor, dest: *Register, src: *Register) void {
        const addr = utils.fromTwoBytes(dest.value, 0xFF);
        proc.memory.write(addr, src.value);
    }

    /// Load to the 8-bit A register, data from the address specified by the 8-bit C register. The full 16-bit
    /// address is obtianed by setting the most significant byte to 0xff and the least significant byte to the
    /// value of C, so the possible range is 0xff00-0xffff.
    /// Example: 0xF2 -> LD A, (C)
    pub fn reg_regMem(proc: *Processor, dest: *Register, src: *Register) void {
        dest.value = proc.memory.read(utils.fromTwoBytes(src.value, 0xFF));
    }

    /// Load to the 8-bit register reg, data from the absolute address specified by the 16-bit operand (a16).
    /// Example: 0xFA -> LD A, (a16)
    pub fn reg_imm16Mem(proc: *Processor, dest: *Register) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        const addr = utils.fromTwoBytes(lo, hi);

        dest.value = proc.memory.read(addr);
    }

    /// Load the 2 bytes of immediate data into register pair rr
    /// The first byte of immediate data is the lower byte (i.e. bits 0-7), and
    /// the second byte of immediate data is the higher byte (i.e., bits 8-15)
    /// Example: 0x01 -> LD BC, d16
    pub fn rr_imm16(proc: *Processor, regPair: Processor.RegisterPair) void {
        switch (regPair) {
            .AF => {
                proc.F.value = proc.fetch();
                proc.A.value = proc.fetch();
            },
            .BC => {
                proc.C.value = proc.fetch();
                proc.B.value = proc.fetch();
            },
            .DE => {
                proc.E.value = proc.fetch();
                proc.D.value = proc.fetch();
            },
            .HL => {
                proc.L.value = proc.fetch();
                proc.H.value = proc.fetch();
            }
        }
    }

    /// Load to the address specified by the 8-bit immediate data, data from the 8-bit register. The full
    /// 16-bit absolute address is obtained by setting the most significant byte to 0xff and the least significant
    /// byte to the value of a8, so the possible range is 0xff00-0xffff.
    pub fn imm8Mem_reg(proc: *Processor, reg: *Register) void {
        const imm = proc.fetch();
        proc.memory.write(mask.HI_MASK | imm, reg.value);
    }

    /// Store the contents of a register reg into the memory location specified by the register pair rr.
    /// Example: 0x12 -> LD (DE), A
    pub fn hlMem_reg(proc: *Processor, reg: *Register) void {
        proc.memory.write(proc.getHL(), reg.value);
    }

    /// Store the contents of 8-bit immediate operand d8 in the memory location
    /// specified by register pair rr.
    /// Example: 0x36 -> LD (HL), d8
    pub fn rrMem_imm8(proc: *Processor, regPair: Processor.RegisterPair) void {
        const value = proc.fetch();
        switch (regPair) {
            .AF => proc.memory.write(proc.getAF(), value),
            .BC => proc.memory.write(proc.getBC(), value),
            .DE => proc.memory.write(proc.getDE(), value),
            .HL => proc.memory.write(proc.getHL(), value),
        }
    }

    /// Store the contents of register reg in the memory location specified by
    /// register pair rr
    /// Example: 0x02 -> LD (BC), A
    pub fn rrMem_reg(proc: *Processor, regPair: Processor.RegisterPair, reg: *Register) void {
        const addr = switch (regPair) {
            .AF => proc.getAF(),
            .BC => proc.getBC(),
            .DE => proc.getDE(),
            .HL => proc.getHL(),
        };
        proc.memory.write(addr, reg.value);
    }

    /// Store into the immediate address the contents of register pair RR.
    pub fn imm16Mem_rr(proc: *Processor, regPair: Processor.RegisterPair) void {
        const addr: u16 = utils.fromTwoBytes(proc.fetch(), proc.fetch());
        switch (regPair) {
            .AF => {
                proc.memory.write(addr, proc.F.value);
                proc.memory.write(addr + 1, proc.A.value);
            },
            .BC => {
                proc.memory.write(addr, proc.C.value);
                proc.memory.write(addr + 1, proc.B.value);
            },
            .DE => {
                proc.memory.write(addr, proc.E.value);
                proc.memory.write(addr + 1, proc.D.value);
            },
            .HL => {
                proc.memory.write(addr, proc.L.value);
                proc.memory.write(addr + 1, proc.H.value);
            },
        }
    }

    /// Store the contents of register A in the internal RAM or register specified by the 16-bit immediate
    /// operand a16.
    /// Example: 0xEA -> LD (a16), A
    pub fn imm16Mem_reg(proc: *Processor, reg: *Register) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        const addr = utils.fromTwoBytes(lo, hi);
        proc.memory.write(addr, reg.value);
    }

    /// Store the lower byte of Special Purpose Register (SPR) at the address specified by the 16-bit
    /// immediate operand a16, and store the upper byte of SPR at address a16 + 1.
    /// Example: 0x08 -> LD (a16), SP
    pub fn imm16Mem_spr(proc: *Processor, val: u16) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        const addr: u16 = utils.fromTwoBytes(lo, hi);
        proc.memory.write(addr, utils.getLoByte(val));
        proc.memory.write(addr + 1, utils.getHiByte(val));
    }

    /// Load the 2 bytes of immediate data into special purpose register (SPR).
    /// The first byte of immedaite data is the lower byte (i.e., bits 0-7), and the second byte of
    /// immediate data is the higher byte (i.e., bits 8-15).
    pub fn spr_imm16(proc: *Processor, spr: *u16) void {
        spr.* = utils.fromTwoBytes(proc.fetch(), proc.fetch());
    }

    /// Load the contents of register pair rr into the Special Purpose Register.
    /// Example: 0xF9 -> LD SP, HL
    pub fn spr_rr(proc: *Processor, spr: *u16, regPair: Processor.RegisterPair) void {
        var loReg: *Register = undefined;
        var hiReg: *Register = undefined;
        switch (regPair) {
            .AF => {
                hiReg = &proc.A;
                loReg = &proc.F;
            },
            .BC => {
                hiReg = &proc.B;
                loReg = &proc.C;
            },
            .DE => {
                hiReg = &proc.D;
                loReg = &proc.E;
            },
            .HL => {
                hiReg = &proc.H;
                loReg = &proc.L;
            },
        }
        spr.* = utils.fromTwoBytes(loReg.value, hiReg.value);
    }

    /// Load the 8-bit contents of memory specified by register pair rr into register reg
    /// Example: 0x0A -> LD A, (BC)
    pub fn reg_rrMem(proc: *Processor, reg: *Register, regPair: Processor.RegisterPair) void {
        switch (regPair) {
            .AF => reg.value = proc.memory.read(proc.getAF()),
            .BC => reg.value = proc.memory.read(proc.getBC()),
            .DE => reg.value = proc.memory.read(proc.getDE()),
            .HL => reg.value = proc.memory.read(proc.getHL()),
        }
    }

    /// Store the contents of register reg into the memory location specified by register pair
    /// HL, and simultaneously increment the contents of HL
    /// Example: 0x22 -> LD (HL+), A
    pub fn hlMem_inc_reg(proc: *Processor, reg: *Register) void {
        const hl = proc.getHL();
        proc.memory.write(hl, reg.value);
        proc.setHL(hl +% 1);
    }

    /// Store the contents of register reg into the memory location specified by register pair
    /// HL, and simultaneously decrement the contents of HL.
    pub fn hlMem_dec_reg(proc: *Processor, reg: *Register) void {
        const hl = proc.getHL();
        proc.memory.write(hl, reg.value);
        proc.setHL(hl -% 1);
    }

    /// Load the contents of memory specified by register pair rr into register reg, and simultaneously
    /// increment the contents of HL.
    /// Example: 0x2A -> LD A, (HL+)
    pub fn reg_hlMem_inc(proc: *Processor, reg: *Register) void {
        const hl = proc.getHL();
        reg.value = proc.memory.read(hl);
        proc.setHL(hl +% 1);
    }

    /// Load the contents of memory specified by register pair HL into register reg, and
    /// simultaneously decrement the contents of HL.
    /// Example: 0x3A -> LD A, (HL-)
    pub fn reg_hlMem_dec(proc: *Processor, reg: *Register) void {
        const hl = proc.getHL();
        reg.value = proc.memory.read(hl);
        proc.setHL(hl -% 1);
    }

    // Add the 8-bit signed operand s8 (values -128 to +127) to the stack pointer SP, and store the result in
    // register pair HL.
    pub fn hl_sp_imm8(proc: *Processor) void {
        const imm = proc.fetch();
        const result = utils.Arithmetic(u16).add_offset(proc.SP, imm);
        proc.SP = result.value;
        proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        if (result.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
        if (result.carry == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
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
    pub fn jump_rel_cc_imm8(proc: *Processor, condition: FlagCondition) void {
        const offset = proc.fetch();
        const cc: bool = switch(condition) {
            .Z => proc.isFlagSet(.Z),
            .NZ => !proc.isFlagSet(.Z),
            .N => proc.isFlagSet(.N),
            .NN => !proc.isFlagSet(.N),
            .H => proc.isFlagSet(.H),
            .NH => !proc.isFlagSet(.H),
            .C => proc.isFlagSet(.C),
            .NC => !proc.isFlagSet(.C),
        };

        if (cc) {
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
        const lo = proc.fetch();
        const hi = proc.fetch();
        proc.PC = utils.fromTwoBytes(lo, hi);
    }


    /// Load the 16-bit immediate operand a16 into the program counter PC if the flag condition cc is met. If the
    /// condition is met, then the subsequent instruction starts at address a16. If not, the contents of PC are
    /// incremented, and the next instruction following the current JP instruction is executed (as usual).
    ///
    /// The second byte of the object code (immediately following the opcode) corresponds to the lower-order
    /// byte of a16 (bits 0-7), and the third byte of the object code corresponds to the higher-order byte
    /// (bits 8-15).
    /// Example: 0xC2 -> JP NZ, a16
    pub fn jump_cc_imm16(proc: *Processor, condition: FlagCondition) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        const cc: bool = switch(condition) {
            .Z => proc.isFlagSet(.Z),
            .NZ => !proc.isFlagSet(.Z),
            .N => proc.isFlagSet(.N),
            .NN => !proc.isFlagSet(.N),
            .H => proc.isFlagSet(.H),
            .NH => !proc.isFlagSet(.H),
            .C => proc.isFlagSet(.C),
            .NC => !proc.isFlagSet(.C),
        };

        if (cc) {
            proc.PC = utils.fromTwoBytes(lo, hi);
        }
    }

    /// Load the contents of register pair HL into the program counter PC. The next instruction is fetched from
    /// the location specified by the new value of PC.
    /// Example: 0xE9 -> JP HL
    pub fn jump_rr(proc: *Processor, regPair: Processor.RegisterPair) void {
        var loReg: *Register = undefined;
        var hiReg: *Register = undefined;
        switch (regPair) {
            .AF => {
                hiReg = &proc.A;
                loReg = &proc.F;
            },
            .BC => {
                hiReg = &proc.B;
                loReg = &proc.C;
            },
            .DE => {
                hiReg = &proc.D;
                loReg = &proc.E;
            },
            .HL => {
                hiReg = &proc.H;
                loReg = &proc.L;
            },
        }

        proc.PC = utils.fromTwoBytes(loReg.value, hiReg.value);
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
        const hi: u8 = proc.popStack();
        proc.PC = utils.fromTwoBytes(lo, hi);
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
    pub fn ret_cc(proc: *Processor, condition: FlagCondition) void {
        const cc: bool = switch(condition) {
            .Z => proc.isFlagSet(.Z),
            .NZ => !proc.isFlagSet(.Z),
            .N => proc.isFlagSet(.N),
            .NN => !proc.isFlagSet(.N),
            .H => proc.isFlagSet(.H),
            .NH => !proc.isFlagSet(.H),
            .C => proc.isFlagSet(.C),
            .NC => !proc.isFlagSet(.C),
        };

        if (cc) {
            ret(proc);
        }
    }

    /// Used when an interrupt-service routine finishes. The address for the return from the interrupt is loaded
    /// in the program counter PC. The master interrupt enable flag is returned to its pre-interrupt status.
    /// The contents of the address specified by the stack pointer SP are loaded in the lower-order byte of PC,
    /// and the contents of SP are incremented by 1. The contents of the address specified by the new SP value
    /// are then loaded in the higher-order byte of PC, and the contents of SP are incremented by 1 again. 
    /// (THe value of SP is 2 larger than before instruction execution.) The next instruction is fetched from
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
    pub fn pop_rr(proc: *Processor, regPair: Processor.RegisterPair) void {
        var hiReg: *Register = undefined;
        var loReg: *Register = undefined;
        switch (regPair) {
            .AF => {
                hiReg = &proc.A;
                loReg = &proc.F;
            },
            .BC => {
                hiReg = &proc.B;
                loReg = &proc.C;
            },
            .DE => {
                hiReg = &proc.D;
                loReg = &proc.E;
            },
            .HL => {
                hiReg = &proc.H;
                loReg = &proc.L;
            }
        }
        loReg.value = proc.popStack();
        hiReg.value = proc.popStack();
    }

    /// Push the contents of register pair rr onto the memory stack by doing the following:
    /// 1. Subtract 1 from the stack pointer SP, and put the contents of the higher portion of register pair
    /// BC on on the stack.
    /// 2. Subtract 1 from SP, and put the lower portion of register pair BC on the stack.
    /// Example: 0xC5 -> PUSH BC
    pub fn push_rr(proc: *Processor, regPair: Processor.RegisterPair) void {
        var lo: *Register = undefined;
        var hi: *Register = undefined;

        switch (regPair) {
            .AF => {
                lo = &proc.F;
                hi = &proc.A;
            },
            .BC => {
                lo = &proc.C;
                hi = &proc.B;
            },
            .DE => {
                lo = &proc.E;
                hi = &proc.D;
            },
            .HL => {
                lo = &proc.L;
                hi = &proc.H;
            }
        }

        proc.pushStack(hi.value);
        proc.pushStack(lo.value);
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
        const lo = proc.fetch();
        const hi = proc.fetch();
        proc.pushStack(utils.getHiByte(proc.PC));
        proc.pushStack(utils.getLoByte(proc.PC));
        proc.PC = utils.fromTwoBytes(lo, hi);
    }

    /// If condition flag is met, the program counter PC value corresponding to the memory location of the instruction
    /// following the CALL instruction is pushed to the 2 bytes following the memory byte specified by the stack
    /// pointer SP. The 16-bit immediate operand a16 is then loaded into PC.
    ///
    /// The lower-order byte of a16 is placed in byte 2 of the object code, and the higher-order byte is placed
    /// in byte 3.
    /// Example: 0xC4 -> CALL NZ, a16
    pub fn call_cc_imm16(proc: *Processor, condition: FlagCondition) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        const cc: bool = switch(condition) {
            .Z => proc.isFlagSet(.Z),
            .NZ => !proc.isFlagSet(.Z),
            .N => proc.isFlagSet(.N),
            .NN => !proc.isFlagSet(.N),
            .H => proc.isFlagSet(.H),
            .NH => !proc.isFlagSet(.H),
            .C => proc.isFlagSet(.C),
            .NC => !proc.isFlagSet(.C),
        };
        
        if (cc) {
            proc.pushStack(utils.getHiByte(proc.PC));
            proc.pushStack(utils.getLoByte(proc.PC));
            proc.PC = utils.fromTwoBytes(lo, hi);
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
        const bit_7_mask: u8 = 0x80;
        const bit_7: u1 = if ((proc.A.value & bit_7_mask) == bit_7_mask) 1 else 0;
        const carry = proc.getFlag(.C);
        if (bit_7 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
        proc.A.value <<= 1;
        proc.A.value |= carry;
    }

    /// Rotates the 8-bit A register value left in a circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). Bit 7 is copied both to bit
    /// 0 and the carry flag. Note that unlike the related RLC r instruction, RLCA always sets the zero
    /// flag to 0 without looking at the resulting value of the calculation.
    pub fn rotate_left_circular_a(proc: *Processor) void {
        const bit_7_mask: u8 = 0x80;
        const bit_7: u1 = if ((proc.A.value & bit_7_mask) == bit_7_mask) 1 else 0;
        if (bit_7 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
        proc.A.value <<= 1;
        proc.A.value |= bit_7;
    }

    /// Rotate the contents of register A to the right, through the carry (CY) flag.
    /// That is, the contents of bit 7 are copied to bit 6, and the previous contents of bit 6 (before the copy) are
    /// copied to bit 5. The same operation is repeated in sequence for the rest of the register.
    /// The previous contents of the carry flag are copied to bit 7.
    pub fn rotate_right_a(proc: *Processor) void {
        const bit_0: u1 = @truncate(proc.A.value);
        const carry_mask: u8 = if (proc.isFlagSet(.C)) 0x80 else 0x00;
        if (bit_0 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
        proc.A.value >>= 1;
        proc.A.value |= carry_mask;
    }

    /// Rotate the contents of register A to the right.
    /// That is, the contents of bit 7 are copied to bit 6, and the previous contents of bit 6 (before the copy) are
    /// copied to bit 5. The same operation is repeated in sequence for the rest of the register.
    /// The contents of bit 0 are placed in both the CY flag and bit 7 of register A.
    pub fn rotate_right_circular_a(proc: *Processor) void {
        const bit_0: u1 = @truncate(proc.A.value);
        const carry_mask: u8 = if (bit_0 == 1) 0x80 else 0x00;
        proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
        if (bit_0 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        proc.A.value >>= 1;
        proc.A.value |= carry_mask;
    }

    /// Rotates the 8-bit register r value left in a circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). Bit 7 is copied both to bit 0
    /// and the carry flag.
    pub fn rotate_left_circular_r8(proc: *Processor, register: *Register) void {
        const bit_7: u1 = @truncate(register.value >> 7);
        if (bit_7 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        register.value <<= 1;
        register.value |= bit_7;
        if (register.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
    }

    /// Rotates the 8-bit register r value right in a circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). Bit 0 is copied both to bit 7
    /// and the carry flag.
    pub fn rotate_right_circular_r8(proc: *Processor, register: *Register) void {
        const bit_0: u1 = @truncate(register.value);
        if (bit_0 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        const rotate_mask: u8 = if (bit_0 == 1) 0x80 else 0x00;
        register.value >>= 1;
        register.value |= rotate_mask;
        if (register.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, left in a
    /// circular manner (carry flag is updated but not used).
    /// Every bit is shifted t
    pub fn rotate_left_circular_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.getHL()];
        const bit_7: u1 = @truncate(contents.* >> 7);
        if (bit_7 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        contents.* <<= 1;
        contents.* |= bit_7;
        if (contents.* == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, right in a
    /// circular manner (carry flag is updated but not used).
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). Bit 0 is copied both to bit 7
    /// and the carry flag.
    pub fn rotate_right_circular_hlMem(proc: *Processor) void {
        const contents: *u8 = proc.memory.address[proc.getHL()];
        const bit_0: u1 = @truncate(contents.*);
        if (bit_0 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        const carry_mask: u8 = if (bit_0 == 1) 0x80 else 0x00;
        contents.* >>= 1;
        contents.* |= carry_mask;
        if (contents.* == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
    }

    /// Rotates the 8-bit register r value left through the carry flag.
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). The carry flag is copied to bit
    /// 0, and bit 7 is copied to the carry flag.{
    pub fn rotate_left_r8(proc: *Processor, register: *Register) void {
        const bit_7: u1 = @truncate(register.value >> 7);
        const carry = proc.getFlag(.C);
        register.value <<= 1;
        register.value |= carry;
        if (bit_7 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        if (register.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, left through
    /// the carry flag.
    /// Every bit is shifted to the left (e.g. bit 1 value is copied from bit 0). The carry flag is copied to bit
    /// 0, and bit 7 is copied to the carry flag.
    pub fn rotate_left_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.getHL()];
        const bit_7: u1 = @truncate(contents.* >> 7);
        const carry = proc.getFlag(.C);
        contents.* <<= 1;
        contents.* |= carry;
        if (bit_7 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        if (contents.* == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
    }

    /// Rotates the 8-bit register r value right through the carry flag.
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). The carry flag is copied to bit
    /// 7, and bit 0 is copied to the carry flag
    pub fn rotate_right_r8(proc: *Processor, register: *Register) void {
        const bit_0: u1 = @truncate(register.value);
        const carry_mask: u8 = if (proc.getFlag(.C) == 1) 0x80 else 0x00;
        register.value >>= 1;
        register.value |= carry_mask;
        if (bit_0 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        if (register.value == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
    }

    /// Rotates, the 8-bit data at the absolute address specified by the 16-bit register HL, right through
    /// the carry flag.
    /// Every bit is shifted to the right (e.g. bit 1 value is copied to bit 0). The carry flag is copied to bit
    /// 7, and bit 0 is copied to the carry flag.
    pub fn rotate_right_hlMem(proc: *Processor) void {
        const contents: *u8 = &proc.memory.address[proc.getHL()];
        const bit_0: u1 = @truncate(contents.*);
        const carry_mask: u8 = if (proc.getFlag(.C) == 1) 0x80 else 0x00;
        contents.* >>= 1;
        contents.* |= carry_mask;
        if (bit_0 == 1) proc.setFlag(.C) else proc.unsetFlag(.C);
        if (contents.* == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
        proc.unsetFlag(.N);
        proc.unsetFlag(.H);
    }
};

const expectEqual = std.testing.expectEqual;

// Arithmetic Instructions
test "inc_r8" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{});

    arithmetic.inc_r8(&processor, &processor.B);

    try expectEqual(0x01, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    arithmetic.inc_r8(&processor, &processor.B);

    try expectEqual(0x02, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.B.value = 0xFF;
    arithmetic.inc_r8(&processor, &processor.B);

    try expectEqual(0x00, processor.B.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.B.value = 0x0F;
    arithmetic.inc_r8(&processor, &processor.B);
    try expectEqual(0x10, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.E.value = 0x0F;
    arithmetic.inc_r8(&processor, &processor.E);
    try expectEqual(0x10, processor.E.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "dec_reg" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .D = 0x02 });

    arithmetic.dec_reg(&processor, &processor.D);
    try expectEqual(0x01, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    arithmetic.dec_reg(&processor, &processor.D);
    try expectEqual(0x00, processor.D.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    arithmetic.dec_reg(&processor, &processor.D);
    try expectEqual(0xFF, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "inc_rr" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    arithmetic.inc_rr(&processor, .AF);
    try expectEqual(1, processor.getAF());

    processor.setAF(0xFFFF);
    arithmetic.inc_rr(&processor, .AF);
    try expectEqual(0, processor.getAF());

    processor.setBC(0x00FF);
    arithmetic.inc_rr(&processor, .BC);
    try expectEqual(0x0100, processor.getBC());

    processor.setDE(0x0101);
    arithmetic.inc_rr(&processor, .DE);
    try expectEqual(0x0102, processor.getDE());

    processor.setHL(0x0FFF);
    arithmetic.inc_rr(&processor, .HL);
    try expectEqual(0x1000, processor.getHL());
}

test "dec_rr" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{});

    arithmetic.dec_rr(&processor, .AF);
    try expectEqual(0xFFFF, processor.getAF());

    processor.setBC(0x0100);
    arithmetic.dec_rr(&processor, .BC);
    try expectEqual(0x00FF, processor.getBC());

    processor.setDE(0x0102);
    arithmetic.dec_rr(&processor, .DE);
    try expectEqual(0x0101, processor.getDE());

    processor.setHL(0x1000);
    arithmetic.dec_rr(&processor, .HL);
    try expectEqual(0x0FFF, processor.getHL());
}

test "add_reg" {
    const PC: u16 = 0x0100;
    const A: u8 = 0x14;
    const B: u8 = 0x07;
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .PC = PC, .A = A, .B = B });

    arithmetic.add_reg(&processor, &processor.B);
    try expectEqual(0x1B, processor.A.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.C));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.A.value = 0xFF;
    processor.C.value = 0xFF;
    arithmetic.add_reg(&processor, &processor.C);
    try expectEqual(0xFE, processor.A.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.C));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.D.value = 0x02;
    arithmetic.add_reg(&processor, &processor.D);
    try expectEqual(0x00, processor.A.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.C));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.E.value = 0x01;
    arithmetic.add_reg(&processor, &processor.E);
    try expectEqual(0x01, processor.A.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.C));
    try expectEqual(false, processor.isFlagSet(.H));
}

test "arithmetic.add16_rr_rr" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{
        .B = 0x11,
        .C = 0x5E,
    });
    
    arithmetic.add16_rr_rr(&processor, .HL, .BC);
    try expectEqual(0x115E, processor.getHL());
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.C));
    try expectEqual(false, processor.isFlagSet(.H));
}

// Load instructions
test "load.rr_imm16" {
    const PC: u16 = 0x0100;
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .PC = PC });
    const immLo: u8 = 0x03;
    const immHi: u8 = 0xA5;

    processor.memory.write(PC, immLo);
    processor.memory.write(PC + 1, immHi);

    load.rr_imm16(&processor, .BC);
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

test "bitShift.rotate_left_r8" {
    var memory = Memory.init();
    var processor = Processor.init(&memory, .{ .B = 0x7F });

    bitShift.rotate_left_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b1111_1110, processor.B.value);

    bitShift.rotate_left_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1100, processor.B.value);

    bitShift.rotate_left_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_1001, processor.B.value);

    bitShift.rotate_left_r8(&processor, &processor.B);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(1, processor.getFlag(.C));
    try expectEqual(0b1111_0011, processor.B.value);

    processor.unsetFlag(.C);
    processor.H.value = 0x00;
    bitShift.rotate_left_r8(&processor, &processor.H);
    try expectEqual(1, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0x00, processor.H.value);

    processor.setFlag(.C);
    bitShift.rotate_left_r8(&processor, &processor.H);
    try expectEqual(0, processor.getFlag(.Z));
    try expectEqual(0, processor.getFlag(.N));
    try expectEqual(0, processor.getFlag(.H));
    try expectEqual(0, processor.getFlag(.C));
    try expectEqual(0b0000_0001, processor.H.value);
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
