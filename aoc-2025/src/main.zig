const std = @import("std");
const aoc = @import("aoc");

pub const solutions = [_]aoc.Solution{
    @import("solutions/d1.zig").Solution,
    @import("solutions/d2.zig").Solution,
    @import("solutions/d3.zig").Solution,
    @import("solutions/d4.zig").Solution,
    @import("solutions/d5.zig").Solution,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    var i: usize = 1;
    var sample: bool = false;
    var day_ix: usize = @max(1, solutions.len) - 1;
    while (i < args.len) {
        const flag = args[i];
        if (std.mem.eql(u8, flag, "--sample")) {
            sample = true;
            i += 1;
        } else if (std.mem.eql(u8, flag, "--day")) {
            day_ix = (try std.fmt.parseInt(usize, args[i + 1], 10)) - 1;
            i += 2;
        } else {
            std.debug.panic("invalid flag {s}", .{args[i]});
        }
    }

    if (day_ix >= solutions.len) {
        std.debug.panic("day out of range\n", .{});
    }

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    var solution: aoc.Solution = solutions[day_ix];

    const ctx1 = aoc.Context{
        .alloc = arena.allocator(),
        .puzzle = if (sample) solution.inputs.part1_sample else solution.inputs.part1,
    };

    const ctx2 = aoc.Context{
        .alloc = arena.allocator(),
        .puzzle = if (sample) solution.inputs.part2_sample else solution.inputs.part2,
    };

    std.debug.print("---------------------\n", .{});
    std.debug.print("part1:\n", .{});
    std.debug.print("---------------------\n", .{});
    var start = try std.time.Instant.now();
    try solution.part1(ctx1);
    std.debug.print("took {d}ms\n", .{elapsedMs(start)});

    std.debug.print("\n\n---------------------\n", .{});
    std.debug.print("part2:\n", .{});
    std.debug.print("---------------------\n", .{});
    start = try std.time.Instant.now();
    try solution.part2(ctx2);
    std.debug.print("took {d}ms\n", .{elapsedMs(start)});
}

fn elapsedMs(start: std.time.Instant) usize {
    const now = std.time.Instant.now() catch unreachable;
    return now.since(start) / std.time.ns_per_ms;
}
