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
% :MM:__THREAD:
%

            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__THREAD:interval
            PREFIX      :MM:__THREAD:
interval    OCTA        #FFFFFFFFFFFFFFFF

            .section .text,"ax",@progbits
            PREFIX      :MM:__THREAD:

t           IS          $255
arg0        IS          $0



%%
% :MM:__THREAD:Enable
%
% PUSHJ
%   arg0 - interval in oops
%   no return values
%
% :MM:__THREAD:EnableG
%
% PUSHJ %255
%
            .global :MM:__THREAD:Enable
            .global :MM:__THREAD:EnableG
EnableG     SET         arg0,t
Enable      LDA         $1,:MM:__THREAD:interval
            STO         arg0,$1
            PUT         :rI,arg0
            SET         t,arg0
            POP         0


%%
% :MM:__THREAD:Disable
%
% PUSHJ
%   no arguments
%   no return values
%
            .global :MM:__THREAD:Disable
Disable     NEG         $1,0,1
            LDA         $0,:MM:__THREAD:interval
            STO         $1,$0
            PUT         :rI,$1
            POP         0


%%
% :MM:__THREAD:ThreadID
%
% PUSHJ
%   no arguments
%   retm - ThreadID
%
% :MM:__THREAD:ThreadIDG
%
% PUSHJ %255
%
            .global :MM:__THREAD:ThreadID
            .global :MM:__THREAD:ThreadIDG
ThreadID    LDA         $0,:MM:__INTERNAL:ThreadRing
            LDO         $0,$0
            LDO         $0,$0
            POP         1,0
ThreadIDG   LDA         t,:MM:__INTERNAL:ThreadRing
            LDO         t,t
            LDO         t,t
            POP         0


%%
% :MM:__THREAD:Clone
%
% PUSHJ
%   no arguments
%   retm - ThreadID of new thread
%
            .global :MM:__THREAD:Clone
            .global :MM:__THREAD:CloneG
Clone       SWYM
            % Disable timer and TRIP:
            GET         $0,:rI
            BN          $0,1F
            NEG         $0,0,1
            PUT         :rI,$0
            SWYM
            % We should be safe now™
1H          TRIP        0,:MM:__INTERNAL:Clone,0
            GET         $0,:rY
            POP         1,0
CloneG      GET         $0,:rJ
            PUSHJ       $1,Clone
            PUT         :rJ,$0
            SET         t,$1
            POP         0,0


%%
% :MM:__THREAD:Yield
%
% PUSHJ
%   no arguments
%   no return values
%
            .global :MM:__THREAD:Yield
Yield       SWYM
            % Disable timer and TRIP:
            GET         $0,:rI
            BN          $0,1F
            NEG         $0,0,1
            PUT         :rI,$0
            SWYM
            % We should be safe now™
1H          TRIP        0,:MM:__INTERNAL:Yield,0
            POP         0
