%
%
%

#include <mm/print>
#include <mm/sys>

            .section .data,"wa",@progbits
str_header  BYTE        "Diagnose startup",10,10,0
str_header2 BYTE        "Library specific adresses:",10,10,0
str_header3 BYTE        "Program parameters (argc, argv):",10,10,0
str_text    BYTE        "    Text segment:              [ ",0
str_data    BYTE        "    Data segment:              [ ",0
str_pool    BYTE        "    Pool segment:              [ ",0
str_stack   BYTE        "    Stack segment:             [ ",0
str_main    BYTE        "    Main:                      [ ",0
str_hndl1   BYTE        "    :MM:__Init:__trip          [ ",0
str_entry   BYTE        "    :MM:__Init:__entry         [ ",0
str_guard   BYTE        "    :MM:__Init:__guard         [ ",0
str_init    BYTE        "    :MM:__Init:__init          [ ",0
str_hndl2   BYTE        "    :MM:__INTERNAL:TripHandler [ ",0
str_hndl3   BYTE        "    :MM:__INTERNAL:ExcHandler  [ ",0
str_aterror BYTE        "    :MM:__SYS:AtErrorAddr      [ ",0
str_between BYTE        " ]    -->    [ ",0
str_argc    BYTE        "    argc:                      [ ",0
str_argv    BYTE        "    argv:                      [ ",0
str_argv2   BYTE        "                               [ ",0
str_str     BYTE        " ]    -->    '",0
str_str2    BYTE        "'",10,0
str_endl    BYTE        " ]",10,0


            .section .text,"xa",@progbits
t           IS          $255
arg0        IS          $0
arg1        IS          $1

            % arg0 - string to print
            % arg1 - address to print
AddressOf   GET         $2,:rJ
            SET         t,arg0
            PUSHJ       t,MM:Print:StrG
            SET         t,arg1
            PUSHJ       t,MM:Print:RegG
            LDA         t,str_endl
            PUSHJ       t,MM:Print:StrG
            PUT         :rJ,$2
            POP         0,0

            % arg0 - string to print
            % arg1 - address to print
AddressOf2  GET         $2,:rJ
            SET         t,arg0
            PUSHJ       t,MM:Print:StrG
            SET         t,arg1
            PUSHJ       t,MM:Print:RegG
            LDA         t,str_between
            PUSHJ       t,MM:Print:StrG
            LDOU        t,arg1
            PUSHJ       t,MM:Print:RegG
            LDA         t,str_endl
            PUSHJ       t,MM:Print:StrG
            PUT         :rJ,$2
            POP         0,0

Main        SET         $2,t
            LDA         t,str_header
            PUSHJ       t,MM:Print:StrG

            LDA         $5,#0
            LDA         $4,str_text
            PUSHJ       $3,AddressOf
            LDA         $5,:Data_Segment
            LDA         $4,str_data
            PUSHJ       $3,AddressOf
            LDA         $5,:Pool_Segment
            LDA         $4,str_pool
            PUSHJ       $3,AddressOf2
            LDA         $5,:Stack_Segment
            LDA         $4,str_stack
            PUSHJ       $3,AddressOf
            PUSHJ       t,MM:Print:Ln

            SET         $5,$2
            LDA         $4,str_main
            PUSHJ       $3,AddressOf
            PUSHJ       t,MM:Print:Ln

            LDA         t,str_header2
            PUSHJ       t,MM:Print:StrG

            LDA         $5,:MM:__INIT:__trip
            LDA         $4,str_hndl1
            PUSHJ       $3,AddressOf
            LDA         $5,:MM:__INIT:__entry
            LDA         $4,str_entry
            PUSHJ       $3,AddressOf
            LDA         $5,:MM:__INIT:__guard
            LDA         $4,str_guard
            PUSHJ       $3,AddressOf
            LDA         $5,:MM:__INIT:__init
            LDA         $4,str_init
            PUSHJ       $3,AddressOf
            PUSHJ       t,MM:Print:Ln

            LDA         $5,:MM:__INTERNAL:TripHandler
            LDA         $4,str_hndl2
            PUSHJ       $3,AddressOf
            LDA         $5,:MM:__INTERNAL:ExcHandler
            LDA         $4,str_hndl3
            PUSHJ       $3,AddressOf
            PUSHJ       t,MM:Print:Ln

            LDA         $5,:MM:__SYS:AtErrorAddr
            LDA         $4,str_aterror
            PUSHJ       $3,AddressOf2
            LDA         $5,:MM:__FILE:Pool
            PUSHJ       t,:MM:Print:Ln

            LDA         t,str_header3
            PUSHJ       t,MM:Print:StrG

            % argc:
            LDA         $4,str_argc
            SET         $5,$0
            PUSHJ       $3,AddressOf

            % argv:
            LDA         t,str_argv
            JMP         2F
1H          LDA         t,str_argv2
2H          PUSHJ       t,:MM:Print:StrG
            LDOU        t,$1
            PUSHJ       t,:MM:Print:RegG
            LDA         t,str_str
            PUSHJ       t,:MM:Print:StrG
            LDOU        t,$1
            PUSHJ       t,:MM:Print:StrG
            LDA         t,str_str2
            PUSHJ       t,:MM:Print:StrG
            SUBU        $0,$0,#1
            ADDU        $1,$1,#8
            BNZ         $0,1B

            PUSHJ       $255,MM:Sys:Exit
