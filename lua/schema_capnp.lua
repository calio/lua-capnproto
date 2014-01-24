-- require "luacov"
local ffi = require "ffi"
local capnp = require "capnp"
local bit = require "bit"
local util = require "util"

local ceil              = math.ceil
local write_val         = capnp.write_val
local read_val          = capnp.read_val
local get_enum_val      = capnp.get_enum_val
local get_data_off      = capnp.get_data_off
local write_listp_buf   = capnp.write_listp_buf
local write_structp_buf = capnp.write_structp_buf
local write_structp     = capnp.write_structp
local parse_struct_buf  = capnp.parse_struct_buf
local parse_listp_buf   = capnp.parse_listp_buf
local parse_list_data   = capnp.parse_list_data
local ffi_new           = ffi.new
local ffi_string        = ffi.string
local ffi_cast          = ffi.cast
local ffi_copy          = ffi.copy
local ffi_fill          = ffi.fill

local ok, new_tab = pcall(require, "table.new")

if not ok then
    new_tab = function (narr, nrec) return {} end
end

local round8 = function(size)
    return ceil(size / 8) * 8
end

local str_buf
local default_segment_size = 4096

local function get_str_buf(size)
    if size > default_segment_size then
        return ffi_new("char[?]", size)
    end

    if not str_buf then
        str_buf = ffi_new("char[?]", default_segment_size)
    end
    return str_buf
end

local _M = new_tab(2, 8)

