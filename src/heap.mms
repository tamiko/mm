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
% :MM:__HEAP:
%
% General memory layout of an allocated block of memory is:
%           OCTA  size      (data + payload + 3 OCTS)
%           OCTA  checksum1 (xor size ptr)
%           OCTAs payload   (currently 3 OCTAs)
%    ptr -> OCTAs data
%           OCTA  checksum2 (nxor size ptr)
%
% We use the first OCTA in payload as a locking mechanism: If it is
% nonzero, Dealloc and Realloc will fail.
%
% Actual memory management is delegated to :MM:__RAW_POOL:Alloc,
% :MM:__RAW_POOL:Dealloc.
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__HEAP:STRS:
            .balign 4
Alloc1      BYTE        "Heap:Alloc failed. Could not request a memory "
            BYTE        "block of size [arg0=",0
            .balign 4
Alloc2      BYTE        "]. Out of memory.",10,0
            .balign 4
Free1       BYTE        "Heap:Free failed. Invalid pointer [arg0=",0
            .balign 4
Free2       BYTE        "]. Double free or corruption.",10,0
            .balign 4
Free3       BYTE        "]. Memory region is locked.",10,0
            .balign 4
Size1       BYTE        "Heap:Size failed. Invalid pointer [arg0=",0
            .balign 4
Size2       BYTE        "].",10,0
            .balign 4
Move1       BYTE        "Heap:Move failed. Invalid pointer [arg0=",0
            .balign 4
Move2       BYTE        "Heap:Move failed. Invalid pointer [arg1=",0
            .balign 4
Move3       BYTE        "].",10,0
            .balign 4
Move4       BYTE        "Heap::Move failed. Something went horribly "
            BYTE        "wrong",10,0
            .balign 4
Reallo1     BYTE        "Heap:Realloc failed. Invalid pointer [arg0=",0
            .balign 4
Reallo2     BYTE        "].",10,0
            .balign 4
Reallo2b    BYTE        "]. Memory region locked.",10,0
            .balign 4
Reallo3     BYTE        "Heap:Realloc failed. Could not request a memory "
            BYTE        "block of size [arg1=",0
            .balign 4
Reallo4     BYTE        "]. Out of memory.",10,0
            .balign 4
Reallo5     BYTE        "Heap::Realloc failed. Something went horribly "
            BYTE        "wrong",10,0
            .balign 4
Set1        BYTE        "Heap:Set failed. Invalid pointer [arg0=",0
            .balign 4
Set2        BYTE        "].",10,0
            .balign 4
Zero1       BYTE        "Heap:Zero failed. Invalid pointer [arg0=",0
            .balign 4
Zero2       BYTE        "].",10,0
            .balign 4
SetZero     BYTE        "Heap:Set/Zero failed. Something went horribly "
            BYTE        "wrong",10,0
            .balign 4
Rand1       BYTE        "Heap:Rand failed. Invalid pointer [arg0=",0
            .balign 4
Rand2       BYTE        "].",10,0
            .balign 4
Rand3       BYTE        "Heap:Rand failed. Something went horribly "
            BYTE        "wrong",10,0


            .section .text,"ax",@progbits
            PREFIX      :MM:__HEAP:
Pool_Segment IS         :Pool_Segment
Stack_Segment IS        :Stack_Segment
t           IS          :MM:t
arg0        IS          $0
arg1        IS          $1
arg2        IS          $2
ret0        IS          $0
ret1        IS          $1
ret2        IS          $2
OCT         IS          #8

% payload + Checksum + size of 6 OCTAs:
payload     IS          #30


%%
% :MM:__HEAP:AllocJ
%
% PUSHJ:
%   arg0 - requested size
%   retm - pointer to allocated memory, [0 in case of error condition]
%
% :MM:__HEAP:Alloc
%
% PUSHJ:
%   arg0 - requested size
%   retm - pointer to allocated memory
%
% :MM:__HEAP:AllocG
%
% PUSHJ
%

            .global :MM:__HEAP:Alloc
            .global :MM:__HEAP:AllocJ
            .global :MM:__HEAP:AllocG
