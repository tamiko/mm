%
% A minimal hello world example
%

#include <mm/print>
#include <mm/sys>

            .section .data,"wa",@progbits
HelloString BYTE        "Hello World!",10,0

            .section .text,"xa",@progbits
t           IS          :MM:t
Main        LDA         t,HelloString
            PUSHJ       t,MM:Print:StrG
            PUSHJ       t,MM:Sys:Exit
