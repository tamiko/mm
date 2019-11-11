%%
% MMIX support library for various purposes.
%
% Copyright (C) 2013-2018 Matthias Maier <tamiko@kyomu.43-1.org>
%
% Permission is hereby granted, free of charge, to any person
% obtaining a copy of this software and associated documentation files
% (the "Software"), to deal in the Software without restriction,
% including without limitation the rights to use, copy, modify, merge,
% publish, distribute, sublicense, and/or sell copies of the Software,
% and to permit persons to whom the Software is furnished to do so,
% subject to the following conditions:
%
% The above copyright notice and this permission notice shall be
% included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
% BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
% ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%%

%
% :MM:__SYS:
%
% Facilities for system, environment, error handling, and program
% termination.
%


%
% Error handling and program termination:
%

            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__SYS:AtErrorAddr
            PREFIX      :MM:__SYS:
AtErrorAddr OCTA        #0000000000000000

            .section .text,"ax",@progbits
            PREFIX      :MM:__SYS:

Halt        IS          :Halt

t           IS          :MM:t
arg0        IS          $0


%%
% :MM:__SYS:Exit
%
% PUSHJ
%   no arguments
%   does not return
%

            .global :MM:__SYS:Exit
Exit        SET         $255,0
            % Good bye so long and thanks for all the fish.
            TRAP        0,Halt,0


%%
% :MM:__SYS:Abort
%
% PUSHJ
%   no arguments
%   does not return
%

            .global :MM:__SYS:Abort
Abort       SET         $255,1
            % Good bye so long and thanks for all the fish.
            TRAP        0,Halt,0



%%
% :MM:__SYS:AtError
%
% PUSHJ
%   arg0 - address of a subroutine that is called upon abortion of the
%          program
%   no return values
%
% :MM:__SYS:AtErrorG
%
% PUSHJ %255
%

            .global :MM:__SYS:AtError
            .global :MM:__SYS:AtErrorG
AtErrorG    SET         arg0,t
AtError     GETA        $1,:MM:__SYS:AtErrorAddr
            STO         arg0,$1
            SET         t,arg0
            POP         0


%%
%
% Set up worker in init section:
%

            .section .data,"wa",@progbits
            .global :MM:__SYS:WorkerDirec
            .balign 8
            PREFIX      :MM:__SYS:
WorkerDirec OCTA        #0000000000000000
HandleMutex OCTA        #0000000000000000
HandleWrite OCTA        #FFFFFFFFFFFFFFFF
HandleRead  OCTA        #FFFFFFFFFFFFFFFF

            PREFIX      :MM:__SYS:STRS:
            .balign 4
InputFIFO   BYTE "/worker.stdin.fifo",0
            .balign 4
OutputFIFO  BYTE "/worker.stdout.fifo",0
            .balign 4
Init1       BYTE        "__SYS:Init failed. Unable to open '"
            .balign 4
Init2       BYTE        "'",10,0

            .section .init,"ax",@progbits
            PREFIX      :MM:__SYS:
BinaryReadWrite IS      :BinaryReadWrite

            GETA        $0,:MM:__SYS:WorkerDirec
            LDO         $0,$0,0
            BZ          $0,1F
            ADDU        $0,$0,17
            SET         $2,$0
            PUSHJ       $1,:MM:__STRING:Size

            SET         $3,$0
            GETA        $4,:MM:__SYS:Buffer
            ADDU        $5,$1,1
            PUSHJ       $2,:MM:__MEM:Copy

            GETA        $3,:MM:__SYS:STRS:InputFIFO
            GETA        $4,:MM:__SYS:Buffer
            ADDU        $4,$4,$1
            SET         $5,19
            PUSHJ       $2,:MM:__MEM:Copy

            GETA        $3,:MM:__SYS:Buffer
            SET         $4,BinaryReadWrite
            PUSHJ       $2,:MM:__FILE:OpenJ
            JMP         4F
            GETA        $3,:MM:__SYS:HandleWrite
            STO         $2,$3

            GETA        $3,:MM:__SYS:STRS:OutputFIFO
            GETA        $4,:MM:__SYS:Buffer
            ADDU        $4,$4,$1
            SET         $5,20
            PUSHJ       $2,:MM:__MEM:Copy

            GETA        $3,:MM:__SYS:Buffer
            SET         $4,BinaryReadWrite
            PUSHJ       $2,:MM:__FILE:OpenJ
            JMP         4F
            GETA        $3,:MM:__SYS:HandleRead
            STO         $2,$3

            JMP         1F
4H          GETA        $2,:MM:__SYS:STRS:Init1
            GETA        $3,:MM:__SYS:Buffer
            GETA        $4,:MM:__SYS:STRS:Init2
            PUSHJ       $1,:MM:__ERROR:IError3 % does not return
