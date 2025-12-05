const std = @import("std");
const aoc = @import("aoc");

const Self = @This();

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d5,
        .part1_sample = aoc.input.d5_sample,
        .part2 = aoc.input.d5,
        .part2_sample = aoc.input.d5_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    var ranges = try RangeSet.init(ctx.alloc);
    const lines = try aoc.input.lines(ctx.alloc, ctx.puzzle);

    var i: usize = 0;
    while (lines[i].len > 0) : (i += 1) {
        const split = std.mem.indexOf(u8, lines[i], "-") orelse unreachable;

        const range = Range{
            .lb = try std.fmt.parseInt(usize, lines[i][0..split], 10),
            .ub = try std.fmt.parseInt(usize, lines[i][split + 1 ..], 10),
        };

        try ranges.add(range);
    }

    i += 1;

    var total: usize = 0;
    while (i < lines.len) : (i += 1) {
        const id = try std.fmt.parseInt(usize, lines[i], 10);
        if (ranges.contains(id)) {
            total += 1;
        }
    }

    std.debug.print("{d}\n", .{total});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    var ranges = try RangeSet.init(ctx.alloc);
    const lines = try aoc.input.lines(ctx.alloc, ctx.puzzle);

    var i: usize = 0;
    while (lines[i].len > 0) : (i += 1) {
        const split = std.mem.indexOf(u8, lines[i], "-") orelse unreachable;

        const range = Range{
            .lb = try std.fmt.parseInt(usize, lines[i][0..split], 10),
            .ub = try std.fmt.parseInt(usize, lines[i][split + 1 ..], 10),
        };

        try ranges.add(range);
    }

    std.debug.print("{d}\n", .{ranges.sum()});
}

const Range = struct {
    lb: usize,
    ub: usize,

    fn overlaps(self: Range, other: Range) bool {
        return @max(self.lb - 1, other.lb) <= @min(other.ub, self.ub + 1);
    }

    fn contains(self: Range, id: usize) bool {
        return id >= self.lb and id <= self.ub;
    }

    fn merge(self: *Range, other: Range) void {
        self.lb = @min(self.lb, other.lb);
        self.ub = @max(self.ub, other.ub);
    }
};

const RangeSet = struct {
    alloc: std.mem.Allocator,
    children: std.DoublyLinkedList,

    const L = struct {
        range: Range,
        node: std.DoublyLinkedList.Node = .{},
    };

    fn init(alloc: std.mem.Allocator) aoc.Error!RangeSet {
        return RangeSet{
            .alloc = alloc,
            .children = .{},
        };
    }

    pub fn format(self: RangeSet, writer: anytype) !void {
        var it = self.children.first;
        while (it) |node| : (it = node.next) {
            const l: *L = @fieldParentPtr("node", node);
            try writer.print("{d} - {d}\n", .{ l.range.lb, l.range.ub });
        }
    }

    fn add(self: *RangeSet, range: Range) aoc.Error!void {
        var it = self.children.first;
        while (it) |node| : (it = node.next) {
            const l: *L = @fieldParentPtr("node", node);

            if (l.range.overlaps(range)) {
                l.range.merge(range);

                var cit = node.next;
                while (cit) |next| : (cit = next.next) {
                    const l_next: *L = @fieldParentPtr("node", next);
                    if (!l_next.range.overlaps(l.range)) {
                        break;
                    }

                    l.range.merge(l_next.range);
                    self.children.remove(next);
                }

                return;
            }

            if (range.ub < l.range.ub) {
                var new_node = try self.alloc.create(L);
                new_node.range = range;
                self.children.insertBefore(node, &new_node.node);
                return;
            }
        }

        var new_node = try self.alloc.create(L);
        new_node.range = range;
        self.children.append(&new_node.node);
    }

    fn contains(self: RangeSet, id: usize) bool {
        var it = self.children.first;
        while (it) |node| : (it = node.next) {
            const l: *L = @fieldParentPtr("node", node);
            if (l.range.contains(id)) {
                return true;
            }
        }
        return false;
    }

    fn sum(self: RangeSet) usize {
        var total: usize = 0;
        var it = self.children.first;
        while (it) |node| : (it = node.next) {
            const l: *L = @fieldParentPtr("node", node);
            total += l.range.ub - l.range.lb + 1;
        }
        return total;
    }
};
