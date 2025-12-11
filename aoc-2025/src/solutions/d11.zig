const std = @import("std");
const aoc = @import("aoc");
const z3 = @import("z3");

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d11,
        .part1_sample = aoc.input.d11_sample,
        .part2 = aoc.input.d11,
        .part2_sample = aoc.input.d11_sample_part2,
    },
    .part1 = part1,
    .part2 = part2,
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    var target_buf: [max_devices]Target = undefined;
    var lookup: [max_devices]?*Target = @splat(null);

    try parsePuzzle(ctx, &target_buf, &lookup);

    const out_id = parseID("out");
    const start = lookup[parseID("you")] orelse unreachable;
    const end = lookup[parseID("out")] orelse unreachable;

    var queue = aoc.CyclicDeque(*Target, 10000).init();
    try queue.append(end);

    while (queue.popFront()) |cur| {
        if (cur.id == out_id or cur.trySatisfy()) {
            for (cur.rdeps.items) |rdep| {
                try queue.append(rdep);
            }
        }
    }

    const final_paths = start.paths orelse unreachable;
    std.debug.print("paths: {d}\n", .{final_paths});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    var target_buf: [max_devices]Target = undefined;
    var lookup: [max_devices]?*Target = @splat(null);

    try parsePuzzle(ctx, &target_buf, &lookup);

    const out_id = parseID("out");
    const start = lookup[parseID("svr")] orelse unreachable;
    const end = lookup[parseID("out")] orelse unreachable;

    var queue = aoc.CyclicDeque(*Target, 10000).init();
    try queue.append(end);

    while (queue.popFront()) |cur| {
        if (cur.id == out_id or cur.trySatisfyPart2()) {
            for (cur.rdeps.items) |rdep| {
                try queue.append(rdep);
            }
        }
    }

    const final_paths = start.paths_both orelse unreachable;
    std.debug.print("paths: {d} \n", .{final_paths});
}

fn parsePuzzle(
    ctx: aoc.Context,
    target_buf: *[max_devices]Target,
    lookup: *[max_devices]?*Target,
) !void {
    var count: usize = 0;

    const out_id = parseID("out");
    target_buf[count] = try Target.init(ctx.alloc, out_id);
    target_buf[count].paths = 1;
    lookup[out_id] = &target_buf[count];
    count += 1;

    for (try aoc.input.lines(ctx.alloc, ctx.puzzle)) |line| {
        const id = parseID(line[0..3]);
        if (lookup[id] == null) {
            target_buf[count] = try Target.init(ctx.alloc, id);
            lookup[id] = &target_buf[count];
            count += 1;
        }

        var target = lookup[id] orelse unreachable;
        try target.parseOutputs(ctx.alloc, line[5..]);

        for (target.outputs.items) |output| {
            if (lookup[output] == null) {
                target_buf[count] = try Target.init(ctx.alloc, output);
                lookup[output] = &target_buf[count];
                count += 1;
            }

            const dep_target = lookup[output] orelse unreachable;
            try target.deps.append(ctx.alloc, dep_target);
            try dep_target.rdeps.append(ctx.alloc, target);
        }
    }
}

const Target = struct {
    id: DeviceID,
    outputs: std.ArrayList(DeviceID),
    deps: std.ArrayList(*Target),
    rdeps: std.ArrayList(*Target),
    paths: ?usize = null,
    paths_dac: ?usize = 0,
    paths_fft: ?usize = 0,
    paths_both: ?usize = 0,

    fn init(alloc: std.mem.Allocator, id: DeviceID) !Target {
        return Target{
            .id = id,
            .outputs = try std.ArrayList(DeviceID).initCapacity(alloc, 0),
            .deps = try std.ArrayList(*Target).initCapacity(alloc, 0),
            .rdeps = try std.ArrayList(*Target).initCapacity(alloc, 0),
        };
    }

    fn parseOutputs(self: *Target, alloc: std.mem.Allocator, line: []const u8) !void {
        var it = std.mem.splitScalar(u8, line, ' ');
        var i: usize = 0;
        while (it.next()) |output| : (i += 1) {
            try self.outputs.append(alloc, parseID(output));
        }
    }

    fn trySatisfy(self: *Target) bool {
        if (self.paths != null) {
            return false;
        }

        var paths: usize = 0;
        for (self.deps.items) |dep| {
            paths += dep.paths orelse return false;
        }

        self.paths = paths;
        return true;
    }

    fn trySatisfyPart2(self: *Target) bool {
        if (self.paths != null) {
            return false;
        }

        var paths: usize = 0;
        var paths_dac: usize = 0;
        var paths_fft: usize = 0;
        var paths_both: usize = 0;

        for (self.deps.items) |dep| {
            paths += dep.paths orelse return false;
            paths_dac += dep.paths_dac orelse return false;
            paths_fft += dep.paths_fft orelse return false;
            paths_both += dep.paths_both orelse return false;
        }

        if (self.id == parseID("dac")) {
            if (paths_dac > 0) unreachable;
            if (paths_both > 0) unreachable;
            self.paths = 0;
            self.paths_dac = paths;
            self.paths_fft = 0;
            self.paths_both = paths_fft;
        } else if (self.id == parseID("fft")) {
            if (paths_fft > 0) unreachable;
            if (paths_both > 0) unreachable;
            self.paths = 0;
            self.paths_dac = 0;
            self.paths_fft = paths;
            self.paths_both = paths_dac;
        } else {
            self.paths = paths;
            self.paths_dac = paths_dac;
            self.paths_fft = paths_fft;
            self.paths_both = paths_both;
        }

        return true;
    }
};

const DeviceID = u16;
const max_outputs = 24;
const max_devices = 26 * 26 * 26;

fn parseID(buf: anytype) DeviceID {
    if (buf.len != 3) unreachable;

    return (26 * 26 * @as(u16, @intCast(buf[0] - 'a')) +
        26 * @as(u16, @intCast(buf[1] - 'a')) +
        @as(u16, @intCast(buf[2] - 'a')));
}

fn idStr(id_: DeviceID) [3]u8 {
    var id: u16 = id_;
    var buf: [3]u8 = undefined;
    buf[2] = @as(u8, @intCast(@mod(id, 26))) + 'a';
    id /= 26;
    buf[1] = @as(u8, @intCast(@mod(id, 26))) + 'a';
    id /= 26;
    buf[0] = @as(u8, @intCast(@mod(id, 26))) + 'a';
    return buf;
}
