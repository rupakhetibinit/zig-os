const console = @import("console.zig");
const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MB1_MAGIC: u32 = 0x1BADB002;
const FLAGS: u32 = ALIGN | MEMINFO;

const MultibootHeader = extern struct {
    magic: u32 = MB1_MAGIC,
    flags: u32,
    checksum: u32,
};

export var multiboot align(4) linksection(".multiboot") = MultibootHeader{
    .flags = FLAGS,
    .checksum = @as(u32, @intCast(((-(@as(i64, @intCast(MB1_MAGIC)) + @as(i64, @intCast(FLAGS)))) & 0xFFFFFFFF))),
};

export fn _start() noreturn {
    @call(.auto, main, .{});
    while (true) {
        asm volatile ("hlt");
    }
}

pub fn main() void {
    console.setColors(.White, .Blue);
    console.clear();
    console.putString("Hello, world");
    console.setForegroundColor(.LightRed);
    console.putChar('!');
    console.terminalSetCursor(0, 1);
}
