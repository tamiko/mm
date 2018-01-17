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
% :MM:__Print:
%
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__PRINT:STRS:
            .balign 4
Ln          BYTE        10,0


            .section .text,"ax",@progbits
            PREFIX      :MM:__PRINT:
t           IS          $255
arg0        IS          $0
Fputs       IS          :Fputs
StdOut      IS          :StdOut


%%
% :MM:__PRINT:Str
% :MM:__PRINT:StrLn
%
% PUSHJ
%   arg0 - pointer to string
%   no return value
%
% :MM:__PRINT:StrG
% :MM:__PRINT:StrLnG
%
% PUSHJ
%   no arguments
%   no return value
%
            .global :MM:__PRINT:Str
            .global :MM:__PRINT:StrG
            .global :MM:__PRINT:StrLn
            .global :MM:__PRINT:StrLnG
Str         SET         t,$0
StrG        SET         $0,t
            TRAP        0,Fputs,StdOut
            SET         t,$0
            POP         0,0
StrLn       SET         t,$0
StrLnG      SET         $0,t
            TRAP        0,Fputs,StdOut
            GET         $1,:rJ
            PUSHJ       t,Ln
            PUT         :rJ,$1
            SET         t,$0
            POP         0,0


%%
% :MM:__PRINT:RegLnG
% :MM:__PRINT:RegG
%
% PUSHJ
%   no return value
%
% :MM:__PRINT:Reg
% :MM:__PRINT:RegLn
%
% PUSHJ
%   arg0 - the OCT to pretty print
%   no return value
%
% :MM:__PRINT:RegP
% :MM:__PRINT:RegLnP
%
% PUSHJ
%   arg0 - the OCT to pretty print
%   arg1 - do not print bytes with position < arg1
%   arg2 - do not print bytes with position > arg2
%   no return value
%
            .global :MM:__PRINT:Reg
            .global :MM:__PRINT:RegG
            .global :MM:__PRINT:RegLn
            .global :MM:__PRINT:RegLnG
            .global :MM:__PRINT:RegP
            .global :MM:__PRINT:RegLnP
buffer      IS          $1
ptr         IS          $2
RegLnG      SET         $0,t
RegLn       SET         $1,0
            SET         $2,8
RegLnP      ADD         $5,$1,$1
            ADD         $6,$2,$2
            GET         $10,:rJ
            GETA        t,:MM:__INTERNAL:BufferMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            GETA        buffer,:MM:__INTERNAL:Buffer
            SET         $3,10 % newline
            STB         $3,buffer,17
            SET         $3,0
            STB         $3,buffer,18
            JMP         1F
RegG        SET         $0,t
Reg         SET         $1,0
            SET         $2,8
RegP        ADD         $5,$1,$1
            ADD         $6,$2,$2
            GET         $10,:rJ
            GETA        t,:MM:__INTERNAL:BufferMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            GETA        buffer,:MM:__INTERNAL:Buffer
            SET         $3,0
            STB         $3,buffer,17
1H          SET         $4,$0 % save original value
            SET         ptr,16
2H          AND         $3,$0,#F
            CMP         t,$3,10
            BN          t,1F
            ADDU        $3,$3,7
1H          ADD         $3,$3,48
            CMPU        t,ptr,$5
            CSNP        $3,t,'_'
            CMPU        t,ptr,$6
            CSP         $3,t,'_'
            STB         $3,buffer,ptr
            SUBU        ptr,ptr,1
            SRU         $0,$0,4
            PBNZ        ptr,2B
            SET         $3,'#'
            STB         $3,buffer,0
            SET         t,buffer
            TRAP        0,Fputs,StdOut
            GETA        t,:MM:__INTERNAL:BufferMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$10
            SET         t,$4 % restore original value
            POP         0,0


%%
% :MM:__PRINT:ByteG
%
% PUSHJ
%   no arguments
%   no return value
%
% :MM:__PRINT:Byte
%
% PUSHJ
%   arg0 - the least significant byte to pretty print
%   no return value
%
            .global :MM:__PRINT:Byte
            .global :MM:__PRINT:ByteG
buffer      IS          $1
ByteG       SET         arg0,t
Byte        GET         $10,:rJ
            GETA        t,:MM:__INTERNAL:BufferMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            GETA        buffer,:MM:__INTERNAL:Buffer
            SET         $2,'#'
            STB         $2,buffer,0
            SET         $2,0
            STB         $2,buffer,3
            AND         $2,arg0,#F
            CMP         t,$2,10
            BN          t,1F
            ADDU        $2,$2,7
