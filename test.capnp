@0xa0d78d3689d48a0b;

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
    #t0 @6 :Text;
    #d0 @7 :Data;
    #l0 @8 :List(Int8);
}
