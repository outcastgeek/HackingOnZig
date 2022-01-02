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
    dir: []const u8,
    includeDir: ?[]const u8,
    flags: []const []const u8,
};

pub const ZigCExeParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    cSrc: ?CSrcParams,
    cppSrc: ?CSrcParams,
    src: []const u8,
    usage: []const u8,
};

pub fn zcExe(zcp: ZigCExeParams) void {
    const exe = zcp.builder.addExecutable(zcp.name, zcp.src);
    exe.setTarget(zcp.target);
    exe.setBuildMode(zcp.mode);
    if (zcp.cSrc) |cSrc| {
        var cSources = collectCSources(.{ .allocator = zcp.builder.allocator, .src = cSrc.dir, .allowed_exts = [][]const u8{ ".c" } });
        if (cSrc.includeDir) |inclDir| {
            exe.addIncludeDir(inclDir);
        }
        exe.addCSourceFiles(cSources.items, cSrc.flags);
        exe.linkLibC();
    }
    if (zcp.cppSrc) |cppSrc| {
        var cppSources = collectCSources(.{ .allocator = zcp.builder.allocator, .src = cppSrc.dir, .allowed_exts = [][]const u8{ ".cpp", ".cxx", ".c++", ".cc" } });
        if (cppSrc.includeDir) |inclDir| {
            exe.addIncludeDir(inclDir);
        }
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
    cSrc: ?CSrcParams,
    cppSrc: ?CSrcParams,
    usage: []const u8,
};

pub fn cExe(cp: CExeParams) void {
    const exe = cp.builder.addExecutable(cp.name, null);
    exe.setTarget(cp.target);
    exe.setBuildMode(cp.mode);
    if (cp.cSrc) |cSrc| {
        var cSources = collectCSources(.{ .allocator = cp.builder.allocator, .src = cSrc.dir, .allowed_exts = [][]const u8{ ".c" } });
        if (cSrc.includeDir) |inclDir| {
            exe.addIncludeDir(inclDir);
        }
        exe.addCSourceFiles(cSources.items, cSrc.flags);
        exe.linkLibC();
    }
    if (cp.cppSrc) |cppSrc| {
        var cppSources = collectCSources(.{ .allocator = cp.builder.allocator, .src = cppSrc.dir, .allowed_exts = [][]const u8{ ".cpp", ".cxx", ".c++", ".cc" } });
        if (cppSrc.includeDir) |inclDir| {
            exe.addIncludeDir(inclDir);
        }
        exe.addCSourceFiles(cppSources.items, cppSrc.flags);
        exe.linkLibCpp();
    }
    exe.install();
    const run_cmd = exe.run();
    if (cp.builder.args) |args| {
        run_cmd.addArgs(args);
    }
    run_cmd.step.dependOn(cp.builder.getInstallStep());
    const help = std.fmt.allocPrint(cp.builder.allocator, "Run {s}", .{cp.src}) catch |err| {
        std.log.err("ALLOCATION_ERROR:::: {}", .{err});
        return;
    };
    defer cp.builder.allocator.free(help);
    const run_step = cp.builder.step(cp.usage, help);
    run_step.dependOn(&run_cmd.step);
}

pub const CCppSrcParams = struct {
    allocator: Allocator,
    src: []const u8,
    allowed_exts: [][]const u8 = [][]const u8{ ".c", ".cpp", ".cxx", ".c++", ".cc" },
};

fn collectCSources(csp: CCppSrcParams) std.ArrayList([]const u8) {
    var sources = std.ArrayList([]const u8).init(csp.allocator);

    // Search for all c/c++ files in the src directory and add them to the list of sources.
    {
        var dir = fs.cwd().openDir(csp.src, .{ .iterate = true }) catch |err| {
            std.log.err("COULD_NOT_OPEN_DIR:::: {}", .{err});
            return;
        };
        var walker = dir.walk(csp.builder.allocator) catch |err| {
            std.log.err("COULD_WALK_DIR:::: {}", .{err});
            return;
        };
        defer walker.deinit();
        while (walker.next()) |entry| {
            const ext = fs.path.extension(entry.basename);
            const include_file = for (csp.allowed_exts) |e| {
                if (std.mem.eql(u8, ext, e))
                    break true;
            } else false;
            if (include_file) {
                sources.append(entry.path) catch |err| {
                    std.log.err("COULD_NOT_APPEND_SOURCES_ARRAY:::: {}", .{err});
                    return;
                };
            }
        }
    }

    return sources;
}
