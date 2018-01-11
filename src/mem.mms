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
% :MM:__MEM:
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__MEM:STRS:
Copy1       BYTE        "Mem:Copy failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
Copy2       BYTE        "Mem:Copy failed. Invalid data range specified. "
            BYTE        "Memory region [arg1,arg1+arg2), with [arg1=",0
Copy3       BYTE        "] and [arg2=",0
Copy4       BYTE        "], wraps.",10,0
Copy5       BYTE        "Mem:Copy failed. Something went horribly "
            BYTE        "wrong",10,0
Set1        BYTE        "Mem:Set failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
Set2        BYTE        "] and [arg2=",0
Set3        BYTE        "], wraps.",10,0
Set4        BYTE        "Mem:Set failed. Something went horribly "
            BYTE        "wrong",10,0
Zero1       BYTE        "Mem:Zero failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
Zero2       BYTE        "] and [arg2=",0
Zero3       BYTE        "], wraps.",10,0
Zero4       BYTE        "Mem:Zero failed. Something went horribly "
            BYTE        "wrong",10,0
Rand1       BYTE        "Mem:Rand failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
Rand2       BYTE        "] and [arg2=",0
Rand3       BYTE        "], wraps.",10,0
Rand4       BYTE        "Mem:Rand failed. Something went horribly "
            BYTE        "wrong",10,0
Cmp1        BYTE        "Mem:Cmp failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
Cmp2        BYTE        "Mem:Cmp failed. Invalid data range specified. "
            BYTE        "Memory region [arg1,arg1+arg2), with [arg1=",0
Cmp3        BYTE        "] and [arg2=",0
Cmp4        BYTE        "], wraps.",10,0


            .section .text,"ax",@progbits
            PREFIX      :MM:__MEM:
t           IS          $255
arg0        IS          $0
arg1        IS          $1
arg2        IS          $2
ret0        IS          $0
ret1        IS          $1
ret2        IS          $2
OCT         IS          #8


%%
% :MM:__MEM:CopyJ
%
% PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - pointer to destination memory
%   arg2 - size (in bytes)
%   no return value
%

            .global :MM:__MEM:CopyJ
            % Check preconditions:
CopyJ       ADDU        t,arg0,arg2
            CMPU        t,t,arg0
            BN          t,9F
            ADDU        t,arg1,arg2
            CMPU        t,t,arg1
            BN          t,9F
            CMPU        t,arg0,arg1
            BZ          t,8F % Nothing to do.
            BZ          arg2,8F % Nothing to do.
CopyInternJ SWYM
            % $2 - bytes rounded down to full octas
            % $3 - remaining bytes
            SET         $3,arg2
            AND         $3,$3,#7
            ANDN        $2,$2,#7
            % $4 - alignment in bits of [arg0,arg+arg2)
            % $5
            % $6 - alignment in bits of [arg1,arg+arg2)
            % $7
            AND         $4,arg0,#7
            NEGU        $5,#8,$4
            AND         $6,arg1,#7
            NEGU        $7,#8,$6
            SLU         $4,$4,3
            SLU         $5,$5,3
            SLU         $6,$6,3
            SLU         $7,$7,3
            % copy full octas:
1H          BZ          $2,2F    % TODO: Refactor into one LDO/STO op per round
            LDOU        $8,$0,0
            LDOU        $9,$0,#8
            SLU         $8,$8,$4
            SRU         $9,$9,$5
            OR          $8,$8,$9
            LDOU        $9,$1,0
            SRU         $9,$9,$7
            SLU         $9,$9,$7
            SRU         $10,$8,$6
            OR          $9,$9,$10
            STOU        $9,$1,0
            LDOU        $9,$1,#8
            SLU         $9,$9,$6
            SRU         $9,$9,$6
            SLU         $10,$8,$7
            OR          $9,$9,$10
            STOU        $9,$1,#8
            ADDU        $0,$0,#8
            ADDU        $1,$1,#8
            SUBU        $2,$2,#8
            JMP         1B
            % copy remaining bytes:
