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

#include "statistics.mmh"

%
% :MM:__STATISTICS
%

            .section .data,"wa",@progbits
            .global     :MM:__STATISTICS:ThreadTripH
            .global     :MM:__STATISTICS:ThreadCriti
            .global     :MM:__STATISTICS:ThreadSwitc
            .global     :MM:__STATISTICS:ThreadYield
            .global     :MM:__STATISTICS:ThreadClone
            .global     :MM:__STATISTICS:ThreadCreat
            .global     :MM:__STATISTICS:ThreadExit
            .global     :MM:__STATISTICS:TimingTotal
            .global     :MM:__STATISTICS:TimingTripH
            .global     :MM:__STATISTICS:TimingCriti
            .global     :MM:__STATISTICS:HeapGrow
            .global     :MM:__STATISTICS:HeapAlloc
            .global     :MM:__STATISTICS:HeapDealloc
            .global     :MM:__STATISTICS:HeapMaxNonC
            .global     :MM:__STATISTICS:HeapSizes
            .global     :MM:__STATISTICS:__buffer
            .global     :MM:__STATISTICS:__lock
            PREFIX      :MM:__STATISTICS:
ThreadTripH OCTA        #0000000000000000
ThreadCriti OCTA        #0000000000000000
ThreadSwitc OCTA        #0000000000000000
ThreadYield OCTA        #0000000000000000
ThreadClone OCTA        #0000000000000000
ThreadCreat OCTA        #0000000000000000
ThreadExit  OCTA        #0000000000000000
TimingTotal OCTA        #0000000000000000
TimingTripH OCTA        #0000000000000000
TimingCriti OCTA        #0000000000000000
HeapAlloc   OCTA        #0000000000000000
HeapDealloc OCTA        #0000000000000000
HeapGrow    OCTA        #0000000000000000
HeapMaxNonC OCTA        #0000000000000000
HeapSizes   .fill       0x100
__buffer    OCTA        #0000000000000000
__lock      OCTA        #0000000000000000

            .section .data,"wa",@progbits
            PREFIX      :MM:__STATISTICS:STRS:
thread_head BYTE        "Thread statistics:",10,0
thread_trip BYTE        "    Number of entries into trip handler:     ",0
thread_crit BYTE        "    Number of entries into critical regions: ",0
thread_swit BYTE        "    Number of context switches:              ",0
thread_yiel BYTE        "    Number of Thread:Yield invocations:      ",0
thread_clon BYTE        "    Number of Thread:Clone invocations:      ",0
thread_crea BYTE        "    Number of Thread:Create invocations:     ",0
thread_exit BYTE        "    Number of Thread:Exit invocations:       ",0

hist1       BYTE        "]  ",0
hist2       BYTE        "#",0
hist3       BYTE        " ",0

timing_head BYTE        "Timing statistics (using :rU):",10,0
timing_tota BYTE        "    Total runtime:                           ",0
timing_his1 BYTE        "        Trip handler:     [",0
timing_his2 BYTE        "        Critical regions: [",0
timing_his3 BYTE        "        User mode         [",0

heap_header BYTE        "Heap statistics:",10,0
heap_alloc  BYTE        "    Number of allocations:                   ",0
heap_deallo BYTE        "    Number of deallocations:                 ",0
heap_grow   BYTE        "    Number of heap grow operations:          ",0
heap_nonc   BYTE        "    Maximal free space fragmentation:        ",0
heap_hist1  BYTE        "    Allocations: ",10,0
heap_hist2  BYTE        "           ",0
heap_hist3  BYTE        "        >= ",0
heap_hist4  BYTE        " bytes:    [",0


            .section .text,"ax",@progbits
            .global     :MM:__STATISTICS:PrintStatistics
            PREFIX      :MM:__STATISTICS:

            .macro      PRINT_FIELD string label
            LDA         $255,\string
            PUSHJ       $255,:MM:__PRINT:StrG
            LDA         $255,\label
            LDO         $255,$255
            PUSHJ       $255,:MM:__PRINT:UnsignedG
            PUSHJ       $255,:MM:__PRINT:Ln
            .endm

            .macro      PRINT_HIST register1 register2 label width padding=0
            LDA         $255,\label
            PUSHJ       $255,:MM:__PRINT:StrG
            SET         $255,#0000
            PUT         :rD,$255
            MULU        $30,\register1,\width
            DIVU        $30,$30,\register2
            .if \padding
            GET         $255,:rR
            BNP         $255,7F
            ADDU        $30,$30,1
            .endif
