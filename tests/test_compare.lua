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
    luaunit.assertTrue(self:result(nil, "hello", "hello"))
    luaunit.assertTrue(self:result("==", nil, nil))
    luaunit.assertTrue(self:result("!=", true, false))
    luaunit.assertFalse(self:result("==", "2", 2))
    luaunit.assertTrue(self:result("<", "a", "b"))
    luaunit.assertError(function() self:result(">", "2", 1) end)
    luaunit.assertError(function() self:result("<", nil, 1) end)
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

function TestCompare:testChangingOperationPreservesWiredInputs()
    local source = self.graph:AddNode("std.greaterthan", { a = 3, b = 2 })
    local target = self.graph:AddNode("std.compare", { b = true })
    self.graph:Connect(source, "result", target, "a")
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
