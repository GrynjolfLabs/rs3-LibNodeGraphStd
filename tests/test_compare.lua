local luaunit = require("luaunit")
local Registry = require("registry")
local Graph = require("graph")
local Compare = require("compare")
local Serialize = require("serialize")

TestCompare = {}

function TestCompare:setUp()
    self.registry = Registry.new()
    Compare.Register(self.registry)
    self.graph = Graph.new(self.registry)
end

function TestCompare:_eval(typeKey, controls)
    local id = self.graph:AddNode(typeKey, controls)
    self.graph:Fire(id)
    return self.graph:GetLastValue(id, "result")
end

function TestCompare:testEquals()
    luaunit.assertTrue(self:_eval("std.equals", { a = 5, b = 5 }))
    luaunit.assertFalse(self:_eval("std.equals", { a = 5, b = 6 }))
    luaunit.assertFalse(self:_eval("std.equals", { a = "x", b = 5 }))
end

function TestCompare:testNotEquals()
    luaunit.assertFalse(self:_eval("std.notequals", { a = 5, b = 5 }))
    luaunit.assertTrue(self:_eval("std.notequals", { a = 5, b = 6 }))
end

function TestCompare:testGreaterThan()
    luaunit.assertTrue(self:_eval("std.greaterthan", { a = 5, b = 3 }))
    luaunit.assertFalse(self:_eval("std.greaterthan", { a = 3, b = 5 }))
end

function TestCompare:testLessThan()
    luaunit.assertTrue(self:_eval("std.lessthan", { a = 3, b = 5 }))
    luaunit.assertFalse(self:_eval("std.lessthan", { a = 5, b = 3 }))
end

function TestCompare:testGreaterOrEqual()
    luaunit.assertTrue(self:_eval("std.greaterorequal", { a = 5, b = 5 }))
    luaunit.assertFalse(self:_eval("std.greaterorequal", { a = 4, b = 5 }))
end

function TestCompare:testLessOrEqual()
    luaunit.assertTrue(self:_eval("std.lessorequal", { a = 5, b = 5 }))
    luaunit.assertFalse(self:_eval("std.lessorequal", { a = 6, b = 5 }))
end

function TestCompare:result(operation, a, b)
    local node = self.graph:AddNode("std.compare", { operation = operation, a = a, b = b })
    self.graph:Fire(node)
    return self.graph:GetLastValue(node, "result")
end

function TestCompare:testAllOperationsTrueAndFalse()
    for _, case in ipairs({
        { "==", 2, 2, true }, { "==", 2, 3, false },
        { "!=", 2, 3, true }, { "!=", 2, 2, false },
        { ">", 3, 2, true }, { ">", 2, 2, false },
        { "<", 2, 3, true }, { "<", 2, 2, false },
        { ">=", 2, 2, true }, { ">=", 2, 3, false },
        { "<=", 2, 2, true }, { "<=", 3, 2, false },
    }) do
        luaunit.assertEquals(self:result(case[1], case[2], case[3]), case[4])
    end
end

function TestCompare:testNativeSemanticsAndDefaultEquality()
    -- An omitted operation is ==. Compare reads numbers.
    luaunit.assertTrue(self:result(nil, 4, 4))
    luaunit.assertFalse(self:result(nil, 4, 5))
    luaunit.assertTrue(self:result("==", 0, 0))
    luaunit.assertTrue(self:result("!=", 1, 2))
    luaunit.assertFalse(self:result("==", 2, 3))
    luaunit.assertTrue(self:result("<", 1, 2))
    luaunit.assertFalse(self:result(">", 1, 2))
end

function TestCompare:testDescriptionSaysCompareComparesTwoNumbers()
    luaunit.assertEquals(
        self.registry:GetNodeType("std.compare").description,
        "Compare two numbers.")
end

function TestCompare:testNewCompareStoresZeroOnBothInputs()
    local id = self.graph:AddNode("std.compare")
    luaunit.assertEquals(self.graph:GetControl(id, "a"), 0)
    luaunit.assertEquals(self.graph:GetControl(id, "b"), 0)
    luaunit.assertEquals(self.graph:GetControl(id, "operation"), "==")
    local operation = self.registry:GetNodeType("std.compare").pins.operation
    luaunit.assertEquals(operation.dataType, "compareOperation")
    luaunit.assertEquals(operation.default, "==")
end

function TestCompare:_source(tag)
    local key = "test.source." .. tag
    self.registry:RegisterNodeType(key, {
        category = "test",
        pins = { { name = "result", kind = "data", direction = "out", dataType = tag } },
        run = function() end,
    })
    return self.graph:AddNode(key)
end

function TestCompare:testNewWireRequiresNumberSource()
    local compare = self.graph:AddNode("std.compare")
    local flag = self:_source("bool")
    local text = self:_source("string")
    for _, pinName in ipairs({ "a", "b" }) do
        local _, boolReason = self.graph:Connect(flag, "result", compare, pinName)
        luaunit.assertEquals(boolReason, "type_mismatch")
        local _, stringReason = self.graph:Connect(text, "result", compare, pinName)
        luaunit.assertEquals(stringReason, "type_mismatch")
    end
    local anySource = self:_source("any")
    for _, pinName in ipairs({ "a", "b" }) do
        local anyWire, anyReason = self.graph:Connect(anySource, "result", compare, pinName)
        luaunit.assertNil(anyWire)
        luaunit.assertEquals(anyReason, "type_mismatch")
    end
    local numberWire = self.graph:Connect(self:_source("number"), "result", compare, "a")
    luaunit.assertNotNil(numberWire)
