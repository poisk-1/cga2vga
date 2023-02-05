src = test.asm
part = AT28C256
rom_size_kb = 32

.PHONY: all
all: test.rom

test.bin: $(src)
	nasm -f bin -o $@ -l test.lst $(src)

romify: romify.c
	gcc -o $@ -DROM_SIZE_KB=$(rom_size_kb) romify.c

test.rom: romify test.bin
	./romify test.bin $@

.PHONY: clean
clean:
	$(RM) test.bin
	$(RM) test.rom
	$(RM) romify

.PHONY: program
program: test.rom
	minipro -p $(part) -w test.rom
