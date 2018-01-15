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
HeapSizes   .fill       0x100

            .section .data,"wa",@progbits
            PREFIX      :MM:__STATISTICS:STRS:
heap_header BYTE        "Heap statistics:",10,0
heap_alloc  BYTE        "    Number of allocations:            ",0
heap_deallo BYTE        "    Number of deallocations:          ",0
heap_grow   BYTE        "    Number of heap grow operations:   ",0
heap_nonc   BYTE        "    Maximal free space fragmentation: ",0
heap_hist1  BYTE        "    Allocations: ",10,0
heap_hist2  BYTE        "           ",0
heap_hist3  BYTE        "        >= ",0
heap_hist4  BYTE        " bytes:  [",0
heap_hist5  BYTE        " ]  ",0
heap_hist6  BYTE        "#",0
heap_hist7  BYTE        " ",0


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
            LDA         $255,:MM:__STATISTICS:STRS:heap_hist1
            PUSHJ       $255,:MM:__PRINT:StrG
            %
            % Print a histogram:
            %

            SET         $1,#0000
            LDA         $2,:MM:__STATISTICS:HeapAlloc
            LDO         $2,$2
            LDA         $3,:MM:__STATISTICS:HeapSizes

1H          SET         $255,#0100
            CMPU        $255,$1,$255
            BNN         $255,9F
            SET         $255,#00f8
            CMPU        $255,$1,$255
            BN          $255,2F
            LDA         $255,:MM:__STATISTICS:STRS:heap_hist3
            JMP         3F
2H          LDA         $255,:MM:__STATISTICS:STRS:heap_hist2
3H          PUSHJ       $255,:MM:__PRINT:StrG
            ADDU        $5,$1,#8
            SLU         $5,$5,3
            SET         $6,6
            SET         $7,8
            PUSHJ       $4,:MM:__PRINT:RegP
            LDA         $255,:MM:__STATISTICS:STRS:heap_hist4
            PUSHJ       $255,:MM:__PRINT:StrG
            SET         $4,#0000
            PUT         :rD,$4
            LDO         $4,$3,$1
            MULU        $4,$4,#20
            DIVU        $4,$4,$2
            GET         $255,:rR
            BNP         $255,7F
            ADDU        $4,$4,1
7H          SET         $5,0
4H          CMPU        $255,$5,$4
            BN          $255,5F
            LDA         $255,:MM:__STATISTICS:STRS:heap_hist7
            JMP         6F
5H          LDA         $255,:MM:__STATISTICS:STRS:heap_hist6
6H          PUSHJ       $255,:MM:__PRINT:StrG
            ADDU        $5,$5,1
            CMPU        $255,$5,32
            BNZ         $255,4B
            LDA         $255,:MM:__STATISTICS:STRS:heap_hist5
            PUSHJ       $255,:MM:__PRINT:StrG
            LDO         $255,$3,$1
            PUSHJ       $255,:MM:__PRINT:UnsignedG
            PUSHJ       $255,:MM:__PRINT:Ln

            ADD         $1,$1,#0008
            JMP         1B

            %
            %
            %
9H          PUT         :rJ,$0
            POP         0


            %LDA         t,:MM:__INTERNAL:BufferMutex
            %PUSHJ       t,:MM:__THREAD:LockMutexG
