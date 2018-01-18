 MMIX support library for various purposes
===========================================


How to compile and run mmix programs
------------------------------------

* TODO: mmix-ld
* TODO: Compilation pipeline

* TODO: bin/

* TODO: binfmt


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
  Thus, when calling a library subroutine - even a non `G`-variant` - the
  contents of `:MM:t` might not be preserved. (Subroutines try to preserve
  the contents of `:MM:t`, though).


Global register usage
---------------------

The library avoids unnecessary allocation of global registers by not using
`LDA` instructions at the expense of a slight runtime overhead. The library
allocated 3 global registers (`GREG`s) for internal use and an additional
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
            PUSHJ       $0,:MM:Heap:AllocJ
            JMP         1F
            ... % Allocation was successful, continue normally.

     1H     ... % Allocation failed, error handling.
```

* Subroutines that have at most one argument and at moste one return
  parameter come also in a variant with a trailing `G` which indicates that
  values are passed through the library specific temporary global register
  `:MM:t`. An example:
```
            % Try to allocate a block of memory:
t           IS          :MM:t
            SET         t,[...]
            PUSHJ       t,:MM:Heap:AllocG
                        % Address of allocated memory in t
```


Copying
-------
```
Copyright (C) 2013-2018 Matthias Maier <tamiko@kyomu.43-1.org>

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
