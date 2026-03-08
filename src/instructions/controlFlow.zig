const std = @import("std");

const Processor = @import("../processor_new.zig");
const PackedRegister = @import("../register_packed.zig");
const Memory = @import("../memory.zig");
const utils = @import("../utils.zig");

const FlagCondition = Processor.FlagCondition;

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
    proc.PC = 0xFF00 | (0x08 * @as(u8, index));
}

