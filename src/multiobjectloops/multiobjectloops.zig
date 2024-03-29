const std = @import("std");

const S = struct {
    tag: u8,
    data: u32,
};

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();

    var list: std.MultiArrayList(S) = .{};

    try list.append(arena, .{ .tag = 42, .data = 99999999 });
    try list.append(arena, .{ .tag = 10, .data = 1231011 });
    try list.append(arena, .{ .tag = 69, .data = 1337 });
    try list.append(arena, .{ .tag = 1, .data = 1 });

    std.debug.print("\nUnsorted:\n", .{});
    for (list.items(.tag), list.items(.data)) |tag, data| {
        std.debug.print("tag: {d}, data: {d}\n", .{ tag, data });
    }

    const TagSort = struct {
        tags: []const u8,

        pub fn lessThan(ctx: @This(), lhs_index: usize, rhs_index: usize) bool {
            const lhs = ctx.tags[lhs_index];
            const rhs = ctx.tags[rhs_index];
            return lhs < rhs;
        }
    };

    list.sort(TagSort{ .tags = list.items(.tag) });

    std.debug.print("\nSorted by tag:\n", .{});
    for (list.items(.tag), list.items(.data)) |tag, data| {
        std.debug.print("tag: {d}, data: {d}\n", .{ tag, data });
    }

    const DataSort = struct {
        data: []const u32,

        pub fn lessThan(ctx: @This(), lhs_index: usize, rhs_index: usize) bool {
            const lhs = ctx.data[lhs_index];
            const rhs = ctx.data[rhs_index];
            return lhs < rhs;
        }
    };

    list.sort(DataSort{ .data = list.items(.data) });
    std.debug.print("\nSorted by data:\n", .{});
    for (list.items(.tag), list.items(.data)) |tag, data| {
        std.debug.print("tag: {d}, data: {d}\n", .{ tag, data });
    }
}
