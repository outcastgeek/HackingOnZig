const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn getLines(allocator: Allocator, raw: []const u8) []const []const u8 {
    var sources = std.ArrayList([]const u8).init(allocator);
    var lineIter = std.mem.split(u8, raw, "\n");
    while (lineIter.next()) |line| {
        if (std.mem.len(line) > 0) {
            std.debug.print("Source File Path --> {s}\n", .{line});
            sources.append(line) catch |err| {
                std.log.err("COULD_NOT_APPEND_SOURCES_ARRAY:::: {}", .{err});
                return sources.items;
            };
        }
    }
    return sources.items;
}
