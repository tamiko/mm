prefix=__gnu_as_

cpp=cpp
cpp_args=-D__GNU_AS -D__MMIXWARE
as=mmix-as
as_args=-linker-allocated-gregs
ld=mmix-ld
ld_args=
ar=mmix-ar
ar_args=cru
ranlib=mmix-ranlib

all: libmm.a $(objects)

sources:=$(wildcard ../src/$(prefix)*.mms)
preproc:=$(patsubst ../src/$(prefix)%.mms,%.s,$(sources))
objects:=$(patsubst ../src/$(prefix)%.mms,%.o,$(sources))

%.s: ../src/$(prefix)%.mms ../src/__%.mmh
	$(cpp) $(cpp_args) -I../include $< -o $@

%.s: ../src/$(prefix)%.mms ../src/__mmix_sim_%.mmh
	$(cpp) $(cpp_args) -I../include $< -o $@

%.s: ../src/$(prefix)%.mms ../src/__strs.mmh
	$(cpp) $(cpp_args) -I../include $< -o $@

%.s: ../src/$(prefix)%.mms
	$(cpp) $(cpp_args) -I../include $< -o $@

%.o: %.s
	$(as) $(as_args) $< -o $@

libmm.a: $(objects)
	$(ar) $(ar_args) $@ $^
	$(ranlib) $@

clean:
	rm -f *.s *.o *.mmo *.a
