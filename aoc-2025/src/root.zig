const std = @import("std");

pub const input = @import("input/input.zig");

pub const Error = std.Io.Reader.StreamError ||
    std.mem.Allocator.Error ||
    std.fmt.ParseIntError ||
    error{
        TODO,
        StreamTooLong,
        Unsupported,
        QueueFull,
        NoSolution,
        NoSpaceLeft,
    };

pub const Context = struct {
    alloc: std.mem.Allocator,
    puzzle: []const u8,
    part: Part,
    sample: bool,
};

pub const Inputs = struct {
    part1: []const u8,
    part1_sample: []const u8,
    part2: []const u8,
    part2_sample: []const u8,
};

pub const Solution = struct {
    inputs: Inputs,
    part1: *const fn (Context) Error!void,
    part2: *const fn (Context) Error!void,
};

pub const Part = enum {
    part1,
    part2,
};

pub fn CyclicDeque(T: type, n: usize) type {
    return struct {
        const Self = @This();

        buf: [n]T,
        start: usize,
        end: usize,
        len: usize,

        pub fn init() Self {
            return Self{
                .buf = undefined,
                .start = 0,
                .end = 0,
                .len = 0,
            };
        }

        pub fn append(self: *Self, elem: T) !void {
            if (self.len + 1 > self.buf.len) {
                return error.QueueFull;
            }

            const idx = self.end;
            self.buf[idx] = elem;
            self.end = @mod(self.end + 1, self.buf.len);
            self.len += 1;
        }

        pub fn prepend(self: *Self, elem: T) !void {
            if (self.len + 1 > self.buf.len) {
                return error.QueueFull;
            }

            self.start = @mod(self.start + self.buf.len - 1, self.buf.len);
            self.buf[self.start] = elem;
            self.len += 1;
        }

        pub fn popFront(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }

            const idx = self.start;
            self.start = @mod(self.start + 1, self.buf.len);
            self.len -= 1;
            return self.buf[idx];
        }

        pub fn popEnd(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }

            self.end = @mod(self.end + self.buf.len - 1, self.buf.len);
            self.len -= 1;
            return self.buf[self.end];
        }
    };
}