_M.Node = {
    id = 16610026722781537303,
    displayName = "proto/schema.capnp:Node",
    dataWordCount = 5,
    pointerCount = 5,
    discriminantCount = 6,
    discriminantOffset = 6,
    calc_size_struct = function(data)
        local size = 80
        -- text
        if data.display_name then
            size = size + round8(#data.display_name + 1) -- size 1, including trailing NULL
        end
        -- composite list
        if data.nested_nodes then
            size = size + 8
            local num = #data.nested_nodes
            for i=1, num do
                size = size + _M.Node.NestedNode.calc_size_struct(data.nested_nodes[i])
            end
        end
        -- composite list
        if data.annotations then
            size = size + 8
            local num = #data.annotations
            for i=1, num do
                size = size + _M.Annotation.calc_size_struct(data.annotations[i])
            end
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.Node.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.id and (type(data.id) == "number"
                or type(data.id) == "boolean") then

            write_val(buf, data.id, 64, 0)
        end
        if data.display_name and type(data.display_name) == "string" then
            local data_off = get_data_off(_M.Node, 0, pos)

            local len = #data.display_name + 1
            write_listp_buf(buf, _M.Node, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.display_name)
            pos = pos + round8(len)
        end
        if data.display_name_prefix_length and (type(data.display_name_prefix_length) == "number"
                or type(data.display_name_prefix_length) == "boolean") then

            write_val(buf, data.display_name_prefix_length, 32, 2)
        end
        if data.scope_id and (type(data.scope_id) == "number"
                or type(data.scope_id) == "boolean") then

            write_val(buf, data.scope_id, 64, 2)
        end
        if data.nested_nodes and type(data.nested_nodes) == "table" then
            local num, size, old_pos = #data.nested_nodes, 0, pos
            local data_off = get_data_off(_M.Node, 1, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Node.NestedNode, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Node.NestedNode.flat_serialize(data.nested_nodes[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Node, 1, 7, (pos - old_pos - 8) / 8, data_off)
        end
        if data.annotations and type(data.annotations) == "table" then
            local num, size, old_pos = #data.annotations, 0, pos
            local data_off = get_data_off(_M.Node, 2, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Annotation, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Annotation.flat_serialize(data.annotations[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Node, 2, 7, (pos - old_pos - 8) / 8, data_off)
        end
        if data.file then
            dscrm = 0
        end

        if data.struct then
            dscrm = 1
        end

        if data.struct and type(data.struct) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Node.struct.flat_serialize(data.struct, buf)
        end

        if data.enum then
            dscrm = 2
        end

        if data.enum and type(data.enum) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Node.enum.flat_serialize(data.enum, buf)
        end

        if data.interface then
            dscrm = 3
        end

        if data.interface and type(data.interface) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Node.interface.flat_serialize(data.interface, buf)
        end

        if data.const then
            dscrm = 4
        end

        if data.const and type(data.const) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Node.const.flat_serialize(data.const, buf)
        end

        if data.annotation then
            dscrm = 5
        end

        if data.annotation and type(data.annotation) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Node.annotation.flat_serialize(data.annotation, buf)
        end

        if dscrm then
            _M.Node.which(buf, 6, dscrm) --buf, discriminantOffset, discriminantValue
        end

        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.Node.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.Node, 0)
        _M.Node.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    which = function(buf, offset, n)
        if n then
            -- set value
            write_val(buf, n, 16, offset)
        else
            -- get value
            return read_val(buf, "uint16", 16, offset)
        end
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local dscrm = _M.Node.which(buf, 6) --buf, dscrmriminantOffset, dscrmriminantValue

        s.id = read_val(buf, "uint64", 64, 0)

        local off, size, num = parse_listp_buf(buf, header, _M.Node, 0)
        if off and num then
            s.display_name = ffi.string(buf + (5 + 0 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.display_name = nil
        end
        s.display_name_prefix_length = read_val(buf, "uint32", 32, 2)
        s.scope_id = read_val(buf, "uint64", 64, 2)

        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Node, 1)
        if off and words then
            local start = (5 + 1 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.nested_nodes then
                s.nested_nodes = new_tab(num, 0)
            end
            for i=1, num do
                if not s.nested_nodes[i] then
                    s.nested_nodes[i] = new_tab(0, 2)
                end
                _M.Node.NestedNode.parse_struct_data(buf + start, dt, pt, header, s.nested_nodes[i])
                start = start + (dt + pt) * 2
            end
        else
            s.nested_nodes = nil
        end
        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Node, 2)
        if off and words then
            local start = (5 + 2 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.annotations then
                s.annotations = new_tab(num, 0)
            end
            for i=1, num do
                if not s.annotations[i] then
                    s.annotations[i] = new_tab(0, 2)
                end
                _M.Annotation.parse_struct_data(buf + start, dt, pt, header, s.annotations[i])
                start = start + (dt + pt) * 2
            end
        else
            s.annotations = nil
        end
        if dscrm == 0 then
        s.file = read_val(buf, "void", 0, 0)

        else
            s.file = nil
        end

        if dscrm == 1 then

        if not s.struct then
            s.struct = new_tab(0, 4)
        end
        _M.Node.struct.parse_struct_data(buf, _M.Node.dataWordCount, _M.Node.pointerCount,
                header, s.struct)

        else
            s.struct = nil
        end

        if dscrm == 2 then

        if not s.enum then
            s.enum = new_tab(0, 4)
        end
        _M.Node.enum.parse_struct_data(buf, _M.Node.dataWordCount, _M.Node.pointerCount,
                header, s.enum)

        else
            s.enum = nil
        end

        if dscrm == 3 then

        if not s.interface then
            s.interface = new_tab(0, 4)
        end
        _M.Node.interface.parse_struct_data(buf, _M.Node.dataWordCount, _M.Node.pointerCount,
                header, s.interface)

        else
            s.interface = nil
        end

        if dscrm == 4 then

        if not s.const then
            s.const = new_tab(0, 4)
        end
        _M.Node.const.parse_struct_data(buf, _M.Node.dataWordCount, _M.Node.pointerCount,
                header, s.const)

        else
            s.const = nil
        end

        if dscrm == 5 then

        if not s.annotation then
            s.annotation = new_tab(0, 4)
        end
        _M.Node.annotation.parse_struct_data(buf, _M.Node.dataWordCount, _M.Node.pointerCount,
                header, s.annotation)

        else
            s.annotation = nil
        end

        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.Node.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.Node.NestedNode = {
    id = 16050641862814319170,
    displayName = "proto/schema.capnp:Node.NestedNode",
    dataWordCount = 1,
    pointerCount = 1,
    calc_size_struct = function(data)
        local size = 16
        -- text
        if data.name then
            size = size + round8(#data.name + 1) -- size 1, including trailing NULL
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.Node.NestedNode.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 16
        local dscrm
        if data.name and type(data.name) == "string" then
            local data_off = get_data_off(_M.Node.NestedNode, 0, pos)

            local len = #data.name + 1
            write_listp_buf(buf, _M.Node.NestedNode, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.name)
            pos = pos + round8(len)
        end
        if data.id and (type(data.id) == "number"
                or type(data.id) == "boolean") then

            write_val(buf, data.id, 64, 0)
        end
        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.Node.NestedNode.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.Node.NestedNode, 0)
        _M.Node.NestedNode.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local off, size, num = parse_listp_buf(buf, header, _M.Node.NestedNode, 0)
        if off and num then
            s.name = ffi.string(buf + (1 + 0 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.name = nil
        end
        s.id = read_val(buf, "uint64", 64, 0)

        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.Node.NestedNode.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.Node.struct = {
    id = 11430331134483579957,
    displayName = "proto/schema.capnp:Node.struct",
    dataWordCount = 5,
    pointerCount = 5,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.data_word_count and (type(data.data_word_count) == "number"
                or type(data.data_word_count) == "boolean") then

            write_val(buf, data.data_word_count, 16, 7)
        end
        if data.pointer_count and (type(data.pointer_count) == "number"
                or type(data.pointer_count) == "boolean") then

            write_val(buf, data.pointer_count, 16, 12)
        end
        if data.preferred_list_encoding and type(data.preferred_list_encoding) == "string" then
            local val = get_enum_val(data.preferred_list_encoding, _M.ElementSize, "Node.struct.preferred_list_encoding")
            write_val(buf, val, 16, 13)
        end
        if data.is_group and (type(data.is_group) == "number"
                or type(data.is_group) == "boolean") then

            write_val(buf, data.is_group, 1, 224)
        end
        if data.discriminant_count and (type(data.discriminant_count) == "number"
                or type(data.discriminant_count) == "boolean") then

            write_val(buf, data.discriminant_count, 16, 15)
        end
        if data.discriminant_offset and (type(data.discriminant_offset) == "number"
                or type(data.discriminant_offset) == "boolean") then

            write_val(buf, data.discriminant_offset, 32, 8)
        end
        if data.fields and type(data.fields) == "table" then
            local num, size, old_pos = #data.fields, 0, pos
            local data_off = get_data_off(_M.Node.struct, 3, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Field, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Field.flat_serialize(data.fields[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Node.struct, 3, 7, (pos - old_pos - 8) / 8, data_off)
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab
        s.data_word_count = read_val(buf, "uint16", 16, 7)
        s.pointer_count = read_val(buf, "uint16", 16, 12)
        local val = read_val(buf, "uint16", 16, 13)
        s.preferred_list_encoding = get_enum_val(val, _M.ElementSizeStr)
        s.is_group = read_val(buf, "bool", 1, 224)
        s.discriminant_count = read_val(buf, "uint16", 16, 15)
        s.discriminant_offset = read_val(buf, "uint32", 32, 8)

        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Node.struct, 3)
        if off and words then
            local start = (5 + 3 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.fields then
                s.fields = new_tab(num, 0)
            end
            for i=1, num do
                if not s.fields[i] then
                    s.fields[i] = new_tab(0, 2)
                end
                _M.Field.parse_struct_data(buf + start, dt, pt, header, s.fields[i])
                start = start + (dt + pt) * 2
            end
        else
            s.fields = nil
        end
        return s
    end,
}
_M.Node.enum = {
    id = 13063450714778629528,
    displayName = "proto/schema.capnp:Node.enum",
    dataWordCount = 5,
    pointerCount = 5,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.enumerants and type(data.enumerants) == "table" then
            local num, size, old_pos = #data.enumerants, 0, pos
            local data_off = get_data_off(_M.Node.enum, 3, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Enumerant, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Enumerant.flat_serialize(data.enumerants[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Node.enum, 3, 7, (pos - old_pos - 8) / 8, data_off)
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Node.enum, 3)
        if off and words then
            local start = (5 + 3 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.enumerants then
                s.enumerants = new_tab(num, 0)
            end
            for i=1, num do
                if not s.enumerants[i] then
                    s.enumerants[i] = new_tab(0, 2)
                end
                _M.Enumerant.parse_struct_data(buf + start, dt, pt, header, s.enumerants[i])
                start = start + (dt + pt) * 2
            end
        else
            s.enumerants = nil
        end
        return s
    end,
}
_M.Node.interface = {
    id = 16728431493453586831,
    displayName = "proto/schema.capnp:Node.interface",
    dataWordCount = 5,
    pointerCount = 5,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.methods and type(data.methods) == "table" then
            local num, size, old_pos = #data.methods, 0, pos
            local data_off = get_data_off(_M.Node.interface, 3, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Method, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Method.flat_serialize(data.methods[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Node.interface, 3, 7, (pos - old_pos - 8) / 8, data_off)
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Node.interface, 3)
        if off and words then
            local start = (5 + 3 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.methods then
                s.methods = new_tab(num, 0)
            end
            for i=1, num do
                if not s.methods[i] then
                    s.methods[i] = new_tab(0, 2)
                end
                _M.Method.parse_struct_data(buf + start, dt, pt, header, s.methods[i])
                start = start + (dt + pt) * 2
            end
        else
            s.methods = nil
        end
        return s
    end,
}
_M.Node.const = {
    id = 12793219851699983392,
    displayName = "proto/schema.capnp:Node.const",
    dataWordCount = 5,
    pointerCount = 5,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.type and type(data.type) == "table" then
            local data_off = get_data_off(_M.Node.const, 3, pos)
            write_structp_buf(buf, _M.Node.const, _M.Type, 3, data_off)
            local size = _M.Type.flat_serialize(data.type, buf + pos)
            pos = pos + size
        end
        if data.value and type(data.value) == "table" then
            local data_off = get_data_off(_M.Node.const, 4, pos)
            write_structp_buf(buf, _M.Node.const, _M.Value, 4, data_off)
            local size = _M.Value.flat_serialize(data.value, buf + pos)
            pos = pos + size
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local p = buf + (5 + 3) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.type then
                s.type = new_tab(0, 2)
            end
            _M.Type.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.type)
        else
            s.type = nil
        end


        local p = buf + (5 + 4) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.value then
                s.value = new_tab(0, 2)
            end
            _M.Value.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.value)
        else
            s.value = nil
        end


        return s
    end,
}
_M.Node.annotation = {
    id = 17011813041836786320,
    displayName = "proto/schema.capnp:Node.annotation",
    dataWordCount = 5,
    pointerCount = 5,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 80
        local dscrm
        if data.type and type(data.type) == "table" then
            local data_off = get_data_off(_M.Node.annotation, 3, pos)
            write_structp_buf(buf, _M.Node.annotation, _M.Type, 3, data_off)
            local size = _M.Type.flat_serialize(data.type, buf + pos)
            pos = pos + size
        end
        if data.targets_file and (type(data.targets_file) == "number"
                or type(data.targets_file) == "boolean") then

            write_val(buf, data.targets_file, 1, 112)
        end
        if data.targets_const and (type(data.targets_const) == "number"
                or type(data.targets_const) == "boolean") then

            write_val(buf, data.targets_const, 1, 113)
        end
        if data.targets_enum and (type(data.targets_enum) == "number"
                or type(data.targets_enum) == "boolean") then

            write_val(buf, data.targets_enum, 1, 114)
        end
        if data.targets_enumerant and (type(data.targets_enumerant) == "number"
                or type(data.targets_enumerant) == "boolean") then

            write_val(buf, data.targets_enumerant, 1, 115)
        end
        if data.targets_struct and (type(data.targets_struct) == "number"
                or type(data.targets_struct) == "boolean") then

            write_val(buf, data.targets_struct, 1, 116)
        end
        if data.targets_field and (type(data.targets_field) == "number"
                or type(data.targets_field) == "boolean") then

            write_val(buf, data.targets_field, 1, 117)
        end
        if data.targets_union and (type(data.targets_union) == "number"
                or type(data.targets_union) == "boolean") then

            write_val(buf, data.targets_union, 1, 118)
        end
        if data.targets_group and (type(data.targets_group) == "number"
                or type(data.targets_group) == "boolean") then

            write_val(buf, data.targets_group, 1, 119)
        end
        if data.targets_interface and (type(data.targets_interface) == "number"
                or type(data.targets_interface) == "boolean") then

            write_val(buf, data.targets_interface, 1, 120)
        end
        if data.targets_method and (type(data.targets_method) == "number"
                or type(data.targets_method) == "boolean") then

            write_val(buf, data.targets_method, 1, 121)
        end
        if data.targets_param and (type(data.targets_param) == "number"
                or type(data.targets_param) == "boolean") then

            write_val(buf, data.targets_param, 1, 122)
        end
        if data.targets_annotation and (type(data.targets_annotation) == "number"
                or type(data.targets_annotation) == "boolean") then

            write_val(buf, data.targets_annotation, 1, 123)
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local p = buf + (5 + 3) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.type then
                s.type = new_tab(0, 2)
            end
            _M.Type.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.type)
        else
            s.type = nil
        end

        s.targets_file = read_val(buf, "bool", 1, 112)
        s.targets_const = read_val(buf, "bool", 1, 113)
        s.targets_enum = read_val(buf, "bool", 1, 114)
        s.targets_enumerant = read_val(buf, "bool", 1, 115)
        s.targets_struct = read_val(buf, "bool", 1, 116)
        s.targets_field = read_val(buf, "bool", 1, 117)
        s.targets_union = read_val(buf, "bool", 1, 118)
        s.targets_group = read_val(buf, "bool", 1, 119)
        s.targets_interface = read_val(buf, "bool", 1, 120)
        s.targets_method = read_val(buf, "bool", 1, 121)
        s.targets_param = read_val(buf, "bool", 1, 122)
        s.targets_annotation = read_val(buf, "bool", 1, 123)

        return s
    end,
}
_M.Field = {
    id = 11145653318641710175,
    displayName = "proto/schema.capnp:Field",
    dataWordCount = 3,
    pointerCount = 4,
    discriminantCount = 2,
    discriminantOffset = 4,
    calc_size_struct = function(data)
        local size = 56
        -- text
        if data.name then
            size = size + round8(#data.name + 1) -- size 1, including trailing NULL
        end
        -- composite list
        if data.annotations then
            size = size + 8
            local num = #data.annotations
            for i=1, num do
                size = size + _M.Annotation.calc_size_struct(data.annotations[i])
            end
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.Field.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 56
        local dscrm
        if data.name and type(data.name) == "string" then
            local data_off = get_data_off(_M.Field, 0, pos)

            local len = #data.name + 1
            write_listp_buf(buf, _M.Field, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.name)
            pos = pos + round8(len)
        end
        if data.code_order and (type(data.code_order) == "number"
                or type(data.code_order) == "boolean") then

            write_val(buf, data.code_order, 16, 0)
        end
        if data.annotations and type(data.annotations) == "table" then
            local num, size, old_pos = #data.annotations, 0, pos
            local data_off = get_data_off(_M.Field, 1, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Annotation, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Annotation.flat_serialize(data.annotations[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Field, 1, 7, (pos - old_pos - 8) / 8, data_off)
        end
        if data.discriminant_value and (type(data.discriminant_value) == "number"
                or type(data.discriminant_value) == "boolean") then

            write_val(buf, data.discriminant_value, 16, 1)
        end
        if data.slot then
            dscrm = 0
        end

        if data.slot and type(data.slot) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Field.slot.flat_serialize(data.slot, buf)
        end

        if data.group then
            dscrm = 1
        end

        if data.group and type(data.group) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Field.group.flat_serialize(data.group, buf)
        end

        if data.ordinal and type(data.ordinal) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Field.ordinal.flat_serialize(data.ordinal, buf)
        end

        if dscrm then
            _M.Field.which(buf, 4, dscrm) --buf, discriminantOffset, discriminantValue
        end

        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.Field.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.Field, 0)
        _M.Field.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    which = function(buf, offset, n)
        if n then
            -- set value
            write_val(buf, n, 16, offset)
        else
            -- get value
            return read_val(buf, "uint16", 16, offset)
        end
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local dscrm = _M.Field.which(buf, 4) --buf, dscrmriminantOffset, dscrmriminantValue


        local off, size, num = parse_listp_buf(buf, header, _M.Field, 0)
        if off and num then
            s.name = ffi.string(buf + (3 + 0 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.name = nil
        end
        s.code_order = read_val(buf, "uint16", 16, 0)

        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Field, 1)
        if off and words then
            local start = (3 + 1 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.annotations then
                s.annotations = new_tab(num, 0)
            end
            for i=1, num do
                if not s.annotations[i] then
                    s.annotations[i] = new_tab(0, 2)
                end
                _M.Annotation.parse_struct_data(buf + start, dt, pt, header, s.annotations[i])
                start = start + (dt + pt) * 2
            end
        else
            s.annotations = nil
        end        s.discriminant_value = read_val(buf, "uint16", 16, 1)

        if dscrm == 0 then

        if not s.slot then
            s.slot = new_tab(0, 4)
        end
        _M.Field.slot.parse_struct_data(buf, _M.Field.dataWordCount, _M.Field.pointerCount,
                header, s.slot)

        else
            s.slot = nil
        end

        if dscrm == 1 then

        if not s.group then
            s.group = new_tab(0, 4)
        end
        _M.Field.group.parse_struct_data(buf, _M.Field.dataWordCount, _M.Field.pointerCount,
                header, s.group)

        else
            s.group = nil
        end

        if not s.ordinal then
            s.ordinal = new_tab(0, 4)
        end
        _M.Field.ordinal.parse_struct_data(buf, _M.Field.dataWordCount, _M.Field.pointerCount,
                header, s.ordinal)

        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.Field.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.Field.slot = {
    id = 14133145859926553711,
    displayName = "proto/schema.capnp:Field.slot",
    dataWordCount = 3,
    pointerCount = 4,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 56
        local dscrm
        if data.offset and (type(data.offset) == "number"
                or type(data.offset) == "boolean") then

            write_val(buf, data.offset, 32, 1)
        end
        if data.type and type(data.type) == "table" then
            local data_off = get_data_off(_M.Field.slot, 2, pos)
            write_structp_buf(buf, _M.Field.slot, _M.Type, 2, data_off)
            local size = _M.Type.flat_serialize(data.type, buf + pos)
            pos = pos + size
        end
        if data.default_value and type(data.default_value) == "table" then
            local data_off = get_data_off(_M.Field.slot, 3, pos)
            write_structp_buf(buf, _M.Field.slot, _M.Value, 3, data_off)
            local size = _M.Value.flat_serialize(data.default_value, buf + pos)
            pos = pos + size
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab
        s.offset = read_val(buf, "uint32", 32, 1)

        local p = buf + (3 + 2) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.type then
                s.type = new_tab(0, 2)
            end
            _M.Type.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.type)
        else
            s.type = nil
        end


        local p = buf + (3 + 3) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.default_value then
                s.default_value = new_tab(0, 2)
            end
            _M.Value.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.default_value)
        else
            s.default_value = nil
        end


        return s
    end,
}
_M.Field.group = {
    id = 14626792032033250577,
    displayName = "proto/schema.capnp:Field.group",
    dataWordCount = 3,
    pointerCount = 4,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 56
        local dscrm
        if data.type_id and (type(data.type_id) == "number"
                or type(data.type_id) == "boolean") then

            write_val(buf, data.type_id, 64, 2)
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab
        s.type_id = read_val(buf, "uint64", 64, 2)

        return s
    end,
}
_M.Field.ordinal = {
    id = 13515537513213004774,
    displayName = "proto/schema.capnp:Field.ordinal",
    dataWordCount = 3,
    pointerCount = 4,
    discriminantCount = 2,
    discriminantOffset = 5,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 56
        local dscrm
        if data.implicit then
            dscrm = 0
        end

        if data.explicit then
            dscrm = 1
        end

        if data.explicit and (type(data.explicit) == "number"
                or type(data.explicit) == "boolean") then

            write_val(buf, data.explicit, 16, 6)
        end
        if dscrm then
            _M.Field.ordinal.which(buf, 5, dscrm) --buf, discriminantOffset, discriminantValue
        end

        return pos
    end,
    which = function(buf, offset, n)
        if n then
            -- set value
            write_val(buf, n, 16, offset)
        else
            -- get value
            return read_val(buf, "uint16", 16, offset)
        end
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local dscrm = _M.Field.ordinal.which(buf, 5) --buf, dscrmriminantOffset, dscrmriminantValue


        if dscrm == 0 then
        s.implicit = read_val(buf, "void", 0, 0)

        else
            s.implicit = nil
        end

        if dscrm == 1 then
        s.explicit = read_val(buf, "uint16", 16, 6)

        else
            s.explicit = nil
        end

        return s
    end,
}
_M.Enumerant = {
    id = 10919677598968879693,
    displayName = "proto/schema.capnp:Enumerant",
    dataWordCount = 1,
    pointerCount = 2,
    calc_size_struct = function(data)
        local size = 24
        -- text
        if data.name then
            size = size + round8(#data.name + 1) -- size 1, including trailing NULL
        end
        -- composite list
        if data.annotations then
            size = size + 8
            local num = #data.annotations
            for i=1, num do
                size = size + _M.Annotation.calc_size_struct(data.annotations[i])
            end
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.Enumerant.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 24
        local dscrm
        if data.name and type(data.name) == "string" then
            local data_off = get_data_off(_M.Enumerant, 0, pos)

            local len = #data.name + 1
            write_listp_buf(buf, _M.Enumerant, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.name)
            pos = pos + round8(len)
        end
        if data.code_order and (type(data.code_order) == "number"
                or type(data.code_order) == "boolean") then

            write_val(buf, data.code_order, 16, 0)
        end
        if data.annotations and type(data.annotations) == "table" then
            local num, size, old_pos = #data.annotations, 0, pos
            local data_off = get_data_off(_M.Enumerant, 1, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Annotation, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Annotation.flat_serialize(data.annotations[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Enumerant, 1, 7, (pos - old_pos - 8) / 8, data_off)
        end
        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.Enumerant.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.Enumerant, 0)
        _M.Enumerant.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local off, size, num = parse_listp_buf(buf, header, _M.Enumerant, 0)
        if off and num then
            s.name = ffi.string(buf + (1 + 0 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.name = nil
        end
        s.code_order = read_val(buf, "uint16", 16, 0)

        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Enumerant, 1)
        if off and words then
            local start = (1 + 1 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.annotations then
                s.annotations = new_tab(num, 0)
            end
            for i=1, num do
                if not s.annotations[i] then
                    s.annotations[i] = new_tab(0, 2)
                end
                _M.Annotation.parse_struct_data(buf + start, dt, pt, header, s.annotations[i])
                start = start + (dt + pt) * 2
            end
        else
            s.annotations = nil
        end
        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.Enumerant.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.Method = {
    id = 10736806783679155584,
    displayName = "proto/schema.capnp:Method",
    dataWordCount = 1,
    pointerCount = 4,
    calc_size_struct = function(data)
        local size = 40
        -- text
        if data.name then
            size = size + round8(#data.name + 1) -- size 1, including trailing NULL
        end
        -- composite list
        if data.params then
            size = size + 8
            local num = #data.params
            for i=1, num do
                size = size + _M.Method.Param.calc_size_struct(data.params[i])
            end
        end
        -- struct
        if data.return_type then
            size = size + _M.Type.calc_size_struct(data.return_type)
        end
        -- composite list
        if data.annotations then
            size = size + 8
            local num = #data.annotations
            for i=1, num do
                size = size + _M.Annotation.calc_size_struct(data.annotations[i])
            end
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.Method.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 40
        local dscrm
        if data.name and type(data.name) == "string" then
            local data_off = get_data_off(_M.Method, 0, pos)

            local len = #data.name + 1
            write_listp_buf(buf, _M.Method, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.name)
            pos = pos + round8(len)
        end
        if data.code_order and (type(data.code_order) == "number"
                or type(data.code_order) == "boolean") then

            write_val(buf, data.code_order, 16, 0)
        end
        if data.params and type(data.params) == "table" then
            local num, size, old_pos = #data.params, 0, pos
            local data_off = get_data_off(_M.Method, 1, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Method.Param, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Method.Param.flat_serialize(data.params[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Method, 1, 7, (pos - old_pos - 8) / 8, data_off)
        end
        if data.required_param_count and (type(data.required_param_count) == "number"
                or type(data.required_param_count) == "boolean") then

            write_val(buf, data.required_param_count, 16, 1)
        end
        if data.return_type and type(data.return_type) == "table" then
            local data_off = get_data_off(_M.Method, 2, pos)
            write_structp_buf(buf, _M.Method, _M.Type, 2, data_off)
            local size = _M.Type.flat_serialize(data.return_type, buf + pos)
            pos = pos + size
        end
        if data.annotations and type(data.annotations) == "table" then
            local num, size, old_pos = #data.annotations, 0, pos
            local data_off = get_data_off(_M.Method, 3, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Annotation, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Annotation.flat_serialize(data.annotations[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Method, 3, 7, (pos - old_pos - 8) / 8, data_off)
        end
        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.Method.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.Method, 0)
        _M.Method.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local off, size, num = parse_listp_buf(buf, header, _M.Method, 0)
        if off and num then
            s.name = ffi.string(buf + (1 + 0 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.name = nil
        end
        s.code_order = read_val(buf, "uint16", 16, 0)

        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Method, 1)
        if off and words then
            local start = (1 + 1 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.params then
                s.params = new_tab(num, 0)
            end
            for i=1, num do
                if not s.params[i] then
                    s.params[i] = new_tab(0, 2)
                end
                _M.Method.Param.parse_struct_data(buf + start, dt, pt, header, s.params[i])
                start = start + (dt + pt) * 2
            end
        else
            s.params = nil
        end        s.required_param_count = read_val(buf, "uint16", 16, 1)

        local p = buf + (1 + 2) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.return_type then
                s.return_type = new_tab(0, 2)
            end
            _M.Type.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.return_type)
        else
            s.return_type = nil
        end


        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Method, 3)
        if off and words then
            local start = (1 + 3 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.annotations then
                s.annotations = new_tab(num, 0)
            end
            for i=1, num do
                if not s.annotations[i] then
                    s.annotations[i] = new_tab(0, 2)
                end
                _M.Annotation.parse_struct_data(buf + start, dt, pt, header, s.annotations[i])
                start = start + (dt + pt) * 2
            end
        else
            s.annotations = nil
        end
        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.Method.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.Method.Param = {
    id = 14681955158633610486,
    displayName = "proto/schema.capnp:Method.Param",
    dataWordCount = 0,
    pointerCount = 4,
    calc_size_struct = function(data)
        local size = 32
        -- text
        if data.name then
            size = size + round8(#data.name + 1) -- size 1, including trailing NULL
        end
        -- struct
        if data.type then
            size = size + _M.Type.calc_size_struct(data.type)
        end
        -- struct
        if data.default_value then
            size = size + _M.Value.calc_size_struct(data.default_value)
        end
        -- composite list
        if data.annotations then
            size = size + 8
            local num = #data.annotations
            for i=1, num do
                size = size + _M.Annotation.calc_size_struct(data.annotations[i])
            end
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.Method.Param.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 32
        local dscrm
        if data.name and type(data.name) == "string" then
            local data_off = get_data_off(_M.Method.Param, 0, pos)

            local len = #data.name + 1
            write_listp_buf(buf, _M.Method.Param, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.name)
            pos = pos + round8(len)
        end
        if data.type and type(data.type) == "table" then
            local data_off = get_data_off(_M.Method.Param, 1, pos)
            write_structp_buf(buf, _M.Method.Param, _M.Type, 1, data_off)
            local size = _M.Type.flat_serialize(data.type, buf + pos)
            pos = pos + size
        end
        if data.default_value and type(data.default_value) == "table" then
            local data_off = get_data_off(_M.Method.Param, 2, pos)
            write_structp_buf(buf, _M.Method.Param, _M.Value, 2, data_off)
            local size = _M.Value.flat_serialize(data.default_value, buf + pos)
            pos = pos + size
        end
        if data.annotations and type(data.annotations) == "table" then
            local num, size, old_pos = #data.annotations, 0, pos
            local data_off = get_data_off(_M.Method.Param, 3, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Annotation, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Annotation.flat_serialize(data.annotations[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.Method.Param, 3, 7, (pos - old_pos - 8) / 8, data_off)
        end
        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.Method.Param.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.Method.Param, 0)
        _M.Method.Param.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local off, size, num = parse_listp_buf(buf, header, _M.Method.Param, 0)
        if off and num then
            s.name = ffi.string(buf + (0 + 0 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.name = nil
        end

        local p = buf + (0 + 1) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.type then
                s.type = new_tab(0, 2)
            end
            _M.Type.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.type)
        else
            s.type = nil
        end


        local p = buf + (0 + 2) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.default_value then
                s.default_value = new_tab(0, 2)
            end
            _M.Value.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.default_value)
        else
            s.default_value = nil
        end


        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.Method.Param, 3)
        if off and words then
            local start = (0 + 3 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.annotations then
                s.annotations = new_tab(num, 0)
            end
            for i=1, num do
                if not s.annotations[i] then
                    s.annotations[i] = new_tab(0, 2)
                end
                _M.Annotation.parse_struct_data(buf + start, dt, pt, header, s.annotations[i])
                start = start + (dt + pt) * 2
            end
        else
            s.annotations = nil
        end
        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.Method.Param.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.Type = {
    id = 15020482145304562784,
    displayName = "proto/schema.capnp:Type",
    dataWordCount = 2,
    pointerCount = 1,
    discriminantCount = 19,
    calc_size_struct = function(data)
        local size = 24
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.Type.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 24
        local dscrm
        if data.void then
            dscrm = 0
        end

        if data.bool then
            dscrm = 1
        end

        if data.int8 then
            dscrm = 2
        end

        if data.int16 then
            dscrm = 3
        end

        if data.int32 then
            dscrm = 4
        end

        if data.int64 then
            dscrm = 5
        end

        if data.uint8 then
            dscrm = 6
        end

        if data.uint16 then
            dscrm = 7
        end

        if data.uint32 then
            dscrm = 8
        end

        if data.uint64 then
            dscrm = 9
        end

        if data.float32 then
            dscrm = 10
        end

        if data.float64 then
            dscrm = 11
        end

        if data.text then
            dscrm = 12
        end

        if data.data then
            dscrm = 13
        end

        if data.list then
            dscrm = 14
        end

        if data.list and type(data.list) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Type.list.flat_serialize(data.list, buf)
        end

        if data.enum then
            dscrm = 15
        end

        if data.enum and type(data.enum) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Type.enum.flat_serialize(data.enum, buf)
        end

        if data.struct then
            dscrm = 16
        end

        if data.struct and type(data.struct) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Type.struct.flat_serialize(data.struct, buf)
        end

        if data.interface then
            dscrm = 17
        end

        if data.interface and type(data.interface) == "table" then
            -- groups are just namespaces, field offsets are set within parent
            -- structs
            _M.Type.interface.flat_serialize(data.interface, buf)
        end

        if data.object then
            dscrm = 18
        end

        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.Type.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.Type, 0)
        _M.Type.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        if dscrm == 0 then
        s.void = read_val(buf, "void", 0, 0)

        else
            s.void = nil
        end

        if dscrm == 1 then
        s.bool = read_val(buf, "void", 0, 0)

        else
            s.bool = nil
        end

        if dscrm == 2 then
        s.int8 = read_val(buf, "void", 0, 0)

        else
            s.int8 = nil
        end

        if dscrm == 3 then
        s.int16 = read_val(buf, "void", 0, 0)

        else
            s.int16 = nil
        end

        if dscrm == 4 then
        s.int32 = read_val(buf, "void", 0, 0)

        else
            s.int32 = nil
        end

        if dscrm == 5 then
        s.int64 = read_val(buf, "void", 0, 0)

        else
            s.int64 = nil
        end

        if dscrm == 6 then
        s.uint8 = read_val(buf, "void", 0, 0)

        else
            s.uint8 = nil
        end

        if dscrm == 7 then
        s.uint16 = read_val(buf, "void", 0, 0)

        else
            s.uint16 = nil
        end

        if dscrm == 8 then
        s.uint32 = read_val(buf, "void", 0, 0)

        else
            s.uint32 = nil
        end

        if dscrm == 9 then
        s.uint64 = read_val(buf, "void", 0, 0)

        else
            s.uint64 = nil
        end

        if dscrm == 10 then
        s.float32 = read_val(buf, "void", 0, 0)

        else
            s.float32 = nil
        end

        if dscrm == 11 then
        s.float64 = read_val(buf, "void", 0, 0)

        else
            s.float64 = nil
        end

        if dscrm == 12 then
        s.text = read_val(buf, "void", 0, 0)

        else
            s.text = nil
        end

        if dscrm == 13 then
        s.data = read_val(buf, "void", 0, 0)

        else
            s.data = nil
        end

        if dscrm == 14 then

        if not s.list then
            s.list = new_tab(0, 4)
        end
        _M.Type.list.parse_struct_data(buf, _M.Type.dataWordCount, _M.Type.pointerCount,
                header, s.list)

        else
            s.list = nil
        end

        if dscrm == 15 then

        if not s.enum then
            s.enum = new_tab(0, 4)
        end
        _M.Type.enum.parse_struct_data(buf, _M.Type.dataWordCount, _M.Type.pointerCount,
                header, s.enum)

        else
            s.enum = nil
        end

        if dscrm == 16 then

        if not s.struct then
            s.struct = new_tab(0, 4)
        end
        _M.Type.struct.parse_struct_data(buf, _M.Type.dataWordCount, _M.Type.pointerCount,
                header, s.struct)

        else
            s.struct = nil
        end

        if dscrm == 17 then

        if not s.interface then
            s.interface = new_tab(0, 4)
        end
        _M.Type.interface.parse_struct_data(buf, _M.Type.dataWordCount, _M.Type.pointerCount,
                header, s.interface)

        else
            s.interface = nil
        end

        if dscrm == 18 then
        s.object = read_val(buf, "void", 0, 0)

        else
            s.object = nil
        end

        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.Type.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.Type.list = {
    id = 9792858745991129751,
    displayName = "proto/schema.capnp:Type.list",
    dataWordCount = 2,
    pointerCount = 1,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 24
        local dscrm
        if data.element_type and type(data.element_type) == "table" then
            local data_off = get_data_off(_M.Type.list, 0, pos)
            write_structp_buf(buf, _M.Type.list, _M.Type, 0, data_off)
            local size = _M.Type.flat_serialize(data.element_type, buf + pos)
            pos = pos + size
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        local p = buf + (2 + 0) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.element_type then
                s.element_type = new_tab(0, 2)
            end
            _M.Type.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.element_type)
        else
            s.element_type = nil
        end


        return s
    end,
}
_M.Type.enum = {
    id = 11389172934837766057,
    displayName = "proto/schema.capnp:Type.enum",
    dataWordCount = 2,
    pointerCount = 1,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 24
        local dscrm
        if data.type_id and (type(data.type_id) == "number"
                or type(data.type_id) == "boolean") then

            write_val(buf, data.type_id, 64, 1)
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab
        s.type_id = read_val(buf, "uint64", 64, 1)

        return s
    end,
}
_M.Type.struct = {
    id = 12410354185295152851,
    displayName = "proto/schema.capnp:Type.struct",
    dataWordCount = 2,
    pointerCount = 1,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 24
        local dscrm
        if data.type_id and (type(data.type_id) == "number"
                or type(data.type_id) == "boolean") then

            write_val(buf, data.type_id, 64, 1)
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab
        s.type_id = read_val(buf, "uint64", 64, 1)

        return s
    end,
}
_M.Type.interface = {
    id = 17116997365232503999,
    displayName = "proto/schema.capnp:Type.interface",
    dataWordCount = 2,
    pointerCount = 1,
    isGroup = true,

    flat_serialize = function(data, buf)
        local pos = 24
        local dscrm
        if data.type_id and (type(data.type_id) == "number"
                or type(data.type_id) == "boolean") then

            write_val(buf, data.type_id, 64, 1)
        end
        return pos
    end,
    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab
        s.type_id = read_val(buf, "uint64", 64, 1)

        return s
    end,
}
_M.Value = {
    id = 14853958794117909659,
    displayName = "proto/schema.capnp:Value",
    dataWordCount = 2,
    pointerCount = 1,
    discriminantCount = 19,
    calc_size_struct = function(data)
        local size = 24
        -- text
        if data.text then
            size = size + round8(#data.text + 1) -- size 1, including trailing NULL
        end
        -- data
        if data.data then
            size = size + round8(#data.data)
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.Value.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 24
        local dscrm
        if data.void then
            dscrm = 0
        end

        if data.bool then
            dscrm = 1
        end

        if data.bool and (type(data.bool) == "number"
                or type(data.bool) == "boolean") then

            write_val(buf, data.bool, 1, 16)
        end
        if data.int8 then
            dscrm = 2
        end

        if data.int8 and (type(data.int8) == "number"
                or type(data.int8) == "boolean") then

            write_val(buf, data.int8, 8, 2)
        end
        if data.int16 then
            dscrm = 3
        end

        if data.int16 and (type(data.int16) == "number"
                or type(data.int16) == "boolean") then

            write_val(buf, data.int16, 16, 1)
        end
        if data.int32 then
            dscrm = 4
        end

        if data.int32 and (type(data.int32) == "number"
                or type(data.int32) == "boolean") then

            write_val(buf, data.int32, 32, 1)
        end
        if data.int64 then
            dscrm = 5
        end

        if data.int64 and (type(data.int64) == "number"
                or type(data.int64) == "boolean") then

            write_val(buf, data.int64, 64, 1)
        end
        if data.uint8 then
            dscrm = 6
        end

        if data.uint8 and (type(data.uint8) == "number"
                or type(data.uint8) == "boolean") then

            write_val(buf, data.uint8, 8, 2)
        end
        if data.uint16 then
            dscrm = 7
        end

        if data.uint16 and (type(data.uint16) == "number"
                or type(data.uint16) == "boolean") then

            write_val(buf, data.uint16, 16, 1)
        end
        if data.uint32 then
            dscrm = 8
        end

        if data.uint32 and (type(data.uint32) == "number"
                or type(data.uint32) == "boolean") then

            write_val(buf, data.uint32, 32, 1)
        end
        if data.uint64 then
            dscrm = 9
        end

        if data.uint64 and (type(data.uint64) == "number"
                or type(data.uint64) == "boolean") then

            write_val(buf, data.uint64, 64, 1)
        end
        if data.float32 then
            dscrm = 10
        end

        if data.float32 and (type(data.float32) == "number"
                or type(data.float32) == "boolean") then

            write_val(buf, data.float32, 32, 1)
        end
        if data.float64 then
            dscrm = 11
        end

        if data.float64 and (type(data.float64) == "number"
                or type(data.float64) == "boolean") then

            write_val(buf, data.float64, 64, 1)
        end
        if data.text then
            dscrm = 12
        end

        if data.text and type(data.text) == "string" then
            local data_off = get_data_off(_M.Value, 0, pos)

            local len = #data.text + 1
            write_listp_buf(buf, _M.Value, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.text)
            pos = pos + round8(len)
        end
        if data.data then
            dscrm = 13
        end

        if data.data and type(data.data) == "string" then
            local data_off = get_data_off(_M.Value, 0, pos)

            local len = #data.data
            write_listp_buf(buf, _M.Value, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.data)
            pos = pos + round8(len)
        end
        if data.list then
            dscrm = 14
        end

        if data.list and (type(data.list) == "number"
                or type(data.list) == "boolean") then

            write_val(buf, data.list, 8, 0)
        end
        if data.enum then
            dscrm = 15
        end

        if data.enum and (type(data.enum) == "number"
                or type(data.enum) == "boolean") then

            write_val(buf, data.enum, 16, 1)
        end
        if data.struct then
            dscrm = 16
        end

        if data.struct and (type(data.struct) == "number"
                or type(data.struct) == "boolean") then

            write_val(buf, data.struct, 8, 0)
        end
        if data.interface then
            dscrm = 17
        end

        if data.object then
            dscrm = 18
        end

        if data.object and (type(data.object) == "number"
                or type(data.object) == "boolean") then

            write_val(buf, data.object, 8, 0)
        end
        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.Value.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.Value, 0)
        _M.Value.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        if dscrm == 0 then
        s.void = read_val(buf, "void", 0, 0)

        else
            s.void = nil
        end

        if dscrm == 1 then
        s.bool = read_val(buf, "bool", 1, 16)

        else
            s.bool = nil
        end

        if dscrm == 2 then
        s.int8 = read_val(buf, "int8", 8, 2)

        else
            s.int8 = nil
        end

        if dscrm == 3 then
        s.int16 = read_val(buf, "int16", 16, 1)

        else
            s.int16 = nil
        end

        if dscrm == 4 then
        s.int32 = read_val(buf, "int32", 32, 1)

        else
            s.int32 = nil
        end

        if dscrm == 5 then
        s.int64 = read_val(buf, "int64", 64, 1)

        else
            s.int64 = nil
        end

        if dscrm == 6 then
        s.uint8 = read_val(buf, "uint8", 8, 2)

        else
            s.uint8 = nil
        end

        if dscrm == 7 then
        s.uint16 = read_val(buf, "uint16", 16, 1)

        else
            s.uint16 = nil
        end

        if dscrm == 8 then
        s.uint32 = read_val(buf, "uint32", 32, 1)

        else
            s.uint32 = nil
        end

        if dscrm == 9 then
        s.uint64 = read_val(buf, "uint64", 64, 1)

        else
            s.uint64 = nil
        end

        if dscrm == 10 then
        s.float32 = read_val(buf, "float32", 32, 1)

        else
            s.float32 = nil
        end

        if dscrm == 11 then
        s.float64 = read_val(buf, "float64", 64, 1)

        else
            s.float64 = nil
        end

        if dscrm == 12 then

        local off, size, num = parse_listp_buf(buf, header, _M.Value, 0)
        if off and num then
            s.text = ffi.string(buf + (2 + 0 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.text = nil
        end

        else
            s.text = nil
        end

        if dscrm == 13 then

        local off, size, num = parse_listp_buf(buf, header, _M.Value, 0)
        if off and num then
            s.data = ffi.string(buf + (2 + 0 + 1 + off) * 2, num) -- dataWordCount + offset + pointerSize + off
        else
            s.data = nil
        end

        else
            s.data = nil
        end

        if dscrm == 14 then
        s.list = read_val(buf, "object", 8, 0)

        else
            s.list = nil
        end

        if dscrm == 15 then
        s.enum = read_val(buf, "uint16", 16, 1)

        else
            s.enum = nil
        end

        if dscrm == 16 then
        s.struct = read_val(buf, "object", 8, 0)

        else
            s.struct = nil
        end

        if dscrm == 17 then
        s.interface = read_val(buf, "void", 0, 0)

        else
            s.interface = nil
        end

        if dscrm == 18 then
        s.object = read_val(buf, "object", 8, 0)

        else
            s.object = nil
        end

        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.Value.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.Annotation = {
    id = 17422339044421236034,
    displayName = "proto/schema.capnp:Annotation",
    dataWordCount = 1,
    pointerCount = 1,
    calc_size_struct = function(data)
        local size = 16
        -- struct
        if data.value then
            size = size + _M.Value.calc_size_struct(data.value)
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.Annotation.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 16
        local dscrm
        if data.id and (type(data.id) == "number"
                or type(data.id) == "boolean") then

            write_val(buf, data.id, 64, 0)
        end
        if data.value and type(data.value) == "table" then
            local data_off = get_data_off(_M.Annotation, 0, pos)
            write_structp_buf(buf, _M.Annotation, _M.Value, 0, data_off)
            local size = _M.Value.flat_serialize(data.value, buf + pos)
            pos = pos + size
        end
        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.Annotation.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.Annotation, 0)
        _M.Annotation.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab
        s.id = read_val(buf, "uint64", 64, 0)

        local p = buf + (1 + 0) * 2 -- buf, dataWordCount, offset
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            if not s.value then
                s.value = new_tab(0, 2)
            end
            _M.Value.parse_struct_data(p + 2 + off * 2, dw, pw, header, s.value)
        else
            s.value = nil
        end


        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.Annotation.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.ElementSize = {
    ["EMPTY"] = 0,
    ["BIT"] = 1,
    ["BYTE"] = 2,
    ["TWO_BYTES"] = 3,
    ["FOUR_BYTES"] = 4,
    ["EIGHT_BYTES"] = 5,
    ["POINTER"] = 6,
    ["INLINE_COMPOSITE"] = 7,

}
_M.ElementSizeStr = {
    [0] = "EMPTY",
    [1] = "BIT",
    [2] = "BYTE",
    [3] = "TWO_BYTES",
    [4] = "FOUR_BYTES",
    [5] = "EIGHT_BYTES",
    [6] = "POINTER",
    [7] = "INLINE_COMPOSITE",

}
_M.CodeGeneratorRequest = {
    id = 13818529054586492878,
    displayName = "proto/schema.capnp:CodeGeneratorRequest",
    dataWordCount = 0,
    pointerCount = 2,
    calc_size_struct = function(data)
        local size = 16
        -- composite list
        if data.nodes then
            size = size + 8
            local num = #data.nodes
            for i=1, num do
                size = size + _M.Node.calc_size_struct(data.nodes[i])
            end
        end
        -- composite list
        if data.requested_files then
            size = size + 8
            local num = #data.requested_files
            for i=1, num do
                size = size + _M.CodeGeneratorRequest.RequestedFile.calc_size_struct(data.requested_files[i])
            end
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.CodeGeneratorRequest.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 16
        local dscrm
        if data.nodes and type(data.nodes) == "table" then
            local num, size, old_pos = #data.nodes, 0, pos
            local data_off = get_data_off(_M.CodeGeneratorRequest, 0, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.Node, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.Node.flat_serialize(data.nodes[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.CodeGeneratorRequest, 0, 7, (pos - old_pos - 8) / 8, data_off)
        end
        if data.requested_files and type(data.requested_files) == "table" then
            local num, size, old_pos = #data.requested_files, 0, pos
            local data_off = get_data_off(_M.CodeGeneratorRequest, 1, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.CodeGeneratorRequest.RequestedFile, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.CodeGeneratorRequest.RequestedFile.flat_serialize(data.requested_files[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.CodeGeneratorRequest, 1, 7, (pos - old_pos - 8) / 8, data_off)
        end
        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.CodeGeneratorRequest.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.CodeGeneratorRequest, 0)
        _M.CodeGeneratorRequest.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab

        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.CodeGeneratorRequest, 0)
        if off and words then
            local start = (0 + 0 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.nodes then
                s.nodes = new_tab(num, 0)
            end
            for i=1, num do
                if not s.nodes[i] then
                    s.nodes[i] = new_tab(0, 2)
                end
                _M.Node.parse_struct_data(buf + start, dt, pt, header, s.nodes[i])
                start = start + (dt + pt) * 2
            end
        else
            s.nodes = nil
        end
        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.CodeGeneratorRequest, 1)
        if off and words then
            local start = (0 + 1 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.requested_files then
                s.requested_files = new_tab(num, 0)
            end
            for i=1, num do
                if not s.requested_files[i] then
                    s.requested_files[i] = new_tab(0, 2)
                end
                _M.CodeGeneratorRequest.RequestedFile.parse_struct_data(buf + start, dt, pt, header, s.requested_files[i])
                start = start + (dt + pt) * 2
            end
        else
            s.requested_files = nil
        end
        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.CodeGeneratorRequest.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.CodeGeneratorRequest.RequestedFile = {
    id = 14981803260258615394,
    displayName = "proto/schema.capnp:CodeGeneratorRequest.RequestedFile",
    dataWordCount = 1,
    pointerCount = 2,
    calc_size_struct = function(data)
        local size = 24
        -- text
        if data.filename then
            size = size + round8(#data.filename + 1) -- size 1, including trailing NULL
        end
        -- composite list
        if data.imports then
            size = size + 8
            local num = #data.imports
            for i=1, num do
                size = size + _M.CodeGeneratorRequest.RequestedFile.Import.calc_size_struct(data.imports[i])
            end
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.CodeGeneratorRequest.RequestedFile.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 24
        local dscrm
        if data.id and (type(data.id) == "number"
                or type(data.id) == "boolean") then

            write_val(buf, data.id, 64, 0)
        end
        if data.filename and type(data.filename) == "string" then
            local data_off = get_data_off(_M.CodeGeneratorRequest.RequestedFile, 0, pos)

            local len = #data.filename + 1
            write_listp_buf(buf, _M.CodeGeneratorRequest.RequestedFile, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.filename)
            pos = pos + round8(len)
        end
        if data.imports and type(data.imports) == "table" then
            local num, size, old_pos = #data.imports, 0, pos
            local data_off = get_data_off(_M.CodeGeneratorRequest.RequestedFile, 1, pos)

            -- write tag
            capnp.write_composite_tag(buf + pos, _M.CodeGeneratorRequest.RequestedFile.Import, num)
            pos = pos + 8 -- tag

            -- write data
            for i=1, num do
                pos = pos + _M.CodeGeneratorRequest.RequestedFile.Import.flat_serialize(data.imports[i], buf + pos)
            end

            -- write list pointer
            write_listp_buf(buf, _M.CodeGeneratorRequest.RequestedFile, 1, 7, (pos - old_pos - 8) / 8, data_off)
        end
        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.CodeGeneratorRequest.RequestedFile.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.CodeGeneratorRequest.RequestedFile, 0)
        _M.CodeGeneratorRequest.RequestedFile.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab
        s.id = read_val(buf, "uint64", 64, 0)

        local off, size, num = parse_listp_buf(buf, header, _M.CodeGeneratorRequest.RequestedFile, 0)
        if off and num then
            s.filename = ffi.string(buf + (1 + 0 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.filename = nil
        end

        -- composite list
        local off, size, words = parse_listp_buf(buf, header, _M.CodeGeneratorRequest.RequestedFile, 1)
        if off and words then
            local start = (1 + 1 + 1 + off) * 2-- dataWordCount + offset + pointerSize + off
            local num, dt, pt = capnp.read_composite_tag(buf + start)
            start = start + 2 -- 2 * 32bit
            if not s.imports then
                s.imports = new_tab(num, 0)
            end
            for i=1, num do
                if not s.imports[i] then
                    s.imports[i] = new_tab(0, 2)
                end
                _M.CodeGeneratorRequest.RequestedFile.Import.parse_struct_data(buf + start, dt, pt, header, s.imports[i])
                start = start + (dt + pt) * 2
            end
        else
            s.imports = nil
        end
        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.CodeGeneratorRequest.RequestedFile.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}
_M.CodeGeneratorRequest.RequestedFile.Import = {
    id = 12560611460656617445,
    displayName = "proto/schema.capnp:CodeGeneratorRequest.RequestedFile.Import",
    dataWordCount = 1,
    pointerCount = 1,
    calc_size_struct = function(data)
        local size = 16
        -- text
        if data.name then
            size = size + round8(#data.name + 1) -- size 1, including trailing NULL
        end
        return size
    end,

    calc_size = function(data)
        local size = 16 -- header + root struct pointer
        return size + _M.CodeGeneratorRequest.RequestedFile.Import.calc_size_struct(data)
    end,
    flat_serialize = function(data, buf)
        local pos = 16
        local dscrm
        if data.id and (type(data.id) == "number"
                or type(data.id) == "boolean") then

            write_val(buf, data.id, 64, 0)
        end
        if data.name and type(data.name) == "string" then
            local data_off = get_data_off(_M.CodeGeneratorRequest.RequestedFile.Import, 0, pos)

            local len = #data.name + 1
            write_listp_buf(buf, _M.CodeGeneratorRequest.RequestedFile.Import, 0, 2, len, data_off)

            ffi_copy(buf + pos, data.name)
            pos = pos + round8(len)
        end
        return pos
    end,
    serialize = function(data, buf, size)
        if not buf then
            size = _M.CodeGeneratorRequest.RequestedFile.Import.calc_size(data)

            buf = get_str_buf(size)
        end
        ffi_fill(buf, size)
        local p = ffi_cast("int32_t *", buf)

        p[0] = 0                                    -- 1 segment
        p[1] = (size - 8) / 8

        write_structp(buf + 8, _M.CodeGeneratorRequest.RequestedFile.Import, 0)
        _M.CodeGeneratorRequest.RequestedFile.Import.flat_serialize(data, buf + 16)

        return ffi_string(buf, size)
    end,

    parse_struct_data = function(buf, data_word_count, pointer_count, header, tab)
        local s = tab
        s.id = read_val(buf, "uint64", 64, 0)

        local off, size, num = parse_listp_buf(buf, header, _M.CodeGeneratorRequest.RequestedFile.Import, 0)
        if off and num then
            s.name = ffi.string(buf + (1 + 0 + 1 + off) * 2, num - 1) -- dataWordCount + offset + pointerSize + off
        else
            s.name = nil
        end

        return s
    end,
    parse = function(bin, tab)
        if #bin < 16 then
            return nil, "message too short"
        end

        local header = new_tab(0, 4)
        local p = ffi_cast("uint32_t *", bin)
        header.base = p

        local nsegs = p[0] + 1
        header.seg_sizes = {}
        for i=1, nsegs do
            header.seg_sizes[i] = p[i]
        end
        local pos = round8(4 + nsegs * 4)
        header.header_size = pos / 8
        p = p + pos / 4

        if not tab then
            tab = new_tab(0, 8)
        end
        local off, dw, pw = parse_struct_buf(p, header)
        if off and dw and pw then
            return _M.CodeGeneratorRequest.RequestedFile.Import.parse_struct_data(p + 2 + off * 2, dw, pw, header, tab)
        else
            return nil
        end
    end,

}

return _M
