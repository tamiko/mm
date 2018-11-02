%
% A small example demonstrating system() interaction with a worker:
%

#include <mm/file>
#include <mm/print>
#include <mm/sys>

            .global MM:Interpreter:SPAWN_WORKER

            .data
            .align 4
command     BYTE "date",10,0

            .text
            .global Main
t           IS          :MM:t
Main        SWYM

            GETA        t,command
            PUSHJ       t,:MM:__SYS:CommandG
            PUSHJ       t,:MM:Print:StrG

            PUSHJ       t,MM:Sys:Exit
