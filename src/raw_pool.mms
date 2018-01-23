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
% :MM:__RAW_POOL:
%
% A memory pool implementation with sorted free list.
%
% The heap will be organized as memory blocks inside the :PoolSegment.
%
% By convention M_8[:Pool_Segment] points to the first unallocated OCTA in
% the :PoolSegment and all memory including and above the address is
% assumed to be available for allocation.
%
% User programs utilizing address space from the pool segment manually must
% obey this rule by 'allocating' memory by modifying M_8[:Pool_Segment]
% appropriately.
%
% We maintain a doubly-linked list of used/free memory regions:
%
%          ┌─────────────────────┐           ┌─────────────────────┐
%          │ OCTA  ptr           ---> ... -> │ OCTA  ptr           ---> SENT.
% SENT. <--- OCTA  ptr           │ <- ... <--- OCTA  ptr           │
%          │ OCTA  status/fl ptr │           │ OCTA  status/fl ptr │
%          │ OCTA  status/fl ptr │           │ OCTA  status/fl ptr │
%          │ ─────────────────── │           │ ─────────────────── │
%          │ OCTAs payload       │           │ OCTAs payload       │
%          └─────────────────────┘           └─────────────────────┘
%
% And keep the list ordered in the sense that Pool < ptr1 < ... < ptrN.
%
%  - We keep a sorted, doubly-linked list of free memory regions (in 2*OCT,
%    3*OCT) and add sentinel entries to access common memory sizes <=4kb
%    in 128 byte increments quickly:
%
%      Pool+#00:                                         Pool+#20:
%
%    ┌──────────┐    ┌─────────────────────┐           ┌──────────┐
%    │ sentinel │    │ OCTA  ptr           │           │ sentinel │
%    │          │    │ OCTA  ptr           │           │          │
%    │ s/fl ptr ---> │ OCTA  status/fl ptr ---> ... -> │ s/fl ptr ---> ...
%    │ s/fl ptr │ <--- OCTA  status/fl ptr │ <- ... <--- s/fl ptr │ <- ...
%    └──────────┘    │ ─────────────────── │           └──────────┘
%                    │ OCTAs payload       │
%                    └─────────────────────┘
%
%    The sentinels are kept at fixed memory locations in the .data section:
%      Pool + i * #20, i = 0, 1, 2, ...
%    Allocation happens on a first fit basis. That way allocation has a
%    fixed complexity of O(1). (With a worst case constant proportional to
%    the number of bins.)
%
%  - During deallocation adjacent memory blocks are automatically merged.
%    (This is an O(1) operation). And sorted back into the list of free
%    memory regions. When __ALIGN_TO_SPREAD is set this is an O(1)
%    operation for memory chunks of size <= 4kb. Worst case complexity is
%    O(n).
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__RAW_POOL:STRS:
            .balign 4
Alloc1      BYTE        "__RAW_POOL::Alloc failed. "
            BYTE        "Out of memory.",10,0
            .balign 4
Deallo1     BYTE        "__RAW_POOL::Dealloc called with invalid "
            BYTE        "range specified.",10,0

            %
            % Let us store a pointer to the memory region in the data
            % section:
            %

            .section .data,"wa",@progbits
            PREFIX      :MM:__RAW_POOL:
            .global     :MM:__RAW_POOL:Memory
Memory      OCTA        #0000000000000000

            %
            % The free list pool is organized as a partially ordered,
            % doubly-linked list. Create 'no_entries' sentinels for a
            % spread of 'spread' bytes:
            %

spread      IS          #80
spread_mask IS          #7F
spread_shft IS          7
no_entries  IS          31
#define __ALIGN_TO_SPREAD

            %
            % Our memory pool :-)
            %

            .global     :MM:__RAW_POOL:Pool
            .balign     8
Pool        .fill       #20 * no_entries


            .section .text,"ax",@progbits
            PREFIX      :MM:__RAW_POOL:
