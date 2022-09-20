const std = @import("std");
const mylib = @cImport({
    @cInclude("mylib.h");
});

fn multiply(a: i32, b: i32) i32 {
    return mylib.multiply(a, b);
}

pub fn main() !void {
    const a: i32 = 16;
    const b: i32 = 8;
    var product = multiply(a, b);
    std.log.info("Product of a={d} times b={d} equals: {d}", .{ a, b, product });
}
