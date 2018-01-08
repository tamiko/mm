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
            % Set up an internal buffer used for various purposes
            %

            .section .data,"wa",@progbits
            .global :MM:__INTERNAL:Buffer
            PREFIX      :MM:__INTERNAL:
Buffer      IS          @
            .fill 128*8


            %
            % Arithmetic exception handler
            %

            .section .data,"wa",@progbits
            PREFIX      :MM:__INTERNAL:STRS:
NotImplem   BYTE        "Arithmetic exception handler not implemented.\n",0

            .section .text,"ax",@progbits
            .global :MM:__INTERNAL:ExcHandler
            PREFIX      :MM:__INTERNAL:
ExcHandler  SWYM
            SET         $0,$255
            GET         $1,:rJ
            % We do not handle arithmetic exceptions at the moment.
            LDA         $1,:MM:__INTERNAL:STRS:Unhandled
            PUSHJ       $0,:MM:__ERROR:IError1 % does not return


            %
            % Thread entry data structure (double-linked list):
            %
            %    ptr -> OCTA  Thread ID
            %           OCTA  State (#0..00 run, #0..FF sleep)
            %           OCTA  pointer to previous
            %           OCTA  pointer to next
            %           OCTA  pointer to stack image
            %           OCTA  UNSAVE address
            %

            .section .data,"wa",@progbits
            .global     :MM:__INTERNAL:ThreadRing
            .global     :MM:__INTERNAL:ThreadTmpl
            PREFIX      :MM:__INTERNAL:
NextID      OCTA        #0000000000000001
ThreadRing  OCTA        #0000000000000000 % pointer to active thread
ThreadTmpl  OCTA        #0000000000000000 % pointer to stack image
            OCTA        #0000000000000000 % UNSAVE address


            %
            % The glorious trip handler
            %

            .section .data,"wa",@progbits
            PREFIX      :MM:__INTERNAL:STRS:
Unhandled   BYTE        "Unhandled TRIP.\n",0
DoubleTrip  BYTE        "Double TRIP detected! Lost return context :-(\n",0
SwitchError BYTE        "Fatal error during context switch.",10,0
Tripped     BYTE        "Tripped! :-)\n",0

            .section .text,"ax",@progbits
            .global :MM:__INTERNAL:Yield
            .global :MM:__INTERNAL:Create
            .global :MM:__INTERNAL:Clone
            .global :MM:__INTERNAL:Exit
            .global :MM:__INTERNAL:TripHandler
            PREFIX      :MM:__INTERNAL:

Stack_Segment IS        :Stack_Segment
Yield       IS          #00
Create      IS          #D0
Clone       IS          #E0
Exit        IS          #F0

9H          LDA         $1,:MM:__INTERNAL:STRS:SwitchError
            PUSHJ       $0,:MM:__ERROR:IError1
TripHandler GET         $2,:rW
            GET         $1,:rJ
            SET         $0,$255
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
            LDA         $1,:MM:__INTERNAL:STRS:Unhandled
            PUSHJ       $0,:MM:__ERROR:IError1
1H          GET         $3,:rX
            SRU         $3,$3,8
            AND         $3,$3,#FF
            CMP         $4,$3,Yield
            BZ          $4,DoYield
            CMP         $4,$3,Create
            BZ          $4,DoCreate
            CMP         $4,$3,Clone
            BZ          $4,DoClone
            CMP         $4,$3,Exit
            BZ          $4,DoExit
            LDA         $1,:MM:__INTERNAL:STRS:Unhandled
            PUSHJ       $0,:MM:__ERROR:IError1

            %
            % Yield:
            %

DoYield     SAVE        $255,0
            SET         $0,$255
            LDA         $1,Stack_Segment
            SUBU        $2,$0,$1
            ADDU        $2,$2,#8
            SET         $4,$2
            PUSHJ       $3,:MM:__HEAP:AllocJ
            JMP         9B
            SET         $5,$1
            SET         $6,$3
            SET         $7,$2
            PUSHJ       $4,:MM:__MEM:CopyJ
            JMP         9B
            LDA         $4,:MM:__INTERNAL:ThreadRing
            LDO         $4,$4
            LDO         $5,$4,#08
            SET         $6,#0000
            CMP         $5,$5,$6 % make sure we are in running state
            BNZ         $5,9B
            SET         $5,#00FF
            STO         $5,$4,#08 % state
            STO         $3,$4,#20 % stack image
            STO         $0,$4,#28 % UNSAVE address
            LDO         $4,$4,#18
            LDA         $5,:MM:__INTERNAL:ThreadRing
            STO         $4,$5
            LDO         $5,$4,#08
            SET         $6,#00FF
            CMP         $5,$5,$6
            BNZ         $5,9B
            STO         $5,$4,#08 % state
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
            LDA         $3,:MM:__INTERNAL:ThreadRing
            LDO         $3,$3
            LDO         $5,$3,#20
            PUSHJ       $4,:MM:__HEAP:DeallocJ
            JMP         9B
            NEG         $4,0,1
            STO         $4,$3,#20
            JMP         9F

            %
            % Create:
            %

DoCreate    JMP         9B

            %
            % Clone:
            %

DoClone     SAVE        $255,0
            SET         $0,$255
            LDA         $1,Stack_Segment
            SUBU        $2,$0,$1
            ADDU        $2,$2,#8
            SET         $4,$2
            PUSHJ       $3,:MM:__HEAP:AllocJ
            JMP         9B
            SET         $5,$1
            SET         $6,$3
            SET         $7,$2
            PUSHJ       $4,:MM:__MEM:CopyJ
            JMP         9B
            % Create new list entry:
            SET         $5,#30
            PUSHJ       $4,:MM:__HEAP:AllocJ
            JMP         9B
            % Thread ID:
            LDA         $5,:MM:__INTERNAL:NextID
            LDO         $6,$5
            STO         $6,$4,#00
            ADDU        $6,$6,1
            STO         $6,$5
            % State:
            SET         $5,#FF % sleep
            STO         $5,$4,#08
            % Update pointers:
            LDA         $5,:MM:__INTERNAL:ThreadRing
            LDO         $5,$5
            LDO         $6,$5,#18
            STO         $5,$4,#10
            STO         $6,$4,#18
            STO         $4,$5,#18
            STO         $4,$6,#10
            STO         $3,$4,#20 % stack image
            STO         $0,$4,#28 % UNSAVE address
            UNSAVE      0,$0
            JMP         9F

            %
            % Exit:
            %

DoExit      JMP         9B

            % check whether we double tripped:
9H          GET         $3,:rW
            CMPU        $4,$2,$3
            BZ          $4,1F
            LDA         $1,:MM:__INTERNAL:STRS:DoubleTrip
            PUSHJ       $0,:MM:__ERROR:IError1
1H          LDA         $2,:MM:__THREAD:interval
            LDO         $2,$2
            SET         $255,$0
            PUT         :rJ,$1
            % reenable timer
            PUT         :rI,$2
            POP 0

