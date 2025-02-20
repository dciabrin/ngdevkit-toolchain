#!/bin/bash
MAKE=$(which gmake make 2>/dev/null | head -1)
SUDO=$(which sudo 2>/dev/null)
set -e
test -x "$MAKE"
$MAKE $MAKEOPTS all prefix=$PREFIX GNU_MIRROR=$GNU_MIRROR NEWLIB_MIRROR=$NEWLIB_MIRROR
$SUDO $MAKE install prefix=$PREFIX
