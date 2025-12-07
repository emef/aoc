const std = @import("std");

const StringArrayList = std.ArrayList([]const u8);

pub const d1 = @embedFile("d1.txt");
pub const d1_sample = @embedFile("d1_sample.txt");

pub const d2 = @embedFile("d2.txt");
pub const d2_sample = @embedFile("d2_sample.txt");

pub const d3 = @embedFile("d3.txt");
pub const d3_sample = @embedFile("d3_sample.txt");

pub const d4 = @embedFile("d4.txt");
pub const d4_sample = @embedFile("d4_sample.txt");

pub const d5 = @embedFile("d5.txt");
pub const d5_sample = @embedFile("d5_sample.txt");

pub const d6 = @embedFile("d6.txt");
pub const d6_sample = @embedFile("d6_sample.txt");

pub const d7 = @embedFile("d7.txt");
pub const d7_sample = @embedFile("d7_sample.txt");

pub fn lines(alloc: std.mem.Allocator, buf: []const u8) ![][]const u8 {
    return split(alloc, buf, '\n');
}

pub fn csv(alloc: std.mem.Allocator, buf: []const u8) ![][]const u8 {
    return split(alloc, buf, ',');
}

pub fn split(alloc: std.mem.Allocator, buf: []const u8, delim: u8) ![][]const u8 {
    var list = try StringArrayList.initCapacity(alloc, 0);

    var r = std.Io.Reader.fixed(buf);
    while (true) {
        const elem = r.takeDelimiterExclusive(delim) catch |e| switch (e) {
            error.EndOfStream, error.StreamTooLong => return list.toOwnedSlice(alloc),
            else => return e,
        };

        try list.append(alloc, elem);
    }
}

pub fn trim(str: []const u8) []const u8 {
    var out = str;
    while (out.len > 0 and out[0] == '\n') out = out[1..];
    while (out.len > 0 and out[out.len - 1] == '\n') out = out[0 .. out.len - 1];
    return out;
}
