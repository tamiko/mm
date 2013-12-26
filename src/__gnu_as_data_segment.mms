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
% Assemble data segment structures.
%

#ifndef __GNU_AS
#error Tried to assemble __gnu_as_data_segment.mms with foreign assembler.
#endif

            .data
            .balign 8
#define __MM_INTERNAL
#include "__strs.mmh"
            .balign 8
            PREFIX      :MM:__SYS:
AtExitAddr  OCTA        #0000000000000000
AtAbortAddr OCTA        #0000000000000000
AtErrorAddr OCTA        #0000000000000000
            .balign 8
            PREFIX      :MM:__INIT:
Buffer      IS          @
            .fill 1024*8
            PREFIX      :
            .global :MM:__STRS:Terminated
            .global :MM:__STRS:Continued
            .global :MM:__STRS:InternErro
            .global :MM:__STRS:Error
            .global :MM:__STRS:ErrorHndlR1
            .global :MM:__STRS:ErrorHndlR2
            .global :MM:__STRS:ExcNotImpl
            .global :MM:__STRS:Generic
            .global :MM:__STRS:HeapGrow1
            .global :MM:__STRS:HeapDeallo1
            .global :MM:__STRS:HeapAlloc1
            .global :MM:__STRS:HeapAlloc2
            .global :MM:__STRS:HeapFree1
            .global :MM:__STRS:HeapFree2
            .global :MM:__STRS:HeapSize1
            .global :MM:__STRS:HeapSize2
            .global :MM:__STRS:HeapMove1
            .global :MM:__STRS:HeapMove2
            .global :MM:__STRS:HeapMove3
            .global :MM:__STRS:HeapMove4
            .global :MM:__STRS:HeapReallo1
            .global :MM:__STRS:HeapReallo2
            .global :MM:__STRS:HeapReallo3
            .global :MM:__STRS:HeapReallo4
            .global :MM:__STRS:HeapReallo5
            .global :MM:__STRS:HeapSet1
            .global :MM:__STRS:HeapSet2
            .global :MM:__STRS:HeapZero1
            .global :MM:__STRS:HeapZero2
            .global :MM:__STRS:HeapSetZero
            .global :MM:__STRS:HeapRand1
            .global :MM:__STRS:HeapRand2
            .global :MM:__STRS:HeapRand3
            .global :MM:__STRS:MemCopy1
            .global :MM:__STRS:MemCopy2
            .global :MM:__STRS:MemCopy3
            .global :MM:__STRS:MemCopy4
            .global :MM:__STRS:MemCopy5
            .global :MM:__STRS:MemSet1
            .global :MM:__STRS:MemSet2
            .global :MM:__STRS:MemSet3
            .global :MM:__STRS:MemSet4
            .global :MM:__STRS:MemZero1
            .global :MM:__STRS:MemZero2
            .global :MM:__STRS:MemZero3
            .global :MM:__STRS:MemZero4
            .global :MM:__STRS:MemRand1
            .global :MM:__STRS:MemRand2
            .global :MM:__STRS:MemRand3
            .global :MM:__STRS:MemRand4
            .global :MM:__STRS:RandUrandom
            .global :MM:__STRS:RandInit1
            .global :MM:__STRS:RandInit2
            .global :MM:__STRS:RandInit3
            .global :MM:__STRS:RandInit4
            .global :MM:__STRS:RandOcta1
            .global :MM:__STRS:RandOctaG1
            .global :MM:__STRS:RandRange1
            .global :MM:__STRS:RandRange2
            .global :MM:__STRS:RandRange3
            .global :MM:__STRS:RandRange4
            .global :MM:__STRS:PrintLn
            .global :MM:__SYS:AtExitAddr
            .global :MM:__SYS:AtAbortAddr
            .global :MM:__SYS:AtErrorAddr
            .global :MM:__INIT:Buffer
