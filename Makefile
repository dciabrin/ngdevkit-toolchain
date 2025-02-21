# Copyright (c) 2019-2025 Damien Ciabrini
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

# Extra commands to run during "configure && make"
# For platform-specific configuration
EXTRA_BUILD_CMD=true
EXTRA_BUILD_FLAGS=

# Common tools
REALPATH=realpath

# Version of external dependencies
SRC_BINUTILS=binutils-2.35.2
SRC_GCC=gcc-11.4.0
SRC_NEWLIB=newlib-4.0.0
SRC_GDB=gdb-9.2
SRC_SDCC=sdcc-src-4.4.0

TOOLCHAIN=ngbinutils nggcc ngnewlib ngsdcc nggdb

# GCC: compilation flags to support all compilers / OS
#
# per-file workarounds:
# -DCINTERFACE: fix build issue on MSYS2/UCRT64, caused by windows.h being included after gcc/system.h
#
GCC_C_BUILD_FLAGS=\
-Wno-strict-prototypes -Wno-implicit-function-declaration \
-Wno-old-style-definition -Wno-missing-prototypes \
-Wno-unknown-warning-option -Wno-array-bounds \
-Wno-incompatible-pointer-types
GCC_CXX_BUILD_FLAGS=\
-Wno-array-bounds -Wno-deprecated  \
-Wno-format-security -Wno-string-plus-int -Wno-shift-count-overflow \
-Wno-ignored-attributes -Wno-unknown-warning-option \
-Wno-enum-compare-switch -Wno-mismatched-tags -Wno-c++11-narrowing
GCC_GMAKE_OVERRIDES= \
--eval 'override CFLAGS-prefix.o = -DPREFIX=\"$$(prefix)\" -DBASEVER=$$(BASEVER_s) -DCINTERFACE' \
--eval 'override CFLAGS-diagnostic-color.o = -DCINTERFACE' \
--eval 'override GCC_WARN_CFLAGS = ' \
--eval 'override GCC_WARN_CXXFLAGS = ' \
--eval 'override WARN_CFLAGS = ' \
--eval 'override WARN_CXXFLAGS = ' \
--eval 'override LOOSE_WARN = ' \
--eval 'override C_LOOSE_WARN = ' \
--eval 'override STRICT_WARN = ' \
--eval 'override C_STRICT_WARN = '


# GDB: compilation flags to support all compilers / OS
GDB_C_BUILD_FLAGS=\
-Wno-deprecated-declarations -Wno-incompatible-library-redeclaration \
-Wno-visibility -Wno-unused-value -Wno-unknown-warning-option \
-Wno-implicit-function-declaration
GDB_CXX_BUILD_FLAGS= \
-Wno-deprecated-copy-dtor -Wno-enum-constexpr-conversion
GDB_LD_BUILD_FLAGS=
GDB_PKG_CONFIG_PATH=

ifeq ($(shell uname -s),Darwin)
HOMEBREW_PREFIX=$(shell PATH="$$PATH:/opt/homebrew/bin:/usr/local/bin" brew --prefix)

CFLAGS=-I$(HOMEBREW_PREFIX)/include
CXXFLAGS=-I$(HOMEBREW_PREFIX)/include
CPPFLAGS=-I$(HOMEBREW_PREFIX)/include
LDFLAGS=-L$(HOMEBREW_PREFIX)/lib -Wl,-rpath,$(HOMEBREW_PREFIX)/lib
EXTRA_BUILD_CMD=export CFLAGS="$$CFLAGS $(CFLAGS)" CXXFLAGS="$$CXXFLAGS $(CXXFLAGS)" CPPFLAGS="$$CPPFLAGS $(CPPFLAGS)" LDFLAGS="$$LDFLAGS $(LDFLAGS)"

GCC_C_BUILD_FLAGS+=-DHAVE_SETLOCALE
GCC_CXX_BUILD_FLAGS+=-DHAVE_SETLOCALE

GDB_C_BUILD_FLAGS+=-I$(HOMEBREW_PREFIX)/opt/readline/include
GDB_CXX_BUILD_FLAGS+=-I$(HOMEBREW_PREFIX)/opt/readline/include
GDB_LD_BUILD_FLAGS+=-L$(HOMEBREW_PREFIX)/opt/readline/lib
GDB_PKG_CONFIG_PATH+=$(HOMEBREW_PREFIX)/opt/readline/lib/pkgconfig

REALPATH=$(HOMEBREW_PREFIX)/bin/grealpath
endif

ifeq ($(shell uname -o),Msys)
EXTRA_BUILD_FLAGS+=--build=$(MINGW_CHOST) --host=$(MINGW_CHOST)

GCC_C_BUILD_FLAGS+=-DHAVE_SETLOCALE
GCC_CXX_BUILD_FLAGS+=-DHAVE_SETLOCALE
endif


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
	toolchain/sdcc-$(SRC_SDCC:sdcc-src-%=%)

clean-toolchain:
	find toolchain -mindepth 1 -maxdepth 1 -not -name README.md -exec rm -rf {} \;