Pool_Segment IS         :Pool_Segment
Stack_Segment IS        :Stack_Segment

t           IS          :MM:t
arg0        IS          $0
arg1        IS          $1
OCT         IS          #8


%%
% :MM:__RAW_POOL:Initialize
%   Initialize the memory pool. Generously allocate three quarters of the
%   Pool segment and create two sentinel entries at the beginning and end.
%   (And set up a doubly-linked list.)
%
% PUSHJ:
%   no arguments
%   no return value
%
%
            .global :MM:__RAW_POOL:Initialize
Initialize  SWYM
            GETA        $1,Pool_Segment
            LDO         $2,$1
            % Align to OCTA and spread, subtract #20 for first sentinel:
            SET         $3,spread_mask
            ADDU        $2,$2,$3
            ANDN        $2,$2,$3
            SUBU        $2,$2,#20
            % We need 4 OCTAs (sentinel):
            SET         $3,#20
            ADDU        $3,$2,$3
            % Generously allocate three quarters of the Pool segment:
            SETH        $4,#1800
            ADDU        $4,$1,$4
            % We need another 4 OCTAs (sentinel):
            SET         $5,#20
            ADDU        $5,$4,$5
            % $2 ptr to sentinel
            % $3 ptr to free
            % $4 ptr to sentinel
            % $5 new pointer of free region in pool segment
            % Update M8[:Pool_Segment]:
            STO         $5,$1,0
            % First sentinel node:
            STO         $3,$2,0*OCT % ptr to free
            STO         $4,$2,1*OCT % ptr to SENT
            SET         $5,#0
            STO         $5,$2,2*OCT % mark in use
            STO         $5,$2,3*OCT % mark in use
            % free node:
            STO         $4,$3,0*OCT % ptr to SENT
            STO         $2,$3,1*OCT % ptr to SENT
            % Second sentinel node:
            STO         $2,$4,0*OCT % ptr to SENT
            STO         $3,$4,1*OCT % ptr to free
            SET         $5,#0
            STO         $5,$4,2*OCT % mark in use
            STO         $5,$4,3*OCT % mark in use
            % Store memory region:
            GETA        $5,:MM:__RAW_POOL:Memory
            STO         $2,$5
            INCREMENT_COUNTER :MM:__STATISTICS:HeapChunks
            STORE_MAX :MM:__STATISTICS:HeapChunks,:MM:__STATISTICS:HeapMaxNonC
            % Create free list sentinels:
            GETA        $0,:MM:__RAW_POOL:Pool
            SET         $1,no_entries
            SLU         $1,$1,5
1H          SUB         $1,$1,#20
            ADDU        $2,$0,$1
            STO         $2,$2,0*OCT % ptr to self (size 0)
            STO         $2,$2,1*OCT % ptr to self
            ADDU        $4,$2,#20
            STO         $4,$2,2*OCT % fl ptr
            SUBU        $4,$2,#20
            STO         $4,$2,3*OCT % fl ptr
            BNZ         $1,1B
            % Put our free region at the end and make the list cyclic:
            STO         $3,$0,3*OCT
            STO         $0,$3,2*OCT
            SET         $1,no_entries
            SUBU        $1,$1,1
            SLU         $1,$1,5
            ADDU        $4,$0,$1
            STO         $3,$4,2*OCT
            STO         $4,$3,3*OCT
            POP         0


%%
% :MM:__RAW_POOL:Alloc
%   Allocate a contiguous block of memory. arg0 is aligned to OCT.
%
% PUSHJ:
%   arg0 - size of memory block to allocate (in bytes)
%   retm - the address of the allocated block;
%
            .global :MM:__RAW_POOL:Alloc
Alloc       GET         $1,:rJ
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            INCREMENT_COUNTER :MM:__STATISTICS:HeapAlloc
            % Align to OCTA:
            ADDU        $0,$0,#7
            ANDN        $0,$0,#7
