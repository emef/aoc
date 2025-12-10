const std = @import("std");
const z3 = @import("z3");

pub fn main() !void {
    var opt = z3.OptContext.init();
    defer opt.deinit();

    // Create integer variables x and y
    const x = opt.intVar("x");
    const y = opt.intVar("y");

    // Constants
    const zero = opt.intVal(0);
    const six = opt.intVal(6);
    const eight = opt.intVal(8);
    const ten = opt.intVal(10);

    // Constraints: x >= 0, y >= 0
    opt.assert_(opt.ge(x, zero));
    opt.assert_(opt.ge(y, zero));

    // Constraint: x + y <= 10
    var sum_args = [_]z3.Ast{ x, y };
    opt.assert_(opt.le(opt.add(&sum_args), ten));

    // Constraints: x <= 6, y <= 8
    opt.assert_(opt.le(x, six));
    opt.assert_(opt.le(y, eight));

    // Objective: maximize 2x + 3y
    var term_2x = [_]z3.Ast{ opt.intVal(2), x };
    var term_3y = [_]z3.Ast{ opt.intVal(3), y };
    var obj_args = [_]z3.Ast{ opt.mul(&term_2x), opt.mul(&term_3y) };
    const objective = opt.add(&obj_args);
    opt.maximize(objective);

    // Solve
    if (opt.check() == z3.L_TRUE) {
        var model = opt.getModel() orelse return;
        defer model.deinit();

        std.debug.print("Optimal solution found:\n", .{});
        if (model.eval(x)) |v| std.debug.print("  x = {s}\n", .{opt.astToString(v)});
        if (model.eval(y)) |v| std.debug.print("  y = {s}\n", .{opt.astToString(v)});
        if (model.eval(objective)) |v| std.debug.print("  Objective (2x + 3y) = {s}\n", .{opt.astToString(v)});
    } else {
        std.debug.print("No solution found.\n", .{});
    }
}
