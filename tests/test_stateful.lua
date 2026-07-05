local luaunit = require("luaunit")
local Registry = require("registry")
local Graph = require("graph")
local Stateful = require("stateful")

TestStateful = {}

function TestStateful:setUp()
    self.registry = Registry.new()
    Stateful.Register(self.registry)

    -- Fires a chosen exec output on demand, so tests can drive a specific input pin.
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

    -- Two distinct marks so a node's separate exec outputs can be counted independently.
    self.aCount, self.bCount = 0, 0
    self.registry:RegisterNodeType("fixture.markA", {
        category = "action",
        pins = { { name = "in", kind = "exec", direction = "in", terminates = true } },
        run = function() self.aCount = self.aCount + 1 end,
    })
    self.registry:RegisterNodeType("fixture.markB", {
        category = "action",
        pins = { { name = "in", kind = "exec", direction = "in", terminates = true } },
        run = function() self.bCount = self.bCount + 1 end,
    })

    self.graph = Graph.new(self.registry)
end

-- Fire a specific input pin of `nodeId` by wiring a fresh trigger to it and firing that.
function TestStateful:pulse(nodeId, pin)
    local triggerId = self.graph:AddNode("fixture.trigger")
    self.graph:Connect(triggerId, "out", nodeId, pin)
    self.graph:Fire(triggerId)
end

--- Counter ----------------------------------------------------------------------------

function TestStateful:testCounterIncrementsByStep()
    local counterId = self.graph:AddNode("std.counter", { step = 5, start = 10 })
    self:pulse(counterId, "in")
    luaunit.assertEquals(self.graph:GetLastValue(counterId, "count"), 15)
    self:pulse(counterId, "in")
    luaunit.assertEquals(self.graph:GetLastValue(counterId, "count"), 20)
end

function TestStateful:testCounterDefaultsStepOneStartZero()
    local counterId = self.graph:AddNode("std.counter")
    self:pulse(counterId, "in")
    self:pulse(counterId, "in")
    self:pulse(counterId, "in")
    luaunit.assertEquals(self.graph:GetLastValue(counterId, "count"), 3)
end

function TestStateful:testCounterResetRestoresStartAndFiresNothing()
    local counterId = self.graph:AddNode("std.counter", { start = 100 })
    local markId = self.graph:AddNode("fixture.mark")
    self.graph:Connect(counterId, "out", markId, "in")

    self:pulse(counterId, "in")   -- 101, fires out
    self:pulse(counterId, "reset")
    luaunit.assertEquals(#self.log, 1)  -- reset did not fire out

    self:pulse(counterId, "in")   -- back to 101
    luaunit.assertEquals(self.graph:GetLastValue(counterId, "count"), 101)
end

function TestStateful:testCounterFiresOutOnIncrement()
    local counterId = self.graph:AddNode("std.counter")
    local markId = self.graph:AddNode("fixture.mark")
    self.graph:Connect(counterId, "out", markId, "in")
    self:pulse(counterId, "in")
    self:pulse(counterId, "in")
    luaunit.assertEquals(#self.log, 2)
end

--- DoOnce -----------------------------------------------------------------------------

function TestStateful:testDoOnceFiresOnlyOnce()
    local onceId = self.graph:AddNode("std.doonce")
    local markId = self.graph:AddNode("fixture.mark")
    self.graph:Connect(onceId, "out", markId, "in")

    self:pulse(onceId, "in")
    self:pulse(onceId, "in")
    self:pulse(onceId, "in")

    luaunit.assertEquals(#self.log, 1)
end

function TestStateful:testDoOnceReArmsAfterReset()
    local onceId = self.graph:AddNode("std.doonce")
    local markId = self.graph:AddNode("fixture.mark")
    self.graph:Connect(onceId, "out", markId, "in")

    self:pulse(onceId, "in")
    self:pulse(onceId, "reset")
    self:pulse(onceId, "in")

    luaunit.assertEquals(#self.log, 2)
end

function TestStateful:testDoOnceStartClosedBlocksUntilReset()
    local onceId = self.graph:AddNode("std.doonce", { startClosed = true })
    local markId = self.graph:AddNode("fixture.mark")
    self.graph:Connect(onceId, "out", markId, "in")

    self:pulse(onceId, "in")
    luaunit.assertEquals(#self.log, 0)

    self:pulse(onceId, "reset")
    self:pulse(onceId, "in")
    luaunit.assertEquals(#self.log, 1)
end

--- Gate -------------------------------------------------------------------------------

function TestStateful:testGateStartsClosedByDefault()
    local gateId = self.graph:AddNode("std.gate")
    local markId = self.graph:AddNode("fixture.mark")
    self.graph:Connect(gateId, "out", markId, "in")

    self:pulse(gateId, "in")
    luaunit.assertEquals(#self.log, 0)
end

function TestStateful:testGateOpenAndClose()
    local gateId = self.graph:AddNode("std.gate")
    local markId = self.graph:AddNode("fixture.mark")
    self.graph:Connect(gateId, "out", markId, "in")

    self:pulse(gateId, "open")
    self:pulse(gateId, "in")
    self:pulse(gateId, "in")
    luaunit.assertEquals(#self.log, 2)

    self:pulse(gateId, "close")
    self:pulse(gateId, "in")
    luaunit.assertEquals(#self.log, 2)
end

function TestStateful:testGateToggleFlipsState()
    local gateId = self.graph:AddNode("std.gate", { startClosed = false })
    local markId = self.graph:AddNode("fixture.mark")
    self.graph:Connect(gateId, "out", markId, "in")

    self:pulse(gateId, "in")       -- open -> fires
    self:pulse(gateId, "toggle")   -- now closed
    self:pulse(gateId, "in")       -- blocked
    self:pulse(gateId, "toggle")   -- open again
    self:pulse(gateId, "in")       -- fires

    luaunit.assertEquals(#self.log, 2)
end

--- FlipFlop ---------------------------------------------------------------------------

function TestStateful:testFlipFlopAlternatesOutputs()
    local ffId = self.graph:AddNode("std.flipflop")
    local aMark = self.graph:AddNode("fixture.markA")
    local bMark = self.graph:AddNode("fixture.markB")
    self.graph:Connect(ffId, "a", aMark, "in")
    self.graph:Connect(ffId, "b", bMark, "in")

    self:pulse(ffId, "in")  -- a
    self:pulse(ffId, "in")  -- b
    self:pulse(ffId, "in")  -- a

    luaunit.assertEquals(self.aCount, 2)
    luaunit.assertEquals(self.bCount, 1)
end

function TestStateful:testFlipFlopReportsIsA()
    local ffId = self.graph:AddNode("std.flipflop")
    self:pulse(ffId, "in")
    luaunit.assertIsTrue(self.graph:GetLastValue(ffId, "isA"))
    self:pulse(ffId, "in")
    luaunit.assertIsFalse(self.graph:GetLastValue(ffId, "isA"))
end

return TestStateful
