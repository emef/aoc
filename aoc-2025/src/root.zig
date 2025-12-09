const std = @import("std");

pub const input = @import("input/input.zig");

pub const Error = std.Io.Reader.StreamError ||
    std.mem.Allocator.Error ||
    std.fmt.ParseIntError ||
    error{
        TODO,
        StreamTooLong,
        Unsupported,
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
