# ngdevkit, open source development for Neo-Geo


This git repository is a subpart of [ngdevkit](ngdevkit), an open
source SDK for Neo-Geo.

ngdevkit-toolchain is the collection of open sources projects that
are used in ngdevkit to build and debug Neo-Geo programs:

   * gcc and binutils provide a C compiler and m68k assembler for
     the Neo-Geo's main CPU.

   * sdcc provides a C compiler and a z80 assembler for the secondary
     CPU, used as a sound driver for the Neo-Geo's sound chip.

   * newlib provide a minimal C library for the m68k CPU.

   * gdb can be used as a remote 68k debugger for source-level
     debugging.


## Build instruction

ngdevkit-toolchain is meant to be consumed by the main
[ngdevkit](ngdevkit) repository.  Please refer to this repository for
build instruction.


## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program. If not, see
<http://www.gnu.org/licenses/>.


[ngdevkit]: https://github.com/dciabrin/ngdevkit
