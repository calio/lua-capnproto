local rand = require("random")
local cjson = require("cjson")

local ok, new_tab = pcall(require, "table.new")

if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = {}

function _M.gen()
    local r = new_tab(0, 8)

    r.i0 = rand.uint32()
    r.i1 = rand.uint16()
    r.i2 = rand.int8()
    r.b0 = rand.bool()
    r.b1 = rand.bool()
    r.i3 = rand.int32()

    local s0 = {}
    s0.f0 = rand.float32()
    s0.f1 = rand.float64()
    r.s0 = s0

    -- r.e0
    r.l0 = rand.list(rand.uint8(), rand.int8)
    r.t0 = rand.text()
    -- r.e1
    return r
end

print(cjson.encode(_M.gen()))
return _M
