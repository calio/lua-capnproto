local ffi = require "ffi" local capnp = require "capnp" 

local ceil      = math.ceil
local floor     = math.floor

local ok, new_tab = pcall(require, "table.new")

if not ok then
    new_tab = function (narr, nrec) return {} end
end

local round8 = function(size)
    return ceil(size / 8) * 8
end

local _M = new_tab(2, 8)

function _M.init(T)
    local segment = capnp.new_segment()
    return T:init(segment)
end

_M.T1 = {
    id = 13624321058757364083,
    displayName = "proto/test.capnp:T1",
    dataWordCount = 2,
    pointerCount = 3,
    fields = {
        i0 = { size = 32, offset = 0 },
        i1 = { size = 16, offset = 2 },
        b0 = { size = 1, offset = 48 },
        i2 = { size = 8, offset = 7 },
        b1 = { size = 1, offset = 49 },
        i3 = { size = 32, offset = 2 },
        s0 = { size = 8, offset = 0, is_pointer = true, },
        e0 = { size = 16, offset = 6, is_enum = true,  }, -- enum size 16
        l0 = { size = 2, offset = 1, is_pointer = true,  }, -- size: list item size id, not actual size
        t0 = { size = 2, offset = 2, is_text = true,  },
        e1 = { size = 16, offset = 7, is_enum = true,  }
    },

    init = function(self, segment, data_pos)
        if not data_pos then
            data_pos = segment.data
            segment.pos = segment.pos + 8
        end
        local struct = capnp.write_struct(data_pos, segment, self)

        ------------------ structs -------------------
        struct.set_i0 = function(self, val)
            capnp.write_val(self.data_pos, val, 32, 0)
        end

        struct.set_i1 = function(self, val)
            capnp.write_val(self.data_pos, val, 16, 2)
        end

        struct.set_b0 = function(self, val)
            capnp.write_val(self.data_pos, val, 1, 48)
        end

        struct.set_i2 = function(self, val)
            capnp.write_val(self.data_pos, val, 8, 7)
        end

        struct.set_b1 = function(self, val)
            capnp.write_val(self.data_pos, val, 1, 49)
        end

        struct.set_i3 = function(self, val)
            capnp.write_val(self.data_pos, val, 32, 2)
        end
        ------------------ enums ---------------------
        struct.set_e0 = function(self, val)
            val = capnp.get_enum_val(val, _M.T1.EnumType1)
            capnp.write_val(self.data_pos, val, 16, 6)
        end

        struct.set_e1 = function(self, val)
            val = capnp.get_enum_val(val, _M.EnumType2)
            capnp.write_val(self.data_pos, val, 16, 7)
        end
        ------------------ text ----------------------
        struct.set_t0 = function(self, val)
            local data_pos = self.pointer_pos + 2 * 8 -- pointer size is 8
            -- list data includes the trailing NULL
            local l = capnp.write_list(data_pos, self.segment, 2, #val + 1)
            ffi.copy(l.data, val)
        end
        -- sub struct
        struct.init_s0 = function(self)
            local segment = self.segment
            local T = self.schema.T1.T2

            local data_pos = self.pointer_pos + 0 * 8 -- s0.offset * s0.size (pointer size is 8)
            return T:init(segment, data_pos)
        end
        -- list
        struct.init_l0 = function(self, num)
            assert(num)
            local segment = self.segment
            local data_pos = self.pointer_pos + 1 * 8 -- l0.offset * l0.size (pointer size is 8)
            local l = capnp.write_list(data_pos, segment, 2, num) -- 2: l0.size_type

            return capnp.init_new_list(l, _M)
        end

        return capnp.init_new_struct(struct, _M)
    end
}



_M.T1.T2 = {
    id = 17202330444354522981,
    displayName = "proto/test.capnp:T1.T2",
    dataWordCount = 2,
    pointerCount = 0,
    fields = {
        f0 = { size = 32, offset = 0 },
        f1 = { size = 64, offset = 1 },
    },

    init = function(self, segment, data_pos)
        if not data_pos then
            data_pos = segment.data
            segment.pos = segment.pos + 8
        end
        local struct = capnp.write_struct(data_pos, segment, self)

        struct.set_f0 = function(self, val)
            capnp.write_val(self.data_pos, val, 32, 0)
        end

        struct.set_f1 = function(self, val)
            capnp.write_val(self.data_pos, val, 64, 1)
        end

        return capnp.init_new_struct(struct, _M)
    end
}

_M.T1.EnumType1 = {
    enum1 = 0,
    enum2 = 1,
    enum3 = 2,
}
_M.EnumType2 = {
    enum5 = 0,
    enum6 = 1,
    enum7 = 2,
}

_M.T1.fields.e0.enum_schema = _M.T1.EnumType1
_M.T1.fields.e1.enum_schema = _M.EnumType2

return _M
