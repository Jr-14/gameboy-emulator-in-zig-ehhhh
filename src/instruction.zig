const std = @import("std");
const Register = @import("register_new.zig");
const Processor = @import("processor_new.zig");
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

pub fn inc_reg(
    proc: *Processor,
    reg: *Register,
) void {
    const sum = utils.byteAdd(reg.value, 1);
    reg.value = sum.result;
    proc.unsetFlag(.N);
    if (sum.result == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
    if (sum.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
}

pub fn dec_reg(
    proc: *Processor,
    reg: *Register,
) void {
    const remainder = utils.byteSub(reg.value, 1);
    reg.value = remainder.result;
    proc.setFlag(.N);
    if (remainder.result == 0) proc.setFlag(.Z) else proc.unsetFlag(.Z);
    if (remainder.half_carry == 1) proc.setFlag(.H) else proc.unsetFlag(.H);
}

/// Increment register pair RR by 1
pub fn inc_rr(proc: *Processor, regPair: Processor.RegisterPair) void {
    switch (regPair) {
        .AF => proc.setAF(proc.getAF() + 1),
        .BC => proc.setBC(proc.getBC() + 1),
        .DE => proc.setDE(proc.getDE() + 1),
        .HL => proc.setHL(proc.getHL() + 1),
    }
}

pub const load = struct {
    pub fn reg_imm8(proc: *Processor, reg: *Register) void {
        reg.value = proc.fetch();
    }

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

    pub fn reg_regMem(proc: *Processor, dest: *Register, src: *Register) void {
        dest.value = proc.memory.read(utils.fromTwoBytes(src.value, 0xFF));
    }

    pub fn reg_imm16Mem(proc: *Processor, dest: *Register) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        const addr = utils.fromTwoBytes(lo, hi);

        dest.value = proc.memory.read(addr);
    }

    /// Load into register pair rr immediate two byte data.
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

    /// Store the contents of a Register into the memory location specified by the register pair RR
    pub fn hlMem_reg(proc: *Processor, reg: *Register) void {
        proc.memory.write(proc.getHL(), reg.value);
    }

    /// Store the contents of a Register into the memory location specified by the register pair RR
    pub fn rrMem_imm8(proc: *Processor, regPair: Processor.RegisterPair) void {
        const value = proc.fetch();
        switch (regPair) {
            .AF => proc.memory.write(proc.getAF(), value),
            .BC => proc.memory.write(proc.getBC(), value),
            .DE => proc.memory.write(proc.getDE(), value),
            .HL => proc.memory.write(proc.getHL(), value),
        }
    }

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

    pub fn imm16Mem_reg(proc: *Processor, reg: *Register) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        const addr = utils.fromTwoBytes(lo, hi);
        proc.memory.write(addr, reg.value);
    }

    /// Store into the immediate address the contents of special purpose registers
    pub fn imm16Mem_spr(proc: *Processor, val: u16) void {
        const addr: u16 = utils.fromTwoBytes(proc.fetch(), proc.fetch());
        proc.memory.write(addr, utils.getLoByte(val));
        proc.memory.write(addr + 1, utils.getHiByte(val));
    }

    /// Load the 2 bytes of immediate data into special register.
    /// The first byte of immedaite data is the lower byte (i.e., bits 0-7), and the second byte of
    /// immediate data is the higher byte (i.e., bits 8-15).
    pub fn spr_imm16(proc: *Processor, spr: *u16) void {
        spr.* = utils.fromTwoBytes(proc.fetch(), proc.fetch());
    }

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

    /// Load the 8-bit contents of memory specified by register pair into register
    pub fn reg_rrMem(proc: *Processor, reg: *Register, regPair: Processor.RegisterPair) void {
        switch (regPair) {
            .AF => reg.value = proc.memory.read(proc.getAF()),
            .BC => reg.value = proc.memory.read(proc.getBC()),
            .DE => reg.value = proc.memory.read(proc.getDE()),
            .HL => reg.value = proc.memory.read(proc.getHL()),
        }
    }

    pub fn hlMem_inc_reg(proc: *Processor, reg: *Register) void {
        const hl = proc.getHL();
        proc.memory.write(hl, reg.value);
        proc.setHL(hl +% 1);
    }

    pub fn hlMem_dec_reg(proc: *Processor, reg: *Register) void {
        const hl = proc.getHL();
        proc.memory.write(hl, reg.value);
        proc.setHL(hl -% 1);
    }

    pub fn reg_hlMem_inc(proc: *Processor, reg: *Register) void {
        const hl = proc.getHL();
        reg.value = proc.memory.read(hl);
        proc.setHL(hl +% 1);
    }

    pub fn reg_hlMem_dec(proc: *Processor, reg: *Register) void {
        const hl = proc.getHL();
        reg.value = proc.memory.read(hl);
        proc.setHL(hl -% 1);
    }
};

pub const controlFlow = struct {
    /// Jump s8 steps fetch from immediate operand in the program counter (PC).
    pub fn jump_rel_imm8(proc: *Processor) void {
        const offset = proc.fetch();
        proc.PC = utils.addOffset(proc.PC, offset);
    }

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

    pub fn jump_imm16(proc: *Processor) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        proc.PC = utils.fromTwoBytes(lo, hi);
    }

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

    pub fn ret(proc: *Processor) void {
        const lo: u8 = proc.popStack();
        const hi: u8 = proc.popStack();
        proc.PC = utils.fromTwoBytes(lo, hi);
    }


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

    pub fn reti(proc: *Processor) void {
        ret(proc);
        proc.IME = true;
    }

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

    pub fn call_imm16(proc: *Processor) void {
        const lo = proc.fetch();
        const hi = proc.fetch();
        proc.pushStack(utils.getHiByte(proc.PC));
        proc.pushStack(utils.getLoByte(proc.PC));
        proc.PC = utils.fromTwoBytes(lo, hi);
    }

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

    pub fn rst(proc: *Processor, index: u3) void {
        proc.pushStack(utils.getHiByte(proc.PC));
        proc.pushStack(utils.getLoByte(proc.PC));
        proc.PC = mask.HI_MASK | (0x08 * @as(u8, index));
    }

};

const expectEqual = std.testing.expectEqual;

test "inc_reg" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{});

    inc_reg(&processor, &processor.B);

    try expectEqual(0x01, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    inc_reg(&processor, &processor.B);

    try expectEqual(0x02, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    processor.B.value = 0xFF;
    inc_reg(&processor, &processor.B);

    try expectEqual(0x00, processor.B.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.B.value = 0x0F;
    inc_reg(&processor, &processor.B);
    try expectEqual(0x10, processor.B.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));

    processor.E.value = 0x0F;
    inc_reg(&processor, &processor.E);
    try expectEqual(0x10, processor.E.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(false, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

test "dec_reg" {
    var memory: Memory = .init();
    var processor = Processor.init(&memory, .{ .D = 0x02 });

    dec_reg(&processor, &processor.D);
    try expectEqual(0x01, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    dec_reg(&processor, &processor.D);
    try expectEqual(0x00, processor.D.value);
    try expectEqual(true, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(false, processor.isFlagSet(.H));

    dec_reg(&processor, &processor.D);
    try expectEqual(0xFF, processor.D.value);
    try expectEqual(false, processor.isFlagSet(.Z));
    try expectEqual(true, processor.isFlagSet(.N));
    try expectEqual(true, processor.isFlagSet(.H));
}

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