AllocJ      GET         $1,:rJ
            SET         $3,t
            ADDU        $0,arg0,#7 % round up to next OCTA
            ANDN        $0,$0,#7
            ADDU        $0,$0,payload
            CMPU        t,$0,payload % check for overflow
            BN          t,1F
            SET         $5,$0
            PUSHJ       $4,:MM:__RAW_POOL:Alloc
            SET         $2,$4
            BZ          $2,1F
            PUT         :rJ,$1
            SET         $1,$2
            STO         $0,$1,0 % store size
            ADDU        $2,$2,payload-OCT
            XOR         $2,$2,$0
            STO         $2,$1,1*OCT % store checksum1
            SET         t,#0000
            STO         t,$1,2*OCT % set first payload OCTA to zero
            NXOR        $2,$2,0
            SUBU        $0,$0,1*OCT
            STO         $2,$1,$0 % store checksum2
            ADDU        ret0,$1,payload-OCT
            SET         t,$3
            POP         1,1
1H          PUT         :rJ,$1
            POP         0,0
Alloc       SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,AllocJ
            JMP         1F
            PUT         :rJ,$1
            SET         ret0,$2
            POP         1,0
AllocG      SET         $3,t
            GET         $1,:rJ
            PUSHJ       $2,AllocJ
            JMP         1F
            PUT         :rJ,$1
            SET         t,$2
            POP         0,0
1H          GET         t,:rJ % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Alloc1
            GETA        $3,:MM:__HEAP:STRS:Alloc2
            PUSHJ       $0,:MM:__ERROR:Error3R2


%%
% :MM:__HEAP:DeallocJ
%
% PUSHJ:
%   arg0 - pointer to allocated memory
%   no return value
%
% :MM:__HEAP:Dealloc
%
% PUSHJ:
%   arg0 - pointer to allocated memory
%   no return value
%
% :MM:__HEAP:DeallocG
%
% PUSHJ
%

            .global :MM:__HEAP:Dealloc
            .global :MM:__HEAP:DeallocJ
            .global :MM:__HEAP:DeallocG
DeallocJ    GET         $1,:rJ
            SET         $5,t
            SET         $7,arg0
            PUSHJ       $6,SizeJ
            JMP         1F % Invalid pointer
            SET         $2,$6
            % Check if memory region is locked:
            SUBU        $3,arg0,payload-3*OCT % first payload OCTA
            LDO         $3,$3
            BNZ         $3,1F
            % Zero out metadata:
            SUBU        $3,arg0,payload-OCT % raw pointer
            STCO        0,$3,0 % size field
            STCO        0,$3,1*OCT % checksum1
            PREST       #10,$3
            ADDU        $4,$2,payload-OCT
            STCO        0,$3,$4 % checksum2
            PREST       #8,$3,$4
            ADDU        $4,$4,1*OCT % size
            % And deallocate:
            SET         $7,$3
            SET         $8,$4
            PUSHJ       $6,:MM:__RAW_POOL:Dealloc
            PUT         :rJ,$1
            SET         t,$5
            POP         0,1
1H          PUT         :rJ,$1
            SET         t,$5
            POP         0,0
DeallocG    SET         $0,t
Dealloc     SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,DeallocJ
            JMP         1F
            PUT         :rJ,$1
            POP         0,0
            % Deallocation failed. Check if memory region is valid but
            % locked:
1H          SET         t,arg0
            PUSHJ       t,ValidG
            BN          t,1F
            SUBU        t,arg0,payload-3*OCT % first payload OCTA
            LDO         t,t,0
            BZ          t,1F
            SET         t,$1 % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Free1
            GETA        $3,:MM:__HEAP:STRS:Free3
            PUSHJ       $0,:MM:__ERROR:Error3R2
1H          SET         t,$1 % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Free1
            GETA        $3,:MM:__HEAP:STRS:Free2
            PUSHJ       $0,:MM:__ERROR:Error3R2


