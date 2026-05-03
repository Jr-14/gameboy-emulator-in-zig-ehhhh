const std = @import("std");
const mbc = @import("cartridges/mbc.zig");
const MBCType = mbc.MBCType;

const Cartridge = @This();

const entry_point_size = 4; // Range from 0x0100 - 0x0103
const logo_size = 48; // Range from 0x0104 - 0x0133
const title_size = 16; // Range from 0x0134- 0x0143

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

/// [The Cartridge Header](https://gbdev.io/pandocs/The_Cartridge_Header.html)
/// 
/// Each cartridge contains a header, located at the address range $0100 - $014F. The cartridge header provides the
/// following information about the game itself and the hardware it expects to run on
///
/// We use an extern struct as we want a defined layout for the fields of the struct as the compiler does not guarantee
/// struct layout fields to be defined/well-ordered as the compiler optimises how the struct is laid out. This allows
/// the struct to match the layout of structs in the C ABI.
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

    pub fn init(rom_data: []u8) CartridgeHeader {
        const header: *CartridgeHeader = @ptrCast(@alignCast(rom_data[0x0100..0x0150].ptr));
        return header.*;
    }

    pub fn printDebugCartridgeHeader(self: *const CartridgeHeader) void {
        std.debug.print("new_licensee_code: ${X:0>4}\n", .{ self.new_licensee_code });
        std.debug.print("title: {s}\n", .{ self.title });
        std.debug.print("sbg flag: ${X:0>2}\n", .{ self.sgb_flag });
        std.debug.print("cartridge type: ${X:0>2}\n", .{ self.cartridge_type });
        std.debug.print("rom size: ${X:0>2}\n", .{ self.rom_size });
        std.debug.print("ram size: ${X:0>2}\n", .{ self.ram_size });
        std.debug.print("destination code: ${X:0>2}\n", .{ self.destination_code });
        std.debug.print("old licensee code: ${X:0>2}\n", .{ self.old_licensee_code });
        std.debug.print("mask_rom_version_number: ${X:0>2}\n", .{ self.mask_rom_version_number });
        std.debug.print("header_checksum: ${X:0>2}\n", .{ self.header_checksum });
        std.debug.print("global_checksum: ${X:0>4}\n", .{ self.global_checksum });
    }
};

allocator: std.mem.Allocator,
header: CartridgeHeader,
rom_data: []const u8,

pub fn init(io: std.Io, allocator: std.mem.Allocator, rom_file_path: []const u8) !Cartridge {
    const cwd = std.Io.Dir.cwd();
    const rom_file = try cwd.openFile(io, rom_file_path, .{ .mode = .read_only });
    defer rom_file.close(io);

    const rom_size = try rom_file.length(io);
    std.debug.print("Rom size: {} bytes\n", .{ rom_size });

    const rom_file_buffer = try allocator.alloc(u8, rom_size);
    defer allocator.free(rom_file_buffer);
    var rom_file_reader = rom_file.reader(io, rom_file_buffer);

    const rom_data = try allocator.alloc(u8, 4096);
    rom_file_reader.interface.readSliceAll(rom_data) catch |err| {
        std.debug.print("read failed: {}", .{ err });
    };

    const header = CartridgeHeader.init(rom_data);

    return .{
        .allocator = allocator,
        .rom_data = rom_data,
        .header = header,
    };
}

pub fn deinit(self: *Cartridge) void {
    self.allocator.free(self.rom_data);
}
