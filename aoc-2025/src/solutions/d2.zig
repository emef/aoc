const std = @import("std");
const aoc = @import("aoc");

const Self = @This();

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d2,
        .part1_sample = aoc.input.d2_sample,
        .part2 = aoc.input.d2,
        .part2_sample = aoc.input.d2_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    var sum_bad: usize = 0;
    for (try aoc.input.csv(ctx.alloc, ctx.puzzle)) |range_str| {
        const trimmed = aoc.input.trim(range_str);
        const range = try parseRange(trimmed);
        const bad = checkRange(range, .part1);
        std.debug.print("{s}: {d}\n", .{ trimmed, bad.bad });
        sum_bad += bad.sum_bad;
    }
    std.debug.print("sum of bad: {}\n", .{sum_bad});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    var sum_bad: usize = 0;
    for (try aoc.input.csv(ctx.alloc, ctx.puzzle)) |range_str| {
        const trimmed = aoc.input.trim(range_str);
        const range = try parseRange(trimmed);
        const bad = checkRange(range, .part2);
        std.debug.print("{s}: {d}\n", .{ trimmed, bad.bad });
        sum_bad += bad.sum_bad;
    }
    std.debug.print("sum of bad: {}\n", .{sum_bad});
}

const Range = struct {
    start: usize,
    end: usize,
};

fn parseRange(range_str: []const u8) aoc.Error!Range {
    var r = std.Io.Reader.fixed(range_str);
    const left = try r.takeDelimiterExclusive('-');
    const right = r.buffer[r.seek..];

    return Range{
        .start = try std.fmt.parseInt(usize, left, 10),
        .end = try std.fmt.parseInt(usize, right, 10),
    };
}

const checked = struct {
    bad: usize,
    sum_bad: usize,
};

fn checkRange(r: Range, part: aoc.Part) checked {
    var bad: usize = 0;
    var sum_bad: usize = 0;
    for (r.start..r.end + 1) |x| {
        const x_is_bad = if (part == .part1) isBad(x) else isBadPart2(x);
        if (x_is_bad) {
            // std.debug.print("{d} is bad\n", .{x});
            bad += 1;
            sum_bad += x;
        }
    }
    return .{
        .bad = bad,
        .sum_bad = sum_bad,
    };
}

fn isBad(x: usize) bool {
    const max_len = 20;
    var buf: [max_len]u8 = undefined;
    const x_str = std.fmt.bufPrint(&buf, "{}", .{x}) catch unreachable;

    if (x_str.len % 2 == 1) {
        return false;
    }

    const mid = @divExact(x_str.len, 2);
    const left = x_str[0..mid];
    const right = x_str[mid..];

    return std.mem.eql(u8, left, right);
}

fn isBadPart2(x: usize) bool {
    const max_len = 20;
    var buf: [max_len]u8 = undefined;
    const x_str = std.fmt.bufPrint(&buf, "{}", .{x}) catch unreachable;

    const max_digits = @divFloor(x_str.len, 2);

    for (1..max_digits + 1) |digits| {
        if (@mod(x_str.len, digits) != 0) {
            continue;
        }

        const first = x_str[0..digits];
        const to_check = @divFloor(x_str.len, digits);
        var all_match = true;
        for (1..to_check) |i| {
            const next = x_str[i * digits .. (i + 1) * digits];
            if (!std.mem.eql(u8, first, next)) {
                all_match = false;
                break;
            }
        }

        if (all_match) {
            return true;
        }
    }

    return false;
}

fn isBadStrict(x: usize) bool {
    const max_len = 20;
    var buf: [max_len]u8 = undefined;
    const x_str = std.fmt.bufPrint(&buf, "{}", .{x}) catch unreachable;
    const max_repeat = @divFloor(x_str.len, 2);

    for (1..max_repeat + 1) |digits| {
        const to_check = @divFloor(x_str.len, digits) - 1;
        for (0..to_check) |i| {
            const left = x_str[i .. i + digits];
            const right = x_str[i + digits .. i + digits + digits];
            if (std.mem.eql(u8, left, right)) {
                std.debug.print("{s} is bad bc {s} == {s}\n", .{ x_str, left, right });
                return true;
            }
        }
    }

    return false;
}
