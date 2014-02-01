#include "example.capnp.h"
#include <capnp/message.h>
#include <capnp/serialize-packed.h>
#include <iostream>
#include <stdio.h>
#include <unistd.h>
#include <kj/common.h>


void writeT1(int fd) {
    ::capnp::MallocMessageBuilder message;

    T1::Builder t1 = message.initRoot<T1>();
    //::capnp::List<Person>::Builder people = addressBook.initPeople(2);
    t1.setI0(32);
    t1.setI1(16);
    t1.setB0(true);
    t1.setI2(127);
    t1.setB1(true);
    t1.setI3(65536);
    t1.setE0(::T1::EnumType1::ENUM3);
    T1::T2::Builder t2 = t1.initS0();
    t2.setF0(3.14);
    t2.setF1(3.14159265358979);

    ::capnp::List< ::int8_t>::Builder l0 = t1.initL0(2);
    l0.set(0, 28);
    l0.set(1, 29);

    t1.setT0("hello");
    const char *str = "\1\2\3\4\5\6\7";
    t1.setD0(::capnp::Data::Reader(reinterpret_cast<const ::capnp::byte*>(str),
                strlen(str)));

    t1.setE1(::EnumType2::ENUM7);

    //t1.setUi0(0xf0f0);
    t1.setUi1(0x0f0f);

    T1::G0::Builder g0 = t1.initG0();
    g0.setUi2(0x12345678);

    T1::U0::Builder u0 = t1.initU0();
    T1::U0::Ug0::Builder ug0 = u0.initUg0();
    ug0.setUgu0(32);

    ::capnp::List< ::T1::T2>::Builder ls0 = t1.initLs0(2);
    ls0[0].setF0(0.61803398875);
    ls0[0].setF1(1.61803398875);
    ls0[1].setF0(2.71828182846);
    ls0[1].setF1(2.71828182846);

    //auto o0 = t1.getO0().initAs< ::T1::U0 >();
    //o0.setUv1();
    //o0.set(0, 2);

    writeMessageToFd(fd, message);
}

void readT1(int fd) {
    ::capnp::StreamFdMessageReader message(fd);
    T1::Reader t1 = message.getRoot<T1>();

    printf("%d\n", t1.getI0());
}

int main(int argc, char **argv)
{
    if (argc >= 2) {
        readT1(STDIN_FILENO);
    }

    writeT1(STDOUT_FILENO);

    return 0;
}
