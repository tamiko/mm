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
% :MM:__CALLBACK:
%

            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__CALLBACK:interval
            PREFIX      :MM:__CALLBACK:
interval    OCTA        #FFFFFFFFFFFFFFFF

            .section .text,"ax",@progbits
            PREFIX      :MM:__CALLBACK:

t           IS          $255
arg0        IS          $0



%%
% :MM:__CALLBACK:Enable
%
% PUSHJ
%   arg0 - interval in oops
%   no return values
%
% :MM:__CALLBACK:EnableG
%
% PUSHJ %255
%
            .global :MM:__CALLBACK:Enable
            .global :MM:__CALLBACK:EnableG
EnableG     SET         arg0,t
Enable      LDA         $1,:MM:__CALLBACK:interval
            STO         arg0,$1
            PUT         :rI,arg0
            SET         t,arg0
            POP         0


%%
% :MM:__CALLBACK:Disable
%
% PUSHJ
%   arg0 - interval in oops
%   no return values
%
% :MM:__CALLBACK:DisableG
%
% PUSHJ %255
%
            .global :MM:__CALLBACK:Disable
            .global :MM:__CALLBACK:DisableG
DisableG    SET         arg0,t
Disable     NEG         $2,0,1
            LDA         $1,:MM:__CALLBACK:interval
            STO         $2,$1
            PUT         :rI,$2
            SET         t,arg0
            POP         0
