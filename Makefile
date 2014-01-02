CXXFLAGS:=-std=gnu++11 -g -Iproto -I/usr/local/include
LDFLAGS:=-L/usr/local/lib -lcapnp -lkj -pthread
#CXX:=g++-4.7


compiled: proto/example.capnp proto/enums.capnp
	capnp compile -oc++ $+

test.schema.txt: proto/enums.capnp proto/example.capnp
	capnp compile -oecho $+ > /tmp/capnp.bin
	capnp decode /home/calio/code/c-capnproto/compiler/schema.capnp CodeGeneratorRequest > $@ < /tmp/capnp.bin

example_capnp.o: proto/example.capnp.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

enums_capnp.o: proto/enums.capnp.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

main.o: main.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

main: main.o example_capnp.o enums_capnp.o
	$(CXX) $(CXXFLAGS) -o $@ $+ $(LDFLAGS)

test:
	lunit.sh -i `which luajit` test/sanity.lua

all: main

clean:
	-rm proto/example.capnp.c++ proto/example.capnp.h *.o main test.schema.lua example_capnp.lua a.data c.data test.schema.txt

.PHONY: all clean test
