# Copyright (c) 2019 Damien Ciabrini
# This file is part of ngdevkit
#
# ngdevkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# ngdevkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with ngdevkit.  If not, see <http://www.gnu.org/licenses/>.


VERSION=0.1

# Toolchain will be installed under $DESTDIR/$prefix
BUILD=build
DESTDIR=
prefix=$(PWD)/local/usr
export DESTDIR
export prefix

# There are faster mirrors for downloading the toolchain
GNU_MIRROR=ftp://ftp.gnu.org/gnu
NEWLIB_MIRROR=ftp://sourceware.org/pub
# GNU_MIRROR=https://mirror.checkdomain.de/gnu
# NEWLIB_MIRROR=http://ftp.gwdg.de/pub/linux/sources.redhat.com

# Local copy of the toolchain packages to skip download
LOCAL_PACKAGE_DIR=

# Version of external dependencies
SRC_BINUTILS=binutils-2.32
SRC_GCC=gcc-5.5.0
SRC_NEWLIB=newlib-4.0.0
SRC_GDB=gdb-8.3.1
SRC_SDCC=sdcc-src-3.7.0

TOOLCHAIN=ngbinutils nggcc ngnewlib ngsdcc nggdb


all: \
	download-toolchain \
	unpack-toolchain \
	build-toolchain


download-toolchain: \
	toolchain/$(SRC_BINUTILS).tar.bz2 \
	toolchain/$(SRC_GCC).tar.xz \
	toolchain/$(SRC_NEWLIB).tar.gz \
	toolchain/$(SRC_GDB).tar.xz \
	toolchain/$(SRC_SDCC).tar.bz2

unpack-toolchain: \
	toolchain/$(SRC_BINUTILS) \
	toolchain/$(SRC_GCC) \
	toolchain/$(SRC_NEWLIB) \
	toolchain/$(SRC_GDB) \
	toolchain/sdcc

clean-toolchain:
	find toolchain -mindepth 1 -maxdepth 1 -not -name README.md -exec rm -rf {} \;

toolchain/%:
	tar -C toolchain -xmf toolchain/$(notdir $<)


ifndef LOCAL_PACKAGE_DIR
toolchain/$(SRC_BINUTILS).tar.bz2:
	curl -L $(GNU_MIRROR)/binutils/$(notdir $@) -o $@

toolchain/$(SRC_GCC).tar.xz:
	curl -L $(GNU_MIRROR)/gcc/$(SRC_GCC)/$(notdir $@) -o $@

toolchain/$(SRC_NEWLIB).tar.gz:
	curl -L $(NEWLIB_MIRROR)/newlib/$(notdir $@) -o $@

toolchain/$(SRC_GDB).tar.xz:
	curl -L $(GNU_MIRROR)/gdb/$(notdir $@) -o $@

toolchain/$(SRC_SDCC).tar.bz2:
	curl -L http://sourceforge.net/projects/sdcc/files/sdcc/$(SRC_SDCC:sdcc-src-%=%)/$(notdir $@) -o $@
else
toolchain/$(SRC_BINUTILS).tar.bz2 \
toolchain/$(SRC_GCC).tar.xz \
toolchain/$(SRC_NEWLIB).tar.gz \
toolchain/$(SRC_GDB).tar.xz \
toolchain/$(SRC_SDCC).tar.bz2:
	cp $(LOCAL_PACKAGE_DIR)/$(notdir $@) $@
endif


toolchain/$(SRC_BINUTILS): toolchain/$(SRC_BINUTILS).tar.bz2
toolchain/$(SRC_GCC): toolchain/$(SRC_GCC).tar.xz
toolchain/$(SRC_NEWLIB): toolchain/$(SRC_NEWLIB).tar.gz
toolchain/$(SRC_GDB): toolchain/$(SRC_GDB).tar.xz
toolchain/sdcc: toolchain/$(SRC_SDCC).tar.bz2


build-toolchain: $(TOOLCHAIN:%=$(BUILD)/%)

$(BUILD)/ngbinutils: toolchain/$(SRC_BINUTILS)
	@echo compiling binutils...
	CURPWD=$$(pwd) && \
	mkdir -p $(BUILD)/ngbinutils && \
	cd $(BUILD)/ngbinutils && \
	sed -i -e 's/\(@item\) \(How GNU properties are merged.\)/\1'$$'\\\n''\2/' $$CURPWD/toolchain/binutils-2.32/ld/ld.texi  && \
	$$CURPWD/toolchain/$(SRC_BINUTILS)/configure \
	--target=m68k-neogeo-elf \
	--prefix=$(prefix) \
	--exec-prefix=$(prefix) \
	--libexecdir=$(prefix)/m68k-neogeo-elf/lib \
	--datarootdir=$(prefix)/m68k-neogeo-elf \
	--datadir=$(prefix)/m68k-neogeo-elf/lib \
	--includedir=$(prefix)/m68k-neogeo-elf/include \
	--bindir=$(prefix)/bin \
	-v && $(MAKE)

