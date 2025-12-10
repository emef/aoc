pub const c = @cImport({
    @cInclude("z3.h");
});

// Convenience type aliases
pub const Config = c.Z3_config;
pub const Context = c.Z3_context;
pub const Optimize = c.Z3_optimize;
pub const Ast = c.Z3_ast;
pub const Sort = c.Z3_sort;
pub const Model = c.Z3_model;
pub const Symbol = c.Z3_symbol;

pub const L_FALSE = c.Z3_L_FALSE;
pub const L_TRUE = c.Z3_L_TRUE;
pub const L_UNDEF = c.Z3_L_UNDEF;

// Helper wrapper for easier resource management
pub const OptContext = struct {
    cfg: Config,
    ctx: Context,
    opt: Optimize,

    pub fn init() OptContext {
        const cfg = c.Z3_mk_config();
        const ctx = c.Z3_mk_context(cfg);
        const opt = c.Z3_mk_optimize(ctx);
        c.Z3_optimize_inc_ref(ctx, opt);
        return .{ .cfg = cfg, .ctx = ctx, .opt = opt };
    }

    pub fn deinit(self: *OptContext) void {
        c.Z3_optimize_dec_ref(self.ctx, self.opt);
        c.Z3_del_context(self.ctx);
        c.Z3_del_config(self.cfg);
    }

    // Variable creation helpers
    pub fn intVar(self: *OptContext, name: [*:0]const u8) Ast {
        const int_sort = c.Z3_mk_int_sort(self.ctx);
        return c.Z3_mk_const(self.ctx, c.Z3_mk_string_symbol(self.ctx, name), int_sort);
    }

    pub fn intVal(self: *OptContext, val: c_int) Ast {
        return c.Z3_mk_int(self.ctx, val, c.Z3_mk_int_sort(self.ctx));
    }

    // Constraint helpers
    pub fn assert_(self: *OptContext, constraint: Ast) void {
        c.Z3_optimize_assert(self.ctx, self.opt, constraint);
    }

    pub fn eq(self: *OptContext, a: Ast, b: Ast) Ast {
        return c.Z3_mk_eq(self.ctx, a, b);
    }

    pub fn le(self: *OptContext, a: Ast, b: Ast) Ast {
        return c.Z3_mk_le(self.ctx, a, b);
    }

    pub fn ge(self: *OptContext, a: Ast, b: Ast) Ast {
        return c.Z3_mk_ge(self.ctx, a, b);
    }

    pub fn add(self: *OptContext, args: []Ast) Ast {
        return c.Z3_mk_add(self.ctx, @intCast(args.len), args.ptr);
    }

    pub fn mul(self: *OptContext, args: []Ast) Ast {
        return c.Z3_mk_mul(self.ctx, @intCast(args.len), args.ptr);
    }

    // Optimization
    pub fn maximize(self: *OptContext, objective: Ast) void {
        _ = c.Z3_optimize_maximize(self.ctx, self.opt, objective);
    }

    pub fn minimize(self: *OptContext, objective: Ast) void {
        _ = c.Z3_optimize_minimize(self.ctx, self.opt, objective);
    }

    pub fn check(self: *OptContext) c_int {
        return c.Z3_optimize_check(self.ctx, self.opt, 0, null);
    }

    // Model extraction
    pub fn getModel(self: *OptContext) ?ModelWrapper {
        const model = c.Z3_optimize_get_model(self.ctx, self.opt);
        if (model == null) return null;
        c.Z3_model_inc_ref(self.ctx, model);
        return .{ .ctx = self.ctx, .model = model };
    }

    pub fn astToString(self: *OptContext, ast: Ast) [*:0]const u8 {
        return c.Z3_ast_to_string(self.ctx, ast);
    }

    pub fn astToInt(self: *OptContext, ast: Ast) c_int {
        var val: c_int = undefined;
        if (c.Z3_get_numeral_int(self.ctx, ast, &val)) {
            return val;
        } else unreachable;
    }
};

pub const ModelWrapper = struct {
    ctx: Context,
    model: Model,

    pub fn deinit(self: *ModelWrapper) void {
        c.Z3_model_dec_ref(self.ctx, self.model);
    }

    pub fn eval(self: *ModelWrapper, ast: Ast) ?Ast {
        var result: Ast = undefined;
        if (c.Z3_model_eval(self.ctx, self.model, ast, true, &result) == true) {
            return result;
        }
        return null;
    }
};
