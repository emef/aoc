const std = @import("std");
const aoc = @import("aoc");

const Self = @This();

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d7,
        .part1_sample = aoc.input.d7_sample,
        .part2 = aoc.input.d7,
        .part2_sample = aoc.input.d7_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    var grid = Grid.init(try aoc.input.lines(ctx.alloc, ctx.puzzle));
    var splits: usize = 0;
    for (1..grid.rows) |row| {
        for (0..grid.cols) |col| {
            const above = grid.data[(row - 1) * grid.cols + col];
            if (above != .beam) continue;

            const below = &grid.data[row * grid.cols + col];
            var did_split = false;
            switch (below.*) {
                .empty => {
                    below.* = .beam;
                },
                .splitter => {
                    if (col > 0) {
                        const left = &grid.data[row * grid.cols + col - 1];
                        if (left.* == .empty) {
                            left.* = .beam;
                            did_split = true;
                        }
                    }
                    if (col < grid.cols) {
                        const right = &grid.data[row * grid.cols + col + 1];
                        if (right.* == .empty) {
                            right.* = .beam;
                            did_split = true;
                        }
                    }
                },
                .beam => continue,
                .start => unreachable,
            }

            if (did_split) {
                splits += 1;
            }
        }
    }

    std.debug.print("splits: {d}\n", .{splits});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    var grid = Grid.init(try aoc.input.lines(ctx.alloc, ctx.puzzle));

    var final: usize = 0;
    for (0..grid.rows) |i| {
        const row = grid.rows - i - 1;
        for (0..grid.cols) |col| {
            if (i == 0) {
                grid.possibilities[row * grid.cols + col] = 1;
                continue;
            }

            const this_cell = grid.data[row * grid.cols + col];
            const this_out = &grid.possibilities[row * grid.cols + col];
            switch (this_cell) {
                .empty => {
                    this_out.* = grid.possibilities[(row + 1) * grid.cols + col];
                },
                .start => {
                    final = grid.possibilities[(row + 1) * grid.cols + col];
                },
                .splitter => {
                    if (col > 0) {
                        this_out.* += grid.possibilities[(row + 1) * grid.cols + col - 1];
                    }
                    if (col < grid.cols - 1) {
                        this_out.* += grid.possibilities[(row + 1) * grid.cols + col + 1];
                    }
                },
                .beam => unreachable,
            }
        }
    }

    std.debug.print("final: {d}\n", .{final});
}

const Cell = enum {
    empty,
    splitter,
    beam,
    start,
};

const Grid = struct {
    rows: usize,
    cols: usize,
    data: [1 << 15]Cell,
    possibilities: [1 << 15]usize,

    fn init(lines: [][]const u8) Grid {
        var grid: Grid = Grid{
            .rows = lines.len,
            .cols = lines[0].len,
            .data = undefined,
            .possibilities = undefined,
        };

        std.debug.assert(grid.rows * grid.cols < grid.data.len);

        grid.data = @splat(.empty);
        grid.possibilities = @splat(0);

        for (lines, 0..) |line, i| {
            for (line, 0..) |c, j| {
                if (c == @as(u8, '^')) {
                    grid.data[i * grid.cols + j] = .splitter;
                } else if (c == @as(u8, 'S')) {
                    grid.data[i * grid.cols + j] = .beam;
                }
            }
        }

        return grid;
    }

    pub fn format(self: Grid, writer: anytype) !void {
        for (0..self.rows) |row| {
            for (0..self.cols) |col| {
                const c = switch (self.data[row * self.cols + col]) {
                    .empty => ".",
                    .splitter => "^",
                    .beam => "|",
                    .start => "S",
                };
                try writer.print("{s}", .{c});
            }
            try writer.print("\n", .{});
        }
    }
};
