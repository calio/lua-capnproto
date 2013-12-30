CXXFLAGS:=-std=gnu++11 -g
LDFLAGS:=-lcapnp -lkj -pthread
CXX:=g++-4.7


test.capnp.c++: test.capnp
	capnp compile -oc++ $<

test.schema.txt: test.capnp
	capnp compile -oecho $< > /tmp/capnp.bin
	capnp decode /home/calio/code/c-capnproto/compiler/schema.capnp CodeGeneratorRequest > $@ < /tmp/capnp.bin

test.capnp.h: test.capnp.c++

test_capnp.o: test.capnp.c++ test.capnp.h
	$(CXX) -c $(CXXFLAGS) $< -o $@

test.o: test.c++ test.capnp.h
	$(CXX) -c $(CXXFLAGS) $< -o $@

main: test.o test_capnp.o
	$(CXX) $(CXXFLAGS) -o $@ $+ $(LDFLAGS)

all: main

clean:
	-rm test.capnp.c++ test.capnp.h *.o

.PHONY: all
