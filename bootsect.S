/*
 * originally taken from linux 2.4 kernel source
 *	bootsect.S		Copyright (C) 1991, 1992 Linus Torvalds
 *
 *	modified by Drew Eckhardt
 *	modified by Bruce Evans (bde)
 *	modified by Chris Noe (May 1999) (as86 -> gas)
 *
 */

#include <asm/boot.h>

BOOTSEG		= 0x07C0		/* original address of boot-sector */
INITSEG		= DEF_INITSEG		/* we move boot here - out of the way */

.code16
.text

.global _start
_start:

# First things first. Move ourself from 0x7C00 -> 0x90000 and jump there.

	movw	$BOOTSEG, %ax
	movw	%ax, %ds		# %ds = BOOTSEG
	movw	$INITSEG, %ax
	movw	%ax, %es		# %ax = %es = INITSEG
	movw	$256, %cx
	subw	%si, %si
	subw	%di, %di
	cld
	rep
	movsw
	ljmp	$INITSEG, $go

# bde - changed 0xff00 to 0x4000 to use debugger at 0x6400 up (bde).  We
# wouldn't have to worry about this if we checked the top of memory.  Also
# my BIOS can be configured to put the wini drive tables in high memory
# instead of in the vector table.  The old stack might have clobbered the
# drive table.

go:	movw	$0x4000-12, %di		# 0x4000 is an arbitrary value >=
					# length of bootsect + length of
					# setup + room for stack;
					# 12 is disk parm size.
	movw	%ax, %ds		# %ax and %es already contain INITSEG
	movw	%ax, %ss
	movw	%di, %sp		# put stack at INITSEG:0x4000-12.

	movw	%cx, 0

	movb	$0x03, %ah		# read cursor pos
	xorb	%bh, %bh
	int	$0x10
	movw	$9, %cx
	movb	$0x07, %bl		# page 0, attribute 7 (normal)
					# %bh is set above; int10 doesn't
					# modify it
	movw	$msg1, %bp
	movw	$0x1301, %ax		# write string, move cursor
	int	$0x10			# tell the user we're loading..

	call	print_nl

	xor	%ax,%ax
	xor	%bx,%bx
	xor	%cx,%cx
	xor	%dx,%dx

# Do the test 
	movw	$0x3a,%cx
	rdmsr

# Print the registers
	push	%dx 
	push	%cx
	push	%bx
	push	%ax
	push	$0
	call	print_all

# After that we effectively halt the system
here:
	hlt
	jmp	here


# print_all is for debugging purposes.  
#
# it will print out all of the registers.  The assumption is that this is
# called from a routine, with a stack frame like
#
#	%dx 
#	%cx
#	%bx
#	%ax
#	(error)
#	ret <- %sp
 
print_all:
	movw	$5, %cx			# error code + 4 registers
	movw	%sp, %bp
print_loop:
	pushw	%cx			# save count remaining
	call	print_nl		# <-- for readability
	cmpb	$5, %cl
	jae	no_reg			# see if register name is needed
	
	movw	$0xe05 + 'A' - 1, %ax
	subb	%cl, %al
	int	$0x10
	movb	$'X', %al
	int	$0x10
	movb	$':', %al
	int	$0x10
no_reg:
	addw	$2, %bp			# next register
	call	print_hex		# print it
	popw	%cx
	loop	print_loop
	ret

print_nl:
	movw	$0xe0d, %ax		# CR
	int	$0x10
	movb	$0xa, %al		# LF
	int 	$0x10
	ret

# print_hex is for debugging purposes, and prints the word
# pointed to by %ss:%bp in hexadecimal.

print_hex:
	movw	$4, %cx			# 4 hex digits
	movw	(%bp), %dx		# load word into %dx
print_digit:
	rolw	$4, %dx			# rotate to use low 4 bits
	movw	$0xe0f, %ax		# %ah = request
	andb	%dl, %al		# %al = mask for nybble
	addb	$0x90, %al		# convert %al to ascii hex
	daa				# in only four instructions!
	adc	$0x40, %al
	daa
	int	$0x10
	loop	print_digit
	ret

msg1:		.byte 13, 10
		.ascii "Check.."

.org 497
setup_sects:	.byte 0
root_flags:	.word 0
syssize:	.word 0
swap_dev:	.word 0
ram_size:	.word 0
vid_mode:	.word 0
root_dev:	.word 0
boot_flag:	.word 0xAA55
