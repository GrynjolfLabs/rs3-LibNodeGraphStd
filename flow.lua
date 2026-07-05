local M = {}

function M.Register(registry)
    registry:RegisterNodeType("std.branch", {
        category = "flow",
        displayName = "Branch",
        pins = {
            { name = "in", kind = "exec", direction = "in" },
            { name = "condition", kind = "data", direction = "in", dataType = "bool", default = false },
            { name = "true", kind = "exec", direction = "out" },
            { name = "false", kind = "exec", direction = "out" },
        },
        run = function(ctx)
            if ctx:In("condition") then
                ctx:Fire("true")
            else
                ctx:Fire("false")
            end
        end,
    })

    -- Fires its outputs in declared order on every arrival, giving explicit ordering
    -- where plain fan-out (unordered, docs/adr/0004 rule 1) isn't enough.
    registry:RegisterNodeType("std.sequence", {
        category = "flow",
        displayName = "Sequence",
        pins = {
            { name = "in", kind = "exec", direction = "in" },
            { name = "then1", kind = "exec", direction = "out" },
            { name = "then2", kind = "exec", direction = "out" },
            { name = "then3", kind = "exec", direction = "out" },
            { name = "then4", kind = "exec", direction = "out" },
        },
        run = function(ctx)
            ctx:Fire("then1")
            ctx:Fire("then2")
            ctx:Fire("then3")
            ctx:Fire("then4")
        end,
    })
end

return M
