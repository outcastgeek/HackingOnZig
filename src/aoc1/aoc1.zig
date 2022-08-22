const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const os = std.os;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const aocAllocator = arena.allocator();

    const exe = os.argv[0];
    std.log.debug("Executable: {s}\n", .{exe});

    if (os.argv.len > 1) {
        const arg2 = os.argv[1];

        const inputFile = p2f: {
            const filePath = mem.sliceTo(arg2, 0);
            std.log.debug("FilePath: {s}\n", .{filePath});
            const currentWorkingDir = fs.cwd();
            const absoluteFilePath = try currentWorkingDir.realpathAlloc(aocAllocator, filePath);
            // std.log.debug("File Absolute Path: {s}", .{absoluteFilePath}); // TODO: Not sure why this is broken?
            std.log.debug("File Absolute Path: {any}", .{absoluteFilePath});
            break :p2f try currentWorkingDir.openFile(filePath, .{ .mode = .read_only });
            // break :p2f try currentWorkingDir.openFile(filePath, .{ .read = true, .write = false });
        };
        defer inputFile.close();

        var bufferFileReader = io.bufferedReader(inputFile.reader());
        const fileStream = bufferFileReader.reader();

        var increaseCount: usize = 0;
        var previousMeasurement: usize = std.math.maxInt(usize);
        var lineBuffer: [mem.page_size]u8 = undefined;
        while (try fileStream.readUntilDelimiterOrEof(&lineBuffer, '\n')) |line| {
            const currentMeasurement = try std.fmt.parseInt(usize, line, 10);
            defer previousMeasurement = currentMeasurement;
            if (previousMeasurement < currentMeasurement) {
                std.log.debug("Measurement increased from {d} to {d}\n", .{ previousMeasurement, currentMeasurement });
                increaseCount += 1;
            }
        }
        std.log.debug("{d} measurement(s) are larger than the previous measurement\n", .{increaseCount});
    } else {
        std.log.warn("No file path provided\n", .{});
    }
}