# we have to customize the extract of newlib as the tarball contains a
# symlink which can not reliably be extracted under MSYS2
toolchain/$(SRC_NEWLIB):
	tar -C toolchain -xmf toolchain/$(notdir $<) --exclude 'i386/sys/fenv.h' && \
	cp toolchain/$(SRC_NEWLIB)/newlib/libc/machine/x86_64/sys/fenv.h toolchain/$(SRC_NEWLIB)/newlib/libc/machine/i386/sys/fenv.h && \
	cd $@ && for i in `find ../../patches -type f -name '$(shell echo $(notdir $@) | sed "s/-.*//")-*.patch' | sort`; do patch -p1 < $$i; done

toolchain/%:
	tar -C toolchain -xmf toolchain/$(notdir $<) && \
        cd $@ && for i in `find ../../patches -type f -name '$(shell echo $(notdir $@) | sed "s/-.*//")-*.patch' | sort`; do patch -p1 < $$i; done


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
	curl -L https://sourceforge.net/projects/sdcc/files/sdcc/$(SRC_SDCC:sdcc-src-%=%)/$(notdir $@) -o $@
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
toolchain/sdcc-$(SRC_SDCC:sdcc-src-%=%): toolchain/$(SRC_SDCC).tar.bz2


build-toolchain: $(TOOLCHAIN:%=$(BUILD)/%)

$(BUILD)/ngbinutils: toolchain/$(SRC_BINUTILS)
	@echo compiling binutils...
	CURPWD=$$(pwd) && \
	$(EXTRA_BUILD_CMD) && \
	mkdir -p $(BUILD)/ngbinutils && \
	cd $(BUILD)/ngbinutils && \
	sed -i -e 's/\(@item\) \(How GNU properties are merged.\)/\1'$$'\\\n''\2/' $$CURPWD/toolchain/$(SRC_BINUTILS)/ld/ld.texi  && \
	$$CURPWD/toolchain/$(SRC_BINUTILS)/configure \
	$(EXTRA_BUILD_FLAGS) \
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
	$(EXTRA_BUILD_CMD) && \
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
	CFLAGS="$$CFLAGS $(GCC_C_BUILD_FLAGS)" \
	CXXFLAGS="$$CXXFLAGS $(GCC_CXX_BUILD_FLAGS)" \
	$$CURPWD/toolchain/$(SRC_GCC)/configure \
	$(EXTRA_BUILD_FLAGS) \
	--target=m68k-neogeo-elf \
	--prefix=$(prefix) \
	--exec-prefix=$(prefix)/m68k-neogeo-elf \
	--libexecdir=$(prefix)/m68k-neogeo-elf/lib \
	--datarootdir=$(prefix)/m68k-neogeo-elf \
	--datadir=$(prefix)/m68k-neogeo-elf/lib \
	--includedir=$(prefix)/m68k-neogeo-elf/include \
	--bindir=$(prefix)/bin \
	--src=$$($(REALPATH) $$CURPWD/toolchain/$(SRC_GCC) --relative-to $$PWD) \
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
	-v && $(MAKE) --eval 'override prefix_to_exec_prefix = ' tooldir=$(prefix)/m68k-neogeo-elf build_tooldir=$(prefix)/m68k-neogeo-elf $(GCC_GMAKE_OVERRIDES)

$(BUILD)/ngnewlib: $(BUILD)/nggcc toolchain/$(SRC_NEWLIB)
	@echo compiling newlib...
	CURPWD=$$(pwd) && \
	$(EXTRA_BUILD_CMD) && \
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
	$(EXTRA_BUILD_FLAGS) \
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
	$(EXTRA_BUILD_CMD) && \
	mkdir -p $(BUILD)/nggdb && \
	cd $(BUILD)/nggdb && \
	echo "replacing old texi2pod.pl (causes errors with recent perl)" && \
	cp $$CURPWD/toolchain/$(SRC_BINUTILS)/etc/texi2pod.pl $$CURPWD/toolchain/$(SRC_GDB)/etc/texi2pod.pl && \
	CFLAGS="$$CFLAGS $(GDB_C_BUILD_FLAGS)" \
	CPPFLAGS="$$CPPFLAGS $(GDB_C_BUILD_FLAGS)" \
	CXXFLAGS="$$CXXFLAGS $(GDB_CXX_BUILD_FLAGS)" \
	LDFLAGS="$$LDFLAGS $(GDB_LD_BUILD_FLAGS)" \
	PKG_CONFIG_PATH="$$PKG_CONFIG_PATH:$(GDB_PKG_CONFIG_PATH)" \
	$$CURPWD/toolchain/$(SRC_GDB)/configure \
	$(EXTRA_BUILD_FLAGS) \
	--prefix=$(prefix) \
	--exec-prefix=$(prefix)/m68k-neogeo-elf \
	--libexecdir=$(prefix)/m68k-neogeo-elf/lib \
	--datarootdir=$(prefix)/m68k-neogeo-elf \
	--datadir=$(prefix)/m68k-neogeo-elf/lib \
	--includedir=$(prefix)/m68k-neogeo-elf/include \
	--bindir=$(prefix)/bin \
	--target=m68k-neogeo-elf \
	--with-system-readline \
	-v && $(MAKE)

