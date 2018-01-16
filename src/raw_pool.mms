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
% A very minimalistic memory pool implementation.
%
% TODO: Implement a heap structure for efficiently storing the pool.
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__RAW_POOL:STRS:
Grow1       BYTE        "__RAW_POOL::Grow failed. "
            BYTE        "Out of memory.",10,0
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

t           IS          $255
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
Dealloc     GET         $10,:rJ
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            INCREMENT_COUNTER :MM:__STATISTICS:HeapDealloc
            % Align arg1 to 2*OCT and make sure it is at least 2*OCT:
            CSZ         arg1,arg1,#10
            ADDU        arg1,arg1,#F
            ANDN        arg1,arg1,#F
            % A bunch of rudimentary checks:
            LDA         $2,Pool_Segment
            CMPU        t,$2,arg0
            BNN         t,1F
            ADDU        $3,arg0,arg1
            CMPU        t,$2,$3
            BNN         t,1F
            LDA         $2,Stack_Segment
            CMPU        t,$2,$3
            BNP         t,1F
            %
            % We must keep the linked list of free memory regions sorted!
            %
            LDA         $4,:MM:__RAW_POOL:Pool
            LDO         ptr,$4
            SET         prev_ptr,#0
3H          CMPU        t,arg0,ptr
            BN          t,2F
            SET         prev_ptr,ptr
            LDO         ptr,ptr
            CMPU        t,ptr,#0
            BNZ         t,3B
            % We have prev_ptr < arg0 < ptr:
2H          STO         ptr,arg0,#0
            STO         arg1,arg0,#8
            BNZ         prev_ptr,9F
            STO         arg0,$4
            JMP         8F
9H          STO         arg0,prev_ptr
            % Recompact:
8H          BZ          prev_ptr,4F
            LDO         $4,prev_ptr,#8
            ADDU        $4,$4,prev_ptr
            CMP         $4,$4,arg0
            BNZ         $4,4F
            % Merge prev_ptr and arg0:
            LDO         $4,arg0,#0
            STO         $4,prev_ptr,#0
            LDO         $4,arg0,#8
            LDO         $5,prev_ptr,#8
            ADDU        $4,$5,$4
            STO         $4,prev_ptr,#8
            SET         arg0,prev_ptr
4H          BZ          ptr,4F
            LDO         $4,arg0,#8
            ADDU        $4,$4,arg0
            CMP         $4,$4,ptr
            BNZ         $4,4F
            % Merge arg0 and ptr:
            LDO         $4,ptr,#0
            STO         $4,arg0,#0
            LDO         $4,ptr,#8
            LDO         $5,arg0,#8
            ADDU        $4,$5,$4
            STO         $4,arg0,#8
4H          SWYM
#ifdef STATISTICS
            SET         $0,0
            LDA         $1,:MM:__RAW_POOL:Pool
7H          LDO         $1,$1
            BZ          $1,8F
            ADDU        $0,$0,1
            JMP         7B
8H          STORE_MAX   $0,:MM:__STATISTICS:HeapMaxNonC
#endif
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            PUT         :rJ,$10
            POP         0
1H          LDA         $1,:MM:__RAW_POOL:STRS:Deallo1
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return


