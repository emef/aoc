const std = @import("std");
const aoc = @import("aoc");

const Self = @This();

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d3,
        .part1_sample = aoc.input.d3_sample,
        .part2 = aoc.input.d3,
        .part2_sample = aoc.input.d3_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    const lines = try aoc.input.lines(ctx.alloc, ctx.puzzle);
    var total: usize = 0;
    for (lines) |line| {
        const this_joltage = joltage(line);
        total += this_joltage;

        std.debug.print("{s} {d}\n", .{ line, this_joltage });
    }
    std.debug.print("total joltage {d}\n", .{total});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    const start = try std.time.Instant.now();
    const lines = try aoc.input.lines(ctx.alloc, ctx.puzzle);
    var total: usize = 0;
    for (lines) |line| {
        const this_joltage = joltagePart2(line);
        total += this_joltage;
    }
    const us = (try std.time.Instant.now()).since(start) / std.time.ns_per_us;
    std.debug.print("total joltage {d} in {d}us\n", .{ total, us });
}

fn joltage(line: []const u8) usize {
    var left: usize = 1;
    var right: usize = 1;

    for (line, 0..) |c, i| {
        const digit = c - @as(u8, '0');
        if (i == 0) {
            left = digit;
        } else if (i != line.len - 1 and digit > left) {
            left = digit;
            right = 0;
            continue;
        } else if (digit > right) {
            right = digit;
        }
    }

    return left * 10 + right;
}

fn joltagePart2(line: []const u8) usize {
    var digits: [12]usize = @splat(0);

    for (line, 0..) |c, i| {
        const digit = c - @as(u8, '0');
        const avail = @min(12, line.len - i);
        for (0..avail) |j| {
            if (digit > digits[12 - avail + j]) {
                digits[12 - avail + j] = digit;
                for (12 - avail + j + 1..12) |k| {
                    digits[k] = 0;
                }
                break;
            }
        }
    }

    var total: usize = 0;
    for (0..12) |i| {
        total += digits[i] * std.math.pow(usize, 10, 11 - i);
    }

    return total;
}
