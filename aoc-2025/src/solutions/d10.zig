const std = @import("std");
const aoc = @import("aoc");
const z3 = @import("z3");

pub const Solution = aoc.Solution{
    .inputs = .{
        .part1 = aoc.input.d10,
        .part1_sample = aoc.input.d10_sample,
        .part2 = aoc.input.d10,
        .part2_sample = aoc.input.d10_sample,
    },
    .part1 = part1,
    .part2 = part2,
};

fn part1(ctx: aoc.Context) aoc.Error!void {
    var m_buf: [200]Machine = undefined;
    const machines = try parsePuzzle(ctx, &m_buf);

    var sum: usize = 0;
    for (machines) |*machine| {
        var queue = aoc.CyclicDeque(State, 10000).init();
        try queue.append(State.init(machine));

        var arena = std.heap.ArenaAllocator.init(ctx.alloc);
        defer arena.deinit();
        const alloc = arena.allocator();

        var seen = std.StringArrayHashMap(bool).init(alloc);
        defer seen.deinit();

        while (true) {
            const state = queue.popFront() orelse unreachable;
            const state_key = state.hash_key();
            if (seen.contains(state_key)) {
                continue;
            }

            try seen.put(try alloc.dupe(u8, state_key), true);

            if (state.is_on()) {
                sum += state.pressed;
                break;
            }

            for (state.permute().states) |next| {
                try queue.append(next);
            }
        }
    }

    std.debug.print("sum: {d}\n", .{sum});
}

fn part2(ctx: aoc.Context) aoc.Error!void {
    var m_buf: [200]Machine = undefined;
    const machines = try parsePuzzle(ctx, &m_buf);

    var sum: usize = 0;
    for (machines) |*machine| {
        var arena = std.heap.ArenaAllocator.init(ctx.alloc);
        defer arena.deinit();
        const alloc = arena.allocator();

        sum += try solveZ3(alloc, machine, ctx.sample);
    }

    std.debug.print("sum: {d}\n", .{sum});
}

const AstList = std.ArrayList(z3.Ast);
const AstArgsList = std.ArrayList(AstList);
const NameList = std.ArrayList([]const u8);

fn solveZ3(alloc: std.mem.Allocator, machine: *const Machine, is_sample: bool) !usize {
    var opt = z3.OptContext.init();
    defer opt.deinit();

    const zero = opt.intVal(0);

    var jolt_targets = try AstList.initCapacity(alloc, machine.jolts.len);
    var jolt_sum_args = try AstArgsList.initCapacity(alloc, machine.jolts.len);
    for (machine.jolts) |joltage| {
        try jolt_targets.append(alloc, opt.intVal(@intCast(joltage)));
        try jolt_sum_args.append(alloc, try AstList.initCapacity(alloc, 0));
    }

    var press_vars = try AstList.initCapacity(alloc, machine.btns.len);

    for (machine.btns, 0..) |btn, i| {
        var buf: [32]u8 = undefined;
        const btn_name = try std.fmt.bufPrintZ(&buf, "btn-{d}", .{i});
        const presses = opt.intVar(btn_name.ptr);
        try press_vars.append(alloc, presses);

        // joltage increases by num presses for each of a btn's effects
        for (btn.effects) |effect_idx| {
            try jolt_sum_args.items[effect_idx].append(alloc, presses);
        }

        // presses must be non-negative
        opt.assert_(opt.ge(presses, zero));
    }

    // constrain joltage sum to be equal to machine target
    for (0..machine.jolts.len) |i| {
        const jolt_sum = opt.add(jolt_sum_args.items[i].items);
        const jolt_target = jolt_targets.items[i];
        opt.assert_(opt.eq(jolt_sum, jolt_target));
    }

    // minimize total number of presses
    const objective = opt.add(press_vars.items);
    opt.minimize(objective);

    if (opt.check() == z3.L_TRUE) {
        var model = opt.getModel() orelse unreachable;
        defer model.deinit();

        if (is_sample) {
            std.debug.print("Optimal solution found:\n", .{});

            for (press_vars.items, 0..) |press, i| {
                const v = model.eval(press) orelse unreachable;
                std.debug.print("  btn {d} = {s}\n", .{ i, opt.astToString(v) });
            }
        }

        const solution = model.eval(objective) orelse unreachable;
        return @intCast(opt.astToInt(solution));
    }

    return error.NoSolution;
}

