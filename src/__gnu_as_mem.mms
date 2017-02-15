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
% Assemble __mem.mmh
%

#ifndef __GNU_AS
#error Tried to assemble __gnu_as_data_segment.mms with foreign assembler.
#endif

            .section .text,"ax",@progbits
#define __MM_INTERNAL
#include <mm/__internal/__mem.mmh>
            .global :MM:__MEM:Copy
            .global :MM:__MEM:CopyJ
            .global :MM:__MEM:Zero
            .global :MM:__MEM:ZeroJ
            .global :MM:__MEM:Set
            .global :MM:__MEM:SetJ
            .global :MM:__MEM:Rand
            .global :MM:__MEM:RandJ
