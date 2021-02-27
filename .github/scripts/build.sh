#!/bin/bash
set -eu
make -s all prefix=$PREFIX GNU_MIRROR=$GNU_MIRROR NEWLIB_MIRROR=$NEWLIB_MIRROR
sudo make -s install prefix=$PREFIX