%%
% :MM:__HEAP:ReallocJ
%
% PUSHJ:
%   arg0 - pointer to  memory region
%   arg1 - requested size (in bytes)
%   retm - pointer to allocated memory [0 in case of error condition]
%

            .global :MM:__HEAP:ReallocJ
            % validate first to avoid space leaks
ReallocJ    GET         $2,:rJ
            SET         $4,arg0
            PUSHJ       $3,ValidJ
            JMP         1F
            % Check if memory region is locked:
            SUBU        $3,arg0,payload-3*OCT % first payload OCTA
            LDO         $3,$3
            BNZ         $3,1F
            SET         $4,arg1
            PUSHJ       $3,AllocJ
            JMP         1F
            SET         $6,$3
            SET         $5,arg0
            PUSHJ       $4,CopyJ
            JMP         2F
            SET         $5,arg0
            PUSHJ       $4,DeallocJ
            JMP         2F
            SET         ret0,$3
            PUT         :rJ,$2
            POP         1,1
1H          PUT         :rJ,$2
            POP         0,0
2H          GETA        $1,:MM:__HEAP:STRS:Reallo5
            PUSHJ       $0,:MM:__ERROR:IError1


%%
% :MM:__HEAP:Realloc
%
% PUSHJ:
%   arg0 - pointer to  memory region
%   arg1 - requested size (in bytes)
%   retm - pointer to allocated memory [0 in case of error condition]
%

            .global :MM:__HEAP:Realloc
Realloc     GET         $2,:rJ
            SET         $4,arg0
            PUSHJ       $3,ValidJ
            JMP         1F
            % Check if memory region is locked:
            SUBU        $3,arg0,payload-3*OCT % first payload OCTA
            LDO         $3,$3
            BNZ         $3,8F
            SET         $4,arg1
            PUSHJ       $3,AllocJ
            JMP         2F
            SET         $6,$3
            SET         $5,arg0
            PUSHJ       $4,CopyJ
            JMP         3F
            SET         $5,arg0
            PUSHJ       $4,DeallocJ
            JMP         3F
            SET         ret0,$3
            PUT         :rJ,$2
            POP         1,0
1H          SET         t,$2 % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Reallo1
            GETA        $3,:MM:__HEAP:STRS:Reallo2
            PUSHJ       $0,:MM:__ERROR:Error3R2
8H          SET         t,$2 % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Reallo1
            GETA        $3,:MM:__HEAP:STRS:Reallo2b
            PUSHJ       $0,:MM:__ERROR:Error3R2
2H          SET         t,$2 % :rJ
            SET         $2,arg1
            GETA        $1,:MM:__HEAP:STRS:Reallo3
            GETA        $3,:MM:__HEAP:STRS:Reallo4
            PUSHJ       $0,:MM:__ERROR:Error3R2
3H          GETA        $1,:MM:__HEAP:STRS:Reallo5
            PUSHJ       $0,:MM:__ERROR:IError1


%%
% :MM:__HEAP:ValidJ
%
% PUSHJ:
%   arg0 - pointer to allocated memory
%   no return value
%
% :MM:__HEAP:SizeJ
%
% PUSHJ:
%   arg0 - pointer to allocated memory
%   retm - size of the allocated memory,
%          [0 in case of error condition]
%

            .global :MM:__HEAP:ValidJ
            .global :MM:__HEAP:SizeJ
ValidJ      SET         $5,0
            JMP         1F
SizeJ       SET         $5,1
            % A pointer to memory must be inside the pool segment:
1H          SET         $6,t
            GETA        t,Pool_Segment
            ADDU        t,t,payload-OCT
            CMPU        t,arg0,t
            BN          t,1F
            GETA        t,Stack_Segment
            CMPU        t,arg0,t
            BNN         t,1F
            SUBU        $1,arg0,payload-OCT
            LDO         $2,$1,0 % size
            CMPU        t,$2,payload % size must be at least the payload
            BN          t,1F
            % verify checksum1:
            LDO         $3,$1,1*OCT % checksum1
            XOR         $3,$3,arg0
            CMPU        t,$3,$2
            BNZ         t,1F
            % verify checksum2:
            LDO         $3,$1,1*OCT % checksum1
            SUBU        $2,$2,1*OCT
            LDO         $4,$1,$2 % checksum2
            ADDU        $2,$2,1*OCT
            NXOR        t,$3,$4
            BNZ         t,1F
            SUBU        ret0,$2,payload
            SET         t,$6
            BZ          $5,2F
            POP         1,1 % return for SizeJ
