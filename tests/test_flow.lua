local luaunit = require("luaunit")
local Registry = require("registry")
local Graph = require("graph")
local Flow = require("flow")

TestFlow = {}

function TestFlow:setUp()
    self.registry = Registry.new()
    Flow.Register(self.registry)
    self.registry:RegisterNodeType("fixture.trigger", {
        category = "trigger",
        pins = { { name = "out", kind = "exec", direction = "out" } },
        run = function(ctx) ctx:Fire("out") end,
    })
    self.log = {}
    self.registry:RegisterNodeType("fixture.mark", {
        category = "action",
        pins = { { name = "in", kind = "exec", direction = "in", terminates = true } },
        run = function()
            table.insert(self.log, #self.log + 1)
        end,
    })
    self.graph = Graph.new(self.registry)
end

function TestFlow:testBranchTakesTrueOutputWhenConditionTrue()
    local triggerId = self.graph:AddNode("fixture.trigger")
    local branchId = self.graph:AddNode("std.branch", { condition = true })
    local markId = self.graph:AddNode("fixture.mark")

    self.graph:Connect(triggerId, "out", branchId, "in")
    self.graph:Connect(branchId, "true", markId, "in")

    self.graph:Fire(triggerId)

    luaunit.assertEquals(#self.log, 1)
end

function TestFlow:testBranchTakesFalseOutputWhenConditionFalse()
    local triggerId = self.graph:AddNode("fixture.trigger")
    local branchId = self.graph:AddNode("std.branch", { condition = false })
    local markTrue = self.graph:AddNode("fixture.mark")
    local markFalse = self.graph:AddNode("fixture.mark")

    self.graph:Connect(triggerId, "out", branchId, "in")
    self.graph:Connect(branchId, "true", markTrue, "in")
    self.graph:Connect(branchId, "false", markFalse, "in")

    self.graph:Fire(triggerId)

    luaunit.assertEquals(#self.log, 1)
end

function TestFlow:testSequenceFiresOutputsInOrder()
    local triggerId = self.graph:AddNode("fixture.trigger")
    local sequenceId = self.graph:AddNode("std.sequence")
    local mark1 = self.graph:AddNode("fixture.mark")
    local mark2 = self.graph:AddNode("fixture.mark")
    local mark3 = self.graph:AddNode("fixture.mark")

    self.graph:Connect(triggerId, "out", sequenceId, "in")
    self.graph:Connect(sequenceId, "then1", mark1, "in")
    self.graph:Connect(sequenceId, "then2", mark2, "in")
    self.graph:Connect(sequenceId, "then3", mark3, "in")

    self.graph:Fire(triggerId)

    luaunit.assertEquals(self.log, { 1, 2, 3 })
end

return TestFlow
