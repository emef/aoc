const std = @import("std");
const aoc = @import("aoc");

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d8,
        .part1_sample = aoc.input.d8_sample,
        .part2 = aoc.input.d8,
        .part2_sample = aoc.input.d8_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

const Pair = struct {
    i: usize,
    j: usize,
    dist: i64,
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    var buf: [1000]Junction = undefined;
    const junctions = try Junction.parsePuzzle(ctx, &buf);

    const n = junctions.len;
    var pairs: []Pair = try ctx.alloc.alloc(Pair, n * n);

    var ix: usize = 0;
    for (0..junctions.len - 1) |i| {
        const j1 = junctions[i];
        for (i + 1..junctions.len) |j| {
            const j2 = junctions[j];
            pairs[ix] = .{
                .i = i,
                .j = j,
                .dist = j1.dist(j2),
            };
            ix += 1;
        }
    }

    pairs = pairs[0..ix];
    std.sort.heap(Pair, pairs, {}, struct {
        fn lessThan(_: void, left: Pair, right: Pair) bool {
            return left.dist < right.dist;
        }
    }.lessThan);

    var circuits: [1000]usize = undefined;
    var next: usize = 0;

    const iters: usize = if (ctx.sample) 10 else 1000;
    for (0..iters) |i| {
        const p = pairs[i];
        const j1 = &junctions[p.i];
        const j2 = &junctions[p.j];

        if (j1.circuit) |j1_circuit| {
            if (j2.circuit) |j2_circuit| {
                // both already connected in the same circuit
                if (j1.circuit == j2.circuit) continue;

                // if both are connected to different circuits, we need
                // to merge the circuits together
                circuits[j1_circuit] += circuits[j2_circuit];
                circuits[j2_circuit] = 0;
                for (junctions) |*j| {
                    if (j.circuit == j2_circuit) {
                        j.circuit = j1_circuit;
                    }
                }

                continue;
            }
        }

        if (j1.circuit) |existing| {
            j2.circuit = existing;
            circuits[existing] += 1;
        } else if (j2.circuit) |existing| {
            j1.circuit = existing;
            circuits[existing] += 1;
        } else {
            j1.circuit = next;
            j2.circuit = next;
            circuits[next] = 2;
            next += 1;
        }
    }

    for (0..next) |i| {
        std.debug.print("circuit {d}: {d} junctions\n", .{ i, circuits[i] });
    }

    var unconnected: usize = 0;
    for (junctions) |j| {
        if (j.circuit == null) unconnected += 1;
    }
    std.debug.print("unconnected: {d}\n", .{unconnected});

    std.sort.heap(usize, circuits[0..next], {}, std.sort.desc(usize));
    var prod: usize = 1;
    for (0..3) |i| {
        std.debug.print("circuit {d}: {d} junctions\n", .{ i, circuits[i] });
        prod *= circuits[i];
    }

    std.debug.print("product: {d}\n", .{prod});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    var buf: [1000]Junction = undefined;
    const junctions = try Junction.parsePuzzle(ctx, &buf);

    const n = junctions.len;
    var pairs: []Pair = try ctx.alloc.alloc(Pair, n * n);

    var ix: usize = 0;
    for (0..junctions.len - 1) |i| {
        const j1 = junctions[i];
        for (i + 1..junctions.len) |j| {
            const j2 = junctions[j];
            pairs[ix] = .{
                .i = i,
                .j = j,
                .dist = j1.dist(j2),
            };
            ix += 1;
        }
    }

    pairs = pairs[0..ix];
    std.sort.heap(Pair, pairs, {}, struct {
        fn lessThan(_: void, left: Pair, right: Pair) bool {
            return left.dist < right.dist;
        }
    }.lessThan);

    var circuits: [1000]usize = undefined;
    var next: usize = 0;

    var pair_i: usize = 0;
    while (true) : (pair_i += 1) {
        var done: bool = false;
        var max: usize = 0;
        for (circuits[0..next]) |connected| {
            max = @max(0, connected);
            if (connected == junctions.len) {
                done = true;
                break;
            }
        }

        if (done) break;

        const p = pairs[pair_i];
        const j1 = &junctions[p.i];
        const j2 = &junctions[p.j];

        if (j1.circuit) |j1_circuit| {
            if (j2.circuit) |j2_circuit| {
                // both already connected in the same circuit
                if (j1.circuit == j2.circuit) continue;

                // if both are connected to different circuits, we need
                // to merge the circuits together
                circuits[j1_circuit] += circuits[j2_circuit];
                circuits[j2_circuit] = 0;
                for (junctions) |*j| {
                    if (j.circuit == j2_circuit) {
                        j.circuit = j1_circuit;
                    }
                }

                continue;
            }
        }

        if (j1.circuit) |existing| {
            j2.circuit = existing;
            circuits[existing] += 1;
        } else if (j2.circuit) |existing| {
            j1.circuit = existing;
            circuits[existing] += 1;
        } else {
            j1.circuit = next;
            j2.circuit = next;
            circuits[next] = 2;
            next += 1;
        }
    }

    const last_pair = pairs[pair_i - 1];
    const x_dist = junctions[last_pair.i].x * junctions[last_pair.j].x;
    std.debug.print("last x dist {d}\n", .{x_dist});
}

const Junction = struct {
    x: i64,
    y: i64,
    z: i64,
    circuit: ?usize = null,

    fn dist(self: Junction, other: Junction) i64 {
        const a = self.x - other.x;
        const b = self.y - other.y;
        const c = self.z - other.z;
        return (a * a) + (b * b) + (c * c);
    }

    fn parsePuzzle(ctx: aoc.Context, buf: []Junction) ![]Junction {
        var count: usize = 0;
        for (try aoc.input.lines(ctx.alloc, ctx.puzzle)) |line| {
            buf[count] = Junction.parse(line);
            count += 1;
        }

        return buf[0..count];
    }

    fn parse(line: []const u8) Junction {
        var coords: [3]i64 = undefined;
        var cur = line;
        for (0..3) |i| {
            if (std.mem.indexOfScalar(u8, cur, ',')) |offset| {
                coords[i] = std.fmt.parseInt(i64, cur[0..offset], 10) catch unreachable;
                cur = cur[offset + 1 ..];
            } else {
                coords[i] = std.fmt.parseInt(i64, cur, 10) catch unreachable;
            }
        }

        return Junction{
            .x = coords[0],
            .y = coords[1],
            .z = coords[2],
        };
    }
};
