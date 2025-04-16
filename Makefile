EMU=rars
SRC=$(shell find src -name "*.asm")

all: run

run: $(SRC)
	$(EMU) $^

debug: $(SRC)
	$(EMU) d $^