#ifdef STATISTICS
            SUBU        $2,$0,1
            SRU         $2,$2,4
            SET         $3,#00F8
            ODIF        $3,$2,$3
            SUBU        $2,$2,$3
            INCREMENT_COUNTER :MM:__STATISTICS:HeapSizes,$2
            INCREMENT_COUNTER :MM:__STATISTICS:HeapTotAllo,0,$0
#endif
            % Add header:
            ADDU        $0,$0,#20
#ifdef      __ALIGN_TO_SPREAD
#ifdef STATISTICS
            SET         $2,$0
#endif
            % And align to spread
            SET         $5,spread_mask
            ADDU        $0,$0,$5
            ANDN        $0,$0,$5
#ifdef STATISTICS
            SUBU        $2,$0,$2
            INCREMENT_COUNTER :MM:__STATISTICS:HeapTotOver,0,$2
#endif
#endif
            %
            % Rotate free list to correct bin:
            %
            GETA        $2,:MM:__RAW_POOL:Pool
            SRU         $4,$0,spread_shft
            SET         $5,no_entries-1
            CMP         $5,$5,$4
            CSN         $4,$5,#0
            SLU         $4,$4,5
            ADDU        $2,$2,$4
            SET         $3,$2
            %
            % Go through free list and use the first chunk that is
            % sufficiently large:
            %
2H          LDO         $3,$3,2*OCT
            INCREMENT_COUNTER :MM:__STATISTICS:HeapTotSear
            CMP         $4,$3,$2
            BZ          $4,__fatal % no luck, sentinel reached
            LDO         $4,$3,0
            SUBU        $4,$4,$3 % size
            CMP         $5,$0,$4
            BNP         $5,__out
            % chunk too small, go to next
            JMP         2B
            %
            % Use chunk:
            %
            % $0 - size requested
            % $3 - ptr
            % $4 - size of chunk
__out       SWYM
            % Update free list:
            LDO         $5,$3,2*OCT % next
            LDO         $6,$3,3*OCT % previous
            STO         $5,$6,2*OCT
            STO         $6,$5,3*OCT
            % Mark in use:
            SET         $5,#0
            STO         $5,$3,2*OCT
            STO         $5,$3,3*OCT
            %
            % Split chunk if beneficial. Let us require at least 'spread'
            % bytes:
            %
            SUBU        $2,$4,$0
            CMP         $2,$2,spread
            BN          $2,1F
            INCREMENT_COUNTER :MM:__STATISTICS:HeapChunks
            STORE_MAX :MM:__STATISTICS:HeapChunks,:MM:__STATISTICS:HeapMaxNonC
            ADD         $2,$3,$0 % new chunk
            LDO         $5,$3,0 % next chunk
            % Update pointer:
            STO         $5,$2,0
            STO         $3,$2,OCT
            STO         $2,$3,0
            STO         $2,$5,OCT
            % Add entry to free list:
            SUBU        $4,$4,$0
            SRU         $5,$4,spread_shft
            INCL        $5,#1
            SET         $6,no_entries-1
            CMP         $6,$6,$5
            CSN         $5,$6,#0
            SLU         $5,$5,5
            GETA        $6,:MM:__RAW_POOL:Pool
            ADDU        $6,$6,$5
            % Sort by size:
2H          LDO         $6,$6,3*OCT
            INCREMENT_COUNTER :MM:__STATISTICS:HeapTotPlac
            LDO         $7,$6,0
            SUBU        $7,$7,$6
            CMP         $5,$7,$4
            BP          $5,2B
            % Put into list:
            LDO         $5,$6,2*OCT % next
            STO         $5,$2,2*OCT
            STO         $6,$2,3*OCT
            STO         $2,$5,3*OCT
            STO         $2,$6,2*OCT
1H          SWYM
#ifdef STATISTICS
            ADDU        $2,$0,$3
            GETA        $4,:MM:__STATISTICS:HeapSBRKtmp
            STO         $2,$4
            STORE_MAX :MM:__STATISTICS:HeapSBRKtmp,:MM:__STATISTICS:HeapSBRK
