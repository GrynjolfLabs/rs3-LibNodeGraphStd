local luaunit = require("luaunit")
local Registry = require("registry")
local Graph = require("graph")
local Convert = require("convert")

TestConvert = {}

function TestConvert:setUp()
    self.registry = Registry.new()
    Convert.Register(self.registry)
    self.graph = Graph.new(self.registry)
end

function TestConvert:_eval(typeKey, controls)
    local id = self.graph:AddNode(typeKey, controls)
    self.graph:Fire(id)
    return self.graph:GetLastValue(id, "result")
end

function TestConvert:testToString()
    luaunit.assertEquals(self:_eval("std.tostring", { value = 5 }), "5")
    luaunit.assertEquals(self:_eval("std.tostring", { value = true }), "true")
end

function TestConvert:testToNumber()
    luaunit.assertEquals(self:_eval("std.tonumber", { value = "42" }), 42)
end

function TestConvert:testToNumberFallsBackToZeroOnUnparsableInput()
    luaunit.assertEquals(self:_eval("std.tonumber", { value = "not a number" }), 0)
end

return TestConvert
