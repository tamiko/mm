%%
% MMIX support library for various purposes.
%
% Copyright (C) 2013-2014 Matthias Maier <tamiko@kyomu.43-1.org>
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
AtExitAddr  OCTA        #0000000000000000
AtAbortAddr OCTA        #0000000000000000
AtErrorAddr OCTA        #0000000000000000
            .global :MM:__SYS:AtExitAddr
            .global :MM:__SYS:AtAbortAddr
            .global :MM:__SYS:AtErrorAddr

            .section .text,"ax",@progbits
            PREFIX      :MM:__SYS:

Halt        IS          :Halt

t           IS          $255
arg0        IS          $0


%%
% :MM:__SYS:Exit
%
% PUSHJ
%   no arguments
%   does not return
%

            .global :MM:__SYS:Exit
Exit        LDO         $0,:MM:__SYS:AtExitAddr
            BZ          $0,1F
            GO          $0,$0
1H          SET         t,0
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
Abort       LDO         $0,:MM:__SYS:AtAbortAddr
            BZ          $0,1F
            GO          $0,$0
1H          SET         t,1
            % Good bye so long and thanks for all the fish.
            TRAP        0,Halt,0


%%
% :MM:__SYS:AtExit
%
% PUSHJ
%   arg0 - address of a subroutine that is called upon successful exit
%          of the program
%   no return values
%
% :MM:__SYS:AtExitG
%
% PUSHJ %255
%

            .global :MM:__SYS:AtExit
            .global :MM:__SYS:AtExitG
AtExitG     SET         arg0,t
AtExit      LDA         $1,:MM:__SYS:AtExitAddr
            STO         arg0,$1
            SET         t,arg0
            POP         0


%%
% :MM:__SYS:AtAbort
%
% PUSHJ
%   arg0 - address of a subroutine that is called upon abortion of the
%          program
%   no return values
%
% :MM:__SYS:AtAbortG
%
% PUSHJ %255
%

            .global :MM:__SYS:AtAbort
            .global :MM:__SYS:AtAbortG
AtAbortG    SET         arg0,t
AtAbort     LDA         $1,:MM:__SYS:AtAbortAddr
            STO         arg0,$1
            SET         t,arg0
            POP         0


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
AtError     LDA         $1,:MM:__SYS:AtErrorAddr
            STO         arg0,$1
            SET         t,arg0
            POP         0
