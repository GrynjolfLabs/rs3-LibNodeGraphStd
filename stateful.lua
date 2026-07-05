-- Stateful standard nodes. Each remembers prior runs in ctx.state and distinguishes its
-- several execution inputs via ctx.exec (see LibNodeGraph/docs/adr/0010). Control inputs
-- (reset / open / close / toggle) are declared as Terminators: they mutate state and fire
-- nothing onward, so a wire looping back into one is legal (docs/adr/0004 rule 4).

local M = {}

function M.Register(registry)
    -- Counts execution signals. `in` adds `step` and fires `out` with the new `count`;
    -- `reset` restores `count` to `start` and fires nothing.
    registry:RegisterNodeType("std.counter", {
        category = "stateful",
        displayName = "Counter",
        pins = {
            { name = "in", kind = "exec", direction = "in" },
            { name = "reset", kind = "exec", direction = "in", terminates = true },
            { name = "step", kind = "data", direction = "in", dataType = "number", default = 1 },
            { name = "start", kind = "data", direction = "in", dataType = "number", default = 0 },
            { name = "out", kind = "exec", direction = "out" },
            { name = "count", kind = "data", direction = "out", dataType = "number" },
        },
        run = function(ctx)
            local state = ctx.state
            if state.count == nil then
                state.count = ctx:In("start")
            end
            if ctx.exec == "reset" then
                state.count = ctx:In("start")
                return
            end
            state.count = state.count + ctx:In("step")
            ctx:Out("count", state.count)
            ctx:Fire("out")
        end,
    })

    -- Passes the first execution signal through to `out`, then blocks every later one
    -- until `reset` re-arms it. `startClosed` blocks even the first signal until reset.
    registry:RegisterNodeType("std.doonce", {
        category = "stateful",
        displayName = "Do Once",
        pins = {
            { name = "in", kind = "exec", direction = "in" },
            { name = "reset", kind = "exec", direction = "in", terminates = true },
            { name = "startClosed", kind = "data", direction = "in", dataType = "bool", default = false },
            { name = "out", kind = "exec", direction = "out" },
        },
        run = function(ctx)
            local state = ctx.state
            if ctx.exec == "reset" then
                state.fired = false
                return
            end
            if state.fired == nil then
                state.fired = ctx:In("startClosed") and true or false
            end
            if not state.fired then
                state.fired = true
                ctx:Fire("out")
            end
        end,
    })

    -- A gate on the execution flow. `in` fires `out` only while open. `open` / `close` /
    -- `toggle` set the gate and fire nothing. `startClosed` (default true) sets the
    -- initial state before any control signal.
    registry:RegisterNodeType("std.gate", {
        category = "stateful",
        displayName = "Gate",
        pins = {
            { name = "in", kind = "exec", direction = "in" },
            { name = "open", kind = "exec", direction = "in", terminates = true },
            { name = "close", kind = "exec", direction = "in", terminates = true },
            { name = "toggle", kind = "exec", direction = "in", terminates = true },
            { name = "startClosed", kind = "data", direction = "in", dataType = "bool", default = true },
            { name = "out", kind = "exec", direction = "out" },
        },
        run = function(ctx)
            local state = ctx.state
            if state.open == nil then
                state.open = not ctx:In("startClosed")
            end
            local e = ctx.exec
            if e == "open" then
                state.open = true
            elseif e == "close" then
                state.open = false
            elseif e == "toggle" then
                state.open = not state.open
            elseif state.open then
                ctx:Fire("out")
            end
        end,
    })

    -- Alternates between `a` and `b` on successive signals, starting with `a`. `isA`
    -- reports which output was taken on the current signal.
    registry:RegisterNodeType("std.flipflop", {
        category = "stateful",
        displayName = "FlipFlop",
        pins = {
            { name = "in", kind = "exec", direction = "in" },
            { name = "a", kind = "exec", direction = "out" },
            { name = "b", kind = "exec", direction = "out" },
            { name = "isA", kind = "data", direction = "out", dataType = "bool" },
        },
        run = function(ctx)
            local state = ctx.state
            if state.isA == nil then
                state.isA = true
            end
            if state.isA then
                ctx:Out("isA", true)
                state.isA = false
                ctx:Fire("a")
            else
                ctx:Out("isA", false)
                state.isA = true
                ctx:Fire("b")
            end
        end,
    })
end

return M
