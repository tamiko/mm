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
            % Set the beginning of the .text section to #00. The first
            % instructions assembled into the .text section are the entry
            % point for trip handlers and program startup.
            %

            .set __.MMIX.start..text,#00
            .global __.MMIX.start..text

            %
            % Register :MM:__INTERNAL:TripHandler and :MM:__INIT:__init
            %

            .section .text,"ax",@progbits
            .global :MM:__INIT:__entry
            .global :MM:__INIT:__trampoline
            PREFIX      :MM:__INIT:
            .org #000    % H TRIP command / rI timer
__entry     JMP 1F
            .org #010    % D "integer divide check"
            JMP 2F
            .org #020    % V "integer overflow"
            JMP 2F
            .org #030    % W "float-to-fix overflow"
            JMP 2F
            .org #040    % I "floating invalid operation"
            JMP 2F
            .org #050    % O "floating overflow"
            JMP 2F
            .org #060    % U "floating underflow"
            JMP 2F
            .org #070    % Z "floating division by zero"
            JMP 2F
            .org #080    % X "floating inexact"
            JMP 2F
            .org #0F0    % entry point
            JMP 3F

            .org #100
__trampoline SWYM
1H          PUSHJ       $255,:MM:__INTERNAL:TripHandler
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
2H          PUSHJ       $255,:MM:__INTERNAL:ExcHandler
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
3H          JMP         :MM:__INIT:__init

            %
            % Startup code: hide argc, argv and address of Main.
            % Compilation units can assemble initialization code into the
            % .init section that gets run at program startup before Main is
            % called.
            %

            .section .data,"wa",@progbits
            PREFIX :MM:__INIT:STRS:
InitError   BYTE        "Fatal initialization error.",10,0

            .section .init,"ax",@progbits
            .global :MM:__INIT:__init
            PREFIX      :MM:__INIT:
Stack_Segment IS        :Stack_Segment
            %
            % Prepare RESUME. Eventually we will entry into Main with the
            % resume sequence
            %   PUT :rJ,$255
            %   GET $255,:rW
            %   RESUME
            %
__init      PUT         :rW,$255      % RESUME at Main
            PUT         :rB,$255      % keep address of Main in $255
            SETML       $255,#F700
            PUT         :rX,$255
            SET         $255,#0
            %
            % Save initial state, store stack address in $0
            %
            SAVE        $255,0
            SET         $0,$255
            %
            % Initialize the ThreadRing and create a single entry for the
            % main thread that will eventually start executing at the Main
            % label. Further, save a pristine thread image at ThreadTmpl
            % for the Thread:Create call. Layout:
            %    ptr -> OCTA  Thread ID
            %           OCTA  State (#0..00 running, #0..FF sleeping)
            %           OCTA  pointer to previous
            %           OCTA  pointer to next
            %           OCTA  pointer to stack image
            %           OCTA  UNSAVE address
            %
            GETA        $1,Stack_Segment
            SUBU        $2,$0,$1
            ADDU        $2,$2,#8
            SET         $4,$2
            PUSHJ       $3,:MM:__HEAP:AllocJ
            JMP         2F
            SET         $5,$1
            SET         $6,$3
            SET         $7,$2
            PUSHJ       $4,:MM:__MEM:CopyJ
            JMP         2F
            GETA        $255,:MM:__INTERNAL:ThreadTmpl
            STO         $3,$255,#0
            STO         $0,$255,#8
            SET         $5,#30
            PUSHJ       $4,:MM:__HEAP:AllocJ
            JMP         2F
            XOR         $5,$5,$5
            STO         $5,$4,#00 % Thread ID: 0
            STO         $5,$4,#08 % State: running
            STO         $4,$4,#10
            STO         $4,$4,#18
            NEG         $5,0,1
            STO         $5,$4,#20
            STO         $5,$4,#28
            GETA        $6,:MM:__INTERNAL:ThreadRing
            STO         $4,$6
            %
            % Now, hide $0 with a PUSHJ
            %
            PUSHJ       $1,1F
1H          SET         $255,#0
            JMP         3F
2H          GETA        $1,:MM:__INIT:STRS:InitError
            PUSHJ       $0,:MM:__ERROR:IError1
3H          SWYM

