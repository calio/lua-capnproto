#include "test.capnp.h"
#include <capnp/message.h>
#include <capnp/serialize-packed.h>
#include <iostream>
#include <stdio.h>
#include <unistd.h>

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
    //local t0 = t1.initT0(#"XW&JZ");
    T1::T2::Builder t2 = t1.initS0();
    t2.setF0(3.14);
    t2.setF1(3.14159265358979);

    ::capnp::List< ::int8_t>::Builder l0 = t1.initL0(2);
    l0.set(0, 28);
    l0.set(1, 29);

    t1.setT0("hello");

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