2H          POP         0,1 % return for ValidJ
1H          SET         t,$6
            POP         0,0


%%
% :MM:__HEAP:Size
%
% PUSHJ:
%   arg0 - pointer to allocated memory
%   retm - size of the allocated memory
%
% :MM:__HEAP:SizeG
%
% PUSHJ
%

            .global :MM:__HEAP:Size
            .global :MM:__HEAP:SizeG
Size        SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,SizeJ
            JMP         1F
            PUT         :rJ,$1
            SET         ret0,$2
            POP         1,0
1H          SET         t,$1 % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Size1
            GETA        $3,:MM:__HEAP:STRS:Size2
            PUSHJ       $0,:MM:__ERROR:Error3R2
SizeG       SET         $3,t
            GET         $1,:rJ
            PUSHJ       $2,SizeJ
            JMP         1F
            PUT         :rJ,$1
            SET         t,$2
            POP         0,0
1H          SET         t,$1 % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Size1
            GETA        $3,:MM:__HEAP:STRS:Size2
            PUSHJ       $0,:MM:__ERROR:Error3R2


%%
% :MM:__HEAP:Valid
%
% PUSHJ:
%   arg0 - pointer to allocated memory
%   retm - 0 indicating a valid pointer, -1 otherwise
%
% :MM:__HEAP:ValidG
%
% PUSHJ
%

            .global :MM:__HEAP:Valid
            .global :MM:__HEAP:ValidG
Valid       SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,ValidJ
            JMP         1F
            PUT         :rJ,$1
            SET         ret0,0
            POP         1,0
1H          PUT         :rJ,$1
            SET         ret0,1
            NEG         ret0,ret0
            POP         1,0
ValidG      GET         $0,:rJ
            SET         $2,t
            PUSHJ       $1,Valid
            PUT         :rJ,$0
            SET         t,$1
            POP         0,0


%%
% :MM:__HEAP:CopyJ
%
% PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - pointer to destination memory
%   no return value
%

            .global :MM:__HEAP:CopyJ
CopyJ       GET         $2,:rJ
            SET         $6,arg0
            PUSHJ       $5,SizeJ % size of arg0
            JMP         1F
            SET         $7,arg1
            PUSHJ       $6,SizeJ % size of arg1
            JMP         1F
            CMPU        $7,$5,$6
            CSN         $6,t,$5
            SET         $4,arg0
            SET         $5,arg1
            PUSHJ       $3,:MM:__MEM:CopyJ
            JMP         3F
            PUT         :rJ,$2
            POP         0,1
1H          PUT         :rJ,$2
            POP         0,0
3H          GETA        $1,:MM:__HEAP:STRS:Move4
            PUSHJ       $0,:MM:__ERROR:IError1

%%
% :MM:__HEAP:Copy
%
% PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - pointer to destination memory
%   no return value
%

            .global :MM:__HEAP:Copy
Copy        GET         $2,:rJ
            SET         $6,arg0
            PUSHJ       $5,SizeJ % size of arg0
            JMP         1F
            SET         $7,arg1
            PUSHJ       $6,SizeJ % size of arg1
            JMP         2F
            % No point to call into CopyJ for 5 instuctions...
            CMPU        $7,$5,$6
            CSN         $6,$7,$5
            SET         $4,arg0
            SET         $5,arg1
            PUSHJ       $3,:MM:__MEM:CopyJ
            JMP         3F
            PUT         :rJ,$2
            POP         0,0
1H          SET         t,$2 % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Move1
            GETA        $3,:MM:__HEAP:STRS:Move3
            PUSHJ       $0,:MM:__ERROR:Error3R2
