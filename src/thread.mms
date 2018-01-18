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

#include "statistics.mmh"

%
% :MM:__THREAD:
%

            .section .data,"wa",@progbits
            .balign 8
            PREFIX      :MM:__THREAD:STRS:
            .balign 4
NegInterval BYTE        "Thread:Enable failed. Negative timer interval "
            BYTE        "specified.",10,0
            .balign 4
UnlockMFail BYTE        "Thread:UnlockMutex failed. Mutex is not locked by "
            BYTE        "the current thread.",10,0

            .section .data,"wa",@progbits
            .global :MM:__THREAD:interval
            .balign 8
            .global :MM:__THREAD:interval
            PREFIX      :MM:__THREAD:
interval    OCTA        #FFFFFFFFFFFFFFFF

            PREFIX      :MM:__INTERNAL:
Yield       IS          #00
Create      IS          #D0
Clone       IS          #E0
Exit        IS          #F0

            .section .text,"ax",@progbits
            PREFIX      :MM:__THREAD:

t           IS          :MM:t
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
% PUSHJ
%
            .global :MM:__THREAD:Enable
            .global :MM:__THREAD:EnableJ
            .global :MM:__THREAD:EnableG
EnableJ     BN          arg0,2F
            SET         $1,#2
            CMP         $1,$0,$1
            BNN         $1,1F
            SET         $0,#2
1H          GETA        $1,:MM:__THREAD:interval
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
9H          SET         t,$0 % :rJ
            GETA        $1,:MM:__THREAD:STRS:NegInterval
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
            GETA        $0,:MM:__THREAD:interval
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
% PUSHJ
%
            .global :MM:__THREAD:ThreadID
            .global :MM:__THREAD:ThreadIDG
ThreadID    GETA        $0,:MM:__INTERNAL:ThreadRing
            LDO         $0,$0
            LDO         $0,$0
            POP         1,0
ThreadIDG   GETA        t,:MM:__INTERNAL:ThreadRing
            LDO         t,t,0
            LDO         t,t,0
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

            %
            % Disable timer prior to a TRIP invocation:
            % (stores :rI in $1, sets $2 to -1)
            %
            .macro DISABLE_TIMER
            GET         $1,:rI
            BN          $1,1F
            NEG         $2,0,1
            PUT         :rI,$2
            % We should be safe now™
            .endm

            .global :MM:__THREAD:Clone
            .global :MM:__THREAD:CloneJ
            .global :MM:__THREAD:CloneG
Clone       SWYM
            DISABLE_TIMER
1H          SWYM
            INCREMENT_COUNTER :MM:__STATISTICS:ThreadClone
            TRIP        0,:MM:__INTERNAL:Clone,0
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
            DISABLE_TIMER
1H          SWYM
            INCREMENT_COUNTER :MM:__STATISTICS:ThreadCreat
            TRIP        0,:MM:__INTERNAL:Create,0
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
            DISABLE_TIMER
1H          SWYM
            INCREMENT_COUNTER :MM:__STATISTICS:ThreadYield
            TRIP        0,:MM:__INTERNAL:Yield,0
            POP         0


%%
% :MM:__THREAD:Exit
%
% PUSHJ
%   no arguments
%   no return values
%
            .global :MM:__THREAD:Exit
Exit        SWYM
            DISABLE_TIMER
1H          SWYM
            INCREMENT_COUNTER :MM:__STATISTICS:ThreadExit
            TRIP        0,:MM:__INTERNAL:Exit,0
            POP         0

%%
% :MM:__THREAD:IsRunning
%
% PUSHJ
%   arg0 - ThreadID
%   retm - 0 if thread is running, -1 otherwise.
%
% :MM:__THREAD:IsRunningJ
% :MM:__THREAD:IsRunningG
%
            .global :MM:__THREAD:IsRunning
            .global :MM:__THREAD:IsRunningJ
            .global :MM:__THREAD:IsRunningG
IsRunningJ  SWYM
            DISABLE_TIMER
1H          GETA        $3,:MM:__INTERNAL:ThreadRing
            LDO         $3,$3
            SET         $2,$3
1H          LDO         $4,$3,#00
            CMP         $4,$4,$0
            BNZ         $4,2F
            % found thread ID arg0
            BN          $1,3F
            PUT         :rI,$1
3H          POP         0,1
            % advance to next entry
