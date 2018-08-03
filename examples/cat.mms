%
#include <mm/file>
#include <mm/heap>
#include <mm/print>
#include <mm/sys>

            .section .data,"wa",@progbits

            .section .text,"xa",@progbits
t           IS          :MM:t
Main        SWYM

1H          SUBU        $0,$0,#1
            BZ          $0,2F
            ADDU        $1,$1,#8

            LDO         $3,$1
            PUSHJ       $2,:MM:File:ReadIn
            SET         $4,$2
            PUSHJ       $3,:MM:Print:Str
            SET         $4,$2
            PUSHJ       $3,:MM:Heap:Dealloc
            JMP         1B

2H          PUSHJ       t,MM:Sys:Exit
