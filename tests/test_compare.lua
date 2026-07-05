local luaunit = require("luaunit")
local Registry = require("registry")
local Graph = require("graph")
local Compare = require("compare")

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

return TestCompare
