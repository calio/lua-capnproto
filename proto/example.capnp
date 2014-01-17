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
    e1 @10 :EnumType2;
    #d0 @7 :Data;

    enum EnumType1 $Lua.naming("lower_underscore") {
        enum1 @0;
        enum2 @1;
        enum3 @2;
    }

    # unnamed union
    union {
        ui0 @11 :Int32;
        ui1 @12 :Int32;
        uv0 @13 :Void;
    }

    # group
#    g0 :group {
#        ui1 @4 :UInt32;
#    }

    # named union = unamed union in a group
#    u0 :union {
#        v0 @5 :Void;
#        ui2 @6 :UInt16;
#    }

#    u1: union {
#        g1 :group {
#            v1 @7 :Void;
#            ui3 @8 :UInt32;
#        }
#        g2 :group {
#            b2 @9 :Bool;
#        }
#    }
}
