#!/bin/bash
set -eu
MAKE=$(which gmake make | head -1)
$MAKE all prefix=$PREFIX GNU_MIRROR=$GNU_MIRROR NEWLIB_MIRROR=$NEWLIB_MIRROR
sudo $MAKE install prefix=$PREFIX
