const std = @import("std");
const Builder = std.build.Builder;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;

pub fn build(b: *Builder) void {
    // Standard target option allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // The standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    buildExe(
        b, target, mode,
        "chp0_hello", "src/chp0/hello.zig", "run_chp0_hello"
    );
    // buildExe(
    //     b, target, mode,
    //     "chp1_test_patterns", "src/chp1/test_patterns.zig", "run_chp1_test_patterns"
    // );
    buildExe(
        b, target, mode,
        "aoc1", "src/aoc1/aoc1.zig", "run_aoc1"
    );
}

fn buildExe(
    b: *Builder, target: CrossTarget, mode: Mode,
    name: []const u8, src: []const u8, usage: []const u8
) void {
    const exe = b.addExecutable(name, src);
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    const help = std.fmt.allocPrint(b.allocator, "Run {s}", .{src}) catch |err| {
        std.log.err("ALLOCATION_ERROR:::: {}", .{err});
        return;
    };
    defer b.allocator.free(help);
    const run_step = b.step(usage, help);
    run_step.dependOn(&run_cmd.step);
}
