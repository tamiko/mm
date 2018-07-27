%
% A small allocator animation
%

#include <mm/adt>
#include <mm/heap>
#include <mm/print>
#include <mm/sys>
#include <mm/thread>

#include "random.mmh"

            .section .data,"wa",@progbits
            .balign 4
ClearStr    BYTE "\033[2J\033[0;0H",0

            .section .text,"ax",@progbits
t           IS          :MM:t

            %
            % Choose a distribution:
            %
Draw        IS          DrawExponen
%Draw        IS          DrawUniform

Main        SWYM

            %
            % We use a deque for allocating an maintaining pool data.
            % Allocation is done with the size that is returned by our
            % probability distribution. We store the time in the first octa
            % of the allocated memory region.
            %
            % Let us push a small sentinel first (the only entry with a
            % negative tics count)
            %

            SET         $1,0
            SET         $2,0
            Deque:PushF_fast $1,$2,#8
            JMP         __fatal
            NEG         $3,0,1
            STO         $3,$1

            %
            % Enable threading such that statistics for critical sections
            % are available.
            %

            SETH        t,#7000
            PUSHJ       t,MM:Thread:EnableG

            %
            % The main loop. Loop forever.
            %

1H          SWYM

            %
            % Decrement tics, deallocate if end of lifetime reached:
            %

2H          SWYM
            Deque:Adv_fast $1,$2
            JMP         __fatal
            LDO         $3,$1
            BN          $3,4F % sentinel reached
            SUBU        $3,$3,1
            STO         $3,$1
            BNZ         $3,3F
            Deque:PopF_fast $1,$2
            JMP         __fatal
3H          JMP         2B

            %
            % Allocate a chunk of memory:
            %

4H          PUSHJ       $3,Draw
            Deque:PushB_fast $1,$2,$4
            JMP         __fatal
            STO         $3,$2

            GETA        t,ClearStr
            PUSHJ       t,MM:Print:StrG
            PUSHJ       t,MM:__DEBUG:PlotMemory

            SETML        $10,#1
9H          SUBU        $10,$10,1
            BNZ         $10,9B % main loop

            JMP         1B

            %%
            %
            % Print an error and exit:
            %

            .section .data,"wa",@progbits
            .balign 4
ErrorStr    BYTE "Something went horribly wrong :-(",10,0

            .section .text,"ax",@progbits
__fatal     GETA        t,ErrorStr
            PUSHJ       t,MM:Print:StrG
            PUSHJ       t,MM:Sys:Abort

