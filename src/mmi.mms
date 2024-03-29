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
            % Startup code.
            % Compilation units can assemble initialization code into the
            % .init section that gets run at program startup before Main is
            % called.
            %

            .section .init,"ax",@progbits
            .global :MM:__INIT:__init
            PREFIX      :MM:__INIT:
Stack_Segment IS        :Stack_Segment
__init      SWYM

            %
            % Initialize the memory pool.
            %

            PUSHJ       :MM:t,:MM:__RAW_POOL:Initialize

            %
            % Initialize the thread ring:
            %

            SET         :MM:t,$0
            PUSHJ       :MM:t,:MM:__INTERNAL:Initialize

            %
            % Now, hide $0 with a PUSHJ:
            %

            PUSHJ       $1,1F
1H          SET         $255,#0
            SET         :MM:t,#0

