cpp=cpp
cpp_args=-D__GNU_AS -D__MMIXWARE -DSTATISTICS
as=mmix-as
as_args=-g -x -linker-allocated-gregs
ld=mmix-ld
ld_args=-g
ar=mmix-ar
ar_args=cru
ranlib=mmix-ranlib

sources:=$(wildcard ../src/*.mms)
objects:=$(patsubst ../src/%.mms,%.o,$(sources))
objects:=$(filter-out mmi.o mmo.o guard.o,$(objects))

all: libmm.a mmi.o mmo.o guard.o $(objects)

%.i: ../src/%.mms ../src/statistics.mmh
	$(cpp) $(cpp_args) -I../include $< -o $@

%.o: %.i
	$(as) $(as_args) $< -o $@

libmm.a: $(objects)
	$(ar) $(ar_args) $@ $^
	$(ranlib) $@

clean:
	rm -f *.s *.o *.mmo *.a
