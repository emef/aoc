const std = @import("std");
const aoc = @import("aoc");

const Self = @This();

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d4,
        .part1_sample = aoc.input.d4_sample,
        .part2 = aoc.input.d4,
        .part2_sample = aoc.input.d4_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    const lines = try aoc.input.lines(ctx.alloc, ctx.puzzle);
    const grid = try Grid.init(ctx.alloc, lines);
    var total: usize = 0;
    for (0..grid.rows) |row| {
        for (0..grid.cols) |col| {
            if (!grid.is_set(row, col)) continue;
            if (grid.adjacent(row, col) < 4) {
                total += 1;
            }
        }
    }

    std.debug.print("free: {d}\n", .{total});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    const lines = try aoc.input.lines(ctx.alloc, ctx.puzzle);
    var grid = try Grid.init(ctx.alloc, lines);
    var to_remove = try Grid.empty(ctx.alloc, grid.rows, grid.cols);

    const starting = grid.sum;

    while (true) {
        to_remove.reset();
        for (0..grid.rows) |row| {
            for (0..grid.cols) |col| {
                if (!grid.is_set(row, col)) continue;
                if (grid.adjacent(row, col) < 4) {
                    to_remove.set(row, col);
                }
            }
        }

        if (to_remove.sum == 0) break;

        for (0..grid.rows) |row| {
            for (0..grid.cols) |col| {
                if (to_remove.data[row * grid.cols + col]) {
                    grid.clear(row, col);
                }
            }
        }
    }

    const removed = starting - grid.sum;
    std.debug.print("removed: {d}\n", .{removed});
}

const Grid = struct {
    rows: usize,
    cols: usize,
    sum: usize,
    data: []bool,

    fn init(alloc: std.mem.Allocator, lines: [][]const u8) aoc.Error!Grid {
        const rows = lines.len;
        const cols = lines[0].len;
        var sum: usize = 0;
        var data = try alloc.alloc(bool, rows * cols);

        for (lines, 0..) |line, i| {
            for (line, 0..) |c, j| {
                const cell_set = (c == @as(u8, '@'));
                data[i * cols + j] = cell_set;
                sum += if (cell_set) 1 else 0;
            }
        }

        return .{
            .rows = rows,
            .cols = cols,
            .sum = sum,
            .data = data,
        };
    }

    fn empty(alloc: std.mem.Allocator, rows: usize, cols: usize) aoc.Error!Grid {
        const data = try alloc.alloc(bool, rows * cols);
        @memset(data, false);
        return Grid{
            .rows = rows,
            .cols = cols,
            .data = data,
            .sum = 0,
        };
    }

    fn reset(self: *Grid) void {
        @memset(self.data, false);
        self.sum = 0;
    }

    fn set(self: *Grid, row: usize, col: usize) void {
        std.debug.assert(!self.is_set(row, col));
        self.sum += 1;
        self.data[row * self.cols + col] = true;
    }

    fn clear(self: *Grid, row: usize, col: usize) void {
        std.debug.assert(self.is_set(row, col));
        self.sum -= 1;
        self.data[row * self.cols + col] = false;
    }

    fn is_set(self: Grid, row_: anytype, col_: anytype) bool {
        const row_i64: i64 = @intCast(row_);
        const col_i64: i64 = @intCast(col_);

        if (row_i64 < 0 or row_i64 >= self.rows or col_i64 < 0 or col_i64 >= self.cols) {
            return false;
        }

        const row: usize = @intCast(row_);
        const col: usize = @intCast(col_);

        return self.data[row * self.cols + col];
    }

    fn adjacent(self: Grid, row: usize, col: usize) u8 {
        var found: u8 = 0;
        const deltas: [3]i64 = .{ -1, 0, 1 };
        for (deltas) |drow| {
            for (deltas) |dcol| {
                if (drow == 0 and dcol == 0) continue;
                const check_row = @as(i64, @intCast(row)) + drow;
                const check_col = @as(i64, @intCast(col)) + dcol;
                if (self.is_set(check_row, check_col)) {
                    found += 1;
                }
            }
        }

        return found;
    }
};
