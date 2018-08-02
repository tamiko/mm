%
%
%

            .section .text,"ax",@progbits

Main        PUSHJ       $255,:MM:__DEBUG:PrintMemory
            PUSHJ       $255,:MM:__DEBUG:PlotMemory
            PUSHJ       $255,:MM:__DEBUG:PrintFree
            PUSHJ       $255,:MM:__DEBUG:PrintLayout
            PUSHJ       $255,:MM:__SYS:Exit
