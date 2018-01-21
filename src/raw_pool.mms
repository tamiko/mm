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
% A minimalistic memory pool implementation.
%
% The heap will be organized as memory blocks inside the :PoolSegment.
% Allocations are done in multiples of 2 OCTAs (16 bytes), minimum 2 OCTAs.
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
%          -> OCTA  ptr           -> ... -> OCTA  ptr           -> circular
% circular <- OCTA  ptr           <- ... <- OCTA  ptr
%             OCTA  status/fl ptr           OCTA  status/fl ptr
%             OCTA  status/fl ptr           OCTA  status/fl ptr
%             OCTAs ...                     OCTAs ...
%
% And keep the list ordered in the sense that Pool < ptr1 < ... < ptrN.
%
%  - During deallocation adjacent memory blocks are automatically merged.
%    (This is a O(1) operation).
%
% TODO:
%
%  - Implement a buddy allocator?
%
%  - Implement a small object allocator for small memory requests?
%
%  - Worst case for the allocator is currently O(n), where n is the number
%    of entries in the pool list. That could be improved to log(n)...
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__RAW_POOL:STRS:
            .balign 4
Alloc1      BYTE        "__RAW_POOL::Alloc failed. "
            BYTE        "Out of memory.",10,0
            .balign 4
Deallo1     BYTE        "__RAW_POOL::Dealloc called with invalid "
            BYTE        "range specified.",10,0

            .section .data,"wa",@progbits
            .global     :MM:__RAW_POOL:Memory
            .global     :MM:__RAW_POOL:Pool
            PREFIX      :MM:__RAW_POOL:
Memory      OCTA        #0000000000000000
Pool        OCTA        #0000000000000000

            .section .text,"ax",@progbits
            PREFIX      :MM:__RAW_POOL:
Pool_Segment IS         :Pool_Segment
Stack_Segment IS        :Stack_Segment

t           IS          :MM:t
arg0        IS          $0
arg1        IS          $1
OCT         IS          #8


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
            % Update pointer:
            LDO         $5,$0,0     % next
            STO         $3,$5,OCT
            STO         $5,$3,0
            % Update freelist:
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
            % Update pointer:
            LDO         $5,$3,0     % next
            STO         $0,$5,OCT
            STO         $5,$0,0
            % Update freelist:
            LDO         $5,$3,2*OCT % next
            LDO         $6,$3,3*OCT % previous
            STO         $5,$6,2*OCT
            STO         $6,$5,3*OCT
            % Add entry to freelist:
1H          GETA        $4,:MM:__RAW_POOL:Pool
            LDO         $4,$4 % sentinel
            LDO         $5,$4,2*OCT % next
            STO         $5,$0,2*OCT
            STO         $4,$0,3*OCT
            STO         $0,$4,2*OCT
            STO         $0,$5,3*OCT
            % Return:
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            PUT         :rJ,$2
            POP         0
9H          GETA        $1,:MM:__RAW_POOL:STRS:Deallo1
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return


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
            % Align to OCTA:
            ADDU        $2,$2,#7
            ANDN        $2,$2,#7
            % We need 4 OCTAs (sentinel):
            SET         $3,#20
            ADDU        $3,$2,$3
            % Generously allocate three quarters of the Pool segment:
            SETH        $4,#1800
            ADDU        $4,$1,$4
            % We need another 4 OCTAs (sentinel):
            SET         $5,#20
            ADDU        $5,$4,$5
            % And another one (freelist sentinel):
            SET         $6,#20
            ADDU        $6,$5,$6
            % $2 ptr to sentinel
            % $3 ptr to free
            % $4 ptr to sentinel
            % $5 ptr to FreeList sentinel
            % $6 new pointer of free region in pool segment
            % Update M8[:Pool_Segment]:
            STO         $6,$1,0
            % First sentinel node:
            STO         $3,$2,0*OCT % ptr to free
            STO         $4,$2,1*OCT % ptr to SENT
            SET         $6,#0
            STO         $6,$2,2*OCT % mark in use
            STO         $6,$2,3*OCT % mark in use
            % free node:
            STO         $4,$3,0*OCT % ptr to SENT
            STO         $2,$3,1*OCT % ptr to SENT
            STO         $5,$3,2*OCT % create free list (and mark free)
            STO         $5,$3,3*OCT % create free list (and mark free)
            % Second sentinel node:
            STO         $2,$4,0*OCT % ptr to SENT
            STO         $3,$4,1*OCT % ptr to free
            SET         $6,#0
            STO         $6,$4,2*OCT % mark in use
            STO         $6,$4,3*OCT % mark in use
            % Create FreeList sentinel:
            STO         $5,$5,0*OCT % ptr to self (size 0)
            STO         $5,$5,1*OCT % ptr to self
            STO         $3,$5,2*OCT
            STO         $3,$5,3*OCT
            % Store pointer to sentinel node:
            GETA        $6,:MM:__RAW_POOL:Pool
            STO         $5,$6
            % Store memory region:
            GETA        $6,:MM:__RAW_POOL:Memory
            STO         $2,$6
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
            SRU         $2,arg0,4
            SET         $3,#00F8
            ODIF        $3,$2,$3
            SUBU        $2,$2,$3
            INCREMENT_COUNTER :MM:__STATISTICS:HeapSizes,$2
#endif
            % Add header:
            ADDU        $0,$0,#20
            %
            % Initialize the pool if necessary:
            %
            GETA        $2,:MM:__RAW_POOL:Pool
            LDO         $2,$2
            PBNZ        $2,1F
            PUSHJ       $2,Initialize
            GETA        $2,:MM:__RAW_POOL:Pool
            LDO         $2,$2
            %
            % Go through FreeList and use the first chunk that is
            % sufficiently large:
            %
1H          SET         $3,$2
2H          LDO         $3,$3,2*OCT
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
            % Update FreeList:
            LDO         $5,$3,2*OCT % next
            LDO         $6,$3,3*OCT % previous
            STO         $5,$6,2*OCT
            STO         $6,$5,3*OCT
            % Mark in use:
            SET         $5,#0
            STO         $5,$3,2*OCT
            STO         $5,$3,3*OCT
            % Split chunk if beneficial. We have an overhead of #50 bytes
            % per allocation. So let us say we want to have at least a
            % block of #80 bytes.
            SUBU        $2,$4,$0
            CMP         $2,$2,#80
            BN          $2,1F
            ADD         $2,$3,$0 % new chunk
            LDO         $5,$3,0 % next chunk
            % Update pointer:
            STO         $5,$2,0
            STO         $3,$2,OCT
            STO         $2,$3,0
            STO         $2,$5,OCT
            % Update FreeList:
            GETA        $4,:MM:__RAW_POOL:Pool
            LDO         $4,$4 % sentinel
            LDO         $5,$4,2*OCT % next
            STO         $5,$2,2*OCT
            STO         $4,$2,3*OCT
            STO         $2,$4,2*OCT
            STO         $2,$5,3*OCT
1H          ADDU        $0,$3,#20
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            PUT         :rJ,$1
            POP         1,0
__fatal     GETA        $1,:MM:__RAW_POOL:STRS:Alloc1
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return

