%
% A minimal hello world example
%

#include <mm/print>
#include <mm/sys>

            .section .data,"wa",@progbits
HelloString BYTE        "Hello World!",10,0

            .section .text,"xa",@progbits
Main
            LDA         $255,HelloString
            PUSHJ       $255,MM:Print:StrG
            PUSHJ       $255,MM:Sys:Exit
