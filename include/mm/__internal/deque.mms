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

            %
            % Save and restore registers
            %

            .macro      Deque:__SAVE_REGISTERS
            GET         :MM:__INTERNAL:__t1,:rJ
            SET         :MM:__INTERNAL:__t2,:MM:t
            SET         :MM:__INTERNAL:__t3,:$255
            .endm

            .macro      Deque:__RESTORE_REGISTERS
            PUT         :rJ,:MM:__INTERNAL:__t1
            SET         :MM:t,:MM:__INTERNAL:__t2
            SET         :MM:__INTERNAL:__t1,$255
            SET         $255,:MM:__INTERNAL:__t3
            BZ          :MM:__INTERNAL:__t1,@+#8
            .endm

            % We store a closed, double-linked list:
            %
            %         ptr to next
            %         ptr to previous
            % ptr --> DATA
            %

            %
            % The push operation:
            %

            .macro      Deque:__PUSH front back size side=0
            Deque:__SAVE_REGISTERS
            BNZ         \front,__1h_dpu\@
            % sanity check: both registers must be #0:
            BNZ         \back,__er_dpu\@
            % initialize:
            SET         :MM:t,\size
            ADDU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:AllocG
            STO         :MM:t,:MM:t,#00
            STO         :MM:t,:MM:t,#08
            ADDU        :MM:t,:MM:t,#10
            SET         \front,:MM:t
            SET         \back,:MM:t
            SET         $255,#0 % successful return
            JMP         __er_dpu\@+#4
            % sanity check: both registers must hold a valid memory address:
__1h_dpu\@  SET         :MM:t,\front
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dpu\@
            SET         :MM:t,\back
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dpu\@
            SET         :MM:t,\size
            ADDU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:AllocG
            SUBU        \front,\front,#10
            SUBU        \back,\back,#10
            STO         \back,:MM:t,#08
            STO         \front,:MM:t,#00
            STO         :MM:t,\front,#08
            STO         :MM:t,\back,#00
            .if \side
            SET         \front,:MM:t
            .else
            SET         \back,:MM:t
            .endif
            ADDU        \front,\front,#10
            ADDU        \back,\back,#10
            SET         $255,#0
            JMP         __er_dpu\@+#4
__er_dpu\@  NEG         $255,0,1
            Deque:__RESTORE_REGISTERS
            .endm

            .macro      Deque:PushF front back size
            Deque:__PUSH \front,\back,\size,1
            .endm

            .macro      Deque:PushB front back size
            Deque:__PUSH \front,\back,\size,0
            .endm

            %
            % The pop operation:
            %

            .macro      Deque:__POP front back side=0
            Deque:__SAVE_REGISTERS
            % sanity check: both registers must hold a valid memory address:
            SET         :MM:t,\front
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dpo\@
            SET         :MM:t,\back
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dpo\@
            % special case: last element
            CMP         :MM:t,\front,\back
            BNZ         :MM:t,__1h_dpo\@
            SET         :MM:t,\front
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:DeallocG
            SET         \front,#0
            SET         \back,#0
            SET         $255,#0
            JMP         __er_dpo\@+#4 % successful return
__1h_dpo\@  SUBU        \front,\front,#10
            SUBU        \back,\back,#10
            .if \side
            SET         :MM:t,\front
            LDO         \front,\front,#00
            .else
            SET         :MM:t,\back
            LDO         \back,\back,#08
            .endif
            PUSHJ       :MM:t,:MM:__HEAP:DeallocG
            STO         \front,\back,#00
            STO         \back,\front,#08
            ADDU        \front,\front,#10
            ADDU        \back,\back,#10
            SET         $255,#0
            JMP         @+#8
