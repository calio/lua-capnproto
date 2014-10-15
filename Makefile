VERSION:=0.1.0-1
CXXFLAGS:=-std=gnu++11 -g -Iproto -I/usr/local/include
LDFLAGS:=-L/usr/local/lib -lcapnp -lkj -pthread
CAPNP_TEST:=../capnp_test
PWD:=$(shell pwd)
#CXX:=g++-4.7

export PATH:=bin:$(PATH)
export LUA_PATH:=$(PWD)/?.lua;$(PWD)/proto/?.lua;$(PWD)/lua/?.lua;$(PWD)/proto/?.lua;$(PWD)/tests/?.lua;$(PWD)/$(CAPNP_TEST)/?.lua;$(LUA_PATH);;
export VERBOSE

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

proto/example_capnp.lua: proto/example.capnp proto/enums.capnp proto/struct.capnp proto/lua.capnp
	capnp compile -obin/capnpc-lua $+

test: proto/example_capnp.lua
	tests/run_tests.sh

test1:
	capnp compile -olua $(CAPNP_TEST)/test.capnp ../capnproto/c++/src/capnp/c++.capnp
	$(MAKE) -C $(CAPNP_TEST) CAPNP_TEST_APP=`pwd`/bin/lua-capnproto-test

all: cpp/main

clean:
	-rm proto/example.capnp.c++ proto/example.capnp.h cpp/*.o cpp/main test.schema.lua proto/example_capnp.lua a.data c.data test.schema.txt *.data

release:
	@echo "Add git tag v$(VERSION)?"
	@read
	git tag -f v$(VERSION)
	git push --tags
	cp lua-capnproto.rockspec lua-capnproto-$(VERSION).rockspec
	luarocks pack lua-capnproto-$(VERSION).rockspec
	# increase version number
	@echo "Old version is \"$(VERSION)\""
	@echo "Enter new version: "
	read new_version; perl -pi -e "s/$(VERSION)/$$new_version/" Makefile bin/capnpc-lua lua-capnproto.rockspec
	

.PHONY: all clean test
