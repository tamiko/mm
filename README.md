 MMIX support library for various purposes
===========================================


How to compile and run mmix programs
------------------------------------

### Requirements

* GNU binutils built for the `mmix` target (`mmix-as`, `mmix-ld`,
  `mmix-ar`, `mmix-ranlib`, and optionally `mmix-objdump`)
* The C preprocessor `cpp`
* The `mmix` simulator from Knuth's MMIXware
* `bash` for the scripts in `bin/`

### Building the library

```
cd lib && make
```

This compiles the library into `lib/libmm.a` and creates a number of
special object files (`entry.o`, `mmi.o`, `guard.o` and `mmo.o`) that are
used by the compiler/linker script for linking a final executable.

### Compiling a program

`bin/mmixc` is a small gcc-style driver around `cpp`, `mmix-as` and
`mmix-ld`. It assumes to find `include/` and `lib/` relative to its own
location.

```
export PATH="<path to this repository>/bin:$PATH"
mmixc hello_world.mms -o hello_world.mmo
mmix hello_world.mmo
```

Programs include the headers as `#include <mm/print>` and define a `Main`
label. Run `mmixc -h` for the full list of options. The commonly used ones
are `-c` (stop after assembling), `-E` (stop after preprocessing), `-v`
(print each command), `-keep-tmp` (keep the intermediate files), and
`-Wa,<opt>` / `-Wl,<opt>` to pass options to the assembler or linker.

`mmixc` links in this order:

```
entry.o mmi.o <your objects> guard.o -lmm mmo.o
```

* `entry.o` puts the trip and exception vectors at `#00` and the program
  entry point at `#F0`.
* `mmi.o` and `mmo.o` open and close the `.init` section. Initialization
  code that library units assemble into `.init` (the memory pool and the
  thread ring) ends up between them and runs before `Main`.
* `guard.o` follows the user code. A program that runs past its last
  instruction instead of calling `:MM:Sys:Exit` hits the guard and aborts
  with an error message, rather than falling into library code.

To build all examples, run `make` in `examples/` (requires `mmixc` in
`PATH`).

### Running programs with `binfmt-mmix`

`bin/binfmt-mmix` wraps the `mmix` simulator. It configures the terminal
before the program starts and restores it afterwards. It recognizes three
options, each written as `-mmix <option>` on its command line:

* `-tty-raw-mode` puts the terminal in raw mode without echo.
* `-tty-noblock` implies `-tty-raw-mode` and makes reads non-blocking.
* `-spawn-worker` starts a helper process that runs shell commands for
  `:MM:__SYS:Command` (see `examples/spawn_worker.mms` for an example).

Any other `-mmix <option>` is passed through to the simulator. A program
can also request these modes itself by declaring one of the global symbols
`MM:Interpreter:TTY_RAW_MODE`, `MM:Interpreter:TTY_NOBLOCK` or
`MM:Interpreter:SPAWN_WORKER` (see `examples/raw_mode.mms`). The wrapper
looks for these symbols with `mmix-objdump`, so this only works if
`mmix-objdump` is available in `PATH`.

On Linux, `binfmt-mmix` can be registered with `binfmt_misc` so that
`.mmo` files run directly:

```
echo ":mmix:E::mmo::<path to binfmt-mmix>:" > /proc/sys/fs/binfmt_misc/register
```

or permanently by putting the same line into `/etc/binfmt.d/mmix.conf`.

### Patched simulator for preemptive threading

Preemptive threading (`:MM:Thread:Enable`, used by
`examples/threading.mms`) sets the interval counter `:rI` and expects a
trip when it runs out. The stock `mmix` simulator treats `PUT :rI` as a
privileged instruction and stops with "privileged instruction!".
`patches/mmix-sim-interval-timer-trip.patch` changes the simulator so
that:

* `PUT` to special registers 12 to 18 (`rI`, `rT`, `rTT`, `rK`, `rQ`,
  `rU`, `rV`) is allowed in user programs.
* When `rI` drops to 4 or below, the simulator trips to `#00` and resets
  `rI` to -1. The stock simulator stops at an interactive breakpoint
  instead.
* `rI` starts at -1, so programs that never set it behave as before.

To build the patched simulator from the MMIXware sources at
<https://gitlab.lrz.de/mmix/mmixware/> (this needs `ctangle` from CWEB):

```
git clone https://gitlab.lrz.de/mmix/mmixware.git
cd mmixware
git apply <path to this repository>/patches/mmix-sim-interval-timer-trip.patch
make mmix
```

The patch was last checked against commit `90d53fb` of the `master`
branch.

With GCC 15 or newer, the MMIXware sources fail to compile because C23
made `bool` and `false` keywords. Build with
`make mmix CFLAGS="-O2 -std=gnu17 -Wno-error=implicit-int -Wno-error=implicit-function-declaration"`
instead.

Cooperative threading with `:MM:Thread:Yield` works on the stock
simulator. To build `examples/threading.mms` in that mode, remove its
`#define PREEMPTIVE` line.


Dynamic memory allocation in `:PoolSegment`
-------------------------------------------

The heap will be organized as memory blocks inside the pool segment of the
executable. This needs some cooperation from the user: The convention (as
defined by the mmixware documentation) is that `M_8[:Pool_Segment]` points
to the first unallocated region within the pool address space. User
programs utilizing address space from the pool segment must obey this rule
by 'allocating' memory by modifying `M_8[:Pool_Segment]` appropriately. The
library assumes that this pointer is `OCTA` aligned.


The temporary registers `$255` and `:MM:t`
------------------------------------------

* Neither mmixal, nor GNU guarantee that the contents of the temporary
  register `$255` is preserved after a `JMP`, `PUSHJ` instruction, or `LDA`
  pseudo instruction. The assembler is free to use `$255` to construct an
  absolute address if the target label cannot be reached by a near jump.
  Thus, when calling a library subroutine the contents of `$255` might not be
  preserved.

* Similarly, the library might use `:MM:t` internally.
  Thus, when calling a library subroutine - even a non `G`-variant - the
  contents of `:MM:t` might not be preserved. (Subroutines generally try to
  preserve the contents of `:MM:t`, though).


Global register usage
---------------------

The library avoids unnecessary allocation of global registers by not using
`LDA` instructions at the expense of a slight runtime overhead. The library
allocates 3 global registers (`GREG`s) for internal use and an additional
global register `:MM:t` for calling library routines (see next section).


Calling convention and error handling
-------------------------------------

Suroutines come in a number of different variants.

* Subroutines without a trailing `J`, will terminate the program with an
  error message (or call an error handler if specified). Variants with a
  trailing `J`, will jump to `:rJ+#4` on succes and to `:rJ+#0` on failure
  (some variants that would return a boolean value jump to `:rJ+#4` for
  `true` and to `:rJ+#0` for `false` instead.) This can be used to
  implement customized error handling. An example:
```
            % Try to allocate a block of memory:
            SET         $1,[...]
            PUSHJ       $0,:MM:Pool:AllocJ
            JMP         1F
            ... % Allocation was successful, continue normally.

     1H     ... % Allocation failed, error handling.
```

* Subroutines that have at most one argument and at most one return
  parameter come also in a variant with a trailing `G` which indicates that
  values are passed through the library specific temporary global register
  `:MM:t`. An example:
```
            % Try to allocate a block of memory:
t           IS          :MM:t
            SET         t,[...]
            PUSHJ       t,:MM:Pool:AllocG
                        % Address of allocated memory in t
```


Copying
-------
```
Copyright (C) 2013-2026 Matthias Maier <tamiko@43-1.org>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