2H          LDOU        $8,$0,0
            LDOU        $9,$0,#8
            SLU         $8,$8,$4
            SRU         $9,$9,$5
            OR          $8,$8,$9 % full octa of source
            LDOU        $9,$1,0
            LDOU        $10,$1,#8
            SLU         $9,$9,$6
            SRU         $10,$10,$7
            OR          $9,$9,$10 % full octa of destination
            NEGU        $10,#8,$3
            SLU         $10,$10,3
            SRU         $8,$8,$10
            SLU         $8,$8,$10
            SLU         $3,$3,3
            SLU         $9,$9,$3
            SRU         $9,$9,$3
            OR          $8,$8,$9 % combined octa respecting remaining bytes
                                 % to copy
            LDOU        $9,$1,0
            SRU         $9,$9,$7
            SLU         $9,$9,$7
            SRU         $10,$8,$6
            OR          $9,$9,$10
            STOU        $9,$1,0
            LDOU        $9,$1,#8
            SLU         $9,$9,$6
            SRU         $9,$9,$6
            SLU         $10,$8,$7
            OR          $9,$9,$10
            STOU        $9,$1,#8
8H          POP         0,1
9H          POP         0,0


%%
% :MM:__MEM:Copy
%
% PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - pointer to destination memory
%   arg2 - size (in bytes)
%   no return value
%

            .global :MM:__MEM:Copy
            % Check preconditions:
Copy        GET         $3,:rJ
            ADDU        t,arg0,arg2
            CMPU        t,t,arg0
            BN          t,1F
            ADDU        t,arg1,arg2
            CMPU        t,t,arg1
            BN          t,2F
            CMPU        t,arg0,arg1
            BZ          t,3F % Nothing to do.
            BZ          arg2,3F % Nothing to do.
            SET         $5,arg0
            SET         $6,arg1
            SET         $7,arg2
            PUSHJ       $4,CopyInternJ
            JMP         9F
3H          PUT         :rJ,$3
            POP         0,0
1H          GET         t,:rJ % :rJ
            SET         $4,arg2
            SET         $2,arg0
            LDA         $1,:MM:__MEM:STRS:Copy1
            LDA         $3,:MM:__MEM:STRS:Copy3
            LDA         $5,:MM:__MEM:STRS:Copy4
            PUSHJ       $0,:MM:__ERROR:Error5R24
2H          GET         t,:rJ % :rJ
            SET         $4,arg2
            SET         $2,arg1
            LDA         $1,:MM:__MEM:STRS:Copy2
            LDA         $3,:MM:__MEM:STRS:Copy3
            LDA         $5,:MM:__MEM:STRS:Copy4
            PUSHJ       $0,:MM:__ERROR:Error5R24
9H          LDA         $1,:MM:__MEM:STRS:Copy5
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return


%%
% :MM:__MEM:ZeroJ
%
%   PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - size (in bytes)
%   no return value
%
% :MM:__MEM:SetJ
%
%   PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - byte template
%   arg2 - size (in bytes)
%   no return value
%

            .global :MM:__MEM:ZeroJ
            .global :MM:__MEM:SetJ
ZeroJ       SET         $2,arg1
            SET         $1,0
SetJ        ADDU        t,arg0,arg2
            CMPU        t,t,arg0
            BN          t,1F
            BZ          arg2,2F % Nothing to do.
            % Prepare stencil:
SetJIntern  AND         $1,arg1,#FF
            SLU         t,$1,#08
            OR          $1,$1,t
            SLU         t,$1,#10
            OR          $1,$1,t
            SLU         t,$1,#20
stencil     IS          $1
            OR          stencil,$1,t
            % Check for alignment:
            AND         t,arg0,#7
            BZ          t,3F
            % arg0 is not octa aligned:
            ADDU        $2,arg2,t % increase copy region
            % And generate a bitmask for the first octa block:
            NEG         t,8,t
            SLU         t,t,3
            SET         $3,1
            SLU         t,$3,t
            SUBU        $3,t,1
            % We have to take care of a possibly small arg2 as well:
            CMPU        t,$2,#8
            BNN         t,4F
            % Update bitmask:
            NEG         t,8,$2
            SLU         t,t,3
            SET         $4,1
            SLU         t,$4,t
            NEG         t,t
            AND         $3,t,$3
            % And apply it:
4H          LDO         $4,arg0,0
            ANDN        $4,$4,$3
            AND         $5,$1,$3
            OR          t,$4,$5
            STO         t,arg0,0
            % Update arg0:
            ANDN        $0,arg0,#7
            ADDU        $0,$0,#8
            % Are we done?
            CMPU        t,$2,#8
            BN          t,2F
            SUBU        $2,$2,#8
            CMPU        t,$2,#8
            % arg0 is aligned. Now, round arg2 down to next integral
            % multiple of octa:
