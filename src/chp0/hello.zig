const std = @import("std");
const expect = std.testing.expect;

pub fn main() void {
    std.debug.print("Hello, {s}!\n", .{"World"});
}

test "Some Bogus Test" {
    try expect(1 == 1);
    try expect(2 == 2);
}
