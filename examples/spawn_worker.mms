%
% A small example demonstrating system() interaction with a worker:
%

#include <mm/file>
#include <mm/print>
#include <mm/sys>

            .global MM:Interpreter:SPAWN_WORKER

            .data
            .align 4
cmd_str     BYTE "uname -a",10,0

            .text
            .global Main
t           IS          :MM:t
Main        SWYM

            GETA        t,cmd_str
            PUSHJ       t,:MM:__SYS:CommandG
            PUSHJ       t,:MM:Print:StrG

            SET         t,#0
            PUSHJ       t,MM:Sys:Exit
