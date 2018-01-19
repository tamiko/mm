%
% Variant of threading.mms that uses :MM:Thread:Clone instead of
% :MM:Thread:Create
%

#include <mm/print>
#include <mm/sys>
#include <mm/thread>

#define PREEMPTIVE

            .data
            .balign 4
__error     BYTE        "Something went wrong! :'-(",10,0
            .balign 4
__alice     BYTE        "Hi Alice!",10,0
            .balign 4
__bob       BYTE        "Hi Bob!",10,0
            .balign 4
__dave      BYTE        "I am Dave!",10,0

            .text
t           IS          :MM:t
timeout     IS          #0001

Main        SWYM

            %
            % Clone the main thread three times:
            %

            PUSHJ       $0,:MM:Thread:CloneJ
            JMP         1F % clone jumps to 1F
            PUSHJ       $0,:MM:Thread:CloneJ
            JMP         1F % clone jumps to 1F
            PUSHJ       $0,:MM:Thread:CloneJ
            JMP         1F % clone jumps to 1F

            %
            % On the main thread: Wait for all three threads to finish and
            % print statistics before terminating the program:
            %

#ifdef PREEMPTIVE
            SETL        t,#1000
            PUSHJ       t,MM:Thread:EnableG
#endif
            PUSHJ       t,MM:Thread:WaitAll
#ifdef PREEMPTIVE
            PUSHJ       t,MM:Thread:Disable
#endif
            PUSHJ       t,MM:__STATISTICS:PrintStatistics
            PUSHJ       t,MM:Thread:Exit

            %
            % On the clones:
            %

1H          PUSHJ       $0,MM:Thread:ThreadID
            CMP         $1,$0,#1 % thread ID 1 ?
            BNZ         $1,1F
            GETA        t,__alice
            JMP         2F
1H          CMP         $1,$0,#2 % thread ID 2 ?
            BNZ         $1,1F
            GETA        t,__bob
            JMP         2F
1H          CMP         $1,$0,#3 % thread ID 3 ?
            BNZ         $1,1F
            GETA        t,__dave
            JMP         2F
1H          GETA        t,__error
            PUSHJ       t,MM:Print:StrG
            PUSHJ       t,MM:Sys:Abort

            %
            % Loop for a specified amount of time
            % (measured with the :rU register):
            %

2H          SETML       $0,timeout
1H          GET         $1,:rU
            CMP         $1,$1,$0
            BP          $1,8F
            PUSHJ       t,MM:Print:StrG
#ifndef PREEMPTIVE
            PUSHJ       t,MM:Thread:Yield
#endif
            JMP         1B

8H          PUSHJ       t,MM:Thread:Exit

