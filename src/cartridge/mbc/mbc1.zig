/// [Banking Mode Select](https://gbdev.io/pandocs/MBC1.html#60007fff--banking-mode-select-write-only)
pub const BankingModeSelect = enum(u1) {
    simple = 0,
    advanced = 1,
};

/// [MBC1](https://gbdev.io/pandocs/MBC1.html)
pub const MBC1Cartridge = struct {
    /// [Ram Enable](https://gbdev.io/pandocs/MBC1.html#00001fff--ram-enable-write-only)
    ram_enable: bool,

    /// [Rom bank number](https://gbdev.io/pandocs/MBC1.html#20003fff--rom-bank-number-write-only)
    rom_bank_number: u5,

    /// [Ram Bank Number](https://gbdev.io/pandocs/MBC1.html#40005fff--ram-bank-number--or--upper-bits-of-rom-bank-number-write-only)
    ram_bank_number: u2,

    /// [Banking Mode Select](https://gbdev.io/pandocs/MBC1.html#60007fff--banking-mode-select-write-only)
    banking_mode_select: BankingModeSelect,

    pub fn writeRegister(address: u14, mode: BankingModeSelect) void {
        _ = mode;
        switch (address) {
            // Ram enable
            0x0000...0x1FFF => {}, 

            // Rom Bank Number
            0x2000...0x3FFF => {},

            // Ram Bank Number
            0x4000...0x5FFF => {},

            // Banking Mode Select
            0x6000...0x7FFF => {},

            else => unreachable,
        }
    }
};

