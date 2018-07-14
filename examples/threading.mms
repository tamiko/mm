%
% A threading example demonstrating preemptive / cooperative multitasking.
% To switch between the two set/unset the PREEMPTIVE preprocessor
% definition. Note that preemptive mode needs a patched mmix-sim
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

            %
            % Three threads that print the __alice, __bob and __dave
            % strings for a specified amount of time:
            %

timeout     IS          #0010

Thread1     SWYM
            GETA        t,__alice
            JMP         1F

Thread2     SWYM
            GETA        t,__bob
            JMP         1F

Thread3     SWYM
            GETA        t,__dave

1H          SETML       $0,timeout
1H          GET         $1,:rU
            CMP         $1,$1,$0
            BP          $1,8F
            PUSHJ       t,MM:Print:StrG
#ifndef PREEMPTIVE
            PUSHJ       t,MM:Thread:Yield
#endif
            JMP         1B
8H          PUSHJ       t,MM:Thread:Exit

            %
            % In Main we create all three threads and wait for them to
            % finish. After that print some statistics
            %

Main        SWYM
            GETA        t,Thread1
            PUSHJ       t,MM:Thread:CreateG
            GETA        t,Thread2
            PUSHJ       t,MM:Thread:CreateG
            GETA        t,Thread3
            PUSHJ       t,MM:Thread:CreateG
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
