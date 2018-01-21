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
% assumed to be available for allocation. If we run out of memory in the
% pool, the :MM:__RAW_POOL:Grow subroutine will try to allocate a new,
% large chunk of memory (~100MB or more) by advancing the
% M_8[:Pool_Segment] pointer.
%
% User programs utilizing address space from the pool segment manually must
% obey this rule by 'allocating' memory by modifying M_8[:Pool_Segment]
% appropriately. The library assumes that this pointer is `OCTA` aligned.
%
% We maintain a doubly-linked list of used/free memory regions:
%
% Pool ->   OCTA  ptr     ->   OCTA  ptr     ->  ...  ->   OCTA  ptr   -> #0
% #0   <-   OCTA  ptr     <-   OCTA  ptr     <-  ...  <-   OCTA  ptr
%           OCTA  size         OCTA  size                  OCTA  size
%           OCTA  status/ptr   OCTA  status/ptr            OCTA  status/ptr
%           OCTAs ...          OCTAs ...                   OCTAs ...
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
Grow1       BYTE        "__RAW_POOL::Grow failed. "
            BYTE        "Out of memory.",10,0
            .balign 4
Deallo1     BYTE        "__RAW_POOL::Dealloc called with invalid "
            BYTE        "range specified.",10,0

            .section .data,"wa",@progbits
            .global     :MM:__RAW_POOL:Pool
            PREFIX      :MM:__RAW_POOL:
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
            LDO         $3,$0,2*OCT % size
            CMPU        $5,$1,$3
            BP          $5,9F
            LDO         $3,$0,3*OCT % status
            BNZ         $3,9F
            % Deallocate:
            NEG         $3,0,1
            STO         $3,$0,3*OCT % mark free
            % Merge left:
            LDO         $3,$0,OCT   % previous
            LDO         $4,$3,2*OCT % size
            ADDU        $5,$3,$4
            CMPU        $5,$5,$0
            BNZ         $5,1F
            LDO         $5,$3,3*OCT % status
            BZ          $5,1F
            % Update size:
            LDO         $5,$0,2*OCT % size
            ADDU        $4,$4,$5
            STO         $4,$3,2*OCT
            % Update pointer:
            LDO         $5,$0,0     % next
            STO         $3,$5,OCT
            STO         $5,$3,0
            SET         $0,$3
            % Merge right:
1H          LDO         $3,$0,0     % next
            LDO         $4,$0,2*OCT % size
            ADDU        $5,$0,$4
            CMPU        $5,$5,$3
            BNZ         $5,1F
            LDO         $5,$3,3*OCT % status
            BZ          $5,1F
            % Update size:
            LDO         $5,$3,2*OCT % size
            ADDU        $4,$4,$5
            STO         $4,$0,2*OCT
            % Update pointer:
            LDO         $5,$3,0     % next
            STO         $0,$5,OCT
            STO         $5,$0,0
1H          SWYM
#ifdef STATISTICS
            % TODO
            %STORE_MAX   $0,:MM:__STATISTICS:HeapMaxNonC
#endif
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            PUT         :rJ,$2
            POP         0
9H          GETA        $1,:MM:__RAW_POOL:STRS:Deallo1
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return


%%
% :MM:__RAW_POOL:Initialize
%   Create a sentinel entry in our doubly-linked list:
%
% PUSHJ:
%   no arguments
%   no return value
%
%
            .global :MM:__RAW_POOL:Initialize
Initialize  SWYM
            % Wen need 4 OCTAs:
            SET         $0,#20
            GETA        $1,Pool_Segment
            LDO         $2,$1
            % Align to OCTA:
            ADDU        $2,$2,#7
            ANDN        $2,$2,#7
            ADDU        $3,$2,$0
            % Update M8[:Pool_Segment]:
            STO         $3,$1,0
            % Create sentinel node:
            STO         $2,$2,0*OCT % ptr
            STO         $2,$2,1*OCT % ptr
            STO         $0,$2,2*OCT % size
            SET         $3,#0
            STO         $3,$2,3*OCT % mark in use
            % Store pointer to sentinel node:
            GETA        $3,:MM:__RAW_POOL:Pool
            STO         $2,$3
            POP         0


