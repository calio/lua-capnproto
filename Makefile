VERSION:=0.1.4-4
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

test: clean proto/example_capnp.lua
	tests/run_tests.sh

test1:
	capnp compile -olua $(CAPNP_TEST)/test.capnp ../capnproto/c++/src/capnp/c++.capnp
	$(MAKE) -C $(CAPNP_TEST) CAPNP_TEST_APP=`pwd`/bin/lua-capnproto-test

all: cpp/main

clean:
	-rm proto/example.capnp.c++ proto/example.capnp.h cpp/*.o cpp/main test.schema.lua proto/example_capnp.lua a.data c.data test.schema.txt *.data

tag_and_pack:
ifeq ($(shell git tag --sort=version:refname|tail -n 1), v$(VERSION))
	@echo "Need to \"make version\" first"
	@exit 1
endif
	@echo "Add git tag v$(VERSION)?"
	@read -r FOO
	git tag -f v$(VERSION)
	@echo "Push tags?"
	@read -r FOO
	git push --tags
	@echo "Build package?"
	@read -r FOO
	#cp lua-capnproto.rockspec lua-capnproto-$(VERSION).rockspec
	luarocks pack rockspec/lua-capnproto-$(VERSION).rockspec

version:
	@echo "Old version is \"$(VERSION)\""
	@echo "Enter new version: "
	@# The use of variable "new_version" ($$new_version) should be in the same line as where it gets its value
	@read new_version; perl -pi -e "s/$(VERSION)/$$new_version/" Makefile bin/capnpc-lua rockspec/lua-capnproto.rockspec; cp rockspec/lua-capnproto.rockspec rockspec/lua-capnproto-$$new_version.rockspec
	git add Makefile bin/capnpc-lua rockspec/lua-capnproto.rockspec rockspec/lua-capnproto-*.rockspec
	git commit -m 'Bump version number'

release: tag_and_pack

release_clean:
	-rm -f lua-capnproto-*.rockspec *.rock

.PHONY: all clean test release
