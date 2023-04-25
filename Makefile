
boot.bin: boot.S conio.inc gdt.inc kprot.inc
	nasm boot.S -f bin -l boot.lst -o boot.bin
	cat bzImage >> boot.bin

clean:
	rm -f boot.bin boot.lst
