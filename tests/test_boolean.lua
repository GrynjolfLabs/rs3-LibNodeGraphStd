local luaunit = require("luaunit")
local Registry = require("registry")
local Graph = require("graph")
local Boolean = require("boolean")

TestBoolean = {}

function TestBoolean:setUp()
    self.registry = Registry.new()
    Boolean.Register(self.registry)
    self.graph = Graph.new(self.registry)
end

function TestBoolean:_eval(typeKey, controls)
    local id = self.graph:AddNode(typeKey, controls)
    self.graph:Fire(id)
    return self.graph:GetLastValue(id, "result")
end

function TestBoolean:testAnd()
    luaunit.assertTrue(self:_eval("std.and", { a = true, b = true }))
    luaunit.assertFalse(self:_eval("std.and", { a = true, b = false }))
end

function TestBoolean:testOr()
    luaunit.assertTrue(self:_eval("std.or", { a = false, b = true }))
    luaunit.assertFalse(self:_eval("std.or", { a = false, b = false }))
end

function TestBoolean:testNot()
    luaunit.assertFalse(self:_eval("std.not", { ["in"] = true }))
    luaunit.assertTrue(self:_eval("std.not", { ["in"] = false }))
end

function TestBoolean:testXor()
    luaunit.assertTrue(self:_eval("std.xor", { a = true, b = false }))
    luaunit.assertFalse(self:_eval("std.xor", { a = true, b = true }))
end

return TestBoolean
