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
% :MM:__DEBUG
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__DEBUG:STRS:
            .balign 4
memory_str  BYTE        "Pool memory:",10,0
            .balign 4
pool_str    BYTE        "Free list:",10,0
            .balign 4
pool1       BYTE        "    [",0
            .balign 4
pool2       BYTE        "] [size = ",0
            .balign 4
pool3a      BYTE        "] USED --> [next = ",0
            .balign 4
pool3b      BYTE        "] free --> [next = ",0
            .balign 4
pool3c      BYTE        "] SENT --> [next = ",0
            .balign 4
pool4       BYTE        "]",10,0
            .balign 4
plot1       BYTE        "] ",#E2,#94,#8A,0
            .balign 4
plot2       BYTE        " ",0
            .balign 4
plot3       BYTE        #E2,#94,#81,0
            .balign 4
plot3a      BYTE        #E2,#94,#97,0
            .balign 4
plot3b      BYTE        #E2,#94,#9B,0
            .balign 4
plot3c      BYTE        #E2,#95,#B9,0
            .balign 4
plot4       BYTE        #E2,#94,#8A,10,0
            .balign 4
ring_str    BYTE        "Thread Ring:",10,0
            .balign 4
ring1       BYTE        "    [",0
            .balign 4
ring2       BYTE        "] (ThreadID)",10,0
            .balign 4
ring3       BYTE        "] (State)",10,0
            .balign 4
ring4       BYTE        "] (ptr previous)",10,0
            .balign 4
ring5       BYTE        "] (ptr next)",10,0
            .balign 4
ring6       BYTE        "] (ptr image)",10,0
            .balign 4
ring7       BYTE        "] (UNSAVE address)",10,0
            .balign 4
str_header  BYTE        "Memory Layout:",10,0
            .balign 4
str_header2 BYTE        "Program parameters (argc, argv):",10,0
            .balign 4
str_text    BYTE        "    Text segment:              [ ",0
            .balign 4
str_data    BYTE        "    Data segment:              [ ",0
            .balign 4
str_pool    BYTE        "    Pool segment:              [ ",0
            .balign 4
str_stack   BYTE        "    Stack segment:             [ ",0
            .balign 4
str_main    BYTE        "    Address of Main:           [ ",0
            .balign 4
str_tramp   BYTE        "    :MM:__INIT:__trampoline    [ ",0
            .balign 4
str_entry1  BYTE        "    :MM:__INIT:__entry         [ ",0
            .balign 4
str_entry2  BYTE        "    :MM:__INIT:__init          [ ",0
            .balign 4
str_entry3  BYTE        "    :MM:__INTERNAL:Guard       [ ",0
            .balign 4
str_hndl2   BYTE        "    :MM:__INTERNAL:TripHandler [ ",0
            .balign 4
str_hndl3   BYTE        "    :MM:__INTERNAL:ExcHandler  [ ",0
            .balign 4
str_aterror BYTE        "    :MM:__SYS:AtErrorAddr      [ ",0
            .balign 4
str_directo BYTE        "    :MM:__SYS:WorkerDirec      [ ",0
            .balign 4
str_between BYTE        " ]    -->    [ ",0
            .balign 4
str_argc    BYTE        "    argc:                      [ ",0
            .balign 4
str_argv    BYTE        "    argv:                      [ ",0
            .balign 4
str_argv2   BYTE        "                               [ ",0
            .balign 4
str_str     BYTE        " ]    -->    '",0
            .balign 4
str_str2    BYTE        "'",10,0
            .balign 4
str_endl    BYTE        " ]",10,0


            .section .text,"ax",@progbits
            PREFIX      :MM:__DEBUG:
t           IS          :MM:t
arg0        IS          $0
arg1        IS          $1
Data_Segment IS         :Data_Segment
Pool_Segment IS         :Pool_Segment
Stack_Segment IS        :Stack_Segment


            %
            % PrintMemory - pool memory:
            %


            .global     :MM:__DEBUG:PrintMemory
PrintMemory GET         $0,:rJ
            GETA        t,STRS:memory_str
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        $2,:MM:__RAW_POOL:Memory
            LDO         $2,$2
            % Print memory chunks:
            SET         $3,$2
2H          SWYM
            GETA        t,STRS:pool1
            PUSHJ       t,:MM:__PRINT:StrG
            SET         t,$3
            PUSHJ       t,:MM:__PRINT:RegG
            SWYM
            GETA        t,STRS:pool2
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$3,0
            SUBU        t,t,$3
            CSN         t,t,#20
            PUSHJ       t,:MM:__PRINT:RegG
            SET         $4,#20
            CMP         t,t,$4
            BP          t,1F
            GETA        t,STRS:pool3c
            JMP         4F
1H          LDO         t,$3,#18
            BNZ         t,3F
            GETA        t,STRS:pool3a
            JMP         4F
