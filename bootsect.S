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
	movw	$check, %si
	call	msg

	call	print_nl

# clear registers before testing
	xorl	%eax,%eax
	xorl	%ebx,%ebx
	xorl	%ecx,%ecx
	xorl	%edx,%edx

# perform cpuid 0
	movw	$cpuid0, %si
	call	msg

	cpuid
	call	print_regs

# Do the test 
#	movw	$0x3a,%cx
#	rdmsr


# After that we effectively halt the system
here:
	hlt
	jmp	here


print_regs:
	pushl	%edx 
	pushl	%ecx
	pushl	%ebx
	pushl	%eax
	movw	$4, %cx			# 4 longwords to print
	movw	%sp, %bp

print_regs1:
	pushw	%cx			# save count remaining
	
	movw	$0xe20, %ax
	int	$0x10
	movw	$0xe05 + 'A' - 1, %ax
	subb	%cl, %al
	int	$0x10
	movb	$'X', %al
	int	$0x10
	movb	$':', %al
	int	$0x10

	addw	$4, %bp			# next register
	call	print_long		# print it

	movw	$0xe20, %ax
	int	$0x10
	call	print_lstr		# print the ascii rendition

	popw	%cx
	loop	print_regs1
	
	addw	$4 * 4, %sp
	call	print_nl
	ret

print_long:
	movw	$8, %cx			# 8 hex digits
	movl	(%bp), %edx		# load word into %edx
print_ldigit:
	roll	$4, %edx		# rotate to use low 4 bits
	movw	$0xe0f, %ax		# %ah = request
	andb	%dl, %al		# %al = mask for nybble
	addb	$0x90, %al		# convert %al to ascii hex
	daa				# in only four instructions!
	adc	$0x40, %al
	daa
	int	$0x10
	loop	print_ldigit
	ret

print_lstr:
	movw	$4, %cx			# 4 characters
	movl	(%bp), %edx		# load word into %edx
print_lstr1:
	roll	$8, %edx		# rotate to use low 8 bits
	movb	$0xe, %ah		# %ah = request
	movb	%dl, %al		# %al = mask for nybble
	int	$0x10
	loop	print_lstr1
	ret

print_nl:
	movw	$0xe0d, %ax		# CR
	int	$0x10
	movb	$0xa, %al		# LF
	int 	$0x10
	ret

msg:
	lodsb
	and	%al,%al
	jz	now
	movb	$0x0e,%ah
	movb	$0x07,%bl
	int	$0x10
	jmp	msg
now:
	ret

check:		.ascii "Check.."
		.byte 13, 10,0

cpuid0:		.ascii "CPUID0:"
		.byte 13,10,0
cpuid1:		.ascii "CPUID1:"
		.byte 13,10,0

.org 497
setup_sects:	.byte 0
root_flags:	.word 0
syssize:	.word 0
swap_dev:	.word 0
ram_size:	.word 0
vid_mode:	.word 0
root_dev:	.word 0
boot_flag:	.word 0xAA55
