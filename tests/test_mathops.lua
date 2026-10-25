local luaunit = require("luaunit")
local Registry = require("registry")
local Graph = require("graph")
local Serialize = require("serialize")
local MathOps = require("mathops")

TestMathOps = {}

function TestMathOps:setUp()
    self.registry = Registry.new()
    MathOps.Register(self.registry)
    self.graph = Graph.new(self.registry)
end

function TestMathOps:_eval(typeKey, controls)
    local id = self.graph:AddNode(typeKey, controls)
    self.graph:Fire(id)
    return self.graph:GetLastValue(id, "result")
end

function TestMathOps:testAdd()
    luaunit.assertEquals(self:_eval("std.add", { a = 2, b = 3 }), 5)
end

function TestMathOps:testSubtract()
    luaunit.assertEquals(self:_eval("std.subtract", { a = 5, b = 3 }), 2)
end

function TestMathOps:testMultiply()
    luaunit.assertEquals(self:_eval("std.multiply", { a = 4, b = 3 }), 12)
end

function TestMathOps:testDivide()
    luaunit.assertEquals(self:_eval("std.divide", { a = 6, b = 3 }), 2)
end

function TestMathOps:testModulo()
    luaunit.assertEquals(self:_eval("std.modulo", { a = 7, b = 3 }), 1)
end

function TestMathOps:testMin()
    luaunit.assertEquals(self:_eval("std.min", { a = 7, b = 3 }), 3)
end

function TestMathOps:testMax()
    luaunit.assertEquals(self:_eval("std.max", { a = 7, b = 3 }), 7)
end

function TestMathOps:testAbs()
    luaunit.assertEquals(self:_eval("std.abs", { value = -5 }), 5)
end

function TestMathOps:testNegate()
    luaunit.assertEquals(self:_eval("std.negate", { value = 5 }), -5)
end