1H          SWYM


%%
% :MM:__SYS:Command
% :MM:__SYS:CommandJ
%
% Run a command in a system shell. This function requires a worker to be
% set up
%
% PUSHJ
%   arg0 - address to a shell command stored in a null terminated string
%   retm - address to a pool allocated memory region containing a null
%          terminated string of the shell output
%
% :MM:__SYS:CommandG
%
% PUSHJ %255
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__SYS:STRS:
            .balign 4
Command1    BYTE        "Sys:Command failed. Worker not connected.'",10,0
            PREFIX      :MM:__SYS:
            .balign 4
end_cmd     BYTE        10,"echo __mm_end_of_output=4MCyxzd0",10,0
            .balign 8
Buffer      IS          @
            .fill 128*8



            .section .text,"ax",@progbits
            .global     :MM:__SYS:Command
            .global     :MM:__SYS:CommandJ
            .global     :MM:__SYS:CommandG
            PREFIX      :MM:__SYS:

            % First check file handles:
CommandJ    GETA        $1,HandleWrite
            LDO         $1,$1
            BN          $1,9F
            GETA        $2,HandleRead
            LDO         $2,$2
            BN          $2,9F
            %
            % Take the lock
            %
            GET         $3,:rJ
            GETA        t,HandleMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            %
            % Now execute the command followed by "echo 4MCyxzd0" that we
            % will use to determine whether we reached the end of the
            % output:
            %
            SET         $5,$1
            SET         $6,$0
            PUSHJ       $4,:MM:__FILE:Puts
            SET         $5,$1
            GETA        $6,end_cmd
            PUSHJ       $4,:MM:__FILE:Puts
            %
            % We are in a bit of a pickle here: We do not know the final
            % size of the program output before reading it from the FIFO in
            % its entirety. We also do not know whether we will short read,
            % or try to read past the end (which will block the program).
            % As a heuristic we wait to read exactly 1C bytes and check
            % whether this is the guard message.
            %
            % We allocate a generous temporary 1MiB buffer
            % that we (iteratively) realloc to 8 times its size if it
            % becomes necessary:
            %
            SETML       $6,#10
            PUSHJ       $5,:MM:__POOL:Alloc
            SET         $4,#0
            SETML       $6,#10
            % $4 - number of bytes read
            % $5 - buffer address
            % $6 - buffer size
2H          SET         $8,$2
            ADDU        $9,$5,$4
            SUBU        $10,$6,$4
            PUSHJ       $7,:MM:__FILE:Gets
            ADDU        $4,$4,$7
            SUBU        $8,$7,#1C
            BZ          $8,1F % We might have read the guard message
            ADDU        $7,$4,1
            CMP         $7,$6,$7
            BNZ         $7,2B
            % We have exhausted the buffer, increase it by a factor of 4:
            SLU         $6,$6,2
            SET         $8,$5
            SET         $9,$6
            PUSHJ       $7,:MM:__POOL:Realloc
            SET         $5,$7
            JMP         2B
            % Check that we actually read the guard:
1H          GETA        $8,end_cmd
            INCL        $8,6
            ADDU        $9,$5,$4
            SUBU        $9,$9,#1C
            SET         $10,#1C
            PUSHJ       $7,:MM:__MEM:Cmp
            BNZ         $7,2B
            % Remove the guard message and fix up the string:
            SUBU        $4,$4,#1C
            ADDU        $7,$5,$4
            SET         $8,#0
            STB         $8,$7
            % Do a final allocation with the actual string size and copy
            % over:
            ADDU        $7,$4,1
            PUSHJ       $6,:MM:__POOL:Alloc
            SET         $8,$5
            SET         $9,$6
            ADDU        $10,$4,1
            PUSHJ       $7,:MM:__MEM:Copy
            % Deallocate the scratch area:
            SET         $8,$5
            PUSHJ       $7,:MM:__POOL:Dealloc
            SET         $0,$6 % retm
            %
            % Release the HandleMutex and return:
            %
            GETA        t,HandleMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$3
            POP         1,1
9H          POP         0,0


Command     GET         $1,:rJ
            SET         $3,$0
            PUSHJ       $2,CommandJ
            JMP         9F
            SET         $0,$2
            PUT         :rJ,$1
            POP         1,0
9H          SET         t,$1 % :rJ
            GETA        $1,:MM:__SYS:STRS:Command1
            PUSHJ       $0,:MM:__ERROR:Error1


CommandG    GET         $1,:rJ
            SET         $3,t
            PUSHJ       $2,CommandJ
            JMP         9F
            SET         t,$2
            PUT         :rJ,$1
            POP         0,0
9H          SET         t,$1 % :rJ
            GETA        $1,:MM:__SYS:STRS:Command1
            PUSHJ       $0,:MM:__ERROR:Error1
