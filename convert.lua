local M = {}

function M.Register(registry)
    registry:RegisterNodeType("std.tostring", {
        category = "convert",
        displayName = "To String",
        pins = {
            { name = "value", kind = "data", direction = "in", dataType = "any" },
            { name = "result", kind = "data", direction = "out", dataType = "string" },
        },
        run = function(ctx)
            ctx:Out("result", tostring(ctx:In("value")))
        end,
    })

    -- Unparsable input yields 0 rather than nil/error, so downstream number pins
    -- always receive a value (docs/adr/0005: no runtime type checking, dumb conversion).
    registry:RegisterNodeType("std.tonumber", {
        category = "convert",
        displayName = "To Number",
        pins = {
            { name = "value", kind = "data", direction = "in", dataType = "string", default = "0" },
            { name = "result", kind = "data", direction = "out", dataType = "number" },
        },
        run = function(ctx)
            ctx:Out("result", tonumber(ctx:In("value")) or 0)
        end,
    })
end

return M