# Rationale: we split prefix and exec-prefix so to force gcc to
# install in a dedicated arch subdir ($PREFIX/m68k-neogeo-elf) and
# prevent overwriting existing files (e.g. in /usr/lib/gcc*). But in
# doing so we break gcc's default search dirs
# ($PREFIX/lib/gcc/m68k-neogeo-elf/5.5.0/../../../../m68k-neogeo-elf/m68k-neogeo-elf/lib)
# so we need to tweak build variable prefix_to_exec_prefix
$(BUILD)/nggcc: $(BUILD)/ngbinutils toolchain/$(SRC_GCC)
	@echo compiling gcc...
	CURPWD=$$(pwd) && \
	mkdir -p $(BUILD)/nggcc && \
	cd $(BUILD)/nggcc && \
	echo "replacing old texi2pod.pl (causes errors with recent perl)" && \
	cp $$CURPWD/toolchain/$(SRC_BINUTILS)/etc/texi2pod.pl $$CURPWD/toolchain/$(SRC_GCC)/contrib/texi2pod.pl && \
	AR_FOR_TARGET=$$PWD/../ngbinutils/binutils/ar \
	AS_FOR_TARGET=$$PWD/../ngbinutils/gas/as-new \
	LD_FOR_TARGET=$$PWD/../ngbinutils/ld/ld-new \
	NM_FOR_TARGET=$$PWD/../ngbinutils/binutils/nm-new \
	OBJCOPY_FOR_TARGET=$$PWD/../ngbinutils/binutils/objcopy \
	OBJDUMP_FOR_TARGET=$$PWD/../ngbinutils/binutils/objdump \
	RANLIB_FOR_TARGET=$$PWD/../ngbinutils/binutils/ranlib \
	READELF_FOR_TARGET=$$PWD/../ngbinutils/binutils/readelf \
	STRIP_FOR_TARGET=$$PWD/../ngbinutils/binutils/strip-new \
	CFLAGS="$$CFLAGS -Wno-format-security" \
	CXXFLAGS="$$CXXFLAGS -Wno-format-security" \
	$$CURPWD/toolchain/gcc-5.5.0/configure \
	--target=m68k-neogeo-elf \
	--prefix=$(prefix) \
	--exec-prefix=$(prefix)/m68k-neogeo-elf \
	--libexecdir=$(prefix)/m68k-neogeo-elf/lib \
	--datarootdir=$(prefix)/m68k-neogeo-elf \
	--datadir=$(prefix)/m68k-neogeo-elf/lib \
	--includedir=$(prefix)/m68k-neogeo-elf/include \
	--bindir=$(prefix)/bin \
	--with-system-zlib \
	--with-cpu=m68000 \
	--with-threads=single \
	--with-gnu-as \
	--with-gnu-ld \
	--with-newlib \
	--without-isl \
	--disable-multilib \
	--disable-libssp \
	--enable-languages=c \
	-v && $(MAKE) --eval 'override prefix_to_exec_prefix = ' tooldir=$(prefix)/m68k-neogeo-elf build_tooldir=$(prefix)/m68k-neogeo-elf

$(BUILD)/ngnewlib: $(BUILD)/nggcc toolchain/$(SRC_NEWLIB)
	@echo compiling newlib...
	CURPWD=$$(pwd) && \
	mkdir -p $(BUILD)/ngnewlib && \
	cd $(BUILD)/ngnewlib && \
	CC_FOR_TARGET="$$PWD/../nggcc/gcc/gcc-cross -B$$PWD/../nggcc/gcc" \
	AR_FOR_TARGET=$$PWD/../ngbinutils/binutils/ar \
	AS_FOR_TARGET=$$PWD/../ngbinutils/gas/as-new \
	LD_FOR_TARGET=$$PWD/../ngbinutils/ld/ld-new \
	NM_FOR_TARGET=$$PWD/../ngbinutils/binutils/nm-new \
	OBJCOPY_FOR_TARGET=$$PWD/../ngbinutils/binutils/objcopy \
	OBJDUMP_FOR_TARGET=$$PWD/../ngbinutils/binutils/objdump \
	RANLIB_FOR_TARGET=$$PWD/../ngbinutils/binutils/ranlib \
	READELF_FOR_TARGET=$$PWD/../ngbinutils/binutils/readelf \
	STRIP_FOR_TARGET=$$PWD/../ngbinutils/binutils/strip-new \
	$$CURPWD/toolchain/newlib-4.0.0/configure \
	--prefix=$(prefix) \
	--libexecdir=$(prefix)/m68k-neogeo-elf/lib \
	--infodir=$(prefix)/m68k-neogeo-elf/info \
	--target=m68k-neogeo-elf \
	--bindir=$(prefix)/bin \
	--enable-target-optspace=yes \
	--enable-newlib-multithread=no \
	--enable-newlib-reent-small \
	--disable-newlib-reent-check-verify \
	--disable-newlib-fvwrite-in-streamio \
	--disable-newlib-fseek-optimization \
	--disable-newlib-wide-orient \
	--enable-newlib-nano-malloc \
	--disable-newlib-unbuf-stream-opt \
	--enable-lite-exit \
	--enable-newlib-global-atexit \
	--enable-newlib-nano-formatted-io \
	--disable-nls \
	-v && $(MAKE)

