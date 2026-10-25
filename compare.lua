local M = {}

local function anyPin(name)
    return { name = name, kind = "data", direction = "in", dataType = "any" }
end

local function numberPin(name)
    return { name = name, kind = "data", direction = "in", dataType = "number", default = 0 }
end

local function boolOut()
    return { name = "result", kind = "data", direction = "out", dataType = "bool" }
end

local operations = {
    ["=="] = function(a, b) return a == b end,
    ["!="] = function(a, b) return a ~= b end,
    [">"]  = function(a, b) return a > b end,
    ["<"]  = function(a, b) return a < b end,
    [">="] = function(a, b) return a >= b end,
    ["<="] = function(a, b) return a <= b end,
}

function M.Register(registry)
    registry:RegisterNodeType("std.compare", {
        category = "boolean",
        displayName = "Compare",
        description = "Compare two numbers.",
        pins = {
            { name = "operation", kind = "data", direction = "in", dataType = "compareOperation", default = "==" },
            numberPin("a"), numberPin("b"), boolOut(),
        },
        run = function(ctx)
            ctx:Out("result", operations[ctx:In("operation")](ctx:In("a"), ctx:In("b")))
        end,
    })

    -- Keep old IDs and pin defaults for saved graphs.
    -- Equals/NotEquals accept "any" (docs/adr/0005): plain Lua equality, so two
    -- distinct tables are never equal even with the same contents.
    registry:RegisterNodeType("std.equals", {
        category = "compare",
        hidden = true,
        displayName = "Equals",
        pins = { anyPin("a"), anyPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") == ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.notequals", {
        category = "compare",
        hidden = true,
        displayName = "Not Equals",
        pins = { anyPin("a"), anyPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") ~= ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.greaterthan", {
        category = "compare",
        hidden = true,
        displayName = "Greater Than",
        pins = { numberPin("a"), numberPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") > ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.lessthan", {
        category = "compare",
        hidden = true,
        displayName = "Less Than",
        pins = { numberPin("a"), numberPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") < ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.greaterorequal", {
        category = "compare",
        hidden = true,
        displayName = "Greater Or Equal",
        pins = { numberPin("a"), numberPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") >= ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.lessorequal", {
        category = "compare",
        hidden = true,
        displayName = "Less Or Equal",
        pins = { numberPin("a"), numberPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") <= ctx:In("b"))
        end,
    })
end

return M
