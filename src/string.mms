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
% :MM:__STRING:
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__STRING:STRS:
            .balign 4

            .section .text,"ax",@progbits
            PREFIX      :MM:__STRING:
t           IS          :MM:t
arg0        IS          $0
arg1        IS          $1
arg2        IS          $2
ret0        IS          $0


%%
% :MM:__STRING:Size
%
% PUSHJ:
%   arg0 - pointer to source string
%   arg1 - pointer to destination
%   ret0 - size of string (in bytes) excluding the terminating null byte
%
% :MM:__STRING:SizeG
%
            .global :MM:__STRING:Size
            % $1 is count
            % $2 current octa
Size        SET         $1,8
            LDO         $2,$0,0
            %
            % We have no precondition on string alignment. So deal with the
            % first unaligned bits and set unrelated bits in $2 to one:
            %
            AND         $3,$0,7
            SUBU        $1,$1,$3 % fix count
            NEGU        $4,0,1
            SLU         $3,$3,3
            SRU         $4,$4,$3
            ORN         $2,$2,$4
            %
            % set up bitmask for quick check for null byte:
            % $3 - #0101010101010101
            % $4 - #8080808080808080
            %
            SET         $3,#0101
            ORML        $3,#0101
            ORMH        $3,#0101
            ORH         $3,#0101
            SLU         $4,$3,7
            %
            % check current OCTA in $2
            %
1H          SUBU        $5,$2,$3
            ANDN        $6,$4,$2
            AND         $5,$5,$6
            BNZ         $5,2F % we found a null byte
            LDO         $2,$0,$1
            ADDU        $1,$1,8
            JMP         1B
            %
            % Use $5 to determine the position of the first null byte:
            %
2H          BN          $5,3F
            SLU         $5,$5,8
            ADDU        $1,$1,1
            JMP         2B
3H          SUBU        ret0,$1,8 % fix up count, we counted 8 bytes too many
            POP         1,0

SizeG       SET         $2,t
            GET         $0,:rJ
            PUSHJ       $1,Size
            PUT         :rJ,$0
            SET         t,$1
            POP         0,0