3H          GETA        t,STRS:pool3b
4H          PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$3,#0
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:pool4
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         $3,$3
            CMP         $4,$2,$3
            BNZ         $4,2B
            PUSHJ       t,:MM:__PRINT:Ln
            PUT         :rJ,$0
            POP         0


            %
            % PrintFree - print memory pool
            %


            .global     :MM:__DEBUG:PrintFree
PrintFree   GET         $0,:rJ
            GETA        t,STRS:pool_str
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        $2,:MM:__RAW_POOL:Pool
            LDO         $2,$2
            % Print memory chunks:
            SET         $3,$2
2H          SWYM
            GETA        t,STRS:pool1
            PUSHJ       t,:MM:__PRINT:StrG
            SET         t,$3
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:pool2
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$3,0
            SUBU        t,t,$3
            CSN         t,t,#20
            PUSHJ       t,:MM:__PRINT:RegG
            SET         $4,#20
            CMP         t,t,$4
            BP          t,1F
            GETA        t,STRS:pool3c
            JMP         4F
1H          LDO         t,$3,#18
            BNZ         t,3F
            GETA        t,STRS:pool3a
            JMP         4F
3H          GETA        t,STRS:pool3b
4H          PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$3,#10
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:pool4
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         $3,$3,#10
            CMP         $4,$2,$3
            BNZ         $4,2B
            PUSHJ       t,:MM:__PRINT:Ln
            PUT         :rJ,$0
            POP         0


            %
            % PlotMemory - Show a graphical layout of the memory region:
            %


            .global     :MM:__DEBUG:PlotMemory
PlotMemory  GET         $0,:rJ
            GETA        t,STRS:memory_str
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        $2,:MM:__RAW_POOL:Memory
            LDO         $2,$2     % first sentinel
            LDO         $3,$2,#8  % last sentinel
            LDO         $2,$2     % first block
            LDO         $3,$3,#8  % last block (almost™ always free)
            SUBU        $3,$3,$2
            SET         $4,$2     % first memory chunk
            LDO         $5,$4     % next memory chunk
            LDO         $4,$4,#10 % status of first memory region
            GETA        $16,STRS:pool1
            GETA        $6,STRS:plot1
            GETA        $7,STRS:plot4
            GETA        $8,STRS:plot2
            GETA        $9,STRS:plot3
            GETA        $12,STRS:plot3a
            GETA        $13,STRS:plot3b
            GETA        $14,STRS:plot3c
            SET         $15,$12

            % $2 running memory address
            % $3 size of memory pool
            % $4 status of current memory region
            % $5 next memory block
            SET         $10,#0
            SET         $11,#0
1H          SWYM
            % print address if divisible by #4000
            BNZ         $11,2F
            SET         t,$16
            PUSHJ       t,:MM:__PRINT:StrG
            SET         t,$2
            PUSHJ       t,:MM:__PRINT:RegG
            SET         t,$6
            PUSHJ       t,:MM:__PRINT:StrG
2H          SET         t,$8 % ' '
            BNZ         $4,3F
            SET         t,$15
            SET         $15,$9
3H          PUSHJ       t,:MM:__PRINT:StrG
            ADDU        $2,$2,#80
            SUBU        $3,$3,#80
            ADDU        $10,$10,#80
            SET         $11,$10
            SLU         $11,$11,51 % TODO
            % print newline every #4000:
            BNZ         $11,4F
            SET         t,$7
            PUSHJ       t,:MM:__PRINT:StrG
            % check if we are in a new memory region:
4H          CMPU        t,$2,$5
            BN          t,6F
            LDO         $4,$5,#10 % status memory region
            LDO         $5,$5 % new memory region
            SET         $15,$12 % 'l'
            ADDU        t,$2,#80
            CMPU        t,t,$5
            BN          t,5F
            SET         $15,$14 % 'm'
            JMP         5F
6H          ADDU        t,$2,#80
            CMPU        t,t,$5
            BN          t,5F
            SET         $15,$13 % 'r'
5H          BP          $3,1B

            PUSHJ       t,:MM:__PRINT:Ln
            PUSHJ       t,:MM:__PRINT:Ln
            PUT         :rJ,$0
            POP         0


            %
            % PrintTRing - print thread ring
            %


            .global     :MM:__DEBUG:PrintTRing
PrintTRing  GET         $0,:rJ
            GETA        t,STRS:ring_str
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        $2,:MM:__INTERNAL:ThreadRing
            LDO         $2,$2
            SET         $1,$2
1H          GETA        t,STRS:ring1
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$2,#00
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:ring2
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        t,STRS:ring1
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$2,#08
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:ring3
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        t,STRS:ring1
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$2,#10
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:ring4
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        t,STRS:ring1
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$2,#18
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:ring5
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        t,STRS:ring1
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$2,#20
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:ring6
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        t,STRS:ring1
            PUSHJ       t,:MM:__PRINT:StrG
            LDO         t,$2,#28
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:ring7
            PUSHJ       t,:MM:__PRINT:StrG
            PUSHJ       t,:MM:__PRINT:Ln
            LDO         $2,$2,#18
            CMP         $3,$2,$1
            BNZ         $3,1B
            PUT         :rJ,$0
            POP         0


            %
            % PrintLayout - Print memory layout
            %


            .global     :MM:__DEBUG:AddressOf
            % arg0 - string to print
            % arg1 - address to print
