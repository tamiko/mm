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
% Assemble __heap.mmh
%

#ifndef __GNU_AS
#error Tried to assemble __gnu_as_data_segment.mms with foreign assembler.
#endif

            .section .text,"ax",@progbits
#define __MM_INTERNAL
#include "__internal/__heap.mmh"
            .global :MM:__HEAP:Alloc
            .global :MM:__HEAP:AllocJ
            .global :MM:__HEAP:AllocG
            .global :MM:__HEAP:Dealloc
            .global :MM:__HEAP:DeallocJ
            .global :MM:__HEAP:DeallocG
            .global :MM:__HEAP:Realloc
            .global :MM:__HEAP:ReallocJ
            .global :MM:__HEAP:ReallocG
            .global :MM:__HEAP:Valid
            .global :MM:__HEAP:ValidJ
            .global :MM:__HEAP:ValidG
            .global :MM:__HEAP:Size
            .global :MM:__HEAP:SizeJ
            .global :MM:__HEAP:SizeG
            .global :MM:__HEAP:Copy
            .global :MM:__HEAP:CopyJ
            .global :MM:__HEAP:Set
            .global :MM:__HEAP:SetJ
            .global :MM:__HEAP:Zero
            .global :MM:__HEAP:ZeroJ
            .global :MM:__HEAP:ZeroG
            .global :MM:__HEAP:Rand
            .global :MM:__HEAP:RandJ
            .global :MM:__HEAP:RandG
