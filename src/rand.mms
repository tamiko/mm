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
% :MM:__RAND:
%
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__RAND:STRS:
Urandom     BYTE        "/dev/urandom",0
Init1       BYTE        "__RAND:Init failed. Unable to open '/dev/urandom'",0
Init2       BYTE        ". Internal error. File handle [",0
Init3       BYTE        "] invalid.",10,0
Init4       BYTE        ".",10,0
Octa1       BYTE        "Rand:Octa failed. Could not read random data.",10,0
Range1      BYTE        "Rand:Range failed. Invalid range specified, [arg0=",0
Range2      BYTE        "] and [arg1=",0
Range3      BYTE        "] do not define a valid interval.",10,0
Range4      BYTE        "Heap:Range failed. Could not read from "
            BYTE        "filehandler [",0
ExcNotImpl  BYTE        "I'm sorry Dave. I'm afraid I can't do that "
            BYTE        "(ExcNotImpl).",10,0


            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__RAND:FileHandle
            PREFIX      :MM:__RAND:
FileHandle  OCTA        #FFFFFFFFFFFFFFFF
            .balign 8


            .section .text,"ax",@progbits
            PREFIX      :MM:__RAND:
Ftell       IS          :Ftell
Fopen       IS          :Fopen
Fread       IS          :Fread
BinaryRead  IS          :BinaryRead

t           IS          $255
arg0        IS          $0
arg1        IS          $1
OCT         IS          #8


%%
%
% :MM:__RAND:Init
%
% PUSHJ
%   no arguments
%   no return value
%
Init        GET         $0,:rJ
            LDO         $1,:MM:__RAND:FileHandle
            BN          $1,1F
            % is the filehandle valid?
            SET         $3,$1
            PUSHJ       $2,:MM:__FILE:IsReadableJ
            JMP         3F
            JMP         2F
1H          LDA         $3,:MM:__RAND:STRS:Urandom
            SET         $4,BinaryRead
            PUSHJ       $2,:MM:__FILE:Open
            STO         $2,:MM:__RAND:FileHandle
2H          PUT         :rJ,$0
            POP         0,0
3H          LDA         $2,:MM:__RAND:STRS:Init1
            LDA         $3,:MM:__RAND:STRS:Init2
            LDO         $4,:MM:__RAND:FileHandle
            LDA         $5,:MM:__RAND:STRS:Init3
            PUSHJ       $1,:MM:__ERROR:IError4R3 % does not return
4H          LDA         $2,:MM:__RAND:STRS:Init1
            LDA         $3,:MM:__RAND:STRS:Init4
            PUSHJ       $1,:MM:__ERROR:IError2 % does not return


%%
% :MM:__RAND:Octa
%
% PUSHJ
%   no arguments
%   retm - a random octabyte
%
            % Arguments for Fread:
            .global :MM:__RAND:Octa
Octa        GET         $0,:rJ
            LDO         $4,:MM:__RAND:FileHandle
            BNN         $4,1F
            PUSHJ       t,Init
            LDO         $4,:MM:__RAND:FileHandle
1H          LDA         $2,:MM:__INTERNAL:Buffer
            SET         $3,#8
            PUSHJ       $1,:MM:__FILE:ReadJ
            JMP         9F
            PUT         :rJ,$0
            LDO         $0,:MM:__INTERNAL:Buffer
            POP         1,0
9H          LDA         $2,:MM:__RAND:STRS:Octa1
            PUSHJ       $1,:MM:__ERROR:IError1


%%
% :MM:__RAND:OctaG
%
% PUSHJ $255
%
            .global :MM:__RAND:OctaG
OctaG       GET         $0,:rJ
            PUSHJ       $1,Octa
            PUT         :rJ,$0
            SET         t,$1
            POP         0,0


%%
% :MM:__RAND:Range
% :MM:__RAND:RangeU
%
% PUSHJ
%   arg0 - minimal value
%   arg1 - maximal value
%   retm - a random octabyte within [arg0,arg1]
%
            .global :MM:__RAND:Range
            .global :MM:__RAND:RangeJ
Range       SWYM
RangeU      SWYM
            LDA         $1,:MM:__RAND:STRS:ExcNotImpl
            PUSHJ       $0,:MM:__ERROR:IError1


%%
% :MM:__RAND:SetJ
%
% PUSHJ
%   arg0 - starting address
%   arg1 - size (in bytes)
%   no return value
%
            .global :MM:__RAND:SetJ
SetJ        GET         $3,:rJ
            LDO         $7,:MM:__RAND:FileHandle
            BNN         $7,1F
            PUSHJ       t,Init
            LDO         $7,:MM:__RAND:FileHandle
1H          ADDU        t,arg0,arg1
            CMPU        t,t,arg0
            BN          t,9F
            BZ          arg1,1F % Nothing to do.
            SET         $5,arg0
            SET         $6,arg1
            PUSHJ       $4,:MM:__FILE:ReadJ
            JMP         9F
1H          PUT         :rJ,$3
            POP         0,1
9H          PUT         :rJ,$3
            POP         0,0
