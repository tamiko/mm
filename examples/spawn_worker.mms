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

            GETA        $1,:MM:__SYS:HandleWrite
            LDO         $1,$1
            GETA        $2,command
            PUSHJ       $0,:MM:File:Puts

            GETA        $1,:MM:__SYS:HandleRead
            LDO         $1,$1
            GETA        $2,:MM:__INTERNAL:Buffer
            SET         $3,128
            PUSHJ       $0,:MM:File:Gets

            GETA        t,:MM:__INTERNAL:Buffer
            PUSHJ       t,:MM:Print:StrG

            PUSHJ       t,MM:Sys:Exit

