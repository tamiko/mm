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

            .section .init,"ax",@progbits
            %
            % undo PUSHJ, restore initial state and use RESUME for a
            % pristine entry into Main
            %
            GETA        $0,1F
            PUT         :rJ,$0
            POP         0
1H          UNSAVE      0,$0
            PUT         :rW,$255      % RESUME at Main
            SETML       $255,#F700
            PUT         :rX,$255
            PUT         :rJ,#0
            GET         $255,:rW
            RESUME


            .section .callback,"ax",@progbits
            %
            % undo PUSHJ, restore initial state and POP
            %
            GETA        $0,1F
            PUT         :rJ,$0
            POP         0
1H          UNSAVE      0,$0
            POP         0