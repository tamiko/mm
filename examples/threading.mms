%
% A threading example demonstrating preemptive / cooperative multitasking.
% To switch between the two set/unset the PREEMPTIVE preprocessor
% definition. Note that preemptive mode needs a patches mmix-sim
% interpreter that allows setting :rI and traps when the timer runs out.
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

timeout     IS          #0010


Thread1     SWYM
1H          GET         $5,:rU
            SETML       $6,timeout
            CMP         $5,$5,$6
            BP          $5,8F
            GETA        t,__alice
            PUSHJ       t,MM:Print:StrG
#ifndef PREEMPTIVE
            PUSHJ       t,MM:Thread:Yield
#endif
            JMP         1B
8H          PUSHJ       t,MM:Thread:Exit


Thread2     SWYM
1H          GET         $5,:rU
            SETML       $6,timeout
            CMP         $5,$5,$6
            BP          $5,8F
            GETA        t,__bob
            PUSHJ       t,MM:Print:StrG
#ifndef PREEMPTIVE
            PUSHJ       t,MM:Thread:Yield
#endif
            JMP         1B
8H          PUSHJ       t,MM:Thread:Exit


Thread3     SWYM
1H          GET         $5,:rU
            SETML       $6,timeout
            CMP         $5,$5,$6
            BP          $5,8F
            GETA        t,__dave
            PUSHJ       t,MM:Print:StrG
#ifndef PREEMPTIVE
            PUSHJ       t,MM:Thread:Yield
#endif
            JMP         1B
8H          PUSHJ       t,MM:Thread:Exit


Main        SWYM
            GETA        t,Thread1
            PUSHJ       t,MM:Thread:CreateG
            GETA        t,Thread2
            PUSHJ       t,MM:Thread:CreateG
            GETA        t,Thread3
            PUSHJ       t,MM:Thread:CreateG
#ifdef PREEMPTIVE
            SETML       t,#0001
            PUSHJ       t,MM:Thread:EnableG
#endif

            PUSHJ       t,MM:Thread:WaitAll
#ifdef PREEMPTIVE
            PUSHJ       t,MM:Thread:Disable
#endif
            PUSHJ       t,MM:__STATISTICS:PrintStatistics
            PUSHJ       t,MM:Thread:Exit
