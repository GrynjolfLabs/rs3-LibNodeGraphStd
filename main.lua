-- Public entry point for LibNodeGraphStd. Consumers require this file and call
-- Register(registry) to install the standard, game-agnostic node types into a
-- Registry constructed for a LibNodeGraph Graph (see LibNodeGraph/docs/adr/0008).

local Flow = require("flow")
local Boolean = require("boolean")
local Compare = require("compare")
local MathOps = require("mathops")
local Convert = require("convert")
local Stateful = require("stateful")

LibNodeGraphStd = {}

function LibNodeGraphStd.Register(registry)
    Flow.Register(registry)
    Boolean.Register(registry)
    Compare.Register(registry)
    MathOps.Register(registry)
    Convert.Register(registry)
    Stateful.Register(registry)
end

return LibNodeGraphStd
