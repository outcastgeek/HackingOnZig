const std = @import("std");
const Tuple = std.meta.Tuple;
const fs = std.fs;
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;
const Allocator = std.mem.Allocator;
const Compile = std.Build.Step.Compile;
const Dependency = std.build.Dependency;
const Module = std.build.Module;
const strsources = @import("strsources.zig");
const csources = @import("csources.zig");
const SrcType = csources.SrcType;
pub const getLines = strsources.getLines;

pub const Dep = struct {
    name: []const u8,
    moduleName: []const u8,
    artifacts: ?[][]const u8 = &.{},
};

pub const ZigExeParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    src: []const u8,
    usage: []const u8,
    use_stage1: bool = false,
    dependencies: ?[]Dep = &.{},
};

pub fn zigExe(zp: ZigExeParams) void {
    const exe = zp.builder.addExecutable(.{
        .name = zp.name,
        .root_source_file = .{ .path = zp.src },
        .target = zp.target,
        .optimize = zp.mode,
    });
    //const exe = zp.builder.addExecutable(zp.name, zp.src);
    //exe.setTarget(zp.target);
    //exe.setBuildMode(zp.mode);
    // exe.setVerboseCC(true);
    // exe.setVerboseLink(true);
    //    exe.use_stage1 = zp.use_stage1;

    if (zp.dependencies) |deps| {
        addDeps(exe, zp.builder, zp.target, zp.mode, deps);
    }

    zp.builder.installArtifact(exe);
    //exe.install();
    const run_cmd = zp.builder.addRunArtifact(exe);
    //const run_cmd = exe.run();
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

pub const ZigLibParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    src: []const u8,
    usage: []const u8,
    static: bool = true,
    kind: LibExeObjStep.SharedLibKind = LibExeObjStep.SharedLibKind.unversioned,
    use_stage1: bool = false,
    dependencies: ?[]Dep = &.{},
    libs: ?[]*LibExeObjStep = &.{},
};

pub fn zigLib(zp: ZigLibParams) *LibExeObjStep {
    const lib = libtype: {
        var l: *LibExeObjStep = undefined;
        if (zp.static) {
            l = zp.builder.addStaticLibrary(zp.name, zp.src);
        } else {
            l = zp.builder.addSharedLibrary(zp.name, zp.src, zp.kind);
        }
        break :libtype l;
    };
    lib.setTarget(zp.target);
    lib.setBuildMode(zp.mode);
    // lib.setVerboseCC(true);
    // lib.setVerboseLink(true);
    lib.use_stage1 = zp.use_stage1;

    if (zp.dependencies) |deps| {
        addDeps(lib, zp.builder, zp.target, zp.mode, deps);
    }

    lib.install();
    const help = std.fmt.allocPrint(zp.builder.allocator, "Build {s}", .{zp.src}) catch |err| {
        std.log.err("ALLOCATION_ERROR:::: {}", .{err});
        return lib;
    };
    defer zp.builder.allocator.free(help);
    const lib_step = zp.builder.step(zp.usage, help);
    lib_step.dependOn(zp.builder.getInstallStep());

    return lib;
}

pub const ZigCExeParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    src: []const u8,
    ccSrc: ?csources.Src,
    libs: ?[]*LibExeObjStep = &.{},
    usage: []const u8,
    use_stage1: bool = false,
};

pub fn zcExe(zcp: ZigCExeParams) void {
    const exe = zcp.builder.addExecutable(.{
        .name = zcp.name,
        .root_source_file = .{ .path = zcp.src },
        .target = zcp.target,
        .optimize = zcp.mode,
    });
    //const exe = zcp.builder.addExecutable(zcp.name, zcp.src);
    //exe.setTarget(zcp.target);
    //exe.setBuildMode(zcp.mode);

    if (zcp.ccSrc) |ccSrc| {
        //const cclibName = std.mem.concat(zcp.builder.allocator, u8, &.{
        //    zcp.name,
        //    "vendor",
        //}) catch unreachable;
        //const cclib = cLib(.{
        //    .builder = zcp.builder,
        //    .target = zcp.target,
        //    .mode = zcp.mode,
        //    .name = cclibName,
        //    .src = ccSrc,
        //    .usage = "",
        //    .static = true,
        //    .libs = zcp.libs,
        //});
        //ccSrc.addIncludes(exe);
        //exe.linkLibrary(cclib);
        var cs = csources.init(zcp.builder.allocator);
        cs.collectInputs(.{
            .libExeObjStep = exe,
            .libs = zcp.libs,
            .src = ccSrc,
        });
    }

    if (zcp.libs) |libs| {
        for (libs) |l| {
            exe.linkLibrary(l);
        }
    }

    // exe.setVerboseCC(true);
    // exe.setVerboseLink(true);
    exe.use_stage1 = zcp.use_stage1;
    zcp.builder.installArtifact(exe);
    //exe.install();
    const run_cmd = zcp.builder.addRunArtifact(exe);
    //const run_cmd = exe.run();
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

pub const ZigCLibParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    src: []const u8,
    usage: []const u8,
    static: bool = true,
    kind: LibExeObjStep.SharedLibKind = LibExeObjStep.SharedLibKind.unversioned,
    use_stage1: bool = false,
};

