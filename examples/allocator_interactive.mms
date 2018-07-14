%
% A small allocator stress test
%

#include <mm/adt>
#include <mm/heap>
#include <mm/print>
#include <mm/rand>
#include <mm/sys>
#include <mm/thread>

t           IS          :MM:t


            %%
            % DrawUniform
            %
            % A uniform distribution that selects between a memory chunk
            % with a lifetime between [1,TMax) and a size of [0,SizeMax).
            %
            % No arguments
            % Returns:
            %   ret0 - time
            %   ret1 - size
            %

            .section .text,"ax",@progbits
TMax        IS          100
TShift      IS          9
SizeMax     IS          #0FE0
SizeShift   IS          3
DrawUniform GET         $3,:rJ
1H          PUSHJ       $4,MM:Rand:Octa
            SET         $1,$4
            SRU         $1,$1,48
            SRU         $1,$1,TShift
            BZ          $1,1B % want > 0
            SET         $4,TMax
            CMP         $4,$1,$4
            BP          $4,1B % want <= TMax, retry
1H          PUSHJ       $4,MM:Rand:Octa
            SET         $0,$4
            SRU         $0,$0,48
            SRU         $0,$0,SizeShift
            BZ          $0,1B % want > 0
            SET         $4,SizeMax
            CMP         $4,$0,$4
            BP          $4,1B % want <= SizeMax
            PUT         :rJ,$3
            POP         2,0


            %%
            % DrawExponen
            %
            % An exponential distribution: From the left, advancing to the
            % next bin (+SizeStep and +TimeStep) has a probability of
            % Advance / 16
            %
            % No arguments
            % Returns:
            %   ret0 - time
            %   ret1 - size
            %

            .section .text,"ax",@progbits
Advance     IS          13
SizeStep    IS          #80
TimeStep    IS          20
DrawExponen GET         $2,:rJ
            SET         $0,SizeStep
            SET         $1,TimeStep
2H          PUSHJ       $4,MM:Rand:Octa
            SET         $6,4
3H          AND         $5,$4,#F
            SUBU        $5,$5,Advance
            BNN         $5,1F
            INCL        $0,SizeStep
            INCL        $1,TimeStep
            SRU         $4,$4,#10
            SUBU        $6,$6,1
            BNZ         $6,3B
            JMP         2B
1H          SUBU        $0,$0,#20 % subtract payload
            PUT         :rJ,$2
            POP         2,0


            %%
            %
            % Main:
            %

Main        SWYM

            %
            % Choose a distribution:
            %

Draw        IS          DrawExponen
%Draw        IS          DrawUniform

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

            SETML       $10,#2
9H          SUBU        $10,$10,1
            BNZ         $10,9B % main loop

            JMP         1B

            %
            % Print statistics and exit:
            %

            PUSHJ       t,MM:Sys:Exit


            %%
            %
            % Print an error and exit:
            %

            .section .data,"wa",@progbits
            .balign 4
ErrorStr    BYTE "Something went horribly wrong :-(",10,0
            .balign 4
ClearStr    BYTE "\033[2J\033[0;0H",0

            .section .text,"ax",@progbits
__fatal     GETA        t,ErrorStr
            PUSHJ       t,MM:Print:StrG
            PUSHJ       t,MM:Sys:Abort

