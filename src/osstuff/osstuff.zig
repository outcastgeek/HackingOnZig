const std = @import("std");
const debug = std.debug;
const panic = std.debug.panic;
const assert = debug.assert;
const fs = std.fs;
const process = std.process;
// const BuffMap = std.BufMap;
const EnvMap = std.process.EnvMap;
const Allocator = std.mem.Allocator;
const c = std.c;
const mem = std.mem;
const os = std.os;
const native_os = @import("builtin").target.os.tag;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    builtForOs();

    // var env_map = BuffMap.init(allocator);
    var env_map = EnvMap.init(allocator);
    defer env_map.deinit();
    try env_map.put("CURRENT_DIR", "`pwd`");
    var code: u8 = undefined;

    var output = try execCmd(allocator, &env_map, &.{ "ls", "-l", "." }, &code, .Inherit);
    std.log.info("code => {d} output => {s}\n", .{ code, output });

    const exe = os.argv[0];
    std.log.debug("Executable: {s}\n", .{exe});

    if (os.argv.len > 1) {
        // const arg2 = os.argv[1];
        // const cmd = mem.sliceTo(arg2, 0);
        const CmdArray = std.ArrayList([]const u8);
        var cmd = CmdArray.init(allocator);
        const progArgs = os.argv;
        const allArgs = progArgs[1..];
        for (allArgs) |arg| {
            std.log.debug("arg => {s}\n", .{arg});
            const argc = mem.sliceTo(arg, 0);
            try cmd.append(argc);
        }

        output = try execCmd(allocator, &env_map, cmd.toOwnedSlice(), &code, .Inherit);
        std.log.info("code => {d} output => {s}\n", .{ code, output });
    }
}

pub fn execCmd( // Borrowed from zig std build `execFromStep` and `execAllowFail`
    allocator: Allocator,
    // env_map: *BuffMap,
    env_map: *EnvMap,
    argv: []const []const u8,
    out_code: *u8,
    stderr_behavior: std.ChildProcess.StdIo,
) ![]u8 {
    assert(argv.len != 0);

    const max_output_size = 400 * 1024;
    // const child = try std.ChildProcess.init(argv, allocator);
    var child = std.ChildProcess.init(argv, allocator);
    // defer child.deinit();

    child.cwd = try fs.cwd().realpathAlloc(allocator, "");
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = stderr_behavior;
    child.env_map = env_map;

    try child.spawn();

    const stdout = try child.stdout.?.reader().readAllAlloc(allocator, max_output_size);
    errdefer allocator.free(stdout);

    const term = try child.wait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                out_code.* = @truncate(u8, code);
                return error.ExitCodeFailure;
            }
            return stdout;
        },
        .Signal, .Stopped, .Unknown => |code| {
            out_code.* = @truncate(u8, code);
            return error.ProcessTerminated;
        },
    }
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
