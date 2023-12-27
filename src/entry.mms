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
            % Set the beginning of the .text section to #00. The first
            % instructions assembled into the .text section are the entry
            % point for trip handlers and program startup.
            %

            .set __.MMIX.start..text,#00
            .global __.MMIX.start..text

            %
            % Register :MM:__INTERNAL:TripHandler,
            % :MM:__INTERNAL:ExcHandler and :MM:__INIT:__init.
            %
            % We have to make sure to preserve the exact current state
            % before we make a near/far jump to the TripHandler or init
            % section. A far jump will globber global register $255, thus
            % we have to do the following PUSHJ/JMP dance with the help of
            % a (near) trampoline section.
            %
            % Furthermore, let us explicitly assemble all returns here -
            % this is very convenient for setting breakpoints.
            %

            .section .data,"wa",@progbits
            .align 4
            PREFIX      :MM:__INIT:
InitString  BYTE "__mm_init_worker",0

            .section .init,"ax",@progbits
            .global :MM:__INIT:__entry
            .global :MM:__INIT:__trampoline
            PREFIX      :MM:__INIT:
            .org #000    % H TRIP command / rI timer
__entry     PUSHJ       $255,1F
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #010    % D "integer divide check"
            PUSHJ       $255,2F
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #020    % V "integer overflow"
            PUSHJ       $255,2F
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #030    % W "float-to-fix overflow"
            PUSHJ       $255,2F
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #040    % I "floating invalid operation"
            PUSHJ       $255,2F
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #050    % O "floating overflow"
            PUSHJ       $255,2F
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #060    % U "floating underflow"
            PUSHJ       $255,2F
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #070    % Z "floating division by zero"
            PUSHJ       $255,2F
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #080    % X "floating inexact"
            PUSHJ       $255,2F
            PUT         :rJ,$255
            GET         $255,:rB
            RESUME
            .org #0F0    % entry point
            JMP         3F

__t1        IS     :MM:__INTERNAL:__t1
__t2        IS     :MM:__INTERNAL:__t2
__t3        IS     :MM:__INTERNAL:__t3
            .org #100
__trampoline SWYM
            % Prepare (possible) far jump:
1H          GET         $0,:rW
            SET         $1,$255
            SET         $2,:MM:t
            JMP         :MM:__INTERNAL:TripHandler

            % Prepare (possible) far jump:
2H          GET         $0,:rW
            SET         $1,$255
            SET         $2,:MM:t
            JMP         :MM:__INTERNAL:ExcHandler

3H          SWYM
            %
            % Prepare entry into Main. Eventually we will RESUME (and
            % actually start the program) with the resume sequence:
            %   PUT :rJ,$255
            %   GET $255,:rW
            %   RESUME
            %
            PUT         :rW,$255   % RESUME at Main
            PUT         :rB,$255   % keep address of Main in $255
            SETML       $255,#F700
            PUT         :rX,$255
            SET         $255,#0
            %
            % Hide __mm_init_worker parameter if supplied. This is a bit
            % tricky - let us use only :MM:t, and the internal registers for
            % this purpose:
            %
            SET         __t1,#1
            CMP         __t1,$0,__t1
            BZ          __t1,4F % only one parameter, nothing to do
            GETA        __t3,InitString
            % Compare first 8 bytes:
            LDO         __t2,__t3,0
            LDO         __t1,$1,#8
            LDO         __t1,__t1,0
            CMP         __t1,__t1,__t2
            BNZ         __t1,4F % first OCTA is different from "__mm_ini"
            % Compare next 8 bytes:
            LDO         __t2,__t3,#8
            LDO         __t3,$1,#8
            LDO         __t1,__t3,#8
            CMP         __t1,__t1,__t2
            BNZ         __t1,4F % second OCTA is different from "t_worker"
            % store special parameter at :MM:__SYS_:WorkerDirec
            GETA        __t2,:MM:__SYS:WorkerDirec
            STO         __t3,__t2,0
            % Hide first command line argument:
            SUBU        $0,$0,1
            % Clean up addresses:
            LDO         __t1,$1,#0
            STO         __t1,$1,#8
            ADDU        $1,$1,#8
            %
            % Clean up, save initial state, and store stack address in $0
            %
4H          SET         __t1,#0
            SET         __t2,#0
            SET         __t3,#0
            SAVE        $255,0
            SET         $0,$255
            %
            % Make a near/far jump to the init section
            %
            JMP         :MM:__INIT:__init

