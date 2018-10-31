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
% :MM:__SYS:
%
% Facilities for system, environment, error handling, and program
% termination.
%


%
% Error handling and program termination:
%

            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__SYS:WorkerDirec
            .global :MM:__SYS:HandleWrite
            .global :MM:__SYS:HandleRead
            .global :MM:__SYS:AtErrorAddr
            PREFIX      :MM:__SYS:
WorkerDirec OCTA        #0000000000000000
HandleWrite OCTA        #FFFFFFFFFFFFFFFF
HandleRead  OCTA        #FFFFFFFFFFFFFFFF
AtErrorAddr OCTA        #0000000000000000

            .section .text,"ax",@progbits
            PREFIX      :MM:__SYS:

Halt        IS          :Halt

t           IS          :MM:t
arg0        IS          $0


%%
% :MM:__SYS:Exit
%
% PUSHJ
%   no arguments
%   does not return
%

            .global :MM:__SYS:Exit
Exit        SET         $255,0
            % Good bye so long and thanks for all the fish.
            TRAP        0,Halt,0


%%
% :MM:__SYS:Abort
%
% PUSHJ
%   no arguments
%   does not return
%

            .global :MM:__SYS:Abort
Abort       SET         $255,1
            % Good bye so long and thanks for all the fish.
            TRAP        0,Halt,0



%%
% :MM:__SYS:AtError
%
% PUSHJ
%   arg0 - address of a subroutine that is called upon abortion of the
%          program
%   no return values
%
% :MM:__SYS:AtErrorG
%
% PUSHJ %255
%

            .global :MM:__SYS:AtError
            .global :MM:__SYS:AtErrorG
AtErrorG    SET         arg0,t
AtError     GETA        $1,:MM:__SYS:AtErrorAddr
            STO         arg0,$1
            SET         t,arg0
            POP         0


%
% Set up worker:
%
            .section .data,"wa",@progbits
            PREFIX      :MM:__SYS:STRS:
            .balign 4
InputFIFO   BYTE "/worker.stdin.fifo",0
            .balign 4
OutputFIFO  BYTE "/worker.stdout.fifo",0
            .balign 4
Init1       BYTE        "__SYS:Init failed. Unable to open '"
            .balign 4
Init2       BYTE        "'",10,0

            .section .init,"ax",@progbits
            PREFIX      :MM:__SYS:
BinaryReadWrite IS      :BinaryReadWrite

            GETA        $0,:MM:__SYS:WorkerDirec
            LDO         $0,$0,0
            BZ          $0,1F
            ADDU        $0,$0,17
            SET         $2,$0
            PUSHJ       $1,:MM:__STRING:Size

            SET         $3,$0
            GETA        $4,:MM:__INTERNAL:Buffer
            ADDU        $5,$1,1
            PUSHJ       $2,:MM:__MEM:Copy

            GETA        $3,:MM:__SYS:STRS:InputFIFO
            GETA        $4,:MM:__INTERNAL:Buffer
            ADDU        $4,$4,$1
            SET         $5,19
            PUSHJ       $2,:MM:__MEM:Copy

            GETA        $3,:MM:__INTERNAL:Buffer
            SET         $4,BinaryReadWrite
            PUSHJ       $2,:MM:__FILE:OpenJ
            JMP         4F
            GETA        $3,:MM:__SYS:HandleWrite
            STO         $2,$3

            GETA        $3,:MM:__SYS:STRS:OutputFIFO
            GETA        $4,:MM:__INTERNAL:Buffer
            ADDU        $4,$4,$1
            SET         $5,20
            PUSHJ       $2,:MM:__MEM:Copy

            GETA        $3,:MM:__INTERNAL:Buffer
            SET         $4,BinaryReadWrite
            PUSHJ       $2,:MM:__FILE:OpenJ
            JMP         4F
            GETA        $3,:MM:__SYS:HandleRead
            STO         $2,$3

            JMP         1F
4H          GETA        $2,:MM:__SYS:STRS:Init1
            GETA        $3,:MM:__INTERNAL:Buffer
            GETA        $4,:MM:__SYS:STRS:Init2
            PUSHJ       $1,:MM:__ERROR:IError3 % does not return
1H          SWYM
