/// Reference:
/// https://vimeo.com/649009599?embedded=true&source=video_title&owner=45836359
/// https://zig.news/kristoff/struct-of-arrays-soa-in-zig-easy-in-userland-40m0
const std = @import("std");

const Monster = struct {
    element: ElKind,
    hp: u32,

    const ElKind = enum { fire, water, earth, wind };
};

/// A MultiArrayList stores a list of a struct type.
/// Instead of storing a single list of items, MultiArrayList
/// stores separate lists for each field of the struct.
/// This allows for memory savings if the struct has padding,
/// and also improves cache usage if only some fields are needed
/// for a computation.  The primary API for accessing fields is
/// the `slice()` function, which computes the start pointers
/// for the array of each field.  From the slice you can call
/// `.items(.<field_name>)` to obtain a slice of field values.
const MonsterList = std.MultiArrayList(Monster);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var monsters: MonsterList = .{};
    defer monsters.deinit(gpa.allocator());

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    // Normally you would want to append many monsters
    var i: usize = 0;
    while (i < 40_000) : (i += 1) {
        try monsters.append(gpa.allocator(), .{
            .element = prng.random().enumValue(Monster.ElKind),
            .hp = prng.random().int(u32),
        });
    }

    // Count the number of fire monsters
    var total_fire: usize = 0;
    var total_water: usize = 0;
    var total_earth: usize = 0;
    var total_wind: usize = 0;
    for (monsters.items(.element)) |t| {
        if (t == .fire) total_fire += 1;
        if (t == .water) total_water += 1;
        if (t == .earth) total_earth += 1;
        if (t == .wind) total_wind += 1;
    }

    std.debug.print("Total Fire: {}\n", .{total_fire});
    std.debug.print("Total Water: {}\n", .{total_water});
    std.debug.print("Total Earth: {}\n", .{total_earth});
    std.debug.print("Total Wind: {}\n", .{total_wind});

    var total_monsters = total_fire + total_water + total_earth + total_wind;
    std.debug.print("Total Monsters: {}\n", .{total_monsters});

    // Heal all monsters
    for (monsters.items(.hp)) |*hp| {
        hp.* = 100;
    }
}