fn Permutations(T: type) type {
    return struct {
        state_buf: [max_buttons]T,
        states: []T,
    };
}

const State = struct {
    machine: *const Machine,
    lights: [max_lights]u8,
    pressed: usize,

    fn init(machine: *const Machine) State {
        return State{
            .machine = machine,
            .lights = @splat(0),
            .pressed = 0,
        };
    }

    fn permute(self: State) Permutations(State) {
        var perms: Permutations(State) = undefined;

        var i: usize = 0;
        for (self.machine.btns) |btn| {
            var next = State{
                .machine = self.machine,
                .lights = self.lights,
                .pressed = self.pressed + 1,
            };

            for (btn.effects) |idx| {
                next.lights[idx] = if (next.lights[idx] == 1) 0 else 1;
            }

            perms.state_buf[i] = next;
            i += 1;
        }

        perms.states = perms.state_buf[0..i];
        return perms;
    }

    fn is_on(self: State) bool {
        for (self.machine.lights, 0..) |on, i| {
            if (self.lights[i] != on) {
                return false;
            }
        }
        return true;
    }

    fn hash_key(self: *const State) []const u8 {
        return self.lights[0..self.machine.lights.len];
    }
};

const max_lights = 20;
const max_buttons = 20;
const max_effects = 20;
const max_joltage = 20;

const Button = struct {
    effects_buf: [max_effects]u8,
    effects: []u8,

    pub fn parse(r: *std.Io.Reader, btn: *Button) !void {
        var i: usize = 0;

        var c = try r.takeByte();
        if (c != '(') unreachable;

        while (c != ')') {
            c = try r.takeByte();
            var id: u8 = 0;
            while (c != ',' and c != ')') : (c = try r.takeByte()) {
                id = id * 10 + (c - '0');
            }
            btn.effects_buf[i] = id;
            i += 1;
        }
        r.toss(1);

        btn.effects = btn.effects_buf[0..i];
    }
};

const Machine = struct {
    lights_buf: [max_lights]u8,
    btns_buf: [max_buttons]Button,
    jolts_buf: [max_joltage]u16,

    lights: []u8,
    btns: []Button,
    jolts: []u16,

    pub fn parse(r: *std.Io.Reader, m: *Machine) !void {
        r.toss(1);
        var i: usize = 0;
        while (try r.peekByte() != ']') {
            m.lights_buf[i] = if (try r.takeByte() == '#') 1 else 0;
            i += 1;
        }
        r.toss(2);
        m.lights = m.lights_buf[0..i];

        i = 0;
        while (try r.peekByte() != '{') {
            try Button.parse(r, &m.btns_buf[i]);
            i += 1;
        }
        r.toss(1);
        m.btns = m.btns_buf[0..i];

        i = 0;
        var c: u8 = 0;
        while (c != '}') {
            c = try r.takeByte();
            var jolts: u16 = 0;
            while (c != ',' and c != '}') : (c = try r.takeByte()) {
                jolts = jolts * 10 + (c - '0');
            }
            m.jolts_buf[i] = jolts;
            i += 1;
        }

        m.jolts = m.jolts_buf[0..i];
    }
};

fn parsePuzzle(ctx: aoc.Context, m_buf: []Machine) ![]Machine {
    var i: usize = 0;
    for (try aoc.input.lines(ctx.alloc, ctx.puzzle)) |line| {
        var r = std.Io.Reader.fixed(line);
        try Machine.parse(&r, &m_buf[i]);
        i += 1;
    }

    return m_buf[0..i];
}