1H          ADD         $2,$2,48
            STB         $2,buffer,2
            GET         $10,:rJ
            SRU         $2,arg0,4
            AND         $2,$2,#F
            CMP         t,$2,10
            BN          t,1F
            ADDU        $2,$2,7
1H          ADD         $2,$2,48
            STB         $2,buffer,1
            SET         t,buffer
            TRAP        0,Fputs,StdOut
            GETA        t,:MM:__INTERNAL:BufferMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$10
            SET         t,$0 % restore original value
            POP         0,0


%%
% :MM:__PRINT:UnsignedG
%
% PUSHJ
%   no arguments
%   no return value
%
% :MM:__PRINT:Unsigned
%
% PUSHJ
%   arg0 - the octa to pretty print
%   no return value
%
            .global :MM:__PRINT:Unsigned
            .global :MM:__PRINT:UnsignedG
buffer      IS          $1
ptr         IS          $2
carry       IS          $3
UnsignedG   SET         arg0,t
Unsigned    GET         $10,:rJ
            GETA        t,:MM:__INTERNAL:BufferMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            GETA        buffer,:MM:__INTERNAL:Buffer
            SET         ptr,128*8-1
            SET         t,0
            STB         t,buffer,ptr
            SUB         ptr,ptr,1
            SET         $4,$0
            BNZ         $4,9F
            SET         t,48
            STB         t,buffer,ptr
            SUBU        ptr,ptr,1
            % Yes, I know.. it is div...
9H          DIVU        $4,$4,10
            GET         t,:rR
            BNZ         t,1F
            BZ          $4,2F % done
1H          ADDU        t,t,48
            STB         t,buffer,ptr
            SUBU        ptr,ptr,1
            JMP         9B
2H          ADDU        t,buffer,ptr
            ADDU        t,t,1
            TRAP        0,Fputs,StdOut
            GETA        t,:MM:__INTERNAL:BufferMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$10
            SET         t,$0 % restore original value
            POP         0,0


%%
% :MM:__PRINT:SignedG
%
% PUSHJ
%   no arguments
%   no return value
%
% :MM:__PRINT:Signed
%
% PUSHJ
%   arg0 - the octa to pretty print
%   no return value
%
            .global :MM:__PRINT:Signed
            .global :MM:__PRINT:SignedG
SignedG     SET         arg0,t
Signed      GET         $2,:rJ
            BN          arg0,1F
            PUSHJ       t,UnsignedG
            JMP         2F
1H          GETA        t,:MM:__INTERNAL:BufferMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            GETA        buffer,:MM:__INTERNAL:Buffer
            STCO        0,buffer,0
            SET         t,'-'
            STB         t,buffer,0
            SET         t,buffer
            TRAP        0,Fputs,StdOut
            GETA        t,:MM:__INTERNAL:BufferMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            NEG         t,$0
            PUSHJ       t,UnsignedG
2H          PUT         :rJ,$2
            SET         t,$0 % restore original value
            POP         0,0


%%
% :MM:__PRINT:MemLn
%
% PUSHJ
%   arg0 - pointer to memory region
%   arg1 - size of memory region to pretty print
%   no return value
%
            .global :MM:__PRINT:MemLn
MemLn       GET         $2,:rJ
            SET         $3,0
            % I care for alignment (tm)
            AND         t,$0,#7
            BNP         $1,3F
            ADD         $1,$1,t
1H          BNP         $1,3F
            SUB         $1,$1,8
            LDO         $5,$0,$3
            BZ          $3,7F % first octa
            BNP         $1,8F % last octa
            PUSHJ       $4,RegLn
            ADD         $3,$3,8
            PBP         $1,1B
3H          PUT         :rJ,$2
            POP         0,0
            % Pretty print the last and first octa:
7H          AND         $6,$0,#7
            BNP         $1,8F
            SET         $7,8
            JMP         9F
8H          ADD         $7,$1,8
            CSNZ        $6,$3,0
9H          PUSHJ       $4,RegLnP
            ADD         $3,$3,8
            PBP         $1,1B
            JMP 3B


%%
% :MM:__PRINT:Ln
%
% PUSHJ, PUSHJ $255
%   no arguments
%   no return value
%
            .global :MM:__PRINT:Ln
Ln          SET         $0,t
            GETA        t,:MM:__PRINT:STRS:Ln
            TRAP        0,Fputs,StdOut
            SET         t,$0
            POP         0,0

