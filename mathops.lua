local M = {}

local function numberPin(name)
    return { name = name, kind = "data", direction = "in", dataType = "number", default = 0 }
end

local function numberOut()
    return { name = "result", kind = "data", direction = "out", dataType = "number" }
end

-- Division by zero is not special-cased; it yields inf/-inf/nan like plain Lua
-- division, same as the hidden std.divide node (docs/adr/0005).
local operations = {
    ["+"] = function(a, b) return a + b end,
    ["-"] = function(a, b) return a - b end,
    ["*"] = function(a, b) return a * b end,
    ["/"] = function(a, b) return a / b end,
    ["%"] = function(a, b) return a % b end,
    min = function(a, b) return math.min(a, b) end,
    max = function(a, b) return math.max(a, b) end,
}

function M.Register(registry)
    -- One palette node. The operation is a control, so switching it cannot add,
    -- remove, or disconnect pins. The seven older keys stay registered below.
    registry:RegisterNodeType("std.math", {
        category = "math",
        displayName = "Math",
        pins = {
            { name = "operation", kind = "data", direction = "in", dataType = "mathOperation", default = "+" },
            numberPin("a"), numberPin("b"), numberOut(),
        },
        run = function(ctx)
            ctx:Out("result", operations[ctx:In("operation")](ctx:In("a"), ctx:In("b")))
        end,
    })

    registry:RegisterNodeType("std.add", {
        category = "math",
        hidden = true,
        displayName = "Add",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") + ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.subtract", {
        category = "math",
        hidden = true,
        displayName = "Subtract",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") - ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.multiply", {
        category = "math",
        hidden = true,
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
        hidden = true,
        displayName = "Divide",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") / ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.modulo", {
        category = "math",
        hidden = true,
        displayName = "Modulo",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") % ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.min", {
        category = "math",
        hidden = true,
        displayName = "Min",
        pins = { numberPin("a"), numberPin("b"), numberOut() },
        run = function(ctx)
            ctx:Out("result", math.min(ctx:In("a"), ctx:In("b")))
        end,
    })

    registry:RegisterNodeType("std.max", {
        category = "math",
        hidden = true,
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
