#!/bin/bash
MAKE=$(which gmake make 2>/dev/null | head -1)
SUDO=$(which sudo 2>/dev/null)
set -eu
test -x "$MAKE"
$MAKE -j all prefix=$PREFIX GNU_MIRROR=$GNU_MIRROR NEWLIB_MIRROR=$NEWLIB_MIRROR
$SUDO $MAKE install prefix=$PREFIX
