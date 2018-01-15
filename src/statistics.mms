%%
% MMIX support library for various purposes.
%
% Copyright (C) 2013-2018 Matthias Maier <tamiko@kyomu.43-1.org>
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
% :MM:__STATISTICS
%

            .section .data,"wa",@progbits
            .global     :MM:__STATISTICS:HeapGrow
            .global     :MM:__STATISTICS:HeapAlloc
            .global     :MM:__STATISTICS:HeapDealloc
            .global     :MM:__STATISTICS:HeapMaxNonC
            .global     :MM:__STATISTICS:HeapSizes
            PREFIX      :MM:__STATISTICS:
HeapAlloc   OCTA        #0000000000000000
HeapDealloc OCTA        #0000000000000000
HeapGrow    OCTA        #0000000000000000
HeapMaxNonC OCTA        #0000000000000000
HeapSizes   OCTA        #0000000000000000
            .fill       0x800
__debug     OCTA        #DEADBEEFDEADBEEF

            .section .data,"wa",@progbits
            PREFIX      :MM:__STATISTICS:STRS:
heap_header BYTE        "Heap statistics:",10,0
heap_alloc  BYTE        "    Number of allocations:            ",0
heap_deallo BYTE        "    Number of deallocations:          ",0
heap_grow   BYTE        "    Number of heap grow operations:   ",0
heap_nonc   BYTE        "    Maximal free space fragmentation: ",0



            .section .text,"ax",@progbits
            .global     :MM:__STATISTICS:PrintHeap
            PREFIX      :MM:__STATISTICS:
PrintHeap   GET         $0,:rJ
            LDA         $255,:MM:__STATISTICS:STRS:heap_header
            PUSHJ       $255,:MM:__PRINT:StrG
            LDA         $255,:MM:__STATISTICS:STRS:heap_alloc
            PUSHJ       $255,:MM:__PRINT:StrG
            LDA         $255,:MM:__STATISTICS:HeapAlloc
            LDO         $255,$255
            PUSHJ       $255,:MM:__PRINT:UnsignedG
            PUSHJ       $255,:MM:__PRINT:Ln
            LDA         $255,:MM:__STATISTICS:STRS:heap_deallo
            PUSHJ       $255,:MM:__PRINT:StrG
            LDA         $255,:MM:__STATISTICS:HeapDealloc
            LDO         $255,$255
            PUSHJ       $255,:MM:__PRINT:UnsignedG
            PUSHJ       $255,:MM:__PRINT:Ln
            LDA         $255,:MM:__STATISTICS:STRS:heap_grow
            PUSHJ       $255,:MM:__PRINT:StrG
            LDA         $255,:MM:__STATISTICS:HeapGrow
            LDO         $255,$255
            PUSHJ       $255,:MM:__PRINT:UnsignedG
            PUSHJ       $255,:MM:__PRINT:Ln
            LDA         $255,:MM:__STATISTICS:STRS:heap_nonc
            PUSHJ       $255,:MM:__PRINT:StrG
            LDA         $255,:MM:__STATISTICS:HeapMaxNonC
            LDO         $255,$255
            PUSHJ       $255,:MM:__PRINT:UnsignedG
            PUSHJ       $255,:MM:__PRINT:Ln
            PUT         :rJ,$0
            POP         0
