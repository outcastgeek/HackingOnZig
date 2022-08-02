const std = @import("std");
const fs = std.fs;
const Builder = std.build.Builder;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;
const Allocator = std.mem.Allocator;

pub const ZigExeParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    src: []const u8,
    usage: []const u8,
};

pub fn zigExe(zp: ZigExeParams) void {
    const exe = zp.builder.addExecutable(zp.name, zp.src);
    exe.setTarget(zp.target);
    exe.setBuildMode(zp.mode);
    // exe.setVerboseCC(true);
    // exe.setVerboseLink(true);
    exe.install();
    const run_cmd = exe.run();
    if (zp.builder.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.step.dependOn(zp.builder.getInstallStep());
    const help = std.fmt.allocPrint(zp.builder.allocator, "Run {s}", .{zp.src}) catch |err| {
        std.log.err("ALLOCATION_ERROR:::: {}", .{err});
        return;
    };
    defer zp.builder.allocator.free(help);
    const run_step = zp.builder.step(zp.usage, help);
    run_step.dependOn(&run_cmd.step);
}

pub const CSrcParams = struct {
    dir: []const u8 = &.{},
    includeDir: []const u8 = &.{},
    flags: []const []const u8 = &[_][]const u8{},
};

pub const ZigCExeParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    cSrc: ?CSrcParams = undefined,
    cppSrc: ?CSrcParams = undefined,
    src: []const u8,
    usage: []const u8,
};

pub fn zcExe(zcp: ZigCExeParams) void {
    const exe = zcp.builder.addExecutable(zcp.name, zcp.src);
    exe.setTarget(zcp.target);
    exe.setBuildMode(zcp.mode);
    if (zcp.cSrc) |cSrc| {
        std.log.info("Collecting C Sources...", .{});
        var cSources = collectCSources(.{ .builder = zcp.builder, .src = cSrc.dir, .allowed_exts = [][]const u8{".c"} });
        exe.addIncludeDir(cSrc.includeDir);
        exe.addCSourceFiles(cSources.items, cSrc.flags);
        exe.linkLibC();
    }
    if (zcp.cppSrc) |cppSrc| {
        std.log.info("Collecting C++ Sources...", .{});
        var cppSources = collectCSources(.{ .builder = zcp.builder, .src = cppSrc.dir, .allowed_exts = [][]const u8{ ".cpp", ".cxx", ".c++", ".cc" } });
        exe.addIncludeDir(cppSrc.includeDir);
        exe.addCSourceFiles(cppSources.items, cppSrc.flags);
        exe.linkLibCpp();
    }
    exe.install();
    const run_cmd = exe.run();
    if (zcp.builder.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.step.dependOn(zcp.builder.getInstallStep());
    const help = std.fmt.allocPrint(zcp.builder.allocator, "Run {s}", .{zcp.src}) catch |err| {
        std.log.err("ALLOCATION_ERROR:::: {}", .{err});
        return;
    };
    defer zcp.builder.allocator.free(help);
    const run_step = zcp.builder.step(zcp.usage, help);
    run_step.dependOn(&run_cmd.step);
}

pub const CExeParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    cSrc: ?CSrcParams = undefined,
    cppSrc: ?CSrcParams = undefined,
    usage: []const u8,
};