end

function TestCompare:testLegacyGraphsRetainDefaultsConnectionsAndBehavior()
    -- Old saved records omit unset controls. Numeric legacy pins still default to 0.
    local saved = { version = 1, nodes = {}, connections = {
        { fromNode = 7, fromPin = "result", toNode = 8, toPin = "a" },
    } }
    for id, key in ipairs({ "std.equals", "std.notequals", "std.greaterthan",
        "std.lessthan", "std.greaterorequal", "std.lessorequal" }) do
        saved.nodes[id] = { id = id, type = key, controls = {} }
    end
    saved.nodes[7] = { id = 7, type = "std.greaterthan", controls = { a = 3, b = 2 } }
    saved.nodes[8] = { id = 8, type = "std.equals", controls = { b = true } }
    local restored = Serialize.Deserialize(saved, self.registry)
    for id, expected in ipairs({ true, false, false, false, true, true, true, true }) do
        restored:Fire(id)
        luaunit.assertEquals(restored:GetLastValue(id, "result"), expected)
        luaunit.assertEquals(restored.nodes[id].typeKey, saved.nodes[id].type)
    end
    for id = 3, 6 do
        luaunit.assertEquals(restored:GetControl(id, "a"), 0)
        luaunit.assertEquals(restored:GetControl(id, "b"), 0)
    end
    luaunit.assertEquals(Serialize.Serialize(restored).connections, saved.connections)
end

function TestCompare:testSavedNonNumberWireIntoCompareIsNotKept()
    self.registry:RegisterNodeType("test.flag", {
        category = "test",
        pins = { { name = "result", kind = "data", direction = "out", dataType = "bool" } },
        run = function(ctx)
            ctx:Out("result", true)
        end,
    })
    local saved = {
        version = 1,
        nodes = {
            { id = 1, type = "test.flag", controls = {} },
            { id = 2, type = "std.compare", controls = { b = true } },
        },
        connections = {
            { fromNode = 1, fromPin = "result", toNode = 2, toPin = "a" },
        },
    }
    luaunit.assertErrorMsgContains("type_mismatch", function()
        Serialize.Deserialize(saved, self.registry)
    end)
    local restored = Serialize.Deserialize(saved, self.registry, { onUnknown = "placeholder" })
    luaunit.assertEquals(Serialize.Serialize(restored).connections, {})
    luaunit.assertEquals(restored:GetControl(2, "b"), true)
end

function TestCompare:testSavedNonNumberWireIntoHiddenGreaterThanIsNotKept()
    self.registry:RegisterNodeType("test.flag", {
        category = "test",
        pins = { { name = "result", kind = "data", direction = "out", dataType = "bool" } },
        run = function(ctx)
            ctx:Out("result", true)
        end,
    })
    local saved = {
        version = 1,
        nodes = {
            { id = 1, type = "test.flag", controls = {} },
            { id = 2, type = "std.greaterthan", controls = { b = 1 } },
        },
        connections = {
            { fromNode = 1, fromPin = "result", toNode = 2, toPin = "a" },
        },
    }
    luaunit.assertErrorMsgContains("type_mismatch", function()
        Serialize.Deserialize(saved, self.registry)
    end)
    local restored = Serialize.Deserialize(saved, self.registry, { onUnknown = "placeholder" })
    luaunit.assertEquals(Serialize.Serialize(restored).connections, {})
end

function TestCompare:testChangingOperationPreservesWiredInputs()
    self.registry:RegisterNodeType("test.number", {
        category = "test",
        pins = {
            { name = "n", kind = "data", direction = "in", dataType = "number", default = 0 },
            { name = "result", kind = "data", direction = "out", dataType = "number" },
        },
        run = function(ctx)
            ctx:Out("result", ctx:In("n"))
        end,
    })
    local left = self.graph:AddNode("test.number", { n = 3 })
    local right = self.graph:AddNode("test.number", { n = 3 })
    local target = self.graph:AddNode("std.compare")
    self.graph:Connect(left, "result", target, "a")
    self.graph:Connect(right, "result", target, "b")
    local connections = Serialize.Serialize(self.graph).connections
    self.graph:Fire(target)
    luaunit.assertTrue(self.graph:GetLastValue(target, "result"))
    self.graph:SetControl(target, "operation", "!=")
    self.graph = Serialize.Deserialize(Serialize.Serialize(self.graph), self.registry)
    luaunit.assertEquals(Serialize.Serialize(self.graph).connections, connections)
    self.graph:Fire(target)
    luaunit.assertFalse(self.graph:GetLastValue(target, "result"))
end

function TestCompare:testPublicRegistrationExposesCompareAndHidesLegacyTypes()
    local registry = Registry.new()
    require("main").Register(registry)
    luaunit.assertEquals(registry:GetNodeType("std.compare").category, "boolean")
    luaunit.assertFalse(registry:GetNodeType("std.compare").hidden)
    luaunit.assertEquals(registry:GetNodeTypesByCategory("compare"), {})
    for _, key in ipairs({ "std.equals", "std.notequals", "std.greaterthan",
        "std.lessthan", "std.greaterorequal", "std.lessorequal" }) do
        luaunit.assertTrue(registry:GetNodeType(key).hidden)
    end
end

return TestCompare
