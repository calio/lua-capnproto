local bit = require("bit")
local band = bit.band
local rshift = bit.rshift
local lshift = bit.lshift

local i = 1
local A, B, C, D
local num = {}
for d in string.gmatch(arg[1], "%x%x") do
    d = tonumber("0x" .. d)
    num[#num + 1] = d
end

local sig = band(3, num[1])
A = sig


B = rshift(num[1], 2)
for i = 2, 4 do
    B = B + lshift(num[i], 6 * (i - 1))
end

if A == 0 then
    C = num[5] + lshift(num[6], 8)
    D = num[7] + lshift(num[8], 8)
    print(string.format("struct:%d, offset: %d, dw: %d, pw: %d", A, B, C, D))
elseif A == 1 then
    C = band(7, num[5])
    D = rshift(num[5], 3)
    for i = 6, 8 do
        D = D + lshift(num[i], 5 * (i - 1))
    end
    print(string.format("list:%d, offset: %d, size_type: %d, num: %d", A, B, C, D))
else
    print("not supported sig:", A)
end

