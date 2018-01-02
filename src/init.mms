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
% :MM:__INIT:
%
% Setup internal library routines and data structures.
%

            .section .text,"ax",@progbits
            .global :MM:__INIT:TripHandler
            .global :MM:__INIT:Entry
            PREFIX      :MM:__INIT:
TripHandler SWYM
            % TODO: implement
Entry       SWYM
            % $0 - argc
            % $1 - argv
            % $2 - Main
            SET         $2,$255     % store Main in $2
            %
            % TODO: Now call into startup code
            %
            PUT         :rW,$2      % RESUME at Main
            PUT         :rB,$2      % $255 <- Main after RESUME
            SETML       $2,#F700
            PUT         :rX,$2
            PUT         :rJ,0
            SET         $2,0
            RESUME                  % Use resume for a pristine entry into Main