%%
% :MM:__RAW_POOL:Grow
%   Increase available memory by allocating memory from the pool
%   segment. Ensure that at least a continuous block of arg0 bytes is
%   available for allocation
%
% PUSHJ:
%   arg0 - minimal size of a continous block available
%   no return value
%
            % Allocate
            %   - at least 128MiB (#0800 0000 bytes)
            %   - at least twice the size as requested
            %   - align to 2OCTA
            .global :MM:__RAW_POOL:Grow
ptr         IS          $2
prev_ptr    IS          $3
Grow        SWYM
            INCREMENT_COUNTER :MM:__STATISTICS:HeapGrow
            SLU         $0,arg0,1
            SETML       $1,#0800
            CMPU        t,$0,$1
            CSN         $0,t,$1
            ADDU        $0,$0,#F
            ANDN        $0,$0,#F
            % Sanity checks:
            LDA         $1,Pool_Segment
            LDO         $2,$1
            ADDU        $2,$2,#F
            ANDN        $2,$2,#F % align
            ADDU        $3,$2,$0
            CMPU        t,$1,$2 % valid pointer in M_8[:Pool_Segment]?
            BNN         t,1F
            CMPU        t,$1,$3
            BNN         t,1F % check for overflow
            LDA         $4,Stack_Segment
            CMPU        t,$4,$3 % check for valid range
            BNP         t,1F
            STO         $3,$1,0
            SET         $1,$2
            SET         t,#0000
            STO         t,$1,#0
            STO         $0,$1,#8
            % Get to last entry:
            LDA         $4,:MM:__RAW_POOL:Pool
            LDO         ptr,$4
            SET         prev_ptr,#0
2H          CMPU        t,ptr,#0
            BZ          t,3F
            SET         prev_ptr,ptr
            LDO         ptr,ptr
            JMP         2B
3H          BNZ         prev_ptr,9F
            STO         $1,$4
            JMP         8F
9H          STO         $1,prev_ptr
            % Recompact:
            LDO         $4,prev_ptr,#8
            ADDU        $4,$4,prev_ptr
            CMP         $4,$4,$1
            BNZ         $4,8F
            % Merge prev_ptr and arg0:
            SET         t,#0000
            STO         t,prev_ptr,#0
            LDO         $4,prev_ptr,#8
            ADDU        $4,$4,$0
            STO         $4,prev_ptr,#8
8H          POP         0
1H          LDA         $1,:MM:__RAW_POOL:STRS:Grow1
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return

%%
% :MM:__RAW_POOL:Alloc
%   Allocate a continous block of memory. arg1 is aligned to
%   2*OCT and set to at least 2*OCT.
%
% PUSHJ:
%   arg0 - size of memory block to allocate (in bytes)
%   retm - the address of the allocated block;
%
            .global :MM:__RAW_POOL:Alloc
ptr         IS          $1
prev_ptr    IS          $2
            % Align arg0 to 2 * 8 and make sure to request at least 2*OCT:
Alloc       GET         $5,:rJ
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            INCREMENT_COUNTER :MM:__STATISTICS:HeapAlloc
            CSZ         arg0,arg0,#10
            ADDU        arg0,arg0,#F
            ANDN        arg0,arg0,#F
#ifdef STATISTICS
            SRU         t,arg0,3
            SUBU        t,t,8
            SET         $1,#00F8
            ODIF        $1,t,$1
            SUBU        t,t,$1
            INCREMENT_COUNTER :MM:__STATISTICS:HeapSizes,t
#endif
            %
            % Initialize the pool if necessary:
            %
            LDA         $2,:MM:__RAW_POOL:Pool
            LDO         $2,$2
            PBNZ        $2,1F
__retry     SET         $7,arg0
            PUSHJ       $6,Grow
            %
            % 1st pass: Try to find a chunk with requested size:
            %
1H          LDA         $2,:MM:__RAW_POOL:Pool
            LDO         ptr,$2
            SET         prev_ptr,#0
3H          LDO         t,ptr,OCT
            CMPU        t,arg0,t
            BZ          t,2F % matching size?
            SET         prev_ptr,ptr
            LDO         ptr,ptr
            CMPU        t,ptr,0
            BNZ         t,3B
            JMP         1F % no luck
2H          LDO         $3,ptr
            JMP         __out
            %
            % 2nd pass: Use any chunk that is sufficiently large:
            %
1H          LDA         $2,:MM:__RAW_POOL:Pool
            LDO         ptr,$2
            SET         prev_ptr,#0
3H          LDO         t,ptr,OCT
            CMPU        t,arg0,t
            BN          t,2F % sufficiently large?
            SET         prev_ptr,ptr
            LDO         ptr,ptr
            CMPU        t,ptr,0
            BNZ         t,3B
            JMP         __retry % no luck, increase pool memory and retry.
            % chop off the rest:
2H          LDO         t,ptr,0
            STO         t,ptr,arg0
            LDO         t,ptr,OCT
            SUBU        t,t,arg0
            ADDU        arg0,arg0,OCT
            STO         t,ptr,arg0
            SUBU        arg0,arg0,OCT
            ADDU        $3,ptr,arg0
__out       BNZ         prev_ptr,9F
            LDA         $2,:MM:__RAW_POOL:Pool
            STO         $3,$2
            JMP         8F
9H          STO         $3,prev_ptr
8H          SET         arg0,ptr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            PUT         :rJ,$5
            POP         1,0
