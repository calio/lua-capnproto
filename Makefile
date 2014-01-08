CXXFLAGS:=-std=gnu++11 -g -Iproto -I/usr/local/include
LDFLAGS:=-L/usr/local/lib -lcapnp -lkj -pthread
#CXX:=g++-4.7


compiled: proto/example.capnp proto/enums.capnp
	capnp compile -oc++ $+

test.schema.txt: proto/enums.capnp proto/example.capnp
	capnp compile -oecho $+ > /tmp/capnp.bin
	capnp decode proto/schema.capnp CodeGeneratorRequest > $@ < /tmp/capnp.bin

cpp/example_capnp.o: proto/example.capnp.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

cpp/enums_capnp.o: proto/enums.capnp.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

cpp/main.o: cpp/main.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

cpp/main: cpp/main.o cpp/example_capnp.o cpp/enums_capnp.o
	$(CXX) $(CXXFLAGS) -o $@ $+ $(LDFLAGS)

test:
	luajit test/sanity.lua

all: cpp/main

clean:
	-rm proto/example.capnp.c++ proto/example.capnp.h cpp/*.o cpp/main test.schema.lua example_capnp.lua a.data c.data test.schema.txt *.data

.PHONY: all clean test