3H          AND         $3,$2,#7
            ANDN        $2,$2,#7
            BZ          $2,6F % No full loop left, immediately take
                              % care of last bit
5H          STO         stencil,$0,0 % Inner loop
            ADDU        $0,$0,#8
            SUBU        $2,$2,#8
            PBNZ        $2,5B
            % Are we done?
            BZ          $3,2F
            % Take care of the last bits of non octa aligned arg2:
6H          NEG         t,8,$3
            SLU         t,t,3
            SET         $3,1
            SLU         t,$3,t
            SUBU        t,t,1
            LDO         $4,arg0,0
            AND         $4,$4,t
            ANDN        $5,$1,t
            OR          t,$4,$5
            STO         t,arg0,0
2H          POP         0,1
1H          POP         0,0


%%
% :MM:__MEM:Set
%
%   PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - byte template
%   arg2 - size (in bytes)
%   no return value
%
            .global :MM:__MEM:Set
Set         GET         $3,:rJ
            ADDU        t,arg0,arg2
            CMPU        t,t,arg0
            BN          t,1F
            BZ          arg2,3F % Nothing to do.
            SET         $5,arg0
            SET         $6,arg1
            SET         $7,arg2
            PUSHJ       $4,SetJIntern % Jump right into SetJ
            JMP         9F
3H          PUT         :rJ,$3
            POP         0,0
1H          GET         t,:rJ % :rJ
            SET         $4,arg2
            SET         $2,arg0
            LDA         $1,:MM:__MEM:STRS:Set1
            LDA         $3,:MM:__MEM:STRS:Set2
            LDA         $5,:MM:__MEM:STRS:Set3
            PUSHJ       $0,:MM:__ERROR:Error5R24
9H          LDA         $1,:MM:__MEM:STRS:Set4
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return


%%
% :MM:__MEM:Zero
%
%   PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - size (in bytes)
%   no return value
%
            .global :MM:__MEM:Zero
Zero        GET         $2,:rJ
            ADDU        t,arg0,arg1
            CMPU        t,t,arg0
            BN          t,1F
            BZ          arg1,3F % Nothing to do.
            SET         $4,arg0
            SET         $5,0
            SET         $6,arg1
            PUSHJ       $3,SetJIntern % Jump right into SetJ
            JMP         9F
3H          PUT         :rJ,$2
            POP         0,0
1H          GET         t,:rJ % :rJ
            SET         $4,arg2
            SET         $2,arg0
            LDA         $1,:MM:__MEM:STRS:Zero1
            LDA         $3,:MM:__MEM:STRS:Zero2
            LDA         $5,:MM:__MEM:STRS:Zero3
            PUSHJ       $0,:MM:__ERROR:Error5R24
9H          LDA         $1,:MM:__MEM:STRS:Zero4
            PUSHJ       $0,:MM:__ERROR:IError1


%%
% :MM:__MEM:RandJ
%
%   PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - size (in bytes)
%   no return value
%
% :MM:__MEM:Rand
%
%   PUSHJ:
%   arg0 - pointer to source memory
%   arg1 - size (in bytes)
%   no return value
%
            .global :MM:__MEM:RandJ
            .global :MM:__MEM:Rand
RandJ       IS          :MM:__RAND:SetJ
Rand        GET         $2,:rJ
            ADDU        t,arg0,arg1
            CMPU        t,t,arg0
            BN          t,1F
            BZ          arg1,3F % Nothing to do.
            SET         $4,arg0
            SET         $5,arg1
            PUSHJ       $3,RandJ
            JMP         9F
3H          PUT         :rJ,$2
            POP         0,0
1H          GET         t,:rJ % :rJ
            SET         $4,arg2
            SET         $2,arg0
            LDA         $1,:MM:__MEM:STRS:Rand1
            LDA         $3,:MM:__MEM:STRS:Rand2
            LDA         $5,:MM:__MEM:STRS:Rand3
            PUSHJ       $0,:MM:__ERROR:Error5R24
9H          LDA         $1,:MM:__MEM:STRS:Rand4
            PUSHJ       $0,:MM:__ERROR:IError1