2H          SET         t,$2 % :rJ
            SET         $2,arg1
            GETA        $1,:MM:__HEAP:STRS:Move2
            GETA        $3,:MM:__HEAP:STRS:Move3
            PUSHJ       $0,:MM:__ERROR:Error3R2
3H          GETA        $1,:MM:__HEAP:STRS:Move4
            PUSHJ       $0,:MM:__ERROR:IError1


%%
% :MM:__HEAP:ZeroJ
%
% PUSHJ:
%   arg0 - pointer to memory block
%   no return value
%
% :MM:__HEAP:SetJ
%
% PUSHJ:
%   arg0 - pointer to memory block
%   arg1 - pointer to memory block
%   no return value
%

            .global :MM:__HEAP:ZeroJ
            .global :MM:__HEAP:SetJ
ZeroJ       SET         $1,0
SetJ        GET         $2,:rJ
            SET         $7,arg0
            PUSHJ       $6,SizeJ
            JMP         1F
            SET         $4,arg0
            SET         $5,arg1
            PUSHJ       $3,:MM:__MEM:SetJ
            JMP         2F
            PUT         :rJ,$2
            POP         0,1
1H          PUT         :rJ,$2
            POP         0,0
2H          GETA        $1,:MM:__HEAP:STRS:SetZero
            PUSHJ       $0,:MM:__ERROR:IError1


%%
% :MM:__HEAP:Set
%
% PUSHJ:
%   arg0 - pointer to memory block
%   arg1 - byte template
%   no return value
%

            .global :MM:__HEAP:Set
Set         GET         $2,:rJ
            SET         $5,arg1
            SET         $4,arg0
            PUSHJ       $3,SetJ
            JMP         1F
            PUT         :rJ,$2
            POP         0,0
1H          SET         t,$2 % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Set1
            GETA        $3,:MM:__HEAP:STRS:Set2
            PUSHJ       $0,:MM:__ERROR:Error3R2


%%
% :MM:__HEAP:Zero
%
% PUSHJ:
%   arg0 - pointer to memory block
%   no return value
%
% :MM:__HEAP:ZeroG
%
% PUSHJ
%

            .global :MM:__HEAP:Zero
            .global :MM:__HEAP:ZeroG
ZeroG       SET         $0,t
Zero        GET         $1,:rJ
            SET         $3,arg0
            PUSHJ       $2,ZeroJ
            JMP         1F
            PUT         :rJ,$1
            POP         0,0
1H          SET         t,$1 %:rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Zero1
            GETA        $3,:MM:__HEAP:STRS:Zero2
            PUSHJ       $0,:MM:__ERROR:Error3R2


%%
% :MM:__HEAP:RandJ
%
% PUSHJ:
%   arg0 - pointer to memory block
%   no return value
%

            .global :MM:__HEAP:RandJ
RandJ       GET         $1,:rJ
            SET         $5,arg0
            PUSHJ       $4,SizeJ
            JMP         1F
            SET         $3,arg0
            PUSHJ       $2,:MM:__RAND:SetJ
            JMP         2F
            PUT         :rJ,$1
            POP         0,1
1H          PUT         :rJ,$1
            POP         0,0
2H          GETA        $1,:MM:__HEAP:STRS:Rand3
            PUSHJ       $0,:MM:__ERROR:IError1


%%
% :MM:__HEAP:Rand
%
% PUSHJ:
%   arg0 - pointer to memory block
%   no return value
%
% :MM:__HEAP:RandG
%
% PUSHJ
%

            .global :MM:__HEAP:Rand
            .global :MM:__HEAP:RandG
RandG       SET         $0,t
Rand        GET         $1,:rJ
            SET         $3,arg0
            PUSHJ       $2,RandJ
            JMP         1F
            PUT         :rJ,$1
            POP         0,0
1H          SET         t,$1 % :rJ
            SET         $2,arg0
            GETA        $1,:MM:__HEAP:STRS:Rand1
            GETA        $3,:MM:__HEAP:STRS:Rand2
            PUSHJ       $0,:MM:__ERROR:Error3R2

