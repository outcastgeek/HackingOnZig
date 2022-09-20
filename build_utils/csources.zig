const std = @import("std");
const fs = std.fs;
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;
const Allocator = std.mem.Allocator;

const Self = @This();

/// Memory Allocator
allocator: Allocator,

pub fn init(allocator: Allocator) Self {
    return .{ .allocator = allocator };
}

pub const CSrcParams = struct {
    dir: []const u8 = &.{},
    includeDir: ?[]const u8 = undefined,
    csFiles: ?[]const []const u8 = undefined,
    flags: []const []const u8 = &.{},
};

pub const SrcType = enum {
    cSrc,
    cppSrc,
    cSrcs,
    cppSrcs,

    pub fn allowedExts(self: SrcType) []const []const u8 {
        const allowed_exts: []const []const u8 = switch (self) {
            SrcType.cSrc => &.{"c"},
            SrcType.cSrcs => &.{"c"},
            SrcType.cppSrc => &.{ ".cpp", ".cxx", ".c++", ".cc" },
            SrcType.cppSrcs => &.{ ".cpp", ".cxx", ".c++", ".cc" },
        };
        return allowed_exts;
    }
};

pub const Src = union(SrcType) {
    cSrc: CSrcParams,
    cppSrc: CSrcParams,
    cSrcs: []const CSrcParams,
    cppSrcs: []const CSrcParams,

    pub fn addIncludes(self: Src, libExeObjStep: *LibExeObjStep) void {
        const include_dir: ?[]const u8 = undefined;
        switch (@as(SrcType, self)) {
            SrcType.cSrc => {
                if (self.cSrc.includeDir) |includeDir| {
                    libExeObjStep.addIncludeDir(includeDir);
                }
            },
            SrcType.cSrcs => {
                for (self.cSrcs) |cSrc| {
                    if (cSrc.includeDir) |includeDir| {
                        libExeObjStep.addIncludeDir(includeDir);
                    }
                }
            },
            SrcType.cppSrc => {
                if (self.cppSrc.includeDir) |includeDir| {
                    libExeObjStep.addIncludeDir(includeDir);
                }
            },
            SrcType.cppSrcs => {
                for (self.cppSrcs) |cppSrc| {
                    if (cppSrc.includeDir) |includeDir| {
                        libExeObjStep.addIncludeDir(includeDir);
                    }
                }
            },
        }
        return include_dir;
    }
};

pub const CollectParams = struct {
    libExeObjStep: *LibExeObjStep,
    libs: ?[]*LibExeObjStep = undefined,
    src: Src,
};

/// Collect Build Inputs for C/C++ code
pub fn collectInputs(self: *Self, params: CollectParams) void {
    switch (params.src) {
        SrcType.cSrc => {
            params.libExeObjStep.linkLibC();
            // params.libExeObjStep.setVerboseCC(true);
            // params.libExeObjStep.setVerboseLink(true);
        },
        SrcType.cSrcs => {
            params.libExeObjStep.linkLibC();
            // params.libExeObjStep.setVerboseCC(true);
            // params.libExeObjStep.setVerboseLink(true);
        },
        SrcType.cppSrc => {
            params.libExeObjStep.linkLibC();
            params.libExeObjStep.linkLibCpp();
            // params.libExeObjStep.linkSystemLibrary("c++");
            // params.libExeObjStep.setVerboseCC(true);
            // params.libExeObjStep.setVerboseLink(true);
        },
        SrcType.cppSrcs => {
            params.libExeObjStep.linkLibC();
            params.libExeObjStep.linkLibCpp();
            // params.libExeObjStep.linkSystemLibrary("c++");
            // params.libExeObjStep.setVerboseCC(true);
            // params.libExeObjStep.setVerboseLink(true);
        },
    }
    if (params.libs) |libs| {
        for (libs) |l| {
            params.libExeObjStep.linkLibrary(l);
        }
    }
    var srcs: []const CSrcParams = undefined;
    switch (params.src) {
        SrcType.cSrc => |cSrc| {
            std.log.info("Collecting C Inputs...", .{});
            srcs = &.{cSrc};
        },
        SrcType.cSrcs => |cSrcs| {
            std.log.info("Collecting C Inputs...", .{});
            srcs = cSrcs;
        },
        SrcType.cppSrc => |cppSrc| {
            std.log.info("Collecting C++ Inputs...", .{});
            srcs = &.{cppSrc};
        },
        SrcType.cppSrcs => |cppSrcs| {
            std.log.info("Collecting C++ Inputs...", .{});
            srcs = cppSrcs;
        },
    }
    var allowed_exts = @as(SrcType, params.src).allowedExts();
    for (srcs) |src| {
        var sources = srcs: {
            var csFiles: []const []const u8 = &.{};
            if (src.csFiles) |files| {
                csFiles = files;
            } else {
                csFiles = self.collectCSources(src.dir, allowed_exts).items;
            }
            break :srcs csFiles;
        };
        if (src.includeDir) |includeDir| {
            params.libExeObjStep.addIncludeDir(includeDir);
        }
        params.libExeObjStep.addCSourceFiles(sources, src.flags);
    }
}

/// Search for all c/c++ files in the src directory and add them to the list of sources.
fn collectCSources(self: Self, srcDir: []const u8, allowed_exts: []const []const u8) std.ArrayList([]const u8) {
    var sources = std.ArrayList([]const u8).init(self.allocator);

    const currentWorkingDir = fs.cwd();
    const sourcePath = currentWorkingDir.realpathAlloc(self.allocator, srcDir) catch |err| {
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
                for (allowed_exts) |e| {
                    if (std.mem.eql(u8, ext, e)) {
                        ok = true;
                    }
                }
                break :finc ok;
            };
            if (include_file) {
                const filePath = std.mem.concat(self.allocator, u8, &.{ sourcePath, "/", cFile.name }) catch |err| {
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
    return sources;
}
