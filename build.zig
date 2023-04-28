const std = @import("std");
const Builder = std.build.Builder;
const bldhlpr = @import("build_utils/helper.zig");
const zigExe = bldhlpr.zigExe;
const cExe = bldhlpr.cExe;
const zcExe = bldhlpr.zcExe;

pub fn build(b: *Builder) void {
    // Standard target option allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // The standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    //const mode = b.standardReleaseOptions();
    const mode = b.standardOptimizeOption(.{});

    // Build the Zig Executable Targets
    {
        zigExe(.{
            .builder = b,
            .target = target,
            .mode = mode,
            .name = "chp0_hello",
            .src = "src/chp0/hello.zig",
            .usage = "run_chp0_hello",
        });
        //zigExe(.{
        //    .builder = b,
        //    .target = target,
        //    .mode = mode,
        //    .name = "chp1_test_patterns",
        //    .src = "src/chp1/test_patterns.zig",
        //    .usage = "run_chp1_test_patterns",
        //});
        zigExe(.{
            .builder = b,
            .target = target,
            .mode = mode,
            .name = "aoc1",
            .src = "src/aoc1/aoc1.zig",
            .usage = "run_aoc1",
        });
        zigExe(.{
            .builder = b,
            .target = target,
            .mode = mode,
            .name = "aoc2",
            .src = "src/aoc2/aoc2.zig",
            .usage = "run_aoc2",
        });
        zigExe(.{
            .builder = b,
            .target = target,
            .mode = mode,
            .name = "osstuff",
            .src = "src/osstuff/osstuff.zig",
            .usage = "run_osstuff",
        });
        zigExe(.{
            .builder = b,
            .target = target,
            .mode = mode,
            .name = "multiarr",
            .src = "src/multiarr/multiarr.zig",
            .usage = "run_multiarr",
        });
        //zigExe(.{
        //    .builder = b,
        //    .target = target,
        //    .mode = mode,
        //    .name = "zintrfcs",
        //    .src = "src/zintrfcs/zintrfcs.zig",
        //    .usage = "run_zintrfcs",
        //});
        //zigExe(.{
        //    .builder = b,
        //    .target = target,
        //    .mode = mode,
        //    .name = "zsrvr",
        //    .src = "src/zsrvr/zsrvr.zig",
        //    .usage = "run_zsrvr",
        //    //.use_stage1 = true,
        //});
        zigExe(.{
            .builder = b,
            .target = target,
            .mode = mode,
            .name = "zwavef",
            .src = "src/zwavef/zwavef.zig",
            .usage = "run_zwavef",
        });
        //zcExe(.{
        //    .builder = b,
        //    .target = target,
        //    .mode = mode,
        //    .name = "zc_interop",
        //    .src = "src/zc_interop/zc_interop.zig",
        //    .ccSrc = .{
        //        .cSrc = .{
        //            .dir = "src/zc_interop/clib/",
        //            .includeDir = "src/zc_interop/clib/include/",
        //            .flags = &.{
        //                "-std=c11",
        //            },
        //        },
        //    },
        //    .usage = "run_zc_interop",
        //});
    }

    // Build the C/C++ Executable Targets
    {
        //cExe(.{
        //    .builder = b,
        //    .target = target,
        //    .mode = mode,
        //    .name = "weird_args",
        //    .src = .{
        //        .cSrc = .{
        //            .dir = "src/weird_args/",
        //            .flags = &.{"-std=c17"},
        //        },
        //    },
        //    .usage = "run_weird_args",
        //});
        //cExe(.{
        //    .builder = b,
        //    .target = target,
        //    .mode = mode,
        //    .name = "print_args",
        //    .src = .{
        //        .cSrc = .{
        //            .dir = "src/c_sample/",
        //            .flags = &.{"-std=c17"},
        //        },
        //    },
        //    .usage = "run_print_args",
        //});
        cExe(.{
            .builder = b,
            .target = target,
            .mode = mode,
            .name = "check_primes",
            .src = .{
                .cppSrc = .{
                    .dir = "src/cpp_sample/",
                    .flags = &.{
                        "-Wall",
                        "-Wextra",
                        "-Werror=return-type",
                        "--stdlib=libc++",
                        "-std=c++17",
                    },
                },
            },
            .usage = "run_check_primes",
        });
        cExe(.{
            .builder = b,
            .target = target,
            .mode = mode,
            .name = "cpp20_features",
            .src = .{
                .cppSrc = .{
                    .dir = "src/cpp20/",
                    .flags = &.{
                        "-Wall",
                        "-Wextra",
                        "-Werror=return-type",
                        "--stdlib=libc++",
                        "-std=c++20",
                    },
                },
            },
            .usage = "run_cpp20_features",
        });
    }

    // Run all the unit tests
    {
        //const unit_tests = b.addTest("src/unit_tests.zig");
        //unit_tests.setTarget(target);
        //unit_tests.setBuildMode(mode);
        //
        //const test_step = b.step("unit_tests", "Run the unit tests");
        //test_step.dependOn(&unit_tests.step);

        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/unit_tests.zig" },
            .target = target,
            .optimize = mode,
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);
        _ = run_unit_tests;

        const test_step = b.step("unit_tests", "Run the unit tests");
        test_step.dependOn(&unit_tests.step);
    }
}

// fn buildExe(b: *Builder, target: CrossTarget, mode: Mode, name: []const u8, src: []const u8, usage: []const u8) void {
//     const exe = b.addExecutable(name, src);
//     exe.setTarget(target);
//     exe.setBuildMode(mode);
//     exe.install();
//     const run_cmd = exe.run();
//     if (b.args) |args| {
//         run_cmd.addArgs(args);
//     }
//     run_cmd.step.dependOn(b.getInstallStep());
//     const help = std.fmt.allocPrint(b.allocator, "Run {s}", .{src}) catch |err| {
//         std.log.err("ALLOCATION_ERROR:::: {}", .{err});
//         return;
//     };
//     defer b.allocator.free(help);
//     const run_step = b.step(usage, help);
//     run_step.dependOn(&run_cmd.step);
// }