pub fn cExe(cp: CExeParams) void {
    const exe = cp.builder.addExecutable(cp.name, null);
    exe.setTarget(cp.target);
    exe.setBuildMode(cp.mode);
    if (cp.cSrc) |cSrc| {
        std.log.info("Collecting C Sources...", .{});
        var cSources = collectCSources(.{ .builder = cp.builder, .src = cSrc.dir, .allowed_exts = &[_][]const u8{".c"} });
        exe.addIncludeDir(cSrc.includeDir);
        exe.addCSourceFiles(cSources.items, cSrc.flags);
        exe.linkLibC();
        // exe.setVerboseCC(true);
        // exe.setVerboseLink(true);
    }
    if (cp.cppSrc) |cppSrc| {
        std.log.info("Collecting C++ Sources...", .{});
        var cppSources = collectCSources(.{ .builder = cp.builder, .src = cppSrc.dir, .allowed_exts = &[_][]const u8{ ".cpp", ".cxx", ".c++", ".cc" } });
        exe.addIncludeDir(cppSrc.includeDir);
        exe.addCSourceFiles(cppSources.items, cppSrc.flags);
        exe.linkLibC();
        exe.linkLibCpp();
        // exe.linkSystemLibrary("c++");
        // exe.setVerboseCC(true);
        // exe.setVerboseLink(true);
    }
    exe.install();
    const run_cmd = exe.run();
    if (cp.builder.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.step.dependOn(cp.builder.getInstallStep());
    const help = std.fmt.allocPrint(cp.builder.allocator, "Run {s}", .{cp.name}) catch |err| {
        std.log.err("ALLOCATION_ERROR:::: {}", .{err});
        return;
    };
    defer cp.builder.allocator.free(help);
    const run_step = cp.builder.step(cp.usage, help);
    run_step.dependOn(&run_cmd.step);
}

pub const CCppSrcParams = struct {
    builder: *Builder,
    src: []const u8,
    allowed_exts: []const []const u8 = &[_][]const u8{ ".c", ".cpp", ".cxx", ".c++", ".cc" },
};

fn collectCSources(csp: CCppSrcParams) std.ArrayList([]const u8) {
    var sources = std.ArrayList([]const u8).init(csp.builder.allocator);

    // Search for all c/c++ files in the src directory and add them to the list of sources.
    {
        const currentWorkingDir = fs.cwd();
        const sourcePath = currentWorkingDir.realpathAlloc(csp.builder.allocator, csp.src) catch |err| {
            std.log.err("FILE_PATH_ERROR:::: {}", .{err});
            return sources;
        };
        std.log.info("C/C++ Directory: {s}", .{sourcePath});
        // var dir = currentWorkingDir.openDir(sourcePath, .{ .iterate = true }) catch |err| {
        var dir = currentWorkingDir.openIterableDir(sourcePath, .{}) catch |err| {
            std.log.err("COULD_NOT_OPEN_DIR:::: {}", .{err});
            return sources;
        };
        defer dir.close();
        var walker = dir.walk(csp.builder.allocator) catch |err| {
            std.log.err("COULD_WALK_DIR:::: {}", .{err});
            return sources;
        };
        defer walker.deinit();
        while (walker.next()) |wEntry| {
            if (wEntry) |entry| {
                std.log.info("Entry Basename: {s}", .{entry.basename});
                const ext = fs.path.extension(entry.basename);
                const include_file = finc: {
                    var ok = false;
                    for (csp.allowed_exts) |e| {
                        if (std.mem.eql(u8, ext, e)) {
                            ok = true;
                        }
                    }
                    break :finc ok;
                };
                if (include_file) {
                    std.log.info("Entry Path: {s}", .{entry.path});
                    const filePath = std.fmt.allocPrint(csp.builder.allocator, "{s}{s}", .{ csp.src, entry.path }) catch |err| {
                        std.log.err("ALLOCATION_ERROR:::: {}", .{err});
                        return sources;
                    };
                    std.log.info("File Path: {s}", .{filePath});
                    sources.append(filePath) catch |err| {
                        std.log.err("COULD_NOT_APPEND_SOURCES_ARRAY:::: {}", .{err});
                        return sources;
                    };
                    // sources.append(csp.builder.dupe(entry.path)) catch |err| {
                    //     std.log.err("COULD_NOT_APPEND_SOURCES_ARRAY:::: {}", .{err});
                    //     return sources;
                    // };
                }
            } else {
                break;
            }
        } else |err| {
            std.log.err("COULD_NOT_TRAVERSE_DIR:::: {}", .{err});
            return sources;
        }
    }

    return sources;
}
