const std = @import("std");
const aoc = @import("aoc");

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d9,
        .part1_sample = aoc.input.d9_sample,
        .part2 = aoc.input.d9,
        .part2_sample = aoc.input.d9_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

const Point = struct {
    x: usize,
    y: usize,

    fn parse(line: []const u8) !Point {
        const split = std.mem.indexOfScalar(u8, line, ',') orelse unreachable;
        return Point{
            .x = try std.fmt.parseInt(usize, line[0..split], 10),
            .y = try std.fmt.parseInt(usize, line[split + 1 ..], 10),
        };
    }
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    var buf: [500]Point = undefined;
    const pts = try parsePuzzle(ctx, &buf);

    var best: usize = 0;
    for (0..pts.len - 1) |i| {
        for (i..pts.len) |j| {
            const a = pts[i];
            const b = pts[j];
            const area = Rect.init(a, b).area();
            best = @max(best, area);
        }
    }

    std.debug.print("best: {d}\n", .{best});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    var buf: [500]Point = undefined;
    const pts = try parsePuzzle(ctx, &buf);

    var vbuf: [500]VLine = undefined;
    var vcount: usize = 0;

    for (0..pts.len) |i| {
        const j = @mod(i + 1, pts.len);
        const p1 = pts[j];
        const p2 = pts[i];
        if (VLine.init(p1, p2)) |vline| {
            vbuf[vcount] = vline;
            vcount += 1;
        }
    }

    const vlines = vbuf[0..vcount];

    std.sort.heap(
        VLine,
        vlines,
        {},
        struct {
            fn lessThan(_: void, a: VLine, b: VLine) bool {
                return a.y < b.y;
            }
        }.lessThan,
    );

    const inclusion = try RowInclusion.init(ctx.alloc, vlines);

    var best: usize = 0;
    for (0..pts.len - 1) |i| {
        for (i..pts.len) |j| {
            const a = pts[i];
            const b = pts[j];
            const rect = Rect.init(a, b);
            const area = rect.area();
            if (area < best) continue;
            if (!inclusion.includes(rect)) {
                continue;
            }

            best = area;
        }
    }

    std.debug.print("best: {d}\n", .{best});
}

const Rect = struct {
    min: Point,
    max: Point,

    fn init(p1: Point, p2: Point) Rect {
        return Rect{
            .min = Point{ .x = @min(p1.x, p2.x), .y = @min(p1.y, p2.y) },
            .max = Point{ .x = @max(p1.x, p2.x), .y = @max(p1.y, p2.y) },
        };
    }

    fn area(self: Rect) usize {
        const width = self.max.y - self.min.y + 1;
        const height = self.max.x - self.min.x + 1;
        return width * height;
    }
};

const VLine = struct {
    y: usize,
    min_x: usize,
    max_x: usize,
    up: bool,

    fn init(p1: Point, p2: Point) ?VLine {
        if (p1.y == p2.y) {
            return VLine{
                .y = p1.y,
                .min_x = @min(p1.x, p2.x),
                .max_x = @max(p1.x, p2.x),
                .up = p2.x < p1.x,
            };
        }

        return null;
    }
};

const Range = struct {
    start: usize,
    end: usize,
};

const RowRange = struct {
    alloc: std.mem.Allocator,
    ranges: std.ArrayList(Range),

    fn init(alloc: std.mem.Allocator) !RowRange {
        return RowRange{
            .alloc = alloc,
            .ranges = try std.ArrayList(Range).initCapacity(alloc, 0),
        };
    }

    fn up(self: *RowRange, y: usize) !void {
        if (self.ranges.items.len > 0) {
            const i = self.ranges.items.len - 1;
            const last = self.ranges.items[i];
            if (last.start == last.end) {
                return;
            }
        }

        try self.ranges.append(
            self.alloc,
            Range{ .start = y, .end = y },
        );
    }

    fn down(self: RowRange, y: usize) void {
        if (self.ranges.items.len == 0) unreachable;
        const i = self.ranges.items.len - 1;
        self.ranges.items[i].end = y;
    }

    fn includes(self: RowRange, min_y: usize, max_y: usize) bool {
        for (self.ranges.items) |range| {
            if (range.start <= min_y and range.end >= max_y) {
                return true;
            }
        }

        return false;
    }
};

const RowInclusion = struct {
    rows: std.ArrayList(RowRange),

    pub fn init(alloc: std.mem.Allocator, vlines: []VLine) !RowInclusion {
        var rows = try std.ArrayList(RowRange).initCapacity(alloc, 100000);
        for (0..100000) |_| {
            try rows.append(alloc, try RowRange.init(alloc));
        }

        for (vlines) |vline| {
            if (vline.up) {
                for (vline.min_x..vline.max_x + 1) |x| {
                    try rows.items[x].up(vline.y);
                }
            } else {
                for (vline.min_x..vline.max_x + 1) |x| {
                    rows.items[x].down(vline.y);
                }
            }
        }

        return RowInclusion{
            .rows = rows,
        };
    }

    pub fn includes(self: RowInclusion, rect: Rect) bool {
        for (rect.min.x..rect.max.x + 1) |x| {
            if (!self.rows.items[x].includes(rect.min.y, rect.max.y)) {
                return false;
            }
        }

        return true;
    }
};

fn parsePuzzle(ctx: aoc.Context, buf: []Point) ![]Point {
    var i: usize = 0;
    for (try aoc.input.lines(ctx.alloc, ctx.puzzle)) |line| {
        buf[i] = try Point.parse(line);
        i += 1;
    }
    return buf[0..i];
}
