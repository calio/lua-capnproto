local ffi = require "ffi"
local bit = require "bit"
local capnp = require "capnp"
local cjson = require "cjson"

local tobit = bit.tobit
local bnot = bit.bnot
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local _M = {}

-- works only with Little Endian
assert(ffi.abi("le") == true)



function serialize_header(segs, sizes)
    assert(type(sizes) == "table")
    -- in bytes
    local size = 4 + segs * 4
    local words = math.ceil(size / 64)
    local buf = ffi.new("int32_t[?]", words * 2)

    buf[0] = segs - 1
    for i=1, segs do
        buf[i] = assert(math.ceil(sizes[i]/8))
    end

    return ffi.string(ffi.cast("char *", buf), size)
end

_M.serialize = function (msg)
    local segment = assert(rawget(msg, "segment"))
    --local msg_size = (T.dataWordCount + 1) * 8
    return serialize_header(1, { segment.pos }) .. ffi.string(segment.data, segment.pos)
end

function bwrite_listp(buf, elm_size, nelm, offset)
    buf.data[0] = 0x0000000000000001
    local p = ffi.cast("int32_t *", buf.data)
    --local offset = buf.offset -- FIXME
    p[0] = bor(tonumber(p[0]), lshift(offset, 2))
    p[1] = lshift(T.pointerCount, 16) + T.dataWordCount

    buf.offset = buf.offset + math.ceil(elm_size * nelm/64)
end

function list_newindex(t, k, v)
    local num = assert(rawget(t, "num"))

    if k > num then
        error("access out of boundry")
    end

    assert(k > 0)
    local data = assert(rawget(t, "data"))
    local actual_size = assert(rawget(t, "actual_size"))

    print("list_newindex", k, v, num, actual_size)

    if actual_size == 0 then
        -- do nothing
    elseif actual_size == 0.125 then
        if v == 1 then
            local n = math.floor(k / 8)
            local s = k % 8
            data[n] = bor(data[n], lshift(1, s))
        end
    else
        data[k - 1] = v
    end
end

function msg_newindex(t, k, v)
    --print(string.format("%s, %s\n", k, v))
    local T = rawget(t, "T")
    local schema = T.fields
    local field = schema[k]

    -- TODO deal with unknown value
    if field.is_enum then
        v = capnp.get_enum_val(v, field.enum_name, T)
    end

    local size = assert(field.size)
    local offset = assert(field.offset)
    if field.is_pointer then
        ftype = schema[k].ftype
        if ftype == "data" then
            error("not implemented")
            --bwrite_listp(rawget(t, "pointer_pos"), 1, #v, )
        end
    else
        capnp.write_val(rawget(t, "data_pos"), v, size, offset)
    end
end

------------------------------------------------------------------

_M.T1 = {
    T2 = {
        id = 13624321058757364083,
        displayName = "test.capnp:T1.T2",
        dataWordCount = 2,
        pointerCount = 0,
        fields = {
            f0 = { size = 32, offset = 0 },
            f1 = { size = 64, offset = 1 },
        }

    },
    EnumType1 = {
        enum1 = 0,
        enum2 = 1,
        enum3 = 2,
    },
    id = 13624321058757364083,
    displayName = "test.capnp:T1",
    dataWordCount = 2,
    pointerCount = 2,
    fields = {
        i0 = { size = 32, offset = 0 },
        i1 = { size = 16, offset = 2 },
        i2 = { size = 8, offset = 7 },
        b0 = { size = 1, offset = 48 },
        b1 = { size = 1, offset = 49 },
        i3 = { size = 32, offset = 2 },
        e0 = { enum_name = "EnumType1", is_enum = true, size = 16, offset = 6 }, -- enum size 16
        s0 = { is_pointer = true, offset = 0 },
        t0 = { is_pointer = true, ftype = "text" },
        l0 = { is_pointer = true, size = 2, offset = 1 }, -- size: list item size
    },

    serialize = function(message)
        return rawget(messaga)
    end
    ,

    new = function(self)

        -- FIXME size
        local segment = capnp.new_segment(8000)
        local struct = capnp.init_root(segment, self)

        -- list
        struct.init_l0 = function(self, num)
            assert(num)
            local segment = assert(rawget(self, "segment"))
            local data_pos = assert(rawget(self, "pointer_pos")) + 1 * 8 -- l0.offset * l0.size (pointer size is 8)
            local data_off = ((segment.data + segment.pos) - (data_pos + 8)) / 8 -- unused memory pos - list pointer end pos, result in bytes. So we need to divide this value by 8 to get word offset

            print(num, data_off)
            capnp.write_listp(data_pos, 2, num,  data_off) -- 2: l0.size

            local l = capnp.write_list(segment, 2, num) -- 2: l0.size

            local mt = {
                __newindex =  list_newindex
            }
            return setmetatable(l, mt)
        end

        -- sub struct
        struct.init_s0 = function(self)
            local segment = assert(rawget(self, "segment"))

            local data_pos = assert(rawget(self, "pointer_pos")) + 0 * 8 -- s0.offset * s0.size (pointer size is 8) 
            local data_off = ((segment.data + segment.pos) - (data_pos + 8)) / 8 -- unused memory pos - struct pointer end pos
            capnp.write_structp(data_pos, self.T.T2, data_off)

            print(data_off)
            --local s = init_root(segment, self.T2)
            local s =  capnp.write_struct(segment, self.T.T2)
            local mt = {
                __newindex =  msg_newindex
            }
            return setmetatable(s, mt)
        end

        local mt = {
            __newindex =  msg_newindex
        }
        return setmetatable(struct, mt)
    end
}

return _M
