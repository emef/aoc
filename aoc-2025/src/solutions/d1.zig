const std = @import("std");
const aoc = @import("aoc");

const Self = @This();

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d1,
        .part1_sample = aoc.input.d1_sample,
        .part2 = aoc.input.d1,
        .part2_sample = aoc.input.d1_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    const lines = try aoc.input.lines(ctx.alloc, ctx.puzzle);
    var loc: i64 = 50;
    var zeros: i64 = 0;
    for (lines) |l| {
        const sign: i64 = if (l[0] == 'L') -1 else 1;
        const amt: i64 = try std.fmt.parseInt(i64, l[1..], 10);
        loc = @mod(loc + sign * amt, 100);
        if (loc == 0) {
            zeros += 1;
        }
    }

    std.debug.print("zeros: {d}\n", .{zeros});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    const lines = try aoc.input.lines(ctx.alloc, ctx.puzzle);
    var loc: i64 = 50;
    var zeros: usize = 0;
    for (lines) |l| {
        const sign: i64 = if (l[0] == 'L') -1 else 1;
        var amt: i64 = try std.fmt.parseInt(i64, l[1..], 10);

        if (loc != 0 and sign == -1) {
            amt += 100;
        }

        zeros += @divFloor(@abs(loc + sign * amt), 100);
        loc = @mod(loc + sign * amt, 100);
    }

    std.debug.print("loc: {d}, zeros: {d}\n", .{ loc, zeros });
}