__er_dpo\@  NEG         $255,0,1
            Deque:__RESTORE_REGISTERS
            .endm

            .macro      Deque:PopF front back
            Deque:__POP \front,\back,1
            .endm

            .macro      Deque:PopB front back
            Deque:__POP \front,\back,0
            .endm

            %
            % The size operation:
            %

            .macro      Deque:__SIZE front back result side=0
            Deque:__SAVE_REGISTERS
            % sanity check: both registers must hold a valid memory address:
            .if \side
            SET         :MM:t,\front
            .else
            SET         :MM:t,\back
            .endif
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dsi\@
            .if \side
            SET         :MM:t,\front
            .else
            SET         :MM:t,\back
            .endif
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:SizeG
            SUBU        \result,:MM:t,#10
            .if \result==":MM:t"
            SET         :MM:__INTERNAL:__t2,:MM:t
            .endif
            .if \result=="$255"
            SET         :MM:__INTERNAL:__t3,:MM:t
            .endif
            SET         $255,#0
            JMP         @+#8
__er_dsi\@  NEG         $255,0,1
            Deque:__RESTORE_REGISTERS
            .endm

            .macro      Deque:SizeF front back result
            Deque:__SIZE \front,\back,\result,1
            .endm

            .macro      Deque:SizeB front back result
            Deque:__SIZE \front,\back,\result,0
            .endm

            %
            % The save operation:
            %

            .macro      Deque:Store front back label
            Deque:__SAVE_REGISTERS
            % sanity check: both registers must hold a valid memory address:
            SET         :MM:t,\front
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dst\@
            SET         :MM:t,\back
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dst\@
            % save front element at label:
            SUBU        \front,\front,#10
            GETA        :MM:t,\label
            STO         \front,:MM:t,0
            SET         \front,#0
            SET         \back,#0
            SET         $255,#0
            JMP         @+#8
__er_dst\@  NEG         $255,0,1
            Deque:__RESTORE_REGISTERS
            .endm

            %
            % The load operation:
            %

            .macro      Deque:Load front back label
            Deque:__SAVE_REGISTERS
            % sanity check: M8[label] must hold a valid memory address
            GETA        :MM:t,\label
            LDO         :MM:t,:MM:t,#0
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dlo\@
            GETA        :MM:t,\label
            LDO         :MM:t,:MM:t,#0
            LDO         :MM:t,:MM:t,#8 % back element
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dlo\@
            % save deque structure in front and back registers:
            GETA        :MM:t,\label
            LDO         :MM:t,:MM:t,#0
            ADDU        \front,:MM:t,#10
            LDO         :MM:t,:MM:t,#8 % back element
            ADDU        \back,:MM:t,#10
            SET         $255,#0
            JMP         @+#8
__er_dlo\@  NEG         $255,0,1
            Deque:__RESTORE_REGISTERS
            .endm

            %
            % The check operation:
            %

            .macro      Deque:Check front back
            Deque:__SAVE_REGISTERS
            % Check that both registers hold a valid memory address
            SET         :MM:t,\front
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dch\@
            SET         :MM:t,\back
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dch\@
            SET         $255,#0
            JMP         @+#8
__er_dch\@  NEG         $255,0,1
            Deque:__RESTORE_REGISTERS
            .endm

            %
            % The adv/rew operations:
            %

            .macro      Deque:__ADVANCE front back side=0
            Deque:__SAVE_REGISTERS
            % sanity check: both registers must hold a valid memory address:
            SET         :MM:t,\front
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dav\@
            SET         :MM:t,\back
            SUBU        :MM:t,:MM:t,#10
            PUSHJ       :MM:t,:MM:__HEAP:ValidG
            BN          :MM:t,__er_dav\@
            % save front element at label:
            .if \side
            SET         \back,\front
            SUBU        \front,\front,#10
            LDO         \front,\front,#0 % next
            ADDU        \front,\front,#10
            .else
            SET         \front,\back
            SUBU        \back,\back,#10
            LDO         \back,\back,#8 % previous
            ADDU        \back,\back,#10
            .endif
            SET         $255,#0
            JMP         @+#8
__er_dav\@  NEG         $255,0,1
            Deque:__RESTORE_REGISTERS
            .endm

            .macro      Deque:adv front back
            Deque:__ADVANCE \front,\back,1
            .endm

            .macro      Deque:rew front back
            Deque:__ADVANCE \front,\back,0
            .endm

