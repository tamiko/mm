mmixc=mmixc

sources:=$(wildcard *.mms)
objects:=$(patsubst %.mms,%.mmo,$(sources))

all: $(objects)

%.mmo: %.mms
	$(mmixc) $< -o $@

clean:
	rm -f *.s *.o *.mmo *.a
