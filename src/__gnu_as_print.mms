%%
% MMIX support library for various purposes.
%
% Copyright (C) 2013-2014 Matthias Maier <tamiko@kyomu.43-1.org>
%
% Permission is hereby granted, free of charge, to any person
% obtaining a copy of this software and associated documentation files
% (the "Software"), to deal in the Software without restriction,
% including without limitation the rights to use, copy, modify, merge,
% publish, distribute, sublicense, and/or sell copies of the Software,
% and to permit persons to whom the Software is furnished to do so,
% subject to the following conditions:
%
% The above copyright notice and this permission notice shall be
% included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
% BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
% ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%%

%
% Assemble __print.mmh
%

#ifndef __GNU_AS
#error Tried to assemble __gnu_as_data_segment.mms with foreign assembler.
#endif

            .section .text,"ax",@progbits
#define __MM_INTERNAL
#include <mm/__internal/__print.mmh>
            .global :MM:__PRINT:Str
            .global :MM:__PRINT:StrG
            .global :MM:__PRINT:StrLn
            .global :MM:__PRINT:StrLnG
            .global :MM:__PRINT:Reg
            .global :MM:__PRINT:RegG
            .global :MM:__PRINT:RegLn
            .global :MM:__PRINT:RegLnG
            .global :MM:__PRINT:RegP
            .global :MM:__PRINT:RegLnP
            .global :MM:__PRINT:Byte
            .global :MM:__PRINT:ByteG
            .global :MM:__PRINT:Unsigned
            .global :MM:__PRINT:UnsignedG
            .global :MM:__PRINT:Signed
            .global :MM:__PRINT:SignedG
            .global :MM:__PRINT:MemLn
            .global :MM:__PRINT:Ln
