
const std = @import("std");
const native_os = @import("builtin").target.os.tag;

pub fn main() void {
    builtForOs();
}

fn builtForOs() void {
    if (native_os == .linux) { // Check this out: https://github.com/ziglang/zig/blob/master/lib/std/os/test.zig
        std.log.debug("Built for Linux!!", .{});
    } else if (native_os == .macos) {
        std.log.debug("Built for Mac!!", .{});
    } else if (native_os == .windows) {
        std.log.debug("Built for Windows!!", .{});
    } else {
        @compileError("System not supported");
    }
}
