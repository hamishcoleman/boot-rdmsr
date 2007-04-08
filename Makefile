#
# This file originally taken from the linux 2.4 kernel source
#
# arch/i386/boot/Makefile
#
# This file is subject to the terms and conditions of the GNU General Public
# License.  See the file "COPYING" in the main directory of this archive
# for more details.
#
# Copyright (C) 1994 by Linus Torvalds
#

checkvmx.com: checkvmx.o
	$(LD) -Ttext 0x0 -s --oformat binary -o $@ $<

checkvmx.o: checkvmx.s
	$(AS) -o $@ $<

checkvmx.s: checkvmx.S Makefile #$(BOOT_INCL)
	$(CPP) $(CPPFLAGS) -traditional $(SVGA_MODE) $(RAMDISK) $< -o $@

clean:
	rm -f checkvmx checkvmx.s checkvmx.o
