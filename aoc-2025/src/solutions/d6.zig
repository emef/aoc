const std = @import("std");
const aoc = @import("aoc");

const Self = @This();

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d6,
        .part1_sample = aoc.input.d6_sample,
        .part2 = aoc.input.d6,
        .part2_sample = aoc.input.d6_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

const Op = enum {
    add,
    mult,
};

const Problem = struct {
    operands: [10]u64,
    operand_strs: [10][]u8,
    len: usize,
    width: usize,
    op: Op,

    pub fn init() Problem {
        return Problem{
            .operands = undefined,
            .operand_strs = undefined,
            .len = 0,
            .width = 0,
            .op = undefined,
        };
    }

    pub fn push(self: *Problem, alloc: std.mem.Allocator, operand_str: []const u8) !void {
        std.debug.assert(self.len < self.operands.len);

        var start: usize = 0;
        while (operand_str[start] == @as(u8, ' ')) : (start += 1) {}
        var end: usize = start;
        while (end < operand_str.len and operand_str[end] != @as(u8, ' ')) : (end += 1) {}

        self.operands[self.len] = try std.fmt.parseInt(u64, operand_str[start..end], 10);
        self.operand_strs[self.len] = try alloc.dupe(u8, operand_str);
        self.len += 1;
        self.width = @max(self.width, operand_str.len);
    }

    pub fn setOp(self: *Problem, op: Op) void {
        self.op = op;
    }

    pub fn part1(self: Problem) u64 {
        switch (self.op) {
            .add => {
                var result: u64 = 0;
                for (0..self.len) |j| {
                    result += self.operands[j];
                }
                return result;
            },
            .mult => {
                var result: u64 = 1;
                for (0..self.len) |j| {
                    result *= self.operands[j];
                }
                return result;
            },
        }
    }

    pub fn part2(self: Problem) u64 {
        var total: u64 = if (self.op == .add) 0 else 1;
        var elem_buf: [10]u8 = undefined;
        for (0..self.width) |j| {
            var elem_len: usize = 0;
            for (0..self.len) |i| {
                if (j >= self.operand_strs[i].len or self.operand_strs[i][j] == @as(u8, ' ')) {
                    continue;
                }
                elem_buf[elem_len] = self.operand_strs[i][j];
                elem_len += 1;
            }

            const elem = std.fmt.parseInt(u64, elem_buf[0..elem_len], 10) catch unreachable;

            switch (self.op) {
                .add => total += elem,
                .mult => total *= elem,
            }
        }
        return total;
    }
};

const ProblemSet = struct {
    problems: [4096]Problem,
    len: usize,

    pub fn parse(ctx: aoc.Context) aoc.Error!ProblemSet {
        var problems = ProblemSet{
            .problems = undefined,
            .len = 0,
        };

        var widths = try std.ArrayList(usize).initCapacity(ctx.alloc, 0);

        for (try aoc.input.lines(ctx.alloc, ctx.puzzle)) |line| {
            var count: usize = 0;
            var i: usize = 0;
            while (true) : (count += 1) {
                while (i < line.len and line[i] == @as(u8, ' ')) : (i += 1) {}
                if (i == line.len) break;

                const start = i;
                while (i < line.len and line[i] != @as(u8, ' ')) : (i += 1) {}
                switch (line[start]) {
                    @as(u8, '+') => break,
                    @as(u8, '*') => break,
                    else => {
                        if (widths.items.len == count) {
                            try widths.append(ctx.alloc, 0);
                        }
                        const digits = i - start;
                        widths.items[count] = @max(widths.items[count], digits);
                    },
                }
            }
        }

        for (try aoc.input.lines(ctx.alloc, ctx.puzzle)) |line| {
            var i: usize = 0;
            for (widths.items, 0..) |width, idx| {
                const str = line[i..@min(line.len, i + width)];
                switch (str[0]) {
                    @as(u8, '+') => problems.at(idx).setOp(.add),
                    @as(u8, '*') => problems.at(idx).setOp(.mult),
                    else => {
                        try problems.at(idx).push(ctx.alloc, str);
                    },
                }

                i += width + 1;
            }
        }

        return problems;
    }

    pub fn at(self: *ProblemSet, i: usize) *Problem {
        std.debug.assert(i < self.problems.len);
        if (i >= self.len) {
            self.problems[i] = Problem.init();
            self.len = i + 1;
        }
        return &self.problems[i];
    }
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    var problems = try ProblemSet.parse(ctx);

    var total: u64 = 0;
    for (0..problems.len) |i| {
        total += problems.at(i).part1();
    }

    std.debug.print("answer: {d}\n", .{total});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    var problems = try ProblemSet.parse(ctx);

    var total: u64 = 0;
    for (0..problems.len) |i| {
        total += problems.at(i).part2();
    }

    std.debug.print("answer: {d}\n", .{total});
}