$(BUILD)/nggdb: toolchain/$(SRC_BINUTILS) toolchain/$(SRC_GDB)
	@echo compiling gdb...
	CURPWD=$$(pwd) && \
	mkdir -p $(BUILD)/nggdb && \
	cd $(BUILD)/nggdb && \
	echo "replacing old texi2pod.pl (causes errors with recent perl)" && \
	cp $$CURPWD/toolchain/$(SRC_BINUTILS)/etc/texi2pod.pl $$CURPWD/toolchain/$(SRC_GDB)/etc/texi2pod.pl && \
	$$CURPWD/toolchain/$(SRC_GDB)/configure \
	--prefix=$(prefix) \
	--exec-prefix=$(prefix)/m68k-neogeo-elf \
	--libexecdir=$(prefix)/m68k-neogeo-elf/lib \
	--datarootdir=$(prefix)/m68k-neogeo-elf \
	--datadir=$(prefix)/m68k-neogeo-elf/lib \
	--includedir=$(prefix)/m68k-neogeo-elf/include \
	--bindir=$(prefix)/bin \
	--target=m68k-neogeo-elf \
	-v && $(MAKE)

$(BUILD)/ngsdcc: toolchain/sdcc
	@echo compiling sdcc...
	CURPWD=$$(pwd) && \
	unset CPPFLAGS && \
	mkdir -p $(BUILD)/ngsdcc && \
	cd $(BUILD)/ngsdcc && \
	include_dir_suffix=include \
	lib_dir_suffix=lib \
	$$CURPWD/toolchain/sdcc/configure \
	--program-prefix=z80-neogeo-ihx- \
	--prefix=$(prefix) \
	--libexecdir=$(prefix)/z80-neogeo-ihx/lib \
	--datarootdir=$(prefix)/z80-neogeo-ihx \
	--disable-non-free \
	--enable-z80-port \
	--disable-pic14-port \
	--disable-pic16-port \
	--disable-ds390-port \
	--disable-ds400-port \
	--disable-hc08-port \
	--disable-s08-port \
	--disable-mcs51-port \
	--disable-z180-port \
	--disable-r2k-port \
	--disable-r3ka-port \
	--disable-gbz80-port \
	--disable-tlcs90-port \
	--disable-stm8-port \
	-v && $(MAKE)


install: $(TOOLCHAIN:%=install-%)

install-ngbinutils: $(BUILD)/ngbinutils
	$(MAKE) -C $(BUILD)/ngbinutils install

install-nggcc: $(BUILD)/nggcc
	$(MAKE) -C $(BUILD)/nggcc install build_tooldir=$(prefix)/m68k-neogeo-elf --eval 'override toolexecdir = $$(exec_prefix)' --eval 'override build_tooldir = '$(prefix)'/m68k-neogeo-elf'

install-ngnewlib: $(BUILD)/ngnewlib
	$(MAKE) -C $(BUILD)/ngnewlib install

install-nggdb: $(BUILD)/nggdb
	$(MAKE) -C $(BUILD)/nggdb install --eval 'override gnulocaledir = $$(localedir)'

install-ngsdcc: $(BUILD)/ngsdcc
	$(MAKE) -C $(BUILD)/ngsdcc install DESTDIR=$(DESTDIR) && \
	rm -rf $(DESTDIR)$(prefix)/z80-neogeo-ihx/lib/src && \
	find $(DESTDIR)$(prefix)/z80-neogeo-ihx/lib/ -type d -empty -delete


clean:
	rm -rf build

distclean: clean clean-toolchain
	rm -rf build local && \
	find . -name '*~' -exec rm -f {} \;

.PHONY: clean distclean
