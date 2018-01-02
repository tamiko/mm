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
            % Register :MM:__INIT:TripHandler and :MM:__INIT:Entry
            %

            .section .text,"ax",@progbits
            PREFIX      :MM:__INIT:
            .org #0
__trip      PUSHJ       $255,:MM:__INIT:TripHandler
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #10
            .org #F0
__entry     JMP         :MM:__INIT:Entry
            .org #108
            PREFIX      :
            .global :MM:__INIT:__trip
            .global :MM:__INIT:__entry

            %
            % Set up an internal buffer used for various purposes
            %

            .section .data,"wa",@progbits
            PREFIX      :MM:__INTERNAL:
Buffer      IS          @
            .fill 128*8
            PREFIX      :
            .global :MM:__INTERNAL:Buffer