#endif
            ADDU        $0,$3,#20
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            PUT         :rJ,$1
            POP         1,0
__fatal     GETA        $1,:MM:__RAW_POOL:STRS:Alloc1
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return


%%
% :MM:__RAW_POOL:Dealloc
%   Deallocate a previously allocated bunch of memory. arg1 is
%   aligned to 2*OCT and set to at least 2*OCT.
%
% PUSHJ:
%   arg0 - starting address of memory block to deallocate
%   arg1 - size of memory block (in bytes)
%   no return value
%
% Preconditions:
%   - The memory block defined by arg0, arg1 must have been
%     allocated via :MM:__RAW_POOL:Alloc
%
            .global :MM:__RAW_POOL:Dealloc
ptr         IS          $2
prev_ptr    IS          $3
Dealloc     GET         $2,:rJ
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            INCREMENT_COUNTER :MM:__STATISTICS:HeapDealloc
            % Add the header:
            SUBU        $0,$0,#20
            ADDU        $1,$1,#20
            % Sanity checks:
            GETA        $3,Pool_Segment
            GETA        $4,Stack_Segment
            CMPU        $5,$3,$0
            BNN         $5,9F
            CMPU        $5,$4,$0
            BNP         $5,9F
            LDO         $3,$0,0
            SUBU        $3,$3,$0 % size
            CMPU        $5,$1,$3
            BP          $5,9F
            LDO         $3,$0,2*OCT % status
            BNZ         $3,9F
            LDO         $3,$0,3*OCT % status
            BNZ         $3,9F
            % Merge left:
            LDO         $3,$0,OCT   % previous
            LDO         $5,$3,2*OCT % status
            BZ          $5,1F
            LDO         $5,$3,3*OCT % status
            BZ          $5,1F
            DECREMENT_COUNTER :MM:__STATISTICS:HeapChunks,0,1
            % Update pointer:
            LDO         $5,$0,0     % next
            STO         $3,$5,OCT
            STO         $5,$3,0
            % Update free list:
            LDO         $5,$3,2*OCT % next
            LDO         $6,$3,3*OCT % previous
            STO         $5,$6,2*OCT
            STO         $6,$5,3*OCT
            SET         $0,$3
            % Merge right:
1H          LDO         $3,$0,0     % next
            LDO         $5,$3,2*OCT % status
            BZ          $5,1F
            LDO         $5,$3,3*OCT % status
            BZ          $5,1F
            DECREMENT_COUNTER :MM:__STATISTICS:HeapChunks,0,1
            % Update pointer:
            LDO         $5,$3,0     % next
            STO         $0,$5,OCT
            STO         $5,$0,0
            % Update free list:
            LDO         $5,$3,2*OCT % next
            LDO         $6,$3,3*OCT % previous
            STO         $5,$6,2*OCT
            STO         $6,$5,3*OCT
            % Add entry to free list:
1H          LDO         $4,$0,0
            SUBU        $4,$4,$0
            SRU         $5,$4,spread_shft
            INCL        $5,#1
            SET         $6,no_entries-1
            CMP         $6,$6,$5
            CSN         $5,$6,#0
            SLU         $5,$5,5
            GETA        $6,:MM:__RAW_POOL:Pool
            ADDU        $6,$6,$5
            % Sort by size:
2H          LDO         $6,$6,3*OCT
            INCREMENT_COUNTER :MM:__STATISTICS:HeapTotPlac
            LDO         $7,$6,0
            SUBU        $7,$7,$6
            CMP         $5,$7,$4
            BP          $5,2B
            % Put into list:
            LDO         $5,$6,2*OCT % next
            STO         $5,$0,2*OCT
            STO         $6,$0,3*OCT
            STO         $0,$5,3*OCT
            STO         $0,$6,2*OCT
            % Return:
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            PUT         :rJ,$2
            POP         0
9H          GETA        $1,:MM:__RAW_POOL:STRS:Deallo1
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return

