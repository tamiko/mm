prefix=__gnu_as_

cpp=cpp
cpp_args=-D__GNU_AS -D__MMIXWARE
as=mmix-as
as_args=-g -x -linker-allocated-gregs
ld=mmix-ld
ld_args=-g
ar=mmix-ar
ar_args=cru
ranlib=mmix-ranlib

sources:=$(wildcard ../src/$(prefix)*.mms)
objects:=$(patsubst ../src/$(prefix)%.mms,%.o,$(sources))
objects:=$(filter-out mmi.o,$(objects))

all: libmm.a mmi.o $(objects)

%.i: ../src/$(prefix)%.mms ../include/mm/__internal/__%.mmh
	$(cpp) $(cpp_args) -I../include $< -o $@

%.o: %.i
	$(as) $(as_args) $< -o $@

libmm.a: $(objects)
	$(ar) $(ar_args) $@ $^
	$(ranlib) $@

clean:
	rm -f *.s *.o *.mmo *.a
