CXXFLAGS:=-std=gnu++11 -g -Iproto
LDFLAGS:=-lcapnp -lkj -pthread
CXX:=g++-4.7


compiled: proto/test.capnp
	capnp compile -oc++ proto/*.capnp

#proto/%.capnp.c++: proto/%.capnp
#	capnp compile -oc++ $<

test.schema.txt: proto/test.capnp
	capnp compile -oecho $< > /tmp/capnp.bin
	capnp decode /home/calio/code/c-capnproto/compiler/schema.capnp CodeGeneratorRequest > $@ < /tmp/capnp.bin

test_capnp.o: proto/test.capnp.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

enums_capnp.o: proto/enums.capnp.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

main.o: main.c++ compiled
	$(CXX) -c $(CXXFLAGS) $< -o $@

main: main.o test_capnp.o enums_capnp.o
	$(CXX) $(CXXFLAGS) -o $@ $+ $(LDFLAGS)

all: main

clean:
	-rm proto/test.capnp.c++ proto/test.capnp.h *.o main

.PHONY: all
