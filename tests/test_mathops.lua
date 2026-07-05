local luaunit = require("luaunit")
local Registry = require("registry")
local Graph = require("graph")
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

return TestMathOps
