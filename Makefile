# Makefile for the simple example kernel.
AS	=as
LD	=ld
LDFLAGS =-m elf_i386 -Ttext 0 -s -x -M --oformat binary
ASFLAGS =--gstabs+ --32

all:	Image

# 2880=80*2*18
Image: boot system
	dd bs=512 count=2880 if=/dev/zero of=$@
	dd bs=32 if=boot of=$@ conv=notrunc
	dd bs=512 if=system of=$@ seek=1 conv=notrunc
	sync

head.o: head.s
	$(AS) $(ASFLAGS) -o head.o head.s

system:	head.o 
	$(LD) $(LDFLAGS) head.o  -o system -e startup_32 > System.map

boot:	boot.s
	$(AS) $(ASFLAGS) -o boot.o boot.s
	$(LD) $(LDFLAGS) -e start -o boot boot.o

clean:
	rm -f Image System.map boot *.o system