7H          SET         $31,0
4H          CMPU        $255,$31,$30
            BN          $255,5F
            LDA         $255,STRS:hist3
            JMP         6F
5H          LDA         $255,STRS:hist2
6H          PUSHJ       $255,:MM:__PRINT:StrG
            ADDU        $31,$31,1
            CMPU        $255,$31,\width
            BNZ         $255,4B
            LDA         $255,STRS:hist1
            PUSHJ       $255,:MM:__PRINT:StrG
            SET         $255,\register1
            PUSHJ       $255,:MM:__PRINT:UnsignedG
            PUSHJ       $255,:MM:__PRINT:Ln
            .endm

PrintStatistics SWYM
#ifdef STATISTICS
            % some final touches:
            GET         $30,:rU
            LDA         $31,TimingTotal
            STO         $30,$31
            GET         $0,:rJ
            PUSHJ       $255,:MM:__INTERNAL:EnterCritical

            %
            % Threading:
            %
            PUSHJ       $255,:MM:__PRINT:Ln
            LDA         $255,STRS:thread_head
            PUSHJ       $255,:MM:__PRINT:StrG
            PRINT_FIELD STRS:thread_trip,ThreadTripH
            PRINT_FIELD STRS:thread_crit,ThreadCriti
            PRINT_FIELD STRS:thread_swit,ThreadSwitc
            PRINT_FIELD STRS:thread_yiel,ThreadYield
            PRINT_FIELD STRS:thread_clon,ThreadClone
            PRINT_FIELD STRS:thread_crea,ThreadCreat
            PRINT_FIELD STRS:thread_exit,ThreadExit

            %
            % Timing:
            %
            PUSHJ       $255,:MM:__PRINT:Ln
            LDA         $255,STRS:timing_head
            PUSHJ       $255,:MM:__PRINT:StrG
            PRINT_FIELD STRS:timing_tota,TimingTotal
            LDA         $1,TimingTotal
            LDO         $1,$1
            LDA         $2,TimingTripH
            LDO         $2,$2
            LDA         $3,TimingCriti
            LDO         $3,$3
            SUBU        $4,$1,$2
            SUBU        $4,$4,$3
            % bar chart:
            PRINT_HIST $2,$1,STRS:timing_his1,64
            PRINT_HIST $3,$1,STRS:timing_his2,64
            PRINT_HIST $4,$1,STRS:timing_his3,64

            %
            % Heap:
            %
            PUSHJ       $255,:MM:__PRINT:Ln
            LDA         $255,STRS:heap_header
            PUSHJ       $255,:MM:__PRINT:StrG
            PRINT_FIELD STRS:heap_alloc,HeapAlloc
            PRINT_FIELD STRS:heap_deallo,HeapDealloc
            PRINT_FIELD STRS:heap_grow,HeapGrow
            PRINT_FIELD STRS:heap_nonc,HeapMaxNonC
            %
            % Print a histogram:
            %
            LDA         $255,STRS:heap_hist1
            PUSHJ       $255,:MM:__PRINT:StrG
            SET         $1,#0000
            LDA         $2,HeapAlloc
            LDO         $2,$2
            LDA         $3,HeapSizes
1H          SET         $255,#0100
            CMPU        $255,$1,$255
            BNN         $255,9F
            SET         $255,#00f8
            CMPU        $255,$1,$255
            BN          $255,2F
            LDA         $255,STRS:heap_hist3
            JMP         3F
2H          LDA         $255,STRS:heap_hist2
3H          PUSHJ       $255,:MM:__PRINT:StrG
            ADDU        $5,$1,#8
            SLU         $5,$5,3
            SET         $255,10
            CMP         $255,$5,$255
            BNN         $255,5F
            LDA         $255,STRS:hist3
            PUSHJ       $255,:MM:__PRINT:StrG
5H          SET         $255,100
            CMP         $255,$5,$255
            BNN         $255,5F
            LDA         $255,STRS:hist3
            PUSHJ       $255,:MM:__PRINT:StrG
5H          SET         $255,1000
            CMP         $255,$5,$255
            BNN         $255,5F
            LDA         $255,STRS:hist3
            PUSHJ       $255,:MM:__PRINT:StrG
5H          PUSHJ       $4,:MM:__PRINT:Unsigned
            LDO         $4,$3,$1
            PRINT_HIST  $4,$2,STRS:heap_hist4,64,1
            ADD         $1,$1,#0008
            JMP         1B
9H          PUSHJ       $255,:MM:__INTERNAL:LeaveCritical
            PUT         :rJ,$0
#endif
            POP         0
