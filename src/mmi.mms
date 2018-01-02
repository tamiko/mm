%%
% MMIX support library for various purposes.
%
% Copyright (C) 2013-2014 Matthias Maier <tamiko@kyomu.43-1.org>
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
            % instructions assembled into the .text section thus determines
            % the trip handler and entry point of the program.
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
            .org #0
__trip      PUSHJ       $255,:MM:__INTERNAL:TripHandler
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #10
            .org #F0
__entry     JMP         :MM:__INIT:__init
            .org #108

            %
            % Startup code: hide argc, argv and address of Main.
            % Compilations units can assemble initialization code into the
            % .init section that gets run at program startup before Main is
            % called.
            %

            .section .init,"ax",@progbits
            .global :MM:__INIT:__init
            PREFIX      :MM:__INIT:
__init      SET         $2,$255     % store Main in $2
            % $0 - argc
            % $1 - argv
            % $2 - Main

            % PUSHJ to hide $0,$1,$2
            PUSHJ       $3,1F
1H          SWYM
            % mmo.mms containes the final call to Main
