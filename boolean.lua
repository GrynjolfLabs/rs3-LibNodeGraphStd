local M = {}

local function boolPin(name)
    return { name = name, kind = "data", direction = "in", dataType = "bool", default = false }
end

function M.Register(registry)
    registry:RegisterNodeType("std.and", {
        category = "boolean",
        displayName = "And",
        pins = {
            boolPin("a"),
            boolPin("b"),
            { name = "result", kind = "data", direction = "out", dataType = "bool" },
        },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") and ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.or", {
        category = "boolean",
        displayName = "Or",
        pins = {
            boolPin("a"),
            boolPin("b"),
            { name = "result", kind = "data", direction = "out", dataType = "bool" },
        },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") or ctx:In("b"))
        end,
    })

    registry:RegisterNodeType("std.not", {
        category = "boolean",
        displayName = "Not",
        pins = {
            boolPin("in"),
            { name = "result", kind = "data", direction = "out", dataType = "bool" },
        },
        run = function(ctx)
            ctx:Out("result", not ctx:In("in"))
        end,
    })

    registry:RegisterNodeType("std.xor", {
        category = "boolean",
        displayName = "Xor",
        pins = {
            boolPin("a"),
            boolPin("b"),
            { name = "result", kind = "data", direction = "out", dataType = "bool" },
        },
        run = function(ctx)
            ctx:Out("result", ctx:In("a") ~= ctx:In("b"))
        end,
    })
end

return M