2H          LDO         $3,$3,#18
            CMP         $4,$3,$2
            BNZ         $4,1B
            % did not find thread ID arg0 in any thread ring entry:
            BN          $1,3F
            PUT         :rI,$1
3H          POP         0,0

IsRunning   SET         $2,$0
            GET         $0,:rJ
            SET         $1,#0000
            PUSHJ       $1,IsRunningJ
            NEG         $1,0,1
            SWYM
            PUT         :rJ,$0
            SET         $0,$1
            POP         1,0
IsRunningG  SET         $2,t
            GET         $0,:rJ
            SET         t,#0000
            PUSHJ       t,IsRunningJ
            NEG         t,0,1
            SWYM
            PUT         :rJ,$0
            POP         0,0


%%
% :MM:__THREAD:Wait
%
% PUSHJ
%   arg0 - ThreadID
%   no return values
%
            .global :MM:__THREAD:Wait
            .global :MM:__THREAD:WaitG
Wait        GET         $1,:rJ
1H          SET         $3,arg0
            PUSHJ       $2,IsRunningJ
            JMP         9F
            PUSHJ       $2,Yield
            JMP         1B
9H          PUT         :rJ,$1
            POP         0,0
WaitG       GET         $0,:rJ
            SET         $2,t
            PUSHJ       $1,Wait
            PUT         :rJ,$0
            POP         0,0


%%
% :MM:__THREAD:WaitAll
%
% PUSHJ
%   no arguments
%   no return values
%
            .global :MM:__THREAD:WaitAll
WaitAll     GET         $2,:rJ
            GETA        $0,:MM:__INTERNAL:ThreadRing
            LDO         $0,$0
2H          LDO         $1,$0,#10
            CMP         $1,$0,$1
            BZ          $1,1F
            PUSHJ       t,:MM:__THREAD:Yield
            JMP         2B
1H          PUT         :rJ,$2
            POP         0,0


%%
% :MM:__THREAD:LockMutex
%
% PUSHJ
%   arg0 - address of OCTA used as mutex
%   no return values
%
% :MM:__THREAD:LockMutexJ
% :MM:__THREAD:LockMutexG
%
            .global :MM:__THREAD:LockMutex
            .global :MM:__THREAD:LockMutexJ
            .global :MM:__THREAD:LockMutexG
            % use CSWAP for atomic update of Mutex: We assume the mutex to
            % be unlocked (:rP == #0..0) and try to store $1 (Thread ID |
            % 1<<64).
LockMutexJ  GETA        $1,:MM:__INTERNAL:ThreadRing
            LDO         $1,$1
            LDO         $1,$1
            ORH         $1,#8000
            SET         $2,#0000
            PUT         :rP,$2
            CSWAP       $1,arg0
            BZ          $1,1F
            POP         0,1
1H          POP         0,0
LockMutexG  SET         $0,t
LockMutex   GET         $1,:rJ
1H          SET         $3,$0
            PUSHJ       $2,LockMutexJ
            JMP         2F
            PUT         :rJ,$1
            POP         0,0
2H          PUSHJ       $2,Yield
            JMP         1B


%%
% :MM:__THREAD:UnlockMutex
%
% PUSHJ
%   arg0 - address of OCTA used as mutex
%   no return values
%
% :MM:__THREAD:UnlockMutexJ
% :MM:__THREAD:UnlockMutexG
%
            .global :MM:__THREAD:UnlockMutex
            .global :MM:__THREAD:UnlockMutexJ
            .global :MM:__THREAD:UnlockMutexG
UnlockMutexJ GETA        $1,:MM:__INTERNAL:ThreadRing
            LDO         $1,$1
            LDO         $1,$1
            ORH         $1,#8000
            SET         $2,#0000
            PUT         :rP,$1
            CSWAP       $2,arg0
            BZ          $2,1F
            POP         0,1
1H          POP         0,0
UnlockMutexG SET        $0,t
UnlockMutex GET         $1,:rJ
1H          SET         $3,$0
            PUSHJ       $2,UnlockMutexJ
            JMP         2F
            PUT         :rJ,$1
            POP         0,0
2H          SET         t,$1 % :rJ
            GETA        $1,:MM:__THREAD:STRS:UnlockMFail
            PUSHJ       $0,:MM:__ERROR:Error1