%%
% :MM:__MEM:CmpJ
%
%   arg0 - pointer to memory region
%   arg1 - pointer to memory region
%   arg2 - size (in bytes)
%   no return value
%
            .global :MM:__MEM:CmpJ
            % Check preconditions:
CmpJ        ADDU        t,arg0,arg2
            CMPU        t,t,arg0
            BN          t,9F
            ADDU        t,arg1,arg2
            CMPU        t,t,arg1
            BN          t,9F
            CMPU        t,arg0,arg1
            BZ          t,8F % Nothing to do.
            BZ          arg2,8F % Nothing to do.
CmpInternJ  SWYM
            % $2 - bytes rounded down to full octas
            % $3 - remaining bytes
            SET         $3,arg2
            AND         $3,$3,#7
            ANDN        $2,$2,#7
            % $4 - alignment in bits of [arg0,arg+arg2)
            % $5
            % $6 - alignment in bits of [arg1,arg+arg2)
            % $7
            AND         $4,arg0,#7
            NEGU        $5,#8,$4
            AND         $6,arg1,#7
            NEGU        $7,#8,$6
            SLU         $4,$4,3
            SLU         $5,$5,3
            SLU         $6,$6,3
            SLU         $7,$7,3
            % compare full octas:
1H          BZ          $2,2F
            LDOU        $8,$0,0
            LDOU        $9,$0,#8
            SLU         $8,$8,$4
            SRU         $9,$9,$5
            OR          $8,$8,$9
            LDOU        $9,$1,0
            LDOU        $10,$1,#8
            SLU         $9,$9,$6
            SRU         $10,$10,$7
            OR          $9,$9,$10
            CMP         $8,$8,$9
            BNZ         $8,9F % mismatch found
            ADDU        $0,$0,#8
            ADDU        $1,$1,#8
            SUBU        $2,$2,#8
            JMP         1B
            % compare remaining bytes:
2H          LDOU        $8,$0,0
            LDOU        $9,$0,#8
            SLU         $8,$8,$4
            SRU         $9,$9,$5
            OR          $8,$8,$9
            LDOU        $9,$1,0
            LDOU        $10,$1,#8
            SLU         $9,$9,$6
            SRU         $10,$10,$7
            OR          $9,$9,$10
            % shift to the right until only the bytes that should be
            % compared remain
            NEGU        $3,#8,$3
            SLU         $3,$3,3
            SRU         $8,$8,$3
            SRU         $9,$9,$3
            CMP         $8,$8,$9
            BNZ         $8,9F % mismatch found
8H          POP         0,1
9H          POP         0,0


% :MM:__MEM:Cmp
%
%   PUSHJ:
%   arg0 - pointer to memory region
%   arg1 - pointer to memory region
%   arg2 - size (in bytes)
%   retm - 0 indicating two equal memory regions, -1 otherwise
%
            .global :MM:__MEM:Cmp
            % Check preconditions:
Cmp         GET         $3,:rJ
            ADDU        t,arg0,arg2
            CMPU        t,t,arg0
            BN          t,1F
            ADDU        t,arg1,arg2
            CMPU        t,t,arg1
            BN          t,2F
            CMPU        t,arg0,arg1
            BZ          t,3F % Nothing to do.
            BZ          arg2,3F % Nothing to do.
            SET         $5,arg0
            SET         $6,arg1
            SET         $7,arg2
            PUSHJ       $4,CmpInternJ
            JMP         4F
3H          PUT         :rJ,$3
            SET         ret0,0
            POP         1,0
4H          PUT         :rJ,$3
            SET         ret0,0
            SUB         ret0,ret0,1
            POP         1,0
1H          GET         t,:rJ % :rJ
            SET         $4,arg2
            SET         $2,arg0
            LDA         $1,:MM:__MEM:STRS:Cmp1
            LDA         $3,:MM:__MEM:STRS:Cmp3
            LDA         $5,:MM:__MEM:STRS:Cmp4
            PUSHJ       $0,:MM:__ERROR:Error5R24
2H          GET         t,:rJ % :rJ
            SET         $4,arg2
            SET         $2,arg1
            LDA         $1,:MM:__MEM:STRS:Cmp2
            LDA         $3,:MM:__MEM:STRS:Cmp3
            LDA         $5,:MM:__MEM:STRS:Cmp4
            PUSHJ       $0,:MM:__ERROR:Error5R24

