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
% :MM:__THREAD:
%
            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__THREAD:interval
            PREFIX      :MM:__THREAD:STRS:
NegInterval BYTE        "Thread:Enable failed. Negative timer interval "
            BYTE        "specified.",10,0

            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__THREAD:interval
            PREFIX      :MM:__THREAD:
interval    OCTA        #FFFFFFFFFFFFFFFF

            .section .text,"ax",@progbits
            PREFIX      :MM:__THREAD:

t           IS          $255
arg0        IS          $0



%%
% :MM:__THREAD:Enable
%
% PUSHJ
%   arg0 - interval in oops
%   no return values
%
% :MM:__THREAD:EnableJ
% :MM:__THREAD:EnableG
%
% PUSHJ %255
%
            .global :MM:__THREAD:Enable
            .global :MM:__THREAD:EnableJ
            .global :MM:__THREAD:EnableG
EnableJ     BN          arg0,2F
            SET         $1,#2
            CMP         $1,$0,$1
            BNN         $1,1F
            SET         $0,#2
1H          LDA         $1,:MM:__THREAD:interval
            STO         arg0,$1
            PUT         :rI,arg0
            POP         0,1
2H          POP         0,0
EnableG     SET         arg0,t
Enable      SET         $2,arg0
            GET         $0,:rJ
            PUSHJ       $1,EnableJ
            JMP         9F
            PUT         :rJ,$0
            POP         0,0
9H          LDA         t,:MM:__ERROR:__rJ
            STO         $0,t
            LDA         $1,:MM:__THREAD:STRS:NegInterval
            PUSHJ       $0,:MM:__ERROR:Error1


%%
% :MM:__THREAD:Disable
%
% PUSHJ
%   no arguments
%   no return values
%
            .global :MM:__THREAD:Disable
Disable     NEG         $1,0,1
            LDA         $0,:MM:__THREAD:interval
            STO         $1,$0
            PUT         :rI,$1
            POP         0


%%
% :MM:__THREAD:ThreadID
%
% PUSHJ
%   no arguments
%   retm - ThreadID
%
% :MM:__THREAD:ThreadIDG
%
% PUSHJ %255
%
            .global :MM:__THREAD:ThreadID
            .global :MM:__THREAD:ThreadIDG
ThreadID    LDA         $0,:MM:__INTERNAL:ThreadRing
            LDO         $0,$0
            LDO         $0,$0
            POP         1,0
ThreadIDG   LDA         t,:MM:__INTERNAL:ThreadRing
            LDO         t,t
            LDO         t,t
            POP         0


%%
% :MM:__THREAD:Clone
%
% PUSHJ
%   no arguments
%   retm - ThreadID of new thread
%
% :MM:__THREAD:CloneJ
% :MM:__THREAD:CloneG
%
            .global :MM:__THREAD:Clone
            .global :MM:__THREAD:CloneJ
            .global :MM:__THREAD:CloneG
Clone       SWYM
            % Disable timer and TRIP:
            GET         $0,:rI
            BN          $0,1F
            NEG         $0,0,1
            PUT         :rI,$0
            SWYM
            % We should be safe now™
1H          TRIP        0,:MM:__INTERNAL:Clone,0
            GET         $0,:rY
            BP          $0,1F
            NEG         $0,0,1
1H          POP         1,0
CloneJ      GET         $0,:rJ
            PUSHJ       $1,Clone
            PUT         :rJ,$0
            BN          $1,1F
            POP         1,1
1H          POP         0,0
CloneG      GET         $0,:rJ
            PUSHJ       $1,Clone
            PUT         :rJ,$0
            SET         t,$1
            POP         0,0


%%
% :MM:__THREAD:Create
%
% PUSHJ
%   arg0 - Entry address of new thread
%   retm - The ThreadID of the new thread
%
% :MM:__THREAD:CreateG
%
            .global :MM:__THREAD:Create
            .global :MM:__THREAD:CreateG
Create      SWYM
            % Disable timer and TRIP:
            GET         $1,:rI
            BN          $1,1F
            NEG         $1,0,1
            PUT         :rI,$1
            SWYM
            % We should be safe now™
1H          TRIP        0,:MM:__INTERNAL:Create,0
            GET         $0,:rY
            POP         1,0
CreateG     GET         $0,:rJ
            SET         $2,t
            PUSHJ       $1,Create
            PUT         :rJ,$0
            SET         t,$1
            POP         0,0


%%
% :MM:__THREAD:Yield
%
% PUSHJ
%   no arguments
%   no return values
%
            .global :MM:__THREAD:Yield
Yield       SWYM
            % Disable timer and TRIP:
            GET         $0,:rI
            BN          $0,1F
            NEG         $0,0,1
            PUT         :rI,$0
            SWYM
            % We should be safe now™
1H          TRIP        0,:MM:__INTERNAL:Yield,0
            POP         0


%%
% :MM:__THREAD:Exit
%
% PUSHJ
%   no arguments
%   no return values
%
            .global :MM:__THREAD:Exit
Exit       SWYM
            % Disable timer and TRIP:
            GET         $0,:rI
            BN          $0,1F
            NEG         $0,0,1
            PUT         :rI,$0
            SWYM
            % We should be safe now™
1H          TRIP        0,:MM:__INTERNAL:Exit,0
            POP         0


%%
% :MM:__THREAD:Wait
%
% PUSHJ
%   arg0 - ThreadID
%   no return values
%
            .global :MM:__THREAD:Wait
            .global :MM:__THREAD:WaitG
Wait        SWYM
            % Disable timer:
9H          GET         $1,:rI
            BN          $1,1F
            NEG         $2,0,1
            PUT         :rI,$2
1H          LDA         $3,:MM:__INTERNAL:ThreadRing
            LDO         $3,$3
            SET         $2,$3
1H          LDO         $4,$3,#00
            CMP         $4,$4,$0
            BNZ         $4,2F
            % found thread ID, we have to wait.
            BN          $1,3F
            PUT         :rI,$1
3H          GET         $3,:rJ
            PUSHJ       $4,:MM:__THREAD:Yield
            PUT         :rJ,$3
            JMP         9B
2H          LDO         $3,$3,#18
            CMP         $4,$3,$2
            BNZ         $4,1B
            BN          $1,3F
            PUT         :rI,$1
3H          POP         0,0
WaitG       GET         $0,:rJ
            SET         $2,t
            PUSHJ       $1,Wait
            PUT         :rJ,$0
            POP         0,0