pub fn zcLib(zcp: ZigCLibParams) *LibExeObjStep {
    const lib = libtype: {
        var l: *LibExeObjStep = undefined;
        if (zcp.static) {
            l = zcp.builder.addStaticLibrary(zcp.name, zcp.src);
        } else {
            l = zcp.builder.addSharedLibrary(zcp.name, zcp.src, zcp.kind);
        }
        break :libtype l;
    };
    lib.setTarget(zcp.target);
    lib.setBuildMode(zcp.mode);

    if (zcp.ccSrc) |ccSrc| {
        var cs = csources.init(zcp.builder.allocator);
        cs.collectInputs(.{
            .libExeObjStep = lib,
            .libs = zcp.libs,
            .src = ccSrc,
        });
    }

    if (zcp.libs) |libs| {
        for (libs) |l| {
            lib.linkLibrary(l);
        }
    }

    // lib.setVerboseCC(true);
    // lib.setVerboseLink(true);
    lib.use_stage1 = zcp.use_stage1;
    lib.install();
    const help = std.fmt.allocPrint(zcp.builder.allocator, "Build {s}", .{zcp.src}) catch |err| {
        std.log.err("ALLOCATION_ERROR:::: {}", .{err});
        return lib;
    };
    defer zcp.builder.allocator.free(help);
    const lib_step = zcp.builder.step(zcp.usage, help);
    lib_step.dependOn(zcp.builder.getInstallStep());

    return lib;
}

pub const CExeParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    src: csources.Src,
    usage: []const u8,
    static: bool = true,
    libs: ?[]*LibExeObjStep = &.{},
};

