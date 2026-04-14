const std = @import("std");

const Cartridge = @import("../Cartridge.zig");
const CartridgeType = Cartridge.CartridgeType;

const NoMBC = @import("./mbc/no_mbc.zig");
const MBC1 = @import("./mbc/mbc_1.zig");

pub const MBC = struct {
    number_of_rom_banks: u8,
};

/// I think this is how tagged unions work? I gotta revisit and understand why and how they're used
/// https://ziglang.org/documentation/master/#Tagged-union
pub const MBCType = union(CartridgeType) {
    rom_only,
    mbc1: MBC1
};


