
boot.bin:
	nasm boot.S -f bin -o boot.bin

clean:
	rm -f boot.bin
