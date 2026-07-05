local M = {}

local function numberPin(name)
    return { name = name, kind = "data", direction = "in", dataType = "number", default = 0 }
end

local function numberOut()
    return { name = "result", kind = "data", direction = "out", dataType = "number" }
end

function M.Register(registry)
    registry:RegisterNodeType("std.add", {
        category = "math",
        displayName = "Add",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") + ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.subtract", {
        category = "math",
        displayName = "Subtract",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") - ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.multiply", {
        category = "math",
        displayName = "Multiply",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") * ctx:In("b"))
        end,
    })

    -- Division by zero is not special-cased; it yields inf/-inf/nan like plain Lua
    -- division, consistent with the engine doing no runtime type/value checking
    -- (docs/adr/0005).
    registry:RegisterNodeType("std.divide", {
        category = "math",
        displayName = "Divide",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") / ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.modulo", {
        category = "math",
        displayName = "Modulo",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") % ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.min", {
        category = "math",
        displayName = "Min",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", math.min(ctx:In("a"), ctx:In("b")))
        end,
    })

    registry:RegisterNodeType("std.max", {
        category = "math",
        displayName = "Max",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", math.max(ctx:In("a"), ctx:In("b")))
        end,
    })

    registry:RegisterNodeType("std.abs", {
        category = "math",
        displayName = "Abs",
        pins = { numberPin("value"), numberOut() },
        run = function(ctx)
            ctx:Out("result", math.abs(ctx:In("value")))
        end,
    })

    registry:RegisterNodeType("std.negate", {
        category = "math",
        displayName = "Negate",
        pins = { numberPin("value"), numberOut() },
        run = function(ctx)
            ctx:Out("result", -ctx:In("value"))
        end,
    })
end

return M
