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
            % Arithmetic exception handler
            %

            .section .data,"wa",@progbits
            PREFIX      :MM:__INTERNAL:STRS:
            .balign 4
NotImplem   BYTE        "Arithmetic exception handler not implemented.\n",0

            .section .text,"ax",@progbits
            .global :MM:__INTERNAL:ExcHandler
            PREFIX      :MM:__INTERNAL:
ExcHandler  SWYM
            SET         $0,$255
            GET         $1,:rJ
            % We do not handle arithmetic exceptions at the moment.
            GETA        $1,:MM:__INTERNAL:STRS:NotImplem
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return
