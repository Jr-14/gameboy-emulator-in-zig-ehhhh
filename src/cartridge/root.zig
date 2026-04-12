const std = @import("std");

const entry_point_size = 4; // Range from 0x0100 - 0x0103
const logo_size = 48; // Range from 0x0104 - 0x0133
const title_size = 16; // Range from 0x0134- 0x0143

/// [The Cartridge Header](https://gbdev.io/pandocs/The_Cartridge_Header.html)
/// 
/// Each cartridge contains a header, located at the address range $0100 - $014F. The cartridge header provides the
/// following information about the game itself and the hardware it expects to run on
pub const CartridgeHeader = extern struct {
    /// [Entry point](https://gbdev.io/pandocs/The_Cartridge_Header.html#0100-0103--entry-point)
    _entry_point: [entry_point_size]u8,

    /// [Nintendo Logo](https://gbdev.io/pandocs/The_Cartridge_Header.html#0104-0133--nintendo-logo)
    logo: [logo_size]u8,

    /// [Title](https://gbdev.io/pandocs/The_Cartridge_Header.html#0134-0143--title)
    title: [title_size]u8,

    /// [New licensee code](https://gbdev.io/pandocs/The_Cartridge_Header.html#01440146--new-licensee-code)
    new_licensee_code: u16,

    /// [SGB flag](https://gbdev.io/pandocs/The_Cartridge_Header.html#0146--sgb-flag)
    sgb_flag: u8,

    /// [Cartridge type](https://gbdev.io/pandocs/The_Cartridge_Header.html#0147--cartridge-type)
    cartridge_type: CartridgeType,

    /// [ROM size](https://gbdev.io/pandocs/The_Cartridge_Header.html#0148--rom-size)
    rom_size: u8,

    /// [RAM size](https://gbdev.io/pandocs/The_Cartridge_Header.html#0149--ram-size)
    ram_size: u8,

    /// [Destination code](https://gbdev.io/pandocs/The_Cartridge_Header.html#014a--destination-code)
    destination_code: u8,

    /// [Old licensee code](https://gbdev.io/pandocs/The_Cartridge_Header.html#014b--old-licensee-code)
    old_licensee_code: u8,

    /// [Mask ROM version number](https://gbdev.io/pandocs/The_Cartridge_Header.html#014c--mask-rom-version-number)
    mask_rom_version_number: u8,

    /// [Header checksum](https://gbdev.io/pandocs/The_Cartridge_Header.html#014d--header-checksum)
    header_checksum: u8,

    /// [Global checksum](https://gbdev.io/pandocs/The_Cartridge_Header.html#014e-014f--global-checksum)
    global_checksum: u16,
};

pub fn printDebugCartridgeHeader(header: *CartridgeHeader) void {
    std.debug.print("new_licensee_code: ${X:0>4}\n", .{ header.new_licensee_code });
    std.debug.print("title: {s}\n", .{ header.title });
    std.debug.print("sbg flag: ${X:0>2}\n", .{ header.sgb_flag });
    std.debug.print("cartridge type: ${X:0>2}\n", .{ header.cartridge_type });
    std.debug.print("rom size: ${X:0>2}\n", .{ header.rom_size });
    std.debug.print("ram size: ${X:0>2}\n", .{ header.ram_size });
    std.debug.print("destination code: ${X:0>2}\n", .{ header.destination_code });
    std.debug.print("old licensee code: ${X:0>2}\n", .{ header.old_licensee_code });
    std.debug.print("mask_rom_version_number: ${X:0>2}\n", .{ header.mask_rom_version_number });
    std.debug.print("header_checksum: ${X:0>2}\n", .{ header.header_checksum });
    std.debug.print("global_checksum: ${X:0>4}\n", .{ header.global_checksum });
}


pub fn createCartridge(rom_data: []u8) !void {
    const header: *CartridgeHeader = @ptrCast(@alignCast(rom_data[0x0100..].ptr));
    printDebugCartridgeHeader(header);
}

/// [Cartridge type](https://gbdev.io/pandocs/The_Cartridge_Header.html#0147--cartridge-type)
pub const CartridgeType = enum(u8) {
    rom_only = 0x00,
    mbc1 = 0x01,
    mbc1_ram = 0x02,
    mbc1_ram_batter = 0x03,
    mbc2 = 0x05,
    mbc2_battery = 0x06,
    rom_ram = 0x08,
    rom_ram_battery = 0x09,
    mmmo1 = 0x0B,
    mmmo1_ram = 0x0C,
    mmmo1_ram_battery = 0x0D,
    mbc3_timer_battery = 0x0F,
    mbc3_timer_ram_battery = 0x10,
    mbc3 = 0x11,
    mbc3_ram = 0x12,
    mbc3_ram_battery = 0x13,
    mbc5 = 0x19,
    mbc5_ram = 0x1A,
    mbc5_ram_battery = 0x1B,
    mbc5_rumble = 0x1C,
    mbc5_rumble_ram = 0x1D,
    mbc5_rumble_ram_battery = 0x1E,
    mbc6 = 0x20,
    mbc7_sensor_rumble_ram_battery = 0x22,
    pocket_camera = 0xFC,
    bandai_tama5 = 0xFD,
    huc3 = 0xFE,
    huc1_ram_battery = 0xFF,
};

const expectEqual = std.testing.expectEqual;

test "i need to read stuff" {
    const dbga = std.heap.DebugAllocator(.{}){};
    defer _ = dbga.deinit();
    _ = dbga.allocator();
}