-- A new Math node is the palette entry: named Math, in math, starting on add of 0 and 0.
function TestMathOps:testNewMathNodeAddsItsZeroInputs()
    local id = self.graph:AddNode("std.math")
    local nodeType = self.registry:GetNodeType("std.math")
    luaunit.assertEquals(nodeType.displayName, "Math")
    luaunit.assertEquals(nodeType.category, "math")
    luaunit.assertFalse(nodeType.hidden)
    luaunit.assertEquals(self.graph:GetControl(id, "operation"), "+")
    luaunit.assertEquals(self.graph:GetControl(id, "a"), 0)
    luaunit.assertEquals(self.graph:GetControl(id, "b"), 0)
    local pins = self.graph:GetPins(id)
    local byName = {}
    local names = {}
    for _, pin in ipairs(pins) do
        names[#names + 1] = pin.name
        byName[pin.name] = pin
    end
    luaunit.assertEquals(names, { "operation", "a", "b", "result" })
    luaunit.assertEquals(byName.operation.dataType, "mathOperation")
    luaunit.assertEquals(byName.a.dataType, "number")
    luaunit.assertEquals(byName.a.default, 0)
    luaunit.assertEquals(byName.b.dataType, "number")
    luaunit.assertEquals(byName.b.default, 0)
    luaunit.assertEquals(byName.result.dataType, "number")
    luaunit.assertEquals(byName.result.direction, "out")
    self.graph:Fire(id)
    luaunit.assertEquals(self.graph:GetLastValue(id, "result"), 0)
end

-- Switching the operation recomputes a and b and leaves the wire in place.
-- 9 wired into a, b stored as 3. Divide by zero is plain Lua: inf, and 0/0 is nan.
function TestMathOps:testSwitchingOperationKeepsTheWireAndComputes()
    local source = self.graph:AddNode("std.add", { a = 8, b = 1 })
    local mathId = self.graph:AddNode("std.math", { b = 3 })
    self.graph:Connect(source, "result", mathId, "a")
    local pinsBefore = self.graph:GetPins(mathId)
    local connections = Serialize.Serialize(self.graph).connections
    for _, case in ipairs({
        { "+", 12 },
        { "-", 6 },
        { "*", 27 },
        { "/", 3 },
        { "%", 0 },
        { "min", 3 },
        { "max", 9 },
    }) do
        self.graph:SetControl(mathId, "operation", case[1])
        self.graph:Fire(mathId)
        luaunit.assertEquals(self.graph:GetLastValue(mathId, "result"), case[2])
        luaunit.assertEquals(self.graph:GetPins(mathId), pinsBefore)
        luaunit.assertEquals(Serialize.Serialize(self.graph).connections, connections)
    end

    self.graph:SetControl(mathId, "operation", "/")
    self.graph:SetControl(mathId, "b", 0)
    self.graph:Fire(mathId)
    luaunit.assertEquals(self.graph:GetLastValue(mathId, "result"), math.huge)
    luaunit.assertEquals(self.graph:GetPins(mathId), pinsBefore)
    luaunit.assertEquals(Serialize.Serialize(self.graph).connections, connections)

    local zero = self.graph:AddNode("std.math", { operation = "/", a = 0, b = 0 })
    self.graph:Fire(zero)
    local nan = self.graph:GetLastValue(zero, "result")
    luaunit.assertTrue(nan ~= nan)
end

-- The seven older arithmetic nodes still compute, and the palette category
-- listing omits them. Abs and Negate stay listed, each with one number input.
function TestMathOps:testLegacyArithmeticStaysRunnableAndOffThePalette()
    local registry = Registry.new()
    require("main").Register(registry)
    local graph = Graph.new(registry)

    local visible = {}
    for _, nodeType in ipairs(registry:GetNodeTypesByCategory("math")) do
        visible[#visible + 1] = nodeType.key
    end
    luaunit.assertItemsEquals(visible, { "std.math", "std.abs", "std.negate" })

    for _, row in ipairs({
        { "std.add", 2, 3, 5 },
        { "std.subtract", 5, 3, 2 },
        { "std.multiply", 4, 3, 12 },
        { "std.divide", 6, 3, 2 },
        { "std.modulo", 7, 3, 1 },
        { "std.min", 7, 3, 3 },
        { "std.max", 7, 3, 7 },
    }) do
        luaunit.assertTrue(registry:GetNodeType(row[1]).hidden)
        local id = graph:AddNode(row[1], { a = row[2], b = row[3] })
        graph:Fire(id)
        luaunit.assertEquals(graph:GetLastValue(id, "result"), row[4])
        luaunit.assertEquals(graph.nodes[id].typeKey, row[1])
    end

    for _, key in ipairs({ "std.abs", "std.negate" }) do
        luaunit.assertFalse(registry:GetNodeType(key).hidden)
        local id = graph:AddNode(key)
        local inputs = {}
        for _, pin in ipairs(graph:GetPins(id)) do
            if pin.direction == "in" then inputs[#inputs + 1] = pin end
        end
        luaunit.assertEquals(#inputs, 1)
        luaunit.assertEquals(inputs[1].name, "value")
        luaunit.assertEquals(inputs[1].dataType, "number")
        luaunit.assertEquals(graph:GetControl(id, "value"), 0)
    end
    local absId = graph:AddNode("std.abs", { value = -5 })
    graph:Fire(absId)
    luaunit.assertEquals(graph:GetLastValue(absId, "result"), 5)
    local negateId = graph:AddNode("std.negate", { value = 5 })
    graph:Fire(negateId)
    luaunit.assertEquals(graph:GetLastValue(negateId, "result"), -5)
end

-- Loading a graph that still uses the older arithmetic nodes leaves those type
-- keys and wires as they were saved.
function TestMathOps:testSavedArithmeticGraphIsNotRewritten()
    local saved = {
        version = 1,
        nodes = {
            { id = 1, type = "std.add", controls = { a = 2, b = 3 } },
            { id = 2, type = "std.subtract", controls = { a = 5, b = 3 } },
            { id = 3, type = "std.multiply", controls = { b = 4 } },
            { id = 4, type = "std.divide", controls = { a = 6, b = 3 } },
            { id = 5, type = "std.modulo", controls = { a = 7, b = 3 } },
            { id = 6, type = "std.min", controls = { a = 7, b = 3 } },
            { id = 7, type = "std.max", controls = { a = 7, b = 3 } },
            { id = 8, type = "std.abs", controls = { value = -2 } },
            { id = 9, type = "std.negate", controls = { value = 4 } },
        },
        connections = {
            { fromNode = 1, fromPin = "result", toNode = 3, toPin = "a" },
        },
    }
    local typesBefore = {}
    for i, node in ipairs(saved.nodes) do
        typesBefore[i] = node.type
    end
    local restored = Serialize.Deserialize(saved, self.registry)
    local again = Serialize.Serialize(restored)
    for i, node in ipairs(saved.nodes) do
        luaunit.assertEquals(node.type, typesBefore[i])
        luaunit.assertEquals(again.nodes[i].type, typesBefore[i])
        luaunit.assertEquals(restored.nodes[node.id].typeKey, typesBefore[i])
    end
    luaunit.assertEquals(again.connections, saved.connections)
    restored:Fire(3)
    luaunit.assertEquals(restored:GetLastValue(3, "result"), 20)
end

return TestMathOps
