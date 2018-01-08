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
            % instructions assembled into the .text section determine the
            % trip handlers and the entry point into the program.
            %

            .set __.MMIX.start..text,#00
            .global __.MMIX.start..text

            %
            % Register :MM:__INTERNAL:TripHandler and :MM:__INIT:__init
            %

            .section .text,"ax",@progbits
            .global :MM:__INIT:__trip
            .global :MM:__INIT:__entry
            PREFIX      :MM:__INIT:
            .org #00    % H TRIP command / rI timer
__trip      PUSHJ       $255,:MM:__INTERNAL:TripHandler
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #10    % D "integer divide check"
            JMP 1F
            .org #20    % V "integer overflow"
            JMP 1F
            .org #30    % W "float-to-fix overflow"
            JMP 1F
            .org #40    % I "floating invalid operation"
            JMP 1F
            .org #50    % O "floating overflow"
            JMP 1F
            .org #60    % U "floating underflow"
            JMP 1F
            .org #70    % Z "floating division by zero"
            JMP 1F
            .org #80    % X "floating inexact"
1H          PUSHJ       $255,:MM:__INTERNAL:ExcHandler
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #F0    % entry point
__entry     JMP         :MM:__INIT:__init
            .org #108

            %
            % Startup code: hide argc, argv and address of Main.
            % Compilation units can assemble initialization code into the
            % .init section that gets run at program startup before Main is
            % called.
            %

            .section .init,"ax",@progbits
            .global :MM:__INIT:__init
            PREFIX      :MM:__INIT:
__init      SWYM
            %
            % Prepare RESUME. Eventually we will entry into Main with the
            % resume sequence
            %   PUT :rJ,$255
            %   GET $255,:rW
            %   RESUME
            %
            PUT         :rW,$255      % RESUME at Main
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
            %           OCTA  State (#0..00 run, #0..FF sleep)
            %           OCTA  pointer to previous
            %           OCTA  pointer to next
            %           OCTA  pointer to stack image
            %           OCTA  UNSAVE address
            %SET         
            %PUSHJ       $1,


            %
            % Now, hide $0 with a PUSHJ
            %
            SET         $255,#0
            PUSHJ       $1,1F
1H          SWYM
