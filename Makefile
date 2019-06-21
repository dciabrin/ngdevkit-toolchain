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
DESTDIR=local
prefix=
libexecdir=
export DESTDIR
export prefix
export libexecdir=libexec

# There are faster mirrors for downloading the toolchain
GNU_MIRROR=ftp://ftp.gnu.org/gnu
NEWLIB_MIRROR=ftp://sourceware.org/pub
# GNU_MIRROR=https://mirror.checkdomain.de/gnu
# NEWLIB_MIRROR=http://ftp.gwdg.de/pub/linux/sources.redhat.com

# Version of external dependencies
SRC_BINUTILS=binutils-2.32
SRC_GCC=gcc-5.5.0
SRC_NEWLIB=newlib-1.14.0
SRC_GDB=gdb-7.8.2
SRC_SDCC=sdcc-src-3.7.0

TOOLCHAIN=ngbinutils nggcc ngnewlib ngsdcc nggdb



all: \
	download-toolchain \
	unpack-toolchain \
	build-toolchain

install:
	for i in $(TOOLCHAIN); do \
	  $(MAKE) -C build/$$i install; \
	done



download-toolchain: \
	toolchain/$(SRC_BINUTILS).tar.bz2 \
	toolchain/$(SRC_GCC).tar.xz \
	toolchain/$(SRC_NEWLIB).tar.gz \
	toolchain/$(SRC_GDB).tar.gz \
	toolchain/$(SRC_SDCC).tar.bz2

unpack-toolchain: \
	toolchain/$(SRC_BINUTILS) \
	toolchain/$(SRC_GCC) \
	toolchain/$(SRC_NEWLIB) \
	toolchain/$(SRC_GDB) \
	toolchain/sdcc

toolchain/%:
	tar -C toolchain -xmf toolchain/$(notdir $<)


toolchain/$(SRC_BINUTILS).tar.bz2:
	curl -L $(GNU_MIRROR)/binutils/$(notdir $@) -o $@

toolchain/$(SRC_GCC).tar.xz:
	curl -L $(GNU_MIRROR)/gcc/$(SRC_GCC)/$(notdir $@) -o $@

toolchain/$(SRC_NEWLIB).tar.gz:
	curl -L $(NEWLIB_MIRROR)/newlib/$(notdir $@) -o $@

toolchain/$(SRC_GDB).tar.gz:
	curl -L $(GNU_MIRROR)/gdb/$(notdir $@) -o $@

toolchain/$(SRC_SDCC).tar.bz2:
	curl -L http://sourceforge.net/projects/sdcc/files/sdcc/$(SRC_SDCC:sdcc-src-%=%)/$(notdir $@) -o $@


toolchain/$(SRC_BINUTILS): toolchain/$(SRC_BINUTILS).tar.bz2
toolchain/$(SRC_GCC): toolchain/$(SRC_GCC).tar.xz
toolchain/$(SRC_NEWLIB): toolchain/$(SRC_NEWLIB).tar.gz
toolchain/$(SRC_GDB): toolchain/$(SRC_GDB).tar.gz
toolchain/sdcc: toolchain/$(SRC_SDCC).tar.bz2



build-toolchain: $(TOOLCHAIN:%=build/%)

build:
	mkdir $@

build/ngbinutils: build
	@ echo compiling binutils...; \
	mkdir -p build/ngbinutils && \
	cd build/ngbinutils && \
	../../toolchain/$(SRC_BINUTILS)/configure \
	--prefix=$(prefix) \
	--libexecdir=$(libexecdir) \
	--target=m68k-neogeo-elf \
	--with-system-zlib \
	-v && \
	make

build/nggcc: build/ngbinutils
	@ echo compiling gcc...; \
	mkdir -p build/nggcc && \
	cd build/nggcc && \
	echo "replacing old texi2pod.pl (causes errors with recent perl)" && \
	cp ../../toolchain/$(SRC_BINUTILS)/etc/texi2pod.pl ../../toolchain/$(SRC_GCC)/contrib/texi2pod.pl && \
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
	../../toolchain/$(SRC_GCC)/configure \
	--prefix=$(prefix) \
	--libexecdir=$(libexecdir) \
	--target=m68k-neogeo-elf \
	--with-system-zlib \
	--with-cpu=m68000 \
	--with-threads=single \
	--with-gnu-as \
	--with-gnu-ld \
	--with-newlib \
	--disable-multilib \
	--disable-libssp \
	--enable-languages=c \
	-v && \
	make

build/ngnewlib: build/nggcc build/ngbinutils
	@ echo compiling newlib...; \
	mkdir -p build/ngnewlib && \
	cd build/ngnewlib && \
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
	../../toolchain/newlib-1.14.0/configure \
	--prefix=$(prefix) \
	--libexecdir=$(libexecdir) \
	--target=m68k-neogeo-elf \
	--enable-target-optspace=yes \
	--enable-newlib-multithread=no \
	-v && \
	make

build/nggdb: build
	@ echo compiling gdb...; \
	mkdir -p build/nggdb && \
	cd build/nggdb && \
	echo "replacing old texi2pod.pl (causes errors with recent perl)" && \
	cp ../../toolchain/$(SRC_BINUTILS)/etc/texi2pod.pl ../../toolchain/$(SRC_GDB)/etc/texi2pod.pl && \
	../../toolchain/$(SRC_GDB)/configure \
	--prefix=$(prefix) \
	--libexecdir=$(libexecdir) \
	--target=m68k-neogeo-elf \
	-v && \
	make

build/ngsdcc: build
	@ echo compiling sdcc...; \
	mkdir -p build/ngsdcc && \
	cd build/ngsdcc && \
	../../toolchain/sdcc/configure \
        --program-prefix=z80-neogeo- \
        --prefix=$(prefix) \
	--libexecdir=$(libexecdir) \
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
	-v && \
	make

clean:
	rm -rf build

distclean: clean
	find toolchain -mindepth 1 -maxdepth 1 -not -name README.md -exec rm -rf {} \;
	rm -rf build local
	find . -name '*~' -exec rm -f {} \;

.PHONY: clean distclean