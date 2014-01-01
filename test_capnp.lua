local ffi = require "ffi"
local capnp = require "capnp"


local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(2, 8)



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
    pointerCount = 3,
    fields = {
        i0 = { size = 32, offset = 0 },
        i1 = { size = 16, offset = 2 },
        i2 = { size = 8, offset = 7 },
        b0 = { size = 1, offset = 48 },
        b1 = { size = 1, offset = 49 },
        i3 = { size = 32, offset = 2 },
        e0 = { enum_name = "EnumType1", is_enum = true, size = 16, offset = 6 }, -- enum size 16
        s0 = { is_pointer = true, offset = 0 },
        l0 = { is_pointer = true, size = 2, offset = 1 }, -- size: list item size id, not actual size
        t0 = { is_pointer = true, is_data = true, size = 2, offset = 2 },
    },

    new = function(self)

        -- FIXME size
        local segment = capnp.new_segment(8000)
        local struct = capnp.init_root(segment, self)

        -- list
        struct.init_l0 = function(self, num)
            assert(num)
            local segment = self.segment
            local data_pos = self.pointer_pos + 1 * 8 -- l0.offset * l0.size (pointer size is 8)
            local data_off = ((segment.data + segment.pos) - (data_pos + 8)) / 8 -- unused memory pos - list pointer end pos, result in bytes. So we need to divide this value by 8 to get word offset

            --print(num, data_off)
            capnp.write_listp(data_pos, 2, num,  data_off) -- 2: l0.size

            local l = capnp.write_list(segment, 2, num) -- 2: l0.size

            local mt = {
                __newindex =  capnp.list_newindex
            }
            return setmetatable(l, mt)
        end

        -- sub struct
        struct.init_s0 = function(self)
            local segment = self.segment

            local data_pos = self.pointer_pos + 0 * 8 -- s0.offset * s0.size (pointer size is 8) 
            local data_off = ((segment.data + segment.pos) - (data_pos + 8)) / 8 -- unused memory pos - struct pointer end pos
            capnp.write_structp(data_pos, self.T.T2, data_off)

            --print(data_off)
            --local s = init_root(segment, self.T2)
            local s =  capnp.write_struct(segment, self.T.T2)
            local mt = {
                __newindex =  capnp.struct_newindex
            }
            return setmetatable(s, mt)
        end

        struct.serialize = function(self)
            return capnp.serialize(self)
        end

        local mt = {
            __newindex = capnp.struct_newindex
        }
        return setmetatable(struct, mt)
    end
}

return _M
