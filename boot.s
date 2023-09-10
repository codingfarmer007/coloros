#	boot.s
#
# It then loads the system at 0x10000, using BIOS interrupts. Thereafter
# it disables all interrupts, changes to protected mode, and calls the 
.code16

BOOTSEG = 0x07c0
SYSSEG  = 0x1000			# system loaded at 0x10000 (65536).
SYSLEN  = 17				# sectors occupied.

# 0. simply initiate running environment
.global start
.text
start:
	ljmp $BOOTSEG,$go		# far jmp to switch cs:ip
go:	movw %cs,%ax			# ss = es = ds = cs = BOOTSEG
	movw %ax,%ds
	movw %ax,%ss
	movw $0x400,%sp			# arbitrary value >>512

# 1. read file from disk to memory with BIOS interrupt (reference "PhoenixBIOS 4.0 Programmer’s Guide")
# ok, we've written the message, now
load_system:
	movw $0x0000,%dx		# DL = 0 Drive number, DH = 0 Head number
	movw $0x0002,%cx		# CH = 0 Track number, CL = 2 Sector number (index from 1)
	movw $SYSSEG,%ax		# ES:BX Buffer address (SYSSEG:0x0000)
	movw %ax,%es
	xor  %bx,%bx
	movw $0x200+SYSLEN,%ax 	# AH = 02h Read disk sectors, AL = SYSLEN Number of sectors (1-80h for read)
	int  $0x13				# read file with offset 512 to memory 0x10000
	jnc	ok_load				# If Carry = 1 an error has happened, otherwise AH 00h = No error. AL = Number of sectors transferred
die:	jmp	die				# hang up

# now we want to move to protected mode ...
ok_load:
	cli			# no interrupts allowed #
	movw $SYSSEG,%ax		# copy system from ds:si (0x10000=SYSSEG:0) to es:di (0x0000=0:0)
	movw %ax,%ds
	xor  %ax,%ax
	movw %ax,%es
	movw $(SYSLEN*512/2),%cx	# copy length is (SYSLEN*512/2)*2=0x2200
	subw %si,%si
	subw %di,%di
	rep  movsw

	movw $BOOTSEG,%ax	# ds = BOOTSEG
	movw %ax,%ds
	lidt	idt_48		# load idt with 0,0
	lgdt	gdt_48		# load gdt with whatever appropriate

# absolute address 0x00000, in 32-bit protected mode.
	movw $0x0001, %ax	# protected mode (PE) bit
	lmsw %ax		# This is it#
	ljmp $8,$0		# jmp offset 0 of segment 8 (cs)

gdt:	.word	0,0,0,0		# dummy

	.word	0x07FF		# 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000		# base address=0x00000
	.word	0x9A00		# code read/exec
	.word	0x00C0		# granularity=4096, 386

	.word	0x07FF		# 8Mb - limit=2047 (2048*4096=8Mb)
	.word	0x0000		# base address=0x00000
	.word	0x9200		# data read/write
	.word	0x00C0		# granularity=4096, 386

idt_48: .word	0		# idt limit=0
	.word	0,0		# idt base=0L
gdt_48: .word	0x7ff		# gdt limit=2048, 256 GDT entries
	.word	0x7c00+gdt,0	# gdt base = 07xxx
.org 510
	.word   0xAA55

