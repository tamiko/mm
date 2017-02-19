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
% Assemble __file.mmh
%

#ifndef __GNU_AS
#error Tried to assemble __gnu_as_data_segment.mms with foreign assembler.
#endif

            .section .data,"wa",@progbits
            .balign 8
            PREFIX      :MM:__FILE:
Pool        BYTE        #EE,#EE,#EE
            .fill 253*1
            .global :MM:__FILE:Pool

            .section .text,"ax",@progbits
#define __MM_INTERNAL
#include <mm/__internal/__file.mmh>
            .global :MM:__FILE:LockJ
            .global :MM:__FILE:LockG
            .global :MM:__FILE:Lock
            .global :MM:__FILE:UnlockJ
            .global :MM:__FILE:UnlockG
            .global :MM:__FILE:Unlock
            .global :MM:__FILE:OpenJ
            .global :MM:__FILE:Open
            .global :MM:__FILE:CloseJ
            .global :MM:__FILE:CloseG
            .global :MM:__FILE:Close
            .global :MM:__FILE:IsOpenJ
            .global :MM:__FILE:IsOpenG
            .global :MM:__FILE:IsOpen
            .global :MM:__FILE:IsReadableJ
            .global :MM:__FILE:IsReadableG
            .global :MM:__FILE:IsReadable
            .global :MM:__FILE:IsWritableJ
            .global :MM:__FILE:IsWritableG
            .global :MM:__FILE:IsWritable
            .global :MM:__FILE:ReadJ
            .global :MM:__FILE:Read
