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
Tripped     BYTE        "Tripped! :-)\n",0

            .section .text,"ax",@progbits
            .global :MM:__INTERNAL:Yield
            .global :MM:__INTERNAL:Create
            .global :MM:__INTERNAL:Clone
            .global :MM:__INTERNAL:Exit
            .global :MM:__INTERNAL:TripHandler
            PREFIX      :MM:__INTERNAL:

Yield       IS          #00
Create      IS          #D0
Clone       IS          #E0
Exit        IS          #F0
TripHandler GET         $2,:rW
            GET         $1,:rJ
            SET         $0,$255
            NEG         $3,0,1
            PUT         :rI,$3 % disable timer
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
            GET         $255,:rX % DEBUG
            PUSHJ       $255,:MM:__PRINT:RegLnG % DEBUG
            SRU         $3,$3,8
            AND         $3,$3,#FF
            CMP         $4,$3,Yield
            BZ          $4,1F
            CMP         $4,$3,Create
            BZ          $4,2F
            CMP         $4,$3,Clone
            BZ          $4,3F
            CMP         $4,$3,Exit
            BZ          $4,4F
            LDA         $1,:MM:__INTERNAL:STRS:Unhandled
            PUSHJ       $0,:MM:__ERROR:IError1
1H          SWYM % yield
            JMP         9F
2H          SWYM % create
            JMP         9F
3H          SWYM % clone
            JMP         9F
4H          SWYM % exit
            JMP         9F
            % check whether we double tripped:
9H          GET         $3,:rW
            CMPU        $4,$2,$3
            BZ          $4,1F
            LDA         $1,:MM:__INTERNAL:STRS:DoubleTrip
            PUSHJ       $0,:MM:__ERROR:IError1
            % reenable timer
1H          LDA         $2,:MM:__THREAD:interval
            LDO         $2,$2
            PUT         :rI,$2
            SET         $255,$0
            PUT         :rJ,$1
            POP 0