pub fn cExe(cp: CExeParams) void {
    var exe = cp.builder.addExecutable(.{
        .name = cp.name,
        .target = cp.target,
        .optimize = cp.mode,
    });
    //var exe = cp.builder.addExecutable(cp.name, null);
    //exe.setTarget(cp.target);
    //exe.setBuildMode(cp.mode);

    var cs = csources.init(cp.builder.allocator);
    cs.collectInputs(.{
        .libExeObjStep = exe,
        .libs = cp.libs,
        .src = cp.src,
    });

    cp.builder.installArtifact(exe);
    //exe.install();
    const run_cmd = cp.builder.addRunArtifact(exe);
    //const run_cmd = exe.run();
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

pub const CLibParams = struct {
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    name: []const u8,
    src: csources.Src,
    usage: []const u8,
    static: bool = true,
    libs: ?[]*LibExeObjStep = &.{},
    kind: LibExeObjStep.SharedLibKind = LibExeObjStep.SharedLibKind.unversioned,
};

pub fn cLib(cp: CLibParams) *LibExeObjStep {
    const lib = libtype: {
        var l: *LibExeObjStep = undefined;
        if (cp.static) {
            l = cp.builder.addStaticLibrary(cp.name, null);
        } else {
            l = cp.builder.addSharedLibrary(cp.name, null, cp.kind);
        }
        break :libtype l;
    };
    lib.setTarget(cp.target);
    lib.setBuildMode(cp.mode);

    var cs = csources.init(cp.builder.allocator);
    cs.collectInputs(.{
        .libExeObjStep = lib,
        .libs = cp.libs,
        .src = cp.src,
    });

    lib.install();
    const help = std.fmt.allocPrint(cp.builder.allocator, "Run {s}", .{cp.name}) catch |err| {
        std.log.err("ALLOCATION_ERROR:::: {}", .{err});
        return lib;
    };
    defer cp.builder.allocator.free(help);
    const lib_step = cp.builder.step(cp.usage, help);
    lib_step.dependOn(cp.builder.getInstallStep());

    return lib;
}

pub const CCppSrcParams = struct {
    builder: *Builder,
    src: []const u8,
    recurse: bool = false,
    allowed_exts: []const []const u8 = &.{ ".c", ".cpp", ".cxx", ".c++", ".cc" },
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

        var walker = dir.iterate();
        while (walker.next()) |wEntry| {
            if (wEntry) |cFile| {
                const fileName = cFile.name;
                // std.log.info("File Name: {s} with Type {any}", .{fileName, cFile.kind});
                const ext = fs.path.extension(fileName);
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
                    const filePath = std.mem.concat(csp.builder.allocator, u8, &.{ sourcePath, "/", cFile.name }) catch |err| {
                        std.log.err("COULD_NOT_INFER_FILE_PATH:::: {}", .{err});
                        return sources;
                    };
                    // std.log.info("File Path: {s}", .{filePath});
                    sources.append(filePath) catch |err| {
                        std.log.err("COULD_NOT_APPEND_SOURCES_ARRAY:::: {}", .{err});
                        return sources;
                    };
                }
            } else {
                break;
            }
        } else |err| {
            std.log.err("COULD_NOT_TRAVERSE_DIR:::: {}", .{err});
            return sources;
        }
    }

    // {
    //     var walkerFlatFoot = dir.iterate();
    //     while (walkerFlatFoot.next()) |entry| {
    //         if (entry) |cFile| {
    //             std.debug.print("Flat Dir Content:::: {any}", .{cFile});
    //         } else {
    //             break;
    //         }
    //     } else |err| {
    //         std.debug.print("COULD_LIST_DIR:::: {any}", .{err});
    //         return sources;
    //     }
    // }

    //     var walker = dir.walk(csp.builder.allocator) catch |err| {
    //         std.log.err("COULD_WALK_DIR:::: {}", .{err});
    //         return sources;
    //     };
    //     defer walker.deinit();
    //     while (walker.next()) |wEntry| {
    //         if (wEntry) |entry| {
    //             std.log.info("Entry Basename: {s}", .{entry.basename});
    //             const ext = fs.path.extension(entry.basename);
    //             const include_file = finc: {
    //                 var ok = false;
    //                 for (csp.allowed_exts) |e| {
    //                     if (std.mem.eql(u8, ext, e)) {
    //                         ok = true;
    //                     }
    //                 }
    //                 break :finc ok;
    //             };
    //             if (include_file) {
    //                 std.log.info("Entry Path: {s}", .{entry.path});
    //                 const filePath = std.fmt.allocPrint(csp.builder.allocator, "{s}{s}", .{ csp.src, entry.path }) catch |err| {
    //                     std.log.err("ALLOCATION_ERROR:::: {}", .{err});
    //                     return sources;
    //                 };
    //                 std.log.info("File Path: {s}", .{filePath});
    //                 sources.append(filePath) catch |err| {
    //                     std.log.err("COULD_NOT_APPEND_SOURCES_ARRAY:::: {}", .{err});
    //                     return sources;
    //                 };
    //                 // sources.append(csp.builder.dupe(entry.path)) catch |err| {
    //                 //     std.log.err("COULD_NOT_APPEND_SOURCES_ARRAY:::: {}", .{err});
    //                 //     return sources;
    //                 // };
    //             }
    //         } else {
    //             break;
    //         }
    //     } else |err| {
    //         std.log.err("COULD_NOT_TRAVERSE_DIR:::: {}", .{err});
    //         return sources;
    //     }
    // }

    return sources;
}

pub fn addDeps(
    bld: *Compile,
    builder: *Builder,
    target: CrossTarget,
    mode: Mode,
    dependencies: []Dep,
) void {
    for (dependencies) |dependency| {
        const name = dependency.name;
        const moduleName = dependency.moduleName;
        const dep = builder.dependency(name, .{ .target = target, .optimize = mode });
        const dep_module = dep.module(moduleName);
        bld.addModule(name, dep_module);

        if (dependency.artifacts) |artifacts| {
            for (artifacts) |artifact| {
                const dep_artifact = dep.artifact(artifact);
                bld.linkLibrary(dep_artifact);
            }
        }
    }
}
