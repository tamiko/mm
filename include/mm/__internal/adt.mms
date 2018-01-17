%%
% MMIX support library for various purposes.
%
% Copyright (C) 2013-2017 Matthias Maier <tamiko@kyomu.43-1.org>
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

            .macro      __SAVE_REGISTERS
            GET         :MM:__ADT:__t1,:rJ
            SET         :MM:__ADT:__t2,:$255
            .endm

            .macro      __RESTORE_REGISTERS
            PUT         :rJ,:MM:__ADT:__t1
            SET         $255,:MM:__ADT:__t2
            .endm


            .macro      Stack:Push register size
            __SAVE_REGISTERS
            SET         $255,\size
            ADDU        $255,$255,#8
            PUSHJ       $255,:MM:__HEAP:AllocG
            STO         \register,$255,#0
            ADDU        $255,$255,#8
            SET         \register,$255
            __RESTORE_REGISTERS
            JMP         @+#8
            .endm


            .macro      Stack:Pop register
            __SAVE_REGISTERS
            SET         $255,\register
            SUBU        $255,$255,#8
            PUSHJ       $255,:MM:__HEAP:ValidG
            BZ          $255,@+#10
            __RESTORE_REGISTERS
            JMP         @+#24
            SET         $255,\register
            SUBU        $255,$255,#8
            SUBU        \register,\register,#8
            LDO         \register,\register
            PUSHJ       $255,:MM:__HEAP:DeallocG
            __RESTORE_REGISTERS
            JMP         @+#8
            .endm