%%
% :MM:__RAW_POOL:Grow
%   Increase available memory by allocating memory from the pool
%   segment. Ensure that at least a contiguous block of arg0 bytes is
%   available for allocation
%
% PUSHJ:
%   arg0 - minimal size of a contigous block available
%   no return value
%
            .global :MM:__RAW_POOL:Grow
Grow        SWYM
            INCREMENT_COUNTER :MM:__STATISTICS:HeapGrow
            % Allocate
            %   - align to OCTA
            %   - at least twice the size as requested
            %   - at least 128MiB (#0800 0000 bytes)
            ADDU        $0,$0,#7
            ANDN        $0,$0,#7
            SLU         $0,arg0,1
            SETML       $1,#0800
            CMPU        $2,$0,$1
            CSN         $0,$2,$1
            % Sanity checks:
            GETA        $1,Pool_Segment
            LDO         $2,$1
            % Align to OCTA:
            ADDU        $2,$2,#7
            ANDN        $2,$2,#7
            ADDU        $3,$2,$0
            CMPU        $4,$1,$2 % valid pointer in M_8[:Pool_Segment]?
            BNN         $4,9F
            CMPU        $4,$1,$3
            BNN         $4,9F % check for overflow
            GETA        $4,Stack_Segment
            CMPU        $5,$4,$3 % check for valid range
            BNP         $5,9F
            % $0 - size
            % $1 - Pool_Segment
            % $2 - ptr
            % Update M8[:Pool_Segment]:
            STO         $3,$1,0
            % Update pointer:
            GETA        $1,:MM:__RAW_POOL:Pool
            LDO         $1,$1       % sentinel
            LDO         $3,$1,1*OCT % last element
            STO         $2,$1,1*OCT
            STO         $2,$3,0*OCT
            % Create entry:
            STO         $1,$2,0*OCT
            STO         $3,$2,1*OCT
            STO         $0,$2,2*OCT % size
            NEGU        $4,0,1
            STO         $4,$2,3*OCT % mark free
            % Merge left:
            % TODO
            POP         0
9H          GETA        $1,:MM:__RAW_POOL:STRS:Grow1
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return

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
            SRU         $2,arg0,3
            SUBU        $2,$2,8
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
__retry     SET         $3,arg0
            PUSHJ       $2,Grow
            GETA        $2,:MM:__RAW_POOL:Pool
            LDO         $2,$2

            %
            % 2nd pass: Use any chunk that is sufficiently large:
            %

1H          SET         $3,$2
2H          LDO         $3,$3,0
            CMP         $4,$3,$2
            BZ          $4,__retry % sentinel reached, no luck
            LDO         $4,$3,3*OCT
            BZ          $4,2B % chunk in use, go to next
            LDO         $4,$3,2*OCT % size
            CMP         $5,$0,$4
            BP          $5,2B % chunk too small, go to next
            SET         $5,#0
            STO         $5,$3,3*OCT % mark in use

            % $0 - size requested
            % $3 - ptr
            % $4 - size of chunk

            % Split chunk if beneficial
            % We have an overhead of #50 bytes per allocation. So let's say
            % we want to have at least a block of #80 bytes.
__out       SUBU        $2,$4,$0
            CMP         $2,$2,#80
            BN          $2,1F
            ADD         $2,$3,$0 % new chunk
            LDO         $5,$3,0 % next chunk
            % Mark free:
            NEG         $6,0,1
            STO         $6,$2,3*OCT
            % Update sizes:
            STO         $0,$3,2*OCT
            SUBU        $4,$4,$0
            STO         $4,$2,2*OCT
            % Update pointer:
            STO         $2,$3,0
            STO         $5,$2,0
            STO         $3,$2,OCT
            STO         $2,$5,OCT
1H          ADDU        $0,$3,#20
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            PUT         :rJ,$1
            POP         1,0

