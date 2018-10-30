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

#include "statistics.mmh"

            %
            % Thread entry data structure (double-linked list):
            %
            %    ptr -> OCTA  Thread ID
            %           OCTA  State (#0..00 run, #0..FF sleep, #0..EE new)
            %           OCTA  pointer to previous
            %           OCTA  pointer to next
            %           OCTA  pointer to stack image
            %           OCTA  UNSAVE address
            %

            .section .data,"wa",@progbits
            .global     :MM:__INTERNAL:ThreadRing
            .global     :MM:__INTERNAL:ThreadTmpl
            PREFIX      :MM:__INTERNAL:
__buffer    OCTA        #0000000000000000
__next_id   OCTA        #0000000000000001
ThreadRing  OCTA        #0000000000000000 % pointer to active thread
ThreadTmpl  OCTA        #0000000000000000 % pointer to stack image
            OCTA        #0000000000000000 % UNSAVE address

            %%
            % Initialize thread structures
            %
            % Create a single entry for the main thread that will
            % eventually start executing at the Main label. Further, save a
            % pristine thread image at ThreadTmpl for the Thread:Create
            % call.
            %

            .section .data,"wa",@progbits
            PREFIX :MM:__INTERNAL:STRS:
InitError   BYTE        "Fatal initialization error.",10,0

            .section .text,"ax",@progbits
            .global :MM:__INTERNAL:Initialize
            PREFIX      :MM:__INTERNAL:
Stack_Segment IS        :Stack_Segment

            % :MM:t contains the address of the initial SAVE
Initialize  GET         $0,:rJ
            GETA        $1,Stack_Segment
            SUBU        $2,:MM:t,$1
            ADDU        $2,$2,#8
            SET         $4,$2
            PUSHJ       $3,:MM:__POOL:AllocJ
            JMP         9F
            SET         $5,$1
            SET         $6,$3
            SET         $7,$2
            SET         $1,:MM:t % __MEM:CopyJ globbers t
            PUSHJ       $4,:MM:__MEM:CopyJ
            JMP         9F
            GETA        $255,:MM:__INTERNAL:ThreadTmpl
            STO         $3,$255,#0
            STO         $1,$255,#8
            SET         $5,#30
            PUSHJ       $4,:MM:__POOL:AllocJ
            JMP         9F
            XOR         $5,$5,$5
            STO         $5,$4,#00 % Thread ID: 0
            STO         $5,$4,#08 % State: running
            STO         $4,$4,#10
            STO         $4,$4,#18
            NEG         $5,0,1
            STO         $5,$4,#20
            STO         $5,$4,#28
            GETA        $6,:MM:__INTERNAL:ThreadRing
            STO         $4,$6
            PUT         :rJ,$0
            POP         0,0
9H          GETA        $1,:MM:__INTERNAL:STRS:InitError
            PUSHJ       $0,:MM:__ERROR:IError1



            %%
            %
            % The glorious trip handler
            %

            .section .data,"wa",@progbits
            PREFIX      :MM:__INTERNAL:STRS:
            .balign 4
Unhandled   BYTE        "Unhandled TRIP. :-(\n",0
            .balign 4
DoubleTrip  BYTE        "Double TRIP detected! Lost return context :-(\n",0
            .balign 4
SwitchError BYTE        "Fatal error during context switch. :-(\n",0

            .section .text,"ax",@progbits
            .global :MM:__INTERNAL:TripHandler
            PREFIX      :MM:__INTERNAL:

Yield       IS          #00
Create      IS          #D0
Clone       IS          #E0
Exit        IS          #F0

            %
            % The trampoline already populated $0, $1, $2 with the contents
            % of :rW, $255 and :MM:t, respectively.
            %
TripHandler SAVE        $255,0
            SET         $0,$255
            STORE_SPECIAL :rU,:MM:__STATISTICS:__buffer
            INCREMENT_COUNTER :MM:__STATISTICS:ThreadTripH
            %
            % Determine whether we got tripped by the timer callback
            % (rX=#8000000000000000), or by an explicit TRIP
            % (rX=#80000000FF00XXXX).
            %
            GET         $3,:rX
            ANDNH       $3,#F000
            BZ          $3,1F % timer interrupt
            ANDNL       $3,#FFFF
            ANDNML      $3,#00FF
            SETML       $4,#FF00
            CMPU        $3,$3,$4
            BZ          $3,1F % explicit TRIP
            GETA        $1,:MM:__INTERNAL:STRS:Unhandled
            PUSHJ       $0,:MM:__ERROR:IError1
1H          GET         $3,:rX
            SRU         $3,$3,8
            AND         $3,$3,#FF
            CMP         $4,$3,Yield
            BZ          $4,__yield
            CMP         $4,$3,Create
            BZ          $4,__create
            CMP         $4,$3,Clone
            BZ          $4,__clone
            CMP         $4,$3,Exit
            BZ          $4,__exit
            GETA        $1,:MM:__INTERNAL:STRS:Unhandled
            PUSHJ       $0,:MM:__ERROR:IError1

            %
            % Exit:
            %

__exit      GETA        $1,Stack_Segment
            GETA        $4,:MM:__INTERNAL:ThreadRing
            LDO         $4,$4
            LDO         $5,$4,#10 % previous
            LDO         $6,$4,#18 % next
            % if this is the last thread context, call exit:
            CMP         $7,$4,$5
            BNZ         $7,1F
            PUSHJ       $255,:MM:__SYS:Exit
1H          SET         $8,$4
            PUSHJ       $7,:MM:__POOL:DeallocJ
            JMP         __fatal
            STO         $5,$6,#10
            STO         $6,$5,#18
            SET         $4,$6
1H          JMP         __unsave

            %
            % Yield:
            %

__yield     GETA        $1,Stack_Segment
            SUBU        $2,$0,$1
            ADDU        $2,$2,#8
            SET         $4,$2
            PUSHJ       $3,:MM:__POOL:AllocJ
            JMP         __fatal
            SET         $5,$1
            SET         $6,$3
            SET         $7,$2
            PUSHJ       $4,:MM:__MEM:CopyJ
            JMP         __fatal
            GETA        $4,:MM:__INTERNAL:ThreadRing
            LDO         $4,$4
            LDO         $5,$4,#08
            SET         $6,#0000
            CMP         $5,$5,$6 % make sure we are in running state
            BNZ         $5,__fatal
            SET         $5,#00FF
            STO         $5,$4,#08 % state
            STO         $3,$4,#20 % stack image
            STO         $0,$4,#28 % UNSAVE address
            LDO         $4,$4,#18

__unsave    SWYM
            INCREMENT_COUNTER :MM:__STATISTICS:ThreadSwitc
            GETA        $5,:MM:__INTERNAL:ThreadRing
            STO         $4,$5
            LDO         $5,$4,#08
            SET         $6,#00EE % new
            CMP         $6,$5,$6
            BZ          $6,__new
            SET         $6,#00FF % sleep
            CMP         $6,$5,$6
            BNZ         $6,__fatal
            STO         $6,$4,#08 % set state to #0000
            LDO         $0,$4,#28
            NEG         $5,0,1
            STO         $5,$4,#28
            % Overwrite stack:
            LDO         $3,$4,#20
            SUBU        $2,$0,$1
1H          LDO         $255,$3,$2
            STO         $255,$1,$2
            SUBU        $2,$2,#8
            BNN         $2,1B
            % We have to UNSAVE in order to get :rO and :rS into a valid
            % state (matching the new register stack)
            UNSAVE      0,$0
            GETA        $3,:MM:__INTERNAL:ThreadRing
            LDO         $3,$3
            LDO         $5,$3,#20
            GET         $3,:rJ
            PUSHJ       $4,:MM:__POOL:DeallocJ
            JMP         __fatal
            PUT         :rJ,$3
            NEG         $4,0,1
            STO         $4,$3,#20
            % make sure :rY is set to zero
            SET         $255,#0000
            PUT         :rY,$255
            JMP         __return

            %
            % Create:
            %

__create    GET         $3,:rZ
            % Create new list entry:
            SET         $5,#30
            PUSHJ       $4,:MM:__POOL:AllocJ
            JMP         __fatal
            % Thread ID:
            GETA        $5,:MM:__INTERNAL:__next_id
            LDO         $6,$5
            STO         $6,$4,#00
            ADDU        $6,$6,1
            STO         $6,$5
            % State:
            SET         $5,#EE % new
            STO         $5,$4,#08
            % Stack image:
            NEG         $5,0,1
            STO         $5,$4,#20 %
            STO         $3,$4,#28 % entry point for new thread
            % Update pointers:
            GETA        $5,:MM:__INTERNAL:ThreadRing
            LDO         $5,$5
            LDO         $6,$5,#18
            STO         $5,$4,#10
            STO         $6,$4,#18
            STO         $4,$5,#18
            STO         $4,$6,#10
            UNSAVE      0,$0
            % store the thread ID of the new process in :rY
            GETA        $255,:MM:__INTERNAL:ThreadRing
            LDO         $255,$255
            LDO         $255,$255,#18
            LDO         $255,$255
            PUT         :rY,$255
            JMP         __return

            %
            % Clone:
            %

__clone     GETA        $1,Stack_Segment
            SUBU        $2,$0,$1
            ADDU        $2,$2,#8
            SET         $4,$2
            PUSHJ       $3,:MM:__POOL:AllocJ
            JMP         __fatal
            SET         $5,$1
            SET         $6,$3
            SET         $7,$2
            PUSHJ       $4,:MM:__MEM:CopyJ
            JMP         __fatal
            % Create new list entry:
            SET         $5,#30
            PUSHJ       $4,:MM:__POOL:AllocJ
            JMP         __fatal
            % Thread ID:
            GETA        $5,:MM:__INTERNAL:__next_id
            LDO         $6,$5
            STO         $6,$4,#00
            ADDU        $6,$6,1
            STO         $6,$5
            % State:
            SET         $5,#FF % sleep
            STO         $5,$4,#08
            % Update pointers:
            GETA        $5,:MM:__INTERNAL:ThreadRing
            LDO         $5,$5
            LDO         $6,$5,#18
            STO         $5,$4,#10
            STO         $6,$4,#18
            STO         $4,$5,#18
            STO         $4,$6,#10
            % stack image:
            STO         $3,$4,#20 % stack image
            STO         $0,$4,#28 % UNSAVE address
            UNSAVE      0,$0
            % store the thread ID of the clone in :rY
            GETA        $255,:MM:__INTERNAL:ThreadRing
            LDO         $255,$255
            LDO         $255,$255,#18
            LDO         $255,$255
            PUT         :rY,$255
            JMP         __return

            %
            % Return to user context:
            %

__return    SWYM
            % check whether we double tripped:
            GET         $3,:rW
            CMPU        $3,$0,$3
            BZ          $3,1F
            GETA        $1,:MM:__INTERNAL:STRS:DoubleTrip
            PUSHJ       $0,:MM:__ERROR:IError1
1H          SET         $255,$1
            SET         :MM:t,$2
            %
            % reenable timer - we have to take into account that leaving
            % the context (POP, SET, PUT, RESUME) will advance the clock by
            % #000B. So increase the timer by that value.
            %
            GETA        $2,:MM:__THREAD:interval
            LDO         $2,$2
            STORE_DIFFERENCE :rU,:MM:__STATISTICS:__buffer,:MM:__STATISTICS:TimingTripH
            BN          $2,1F
            ADDU        $2,$2,#000B
            PUT         :rI,$2
1H          POP 0

            %
            % In order to spawn a new thread (created with "Create") we
            % cannot simply return from a TRIP handler context (we cannot
            % POP from the stack, etc. etc.).
            %

__new       SWYM
            % Set state to #0000:
            SET         $6,#0000
            STO         $6,$4,#08
            % Store entry address in internal buffer:
            GETA        $7,:MM:__INTERNAL:__buffer
            LDO         $6,$4,#28
            STO         $6,$7
            NEG         $6,0,1
            STO         $6,$4,#28
            GETA        $4,:MM:__INTERNAL:ThreadTmpl
            LDO         $3,$4,#0
            LDO         $0,$4,#8
            % Overwrite stack:
            SUBU        $2,$0,$1
1H          LDO         $255,$3,$2
            STO         $255,$1,$2
            SUBU        $2,$2,#8
            BNN         $2,1B
            % We have to take statistics a bit prematurely:
            STORE_DIFFERENCE :rU,:MM:__STATISTICS:__buffer,:MM:__STATISTICS:TimingTripH
            % UNSAVE to get a valid context:
            UNSAVE      0,$0
            %
            % Store old entry address in :rJ
            %
            GET         $255,:rW
            PUT         :rJ,$255
            %
            % Set new entry address (make sure to not use a local register
            % for that...)
            %
            GETA        $255,:MM:__INTERNAL:__buffer
            LDO         $255,$255
            PUT         :rW,$255
            %
            % reenable timer - we have to take into account that leaving
            % the context (PUT, GET, RESUME) will advance the clock by
            % #0005. So increase the timer by that value.
            %
            GETA        $255,:MM:__THREAD:interval
            LDO         $255,$255
            BN          $255,1F
            ADDU        $255,$255,#0005
            PUT         :rI,$255
1H          GET         $255,:rW
            RESUME

__fatal     GETA        $1,:MM:__INTERNAL:STRS:SwitchError
            PUSHJ       $0,:MM:__ERROR:IError1
