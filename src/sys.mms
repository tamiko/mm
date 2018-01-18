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
% Facilities for error handling, and program termination.
%

            .section .data,"wa",@progbits
            .balign 8
            PREFIX      :MM:__SYS:
            .global :MM:__SYS:AtErrorAddr
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

