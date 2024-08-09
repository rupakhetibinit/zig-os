const fmt = @import("std").fmt;
const mem = @import("std").mem;
const Writer = @import("std").io.Writer;

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

/// Enumeration of VGA Text Mode supported colors.
pub const Colors = enum(u8) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

/// The current cursor row position.
pub var row: usize = 0;

/// The current cursor column position.
pub var column: usize = 0;

/// The current color active foreground and background colors.
var color = vgaEntryColor(Colors.LightGray, Colors.Black);

/// Direct memory access to the VGA Text buffer.
var buffer = @as([*]volatile u16, @ptrFromInt(0xB8000));

/// Create a VGA color from a foreground and background Colors enum.
fn vgaEntryColor(fg: Colors, bg: Colors) u8 {
    return @as(u8, @intFromEnum(fg)) | @as(u8, (@intFromEnum(bg)) << 4);
}

/// Create a VGA character entry from a character and a color
fn vgaEntry(uc: u8, newColor: u8) u16 {
    const c: u16 = newColor;
    return uc | (c << 8);
}

/// Set the active colors.
pub fn setColors(fg: Colors, bg: Colors) void {
    color = vgaEntryColor(fg, bg);
}

/// Set the active foreground color.
pub fn setForegroundColor(fg: Colors) void {
    color = (0xF0 & color) | @as(u8, @intFromEnum(fg));
}

/// Set the active background color.
pub fn setBackgroundColor(bg: Colors) void {
    color = (0x0F & color) | @as(u8, (@intFromEnum(bg)) << 4);
}

/// Clear the screen using the active background color as the color to be painted.
pub fn clear() void {
    @memset(buffer[0..VGA_SIZE], vgaEntry(' ', color));
}

/// Sets the current cursor location.
pub fn setLocation(x: u8, y: u8) void {
    row = x % VGA_WIDTH;
    column = y & VGA_HEIGHT;
    buffer[y * VGA_WIDTH + x] = vgaEntry(@as(u8, 0x24), color);
}

/// Puts a character at the specific coordinates using the specified color.
fn putCharAt(c: u8, newColor: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    buffer[index] = vgaEntry(c, newColor);
}

/// Prints a single character
pub fn putChar(c: u8) void {
    putCharAt(c, color, column, row);
    column += 1;
    if (column == VGA_WIDTH) {
        column = 0;
        row += 1;
        if (row == VGA_HEIGHT)
            row = 0;
    }
}

pub fn putString(data: []const u8) void {
    for (data) |c| {
        putChar(c);
    }
}

pub const writer = Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, string: []const u8) error{}!usize {
    putString(string);
    return string.len;
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    fmt.format(writer, format, args) catch unreachable;
}

pub fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "{dx}" (port),
        : "memory"
    );
}

pub fn terminalSetCursor(x: u8, y: u8) void {
    const pos: u16 = @as(u16, y) * VGA_WIDTH + x;

    outb(0x3D4, 0x0F);
    outb(0x3D5, @as(u8, @truncate(pos & 0xFF)));
    outb(0x3D4, 0x0E);
    outb(0x3D5, @as(u8, @truncate((pos >> 8) & 0xFF)));
}
