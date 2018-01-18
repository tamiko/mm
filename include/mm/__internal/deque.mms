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

            .macro      Deque:__SAVE_REGISTERS
            GET         :MM:__INTERNAL:__t1,:rJ
            SET         :MM:__INTERNAL:__t2,:$255
            .endm

            .macro      Deque:__RESTORE_REGISTERS
            PUT         :rJ,:MM:__INTERNAL:__t1
            SET         :MM:__INTERNAL:__t1,$255
            SET         $255,:MM:__INTERNAL:__t2
            CMP         :MM:__INTERNAL:__t1,:MM:__INTERNAL:__t1,#0
            BZ          :MM:__INTERNAL:__t1,@+#8
            .endm

            %
            %         ptr to next
            %         ptr to previous
            % ptr --> DATA
            %

            .macro      Deque:__PUSH front back size side=0
            Deque:__SAVE_REGISTERS
            BNZ         \front,__1h_dpu\@
            % sanity check: both registers must be #0:
            BNZ         \back,__er_dpu\@
            % initialize:
            SET         $255,\size
            ADDU        $255,$255,#10
            PUSHJ       $255,:MM:__HEAP:AllocG
            STO         $255,$255,#00
            STO         $255,$255,#08
            ADDU        $255,$255,#10
            SET         \front,$255
            SET         \back,$255
            SET         $255,#0
            JMP         __er_dpu\@+#4
            % sanity check: both registers must hold a valid memory address:
__1h_dpu\@  SET         $255,\front
            SUBU        $255,$255,#10
            PUSHJ       $255,:MM:__HEAP:ValidG
            BN          $255,__er_dpu\@
            SET         $255,\back
            SUBU        $255,$255,#10
            PUSHJ       $255,:MM:__HEAP:ValidG
            BN          $255,__er_dpu\@

            SET         $255,\size
            ADDU        $255,$255,#10
            PUSHJ       $255,:MM:__HEAP:AllocG
            SUBU        \front,\front,#10
            SUBU        \back,\back,#10
            STO         \back,$255,#08
            STO         \front,$255,#00
            STO         $255,\front,#08
            STO         $255,\back,#00
            .if \side
            SET         \front,$255
            .else
            SET         \back,$255
            .endif
            ADDU        \front,\front,#10
            ADDU        \back,\back,#10
            SET         $255,#0
            JMP         @+#8
__er_dpu\@  NEG         $255,0,1
            Deque:__RESTORE_REGISTERS
            .endm

            .macro      Deque:PushFront front back size
            Deque:__PUSH \front,\back,\size,1
            .endm

            .macro      Deque:PushBack front back size
            Deque:__PUSH \front,\back,\size,0
            .endm


            .macro      Deque:__POP front back side=0
            Deque:__SAVE_REGISTERS
            % sanity check: both registers must hold a valid memory address:
            SET         $255,\front
            SUBU        $255,$255,#10
            PUSHJ       $255,:MM:__HEAP:ValidG
            BN          $255,__er_dpo\@
            SET         $255,\back
            SUBU        $255,$255,#10
            PUSHJ       $255,:MM:__HEAP:ValidG
            BN          $255,__er_dpo\@
            CMP         $255,\front,\back
            BNZ         $255,__1h_dpo\@
            SET         $255,\front
            SUBU        $255,$255,#10
            PUSHJ       $255,:MM:__HEAP:DeallocG
            SET         \front,#0
            SET         \back,#0
            SET         $255,#0
            JMP         __er_dpo\@+#4
__1h_dpo\@  SUBU        \front,\front,#10
            SUBU        \back,\back,#10
            .if \side
            SET         $255,\front
            LDO         \front,\front,#00
            .else
            SET         $255,\back
            LDO         \back,\back,#08
            .endif
            PUSHJ       $255,:MM:__HEAP:DeallocG
            STO         \front,\back,#00
            STO         \back,\front,#08
            ADDU        \front,\front,#10
            ADDU        \back,\back,#10
            SET         $255,#0
            JMP         @+#8
__er_dpo\@  NEG         $255,0,1
            Deque:__RESTORE_REGISTERS
            .endm

            .macro      Deque:PopFront front back
            Deque:__POP \front,\back,1
            .endm

            .macro      Deque:PopBack front back
            Deque:__POP \front,\back,0
            .endm
