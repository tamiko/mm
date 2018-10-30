%
#include <mm/file>
#include <mm/pool>
#include <mm/print>
#include <mm/sys>

            .section .data,"wa",@progbits
            .balign 4
error_str1  BYTE        "Error: Could not open file \"",0
            .balign 4
error_str2  BYTE        "\" for reading.",10,0
            .balign 4

            .section .text,"xa",@progbits
t           IS          :MM:t
Main        SWYM

1H          SUBU        $0,$0,#1
            BZ          $0,2F
            ADDU        $1,$1,#8

            LDO         $3,$1
            PUSHJ       $2,:MM:File:ReadInJ
            JMP         9F

            SET         $4,$2
            PUSHJ       $3,:MM:Print:Str
            SET         $4,$2
            PUSHJ       $3,:MM:Pool:Dealloc
            JMP         1B

2H          PUSHJ       t,MM:Sys:Exit

9H          GETA        t,error_str1
            PUSHJ       t,MM:Print:StrG
            LDO         t,$1
            PUSHJ       t,MM:Print:StrG
            GETA        t,error_str2
            PUSHJ       t,MM:Print:StrG
            PUSHJ       t,MM:Sys:Abort