AddressOf   GET         $2,:rJ
            SET         t,arg0
            PUSHJ       t,:MM:__PRINT:StrG
            SET         t,arg1
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:str_endl
            PUSHJ       t,:MM:__PRINT:StrG
            PUT         :rJ,$2
            POP         0,0

            .global     :MM:__DEBUG:AddressOf2
            % arg0 - string to print
            % arg1 - address to print
AddressOf2  GET         $2,:rJ
            SET         t,arg0
            PUSHJ       t,:MM:__PRINT:StrG
            SET         t,arg1
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:str_between
            PUSHJ       t,:MM:__PRINT:StrG
            LDOU        t,arg1
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:str_endl
            PUSHJ       t,:MM:__PRINT:StrG
            PUT         :rJ,$2
            POP         0,0

            .global     :MM:__DEBUG:PrintLayout
PrintLayout GET         $0,:rJ
            GETA        t,PrintThread
            PUSHJ       t,:MM:__THREAD:CreateG
            PUSHJ       t,:MM:__THREAD:WaitG
            PUT         :rJ,$0
            POP         0,0

PrintThread GET         $2,:rJ
            GETA        t,STRS:str_header
            PUSHJ       t,:MM:__PRINT:StrG

            GETA        $5,#0
            GETA        $4,STRS:str_text
            PUSHJ       $3,AddressOf
            GETA        $5,Data_Segment
            GETA        $4,STRS:str_data
            PUSHJ       $3,AddressOf
            GETA        $5,Pool_Segment
            GETA        $4,STRS:str_pool
            PUSHJ       $3,AddressOf2
            GETA        $5,Stack_Segment
            GETA        $4,STRS:str_stack
            PUSHJ       $3,AddressOf
            PUSHJ       t,:MM:__PRINT:Ln

            GETA        $5,:MM:__INIT:__entry
            GETA        $4,STRS:str_entry1
            PUSHJ       $3,AddressOf
            GETA        $5,:MM:__INIT:__trampoline
            GETA        $4,STRS:str_tramp
            PUSHJ       $3,AddressOf
            GETA        $5,:MM:__INIT:__init
            GETA        $4,STRS:str_entry2
            PUSHJ       $3,AddressOf
            PUSHJ       t,:MM:__PRINT:Ln

            SET         $5,$2
            GETA        $4,STRS:str_main
            PUSHJ       $3,AddressOf
            PUSHJ       t,:MM:__PRINT:Ln


            GETA        $5,:MM:__INTERNAL:Guard
            GETA        $4,STRS:str_entry3
            PUSHJ       $3,AddressOf
            GETA        $5,:MM:__INTERNAL:TripHandler
            GETA        $4,STRS:str_hndl2
            PUSHJ       $3,AddressOf
            GETA        $5,:MM:__INTERNAL:ExcHandler
            GETA        $4,STRS:str_hndl3
            PUSHJ       $3,AddressOf
            PUSHJ       t,:MM:__PRINT:Ln

            GETA        $5,:MM:__SYS:AtErrorAddr
            GETA        $4,STRS:str_aterror
            PUSHJ       $3,AddressOf2
            PUSHJ       t,:MM:__PRINT:Ln

            GETA        $5,:MM:__SYS:WorkerDirec
            GETA        $4,STRS:str_directo
            PUSHJ       $3,AddressOf2

            GETA        t,STRS:str_argv2
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        $5,:MM:__SYS:WorkerDirec
            LDOU        t,$5,0
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:str_str
            PUSHJ       t,:MM:__PRINT:StrG
            LDOU        t,$5,0
            BZ          t,1F
            PUSHJ       t,:MM:__PRINT:StrG
1H          GETA        t,STRS:str_str2
            PUSHJ       t,:MM:__PRINT:StrG
            PUSHJ       t,:MM:__PRINT:Ln

            GETA        t,STRS:str_header2
            PUSHJ       t,:MM:__PRINT:StrG

            % argc:
            GETA        $4,STRS:str_argc
            SET         $5,$0
            PUSHJ       $3,AddressOf

            % argv:
            GETA        t,STRS:str_argv
            JMP         2F
1H          GETA        t,STRS:str_argv2
2H          PUSHJ       t,:MM:__PRINT:StrG
            LDOU        t,$1
            PUSHJ       t,:MM:__PRINT:RegG
            GETA        t,STRS:str_str
            PUSHJ       t,:MM:__PRINT:StrG
            LDOU        t,$1
            PUSHJ       t,:MM:__PRINT:StrG
            GETA        t,STRS:str_str2
            PUSHJ       t,:MM:__PRINT:StrG
            SUBU        $0,$0,#1
            ADDU        $1,$1,#8
            BNZ         $0,1B

            PUSHJ       t,:MM:__PRINT:Ln
            PUSHJ       t,:MM:__THREAD:Exit

