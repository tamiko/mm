        LOC     Data_Segment
        GREG    @
Text    BYTE    "Es ist ein kalter Tag im August",0

        LOC     #100
#include "mm/print.mmh"

Main    LDA     $1,Text
        PUSHJ   $0,MM:PrintLn
        SET     $255,0
        TRAP    0,Halt,0

