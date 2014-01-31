@0xa0d78d3689d48a0b;

using import "enums.capnp".EnumType2;
using Lua = import "lua.capnp";

struct T1 {
    struct T2 {
        f0 @0 :Float32;
        f1 @1 :Float64;
    }

    i0 @0 :UInt32;
    i1 @1 :UInt16;
    i2 @3 :Int8;
    b0 @2 :Bool;
    b1 @4 :Bool;
    i3 @5 :Int32;
    s0 @6 :T2;
    e0 @7 :EnumType1;
    l0 @8 :List(Int8);
    t0 @9 :Text;
    d0 @11 :Data;
    e1 @10 :EnumType2;

    enum EnumType1 $Lua.naming("lower_underscore") {
        enum1 @0;
        enum2 @1;
        enum3 @2;
    }

    # unnamed union
    union {
        ui0 @12 :Int32;
        ui1 @13 :Int32;
        uv0 @14 :Void;
    }

    # group
    g0 :group {
        ui2 @15 :UInt32;
    }

    # named union = unamed union in a group
    u0 :union {
        ui3 @16 :UInt16;
        uv1 @17 :Void;
        ug0 :group {
            ugv0 @18 :Void;
            ugu0 @19 :UInt32;
        }
    }

    ls0 @20 :List(T2);

    du0 @21 :UInt32 = 65535;
    db0 @22 :Bool = true;
    end @23 :Bool; # "end" is lua's reserved word
    o0  @24 :AnyPointer;
#    u1: union {
#        g1 :group {
#            v1 @17 :Void;
#            ui4 @18 :UInt32;
#        }
#        g2 :group {
#            b2 @19 :Bool;
#        }
#    }
}
