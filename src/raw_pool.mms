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
% :MM:__RAW_POOL:
%
% A very minimalistic memory pool implementation.
% Inclusion of this header file will consume one GREG.
%
% TODO: Implement a heap structure for efficiently storing the pool.
%

            .section .data,"wa",@progbits
            .global :MM:__RAW_POOL:STRS:Grow1
            .global :MM:__RAW_POOL:STRS:Deallo1
            PREFIX      :MM:__RAW_POOL:STRS:
Grow1       BYTE        "__RAW_POOL::Grow failed. "
            BYTE        "Out of memory.",10,0
Deallo1     BYTE        "__RAW_POOL::Dealloc called with invalid "
            BYTE        "range specified.",10,0


            .section .text,"ax",@progbits
            PREFIX      :MM:__RAW_POOL:
Pool_Segment IS         :Pool_Segment
Stack_Segment IS        :Stack_Segment

%%
% We use a GREG to maintain a pool of memory blocks
%
            .global :MM:__RAW_POOL:pool_ptr
pool_ptr    GREG        0

t           IS          $255
arg0        IS          $0
arg1        IS          $1
OCT         IS          #8

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
            % Allocate at least 128MiB (#0800 0000 bytes) and at least
            % twice the size as requested:
Grow        SLU         $0,arg0,1
            SETML       $1,#0800
            CMPU        t,$0,$1
            CSN         $0,t,$1
            ADDU        $0,$0,#F
            ANDN        $0,$0,#F
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
            SET         t,$3
            STO         $3,$1,0
            STO         pool_ptr,$2,0
            STO         $0,$2,OCT
            SET         pool_ptr,$2
            GET         $0,:rJ
            PUSHJ       t,Recompact
            PUT         :rJ,$0
            POP         0
1H          LDA         $1,:MM:__POOL:STRS:Grow1
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
            % Align arg1 to 2*OCT and make sure it is at least 2*OCT:
Dealloc     CSZ         arg1,arg1,#10
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
            STO         pool_ptr,arg0,0 % pointer
            STO         arg1,arg0,OCT % size
            SET         pool_ptr,arg0 % update pointer
            GET         $0,:rJ
            PUSHJ       t,Recompact
            PUT         :rJ,$0
            POP         0
1H          LDA         $1,:MM:__POOL:STRS:Deallo1
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return

%%
% :MM:__RAW_POOL:Recompact
%
% A rudimentary reduction strategy: Merge adjacents blocks of memory
% that can be easily spotted by a linear search
%
% PUSHJ:
%   no arguments
%   no return value
%
Recompact   BZ          pool_ptr,2F % nothing to do
ptrB        IS          $0
ptrC        IS          $1
sizeC       IS          $2
ptrN        IS          $3
sizeN       IS          $4
            SET         ptrB,0
            SET         ptrC,pool_ptr % current ptr
9H          LDO         sizeC,ptrC,OCT % current size
            LDO         ptrN,ptrC,0 % next ptr
            CMPU        t,ptrN,0 % nothing more to do
            BZ          t,2F
            LDO         sizeN,ptrN,OCT % next size
            % First case, merge if ptrC + sizeC = ptrN:
            ADDU        t,ptrC,sizeC
            CMPU        t,t,ptrN
            BNZ         t,1F
            LDO         t,ptrN,0 % update ptr
            STO         t,ptrC,0
            STCO        0,ptrN,0 % clear data
            STCO        0,ptrN,OCT
            PREST       #10,ptrN
            ADDU        t,sizeC,sizeN % update size
            STO         t,ptrC,OCT
            JMP         9B
            % Second case, merge if ptrN + sizeN = ptrC:
1H          ADDU        t,ptrN,sizeN
            CMPU        t,t,ptrC
            BNZ         t,1F
            STCO        0,ptrC,0 % clear data
            STCO        0,ptrC,OCT
            PREST       #10,ptrC
            ADDU        sizeN,sizeN,sizeC % update size
            STO         sizeN,ptrN,OCT
            BZ          ptrB,3F
            STO         ptrN,ptrB,0
            SET         ptrC,ptrN
            JMP         9B
3H          SET         pool_ptr,ptrN
            SET         ptrC,ptrN
            JMP         9B
            % Advance pointer
1H          SET         ptrB,ptrC
            SET         ptrC,ptrN
            JMP         9B
2H          POP         0

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
            % Align arg1 to 2 * 8 and make sure to request at least
            % 2*OCT:
Alloc       CSZ         arg0,arg0,#10
            ADDU        arg0,arg0,#F
            ANDN        arg0,arg0,#F
            % Initialize the pool if necessary:
            PBNZ        pool_ptr,1F
            GET         $1,:rJ
            SET         $3,0
            PUSHJ       $2,Grow
            PUT         :rJ,$1
            % 1st case: use chunk pointed to by pool_ptr:
1H          LDO         t,pool_ptr,OCT
            CMPU        t,arg0,t
            BN          t,1F % chunk too big
            BP          t,2F % chunk too small
            SET         arg0,pool_ptr
            LDO         pool_ptr,pool_ptr,0
            POP         1,0
1H          LDO         t,pool_ptr,0
            STO         t,pool_ptr,arg0
            LDO         t,pool_ptr,OCT
            SUBU        t,t,arg0
            ADDU        arg0,arg0,OCT
            STO         t,pool_ptr,arg0
            SUBU        arg0,arg0,OCT
            ADDU        pool_ptr,pool_ptr,arg0
            SUBU        arg0,pool_ptr,arg0
            POP         1,0
            % 2nd case: use some later chunk:
2H          SET         prev_ptr,pool_ptr
            LDO         ptr,pool_ptr
3H          CMPU        t,ptr,0
            PBNZ        t,5F
            % Out of pool memory, allocate new memory from the pool:
            GET         $1,:rJ
            SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,Grow
            PUT         :rJ,$1
            JMP         Alloc % ... and restart
5H          LDO         t,ptr,OCT
            CMPU        t,arg0,t
            BN          t,4F % chunk too big
            BP          t,5F % chunk too small
            SET         arg0,ptr
            LDO         t,ptr,0
            STO         t,prev_ptr,0
            POP         1,0
4H          LDO         t,ptr,0
            STO         t,ptr,arg0
            LDO         t,ptr,OCT
            SUBU        t,t,arg0
            ADDU        arg0,arg0,OCT
            STO         t,ptr,arg0
            SUBU        arg0,arg0,OCT
            ADDU        ptr,ptr,arg0
            STO         ptr,prev_ptr,0
            SUBU        arg0,ptr,arg0
            POP         1,0
5H          SET         prev_ptr,ptr
            LDO         ptr,ptr,0
            JMP         3B % loop
