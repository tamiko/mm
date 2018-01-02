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
% Assemble __sys.mmh
%

#ifndef __GNU_AS
#error Tried to assemble __gnu_as_data_segment.mms with foreign assembler.
#endif

            .section .data,"wa",@progbits
            .balign 8
            PREFIX      :MM:__SYS:
AtExitAddr  OCTA        #0000000000000000
AtAbortAddr OCTA        #0000000000000000
AtErrorAddr OCTA        #0000000000000000
            .global :MM:__SYS:AtExitAddr
            .global :MM:__SYS:AtAbortAddr
            .global :MM:__SYS:AtErrorAddr

            .section .text,"ax",@progbits
#define __MM_INTERNAL
#include <mm/__internal/__sys.mmh>
            .global :MM:__SYS:Exit
            .global :MM:__SYS:Abort
            .global :MM:__SYS:AtExit
            .global :MM:__SYS:AtExitG
            .global :MM:__SYS:AtAbort
            .global :MM:__SYS:AtAbortG
            .global :MM:__SYS:AtError
            .global :MM:__SYS:AtErrorG
