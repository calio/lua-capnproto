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
    #d0 @7 :Data;

    enum EnumType1 $Lua.naming("lower_underscore") {
        enum1 @0;
        enum2 @1;
        enum3 @2;
    }
}

struct T3 {
    name @0 :Text;
    union {
        i1 @1 :Int32;
        i2 @2 :Int32;
    }
#    union {
#        g1 :group {
#            v0 @1 :Void;
#            ui0 @2 :UInt32;
#        }
#        g2 :group {
#            b2 @3 :Bool;
#        }
#    }
#
#    g3 :group {
#        ui1 @4 :UInt32;
#    }
#
#    u0 :union {
#        v1 @5 :Void;
#        ui2 @6 :UInt16;
#    }
}
