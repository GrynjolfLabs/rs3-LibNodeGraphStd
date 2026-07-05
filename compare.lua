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

function M.Register(registry)
    -- Equals/NotEquals accept "any" (docs/adr/0005): plain Lua equality, so two
    -- distinct tables are never equal even with the same contents.
    registry:RegisterNodeType("std.equals", {
        category = "compare",
        displayName = "Equals",
        pins = { anyPin("a"), anyPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") == ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.notequals", {
        category = "compare",
        displayName = "Not Equals",
        pins = { anyPin("a"), anyPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") ~= ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.greaterthan", {
        category = "compare",
        displayName = "Greater Than",
        pins = { numberPin("a"), numberPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") > ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.lessthan", {
        category = "compare",
        displayName = "Less Than",
        pins = { numberPin("a"), numberPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") < ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.greaterorequal", {
        category = "compare",
        displayName = "Greater Or Equal",
        pins = { numberPin("a"), numberPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") >= ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.lessorequal", {
        category = "compare",
        displayName = "Less Or Equal",
        pins = { numberPin("a"), numberPin("b"), boolOut() },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") <= ctx:In("b"))
        end,
    })
end

return M
