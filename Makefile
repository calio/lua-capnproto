CXXFLAGS:=-std=gnu++11 -g -Iproto
LDFLAGS:=-lcapnp -lkj -pthread
CXX:=g++-4.7


compiled: proto/example.capnp
	capnp compile -oc++ proto/*.capnp

#proto/%.capnp.c++: proto/%.capnp
#	capnp compile -oc++ $<

test.schema.txt: proto/example.capnp
	capnp compile -oecho $< > /tmp/capnp.bin
	capnp decode /home/calio/code/c-capnproto/compiler/schema.capnp CodeGeneratorRequest > $@ < /tmp/capnp.bin

example_capnp.o: proto/example.capnp.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

enums_capnp.o: proto/enums.capnp.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

main.o: main.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

main: main.o example_capnp.o enums_capnp.o
	$(CXX) $(CXXFLAGS) -o $@ $+ $(LDFLAGS)

all: main

clean:
	-rm proto/example.capnp.c++ proto/example.capnp.h *.o main

.PHONY: all