$(BUILD)/ngsdcc: toolchain/sdcc-$(SRC_SDCC:sdcc-src-%=%)
	@echo compiling sdcc...
	CURPWD=$$(pwd) && \
	$(EXTRA_BUILD_CMD) && \
	mkdir -p $(BUILD)/ngsdcc && \
	cd $(BUILD)/ngsdcc && \
	$$CURPWD/toolchain/sdcc-$(SRC_SDCC:sdcc-src-%=%)/configure \
	$(EXTRA_BUILD_FLAGS) \
	--program-prefix=z80-neogeo-ihx- \
	--prefix=$(prefix) \
	--libexecdir=$(prefix)/z80-neogeo-ihx/lib \
	--datarootdir=$(prefix)/z80-neogeo-ihx \
	--disable-ds390-port \
	--disable-ds400-port \
	--disable-ez80_z80-port \
	--disable-hc08-port \
	--disable-mcs51-port \
	--disable-mos6502-port \
	--disable-non-free \
	--disable-packihx \
	--disable-pdk13-port \
	--disable-pdk14-port \
	--disable-pdk15-port \
	--disable-pdk16-port \
	--disable-pic14-port \
	--disable-pic16-port \
	--disable-r2k-port \
	--disable-r2ka-port \
	--disable-r3ka-port \
	--disable-s08-port \
	--disable-sm83-port \
	--disable-stm8-port \
	--disable-tlcs90-port \
	--disable-ucsim \
	--disable-z180-port \
	--disable-z80n-port \
	--disable-r800-port \
	--disable-mos65c02-port \
	--disable-device-lib \
	--enable-z80-port \
	-v \
	include_dir_suffix=include \
	lib_dir_suffix=lib \
	&& $(MAKE)


install: $(TOOLCHAIN:%=install-%)

install-ngbinutils: $(BUILD)/ngbinutils
	$(EXTRA_BUILD_CMD) && $(MAKE) -C $(BUILD)/ngbinutils install

install-nggcc: $(BUILD)/nggcc
	$(EXTRA_BUILD_CMD) && $(MAKE) -C $(BUILD)/nggcc install build_tooldir=$(prefix)/m68k-neogeo-elf --eval 'override toolexecdir = $$(exec_prefix)' --eval 'override build_tooldir = '$(prefix)'/m68k-neogeo-elf'

install-ngnewlib: $(BUILD)/ngnewlib
	$(EXTRA_BUILD_CMD) && $(MAKE) -C $(BUILD)/ngnewlib install

install-nggdb: $(BUILD)/nggdb
	$(EXTRA_BUILD_CMD) && $(MAKE) -C $(BUILD)/nggdb install --eval 'override gnulocaledir = $$(localedir)'

install-ngsdcc: $(BUILD)/ngsdcc
	$(EXTRA_BUILD_CMD) && $(MAKE) -C $(BUILD)/ngsdcc install DESTDIR=$(DESTDIR) && \
	for d in ez80_z80 mos6502 pdk13 pdk14 pdk15 pdk15-stack-auto r2ka sm83 z80n src; do \
	    rm -rf "$(DESTDIR)$(prefix)/z80-neogeo-ihx/lib/$$d"; \
	done && \
	for d in ds390 ds400 hc08 mcs51 pic14 pic16 r2k r3ka rab sm83 stm8 tlcs90 z180; do \
	    rm -rf "$(DESTDIR)$(prefix)/z80-neogeo-ihx/include/asm/$$d"; \
	    rm -rf "$(DESTDIR)$(prefix)/z80-neogeo-ihx/include/$$d"; \
	done && \
	if [ -d "$(DESTDIR)$(prefix)/z80-neogeo-ihx/lib" ]; then \
	    find "$(DESTDIR)$(prefix)/z80-neogeo-ihx/lib" -mindepth 1 -type d -empty -delete; \
	fi && \
	mkdir -p "$(DESTDIR)$(prefix)/z80-neogeo-ihx/bin" && \
	(cd "$(DESTDIR)$(prefix)/bin"; \
	for f in `find . -name 'z80-neogeo-ihx-*'`; do \
	    fbase=`echo $$f | cut -d- -f4`; \
	    mv $$f "$(DESTDIR)$(prefix)/z80-neogeo-ihx/bin/$$fbase"; \
	    echo "#!/bin/sh" > "$(DESTDIR)$(prefix)/bin/$$f"; \
	    echo "PATH=$(prefix)/z80-neogeo-ihx/bin:\$$PATH" >> "$(DESTDIR)$(prefix)/bin/$$f"; \
	    echo "$(prefix)/z80-neogeo-ihx/bin/$$fbase \$$@" >> "$(DESTDIR)$(prefix)/bin/$$f"; \
	    chmod 755 "$(DESTDIR)$(prefix)/bin/$$f"; \
	done)


clean:
	rm -rf build

distclean: clean clean-toolchain
	rm -rf build local && \
	find . -name '*~' -exec rm -f {} \;

.PHONY: clean distclean
