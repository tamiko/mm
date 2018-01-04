mmixc=mmixc

sources:=$(wildcard *.mms)
objects:=$(patsubst %.mms,%.mmo,$(sources))

all: $(objects)

%.mmo: %.mms ../lib/libmm.a ../lib/mmi.o ../lib/mmo.o
	$(mmixc) $< -o $@

clean:
	rm -f *.s *.o *.mmo *.a
