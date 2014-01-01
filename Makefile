CXXFLAGS:=-std=gnu++11 -g
LDFLAGS:=-lcapnp -lkj -pthread
CXX:=g++-4.7


proto/test.capnp.c++: proto/test.capnp
	capnp compile -oc++ $<

test.schema.txt: proto/test.capnp
	capnp compile -oecho $< > /tmp/capnp.bin
	capnp decode /home/calio/code/c-capnproto/compiler/schema.capnp CodeGeneratorRequest > $@ < /tmp/capnp.bin

proto/test.capnp.h: proto/test.capnp.c++

test_capnp.o: proto/test.capnp.c++ proto/test.capnp.h
	$(CXX) -c $(CXXFLAGS) $< -o $@

main.o: main.c++ proto/test.capnp.h
	$(CXX) -c $(CXXFLAGS) $< -o $@

main: main.o test_capnp.o
	$(CXX) $(CXXFLAGS) -o $@ $+ $(LDFLAGS)

all: main

clean:
	-rm proto/test.capnp.c++ proto/test.capnp.h *.o main

.PHONY: all
