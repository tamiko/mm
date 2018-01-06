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
            % The glorious trip handler
            %

            .section .data,"wa",@progbits
            PREFIX      :MM:__INTERNAL:STRS:
Unhandled   BYTE        "Unhandled TRIP.\n",0

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
TripHandler SET         $0,$255
            GET         $1,:rJ
            %
            % Determine whether we got tripped by the timer callback
            % (rX=#8000000000000000), or by an explicit TRIP
            % (rX=#80000000FF00XXXX).
            %
            GET         $2,:rX
            ANDNH       $2,#F000
            BZ          $2,1F % timer interrupt
            ANDNL       $2,#FFFF
            ANDNML      $2,#00FF
            SETML       $3,#FF00
            CMPU        $2,$2,$3
            BZ          $2,1F % explicit TRIP
            LDA         $1,:MM:__INTERNAL:STRS:Unhandled
            PUSHJ       $0,:MM:__ERROR:IError1
            SET         $255,$0
            PUT         :rJ,$1
            POP 0
1H          GET         $3,:rX
            SRU         $3,$3,8
            AND         $3,$3,#FF
            SET         $255,$3
            PUSHJ       $255,:MM:__PRINT:RegLnG
            CMP         $2,$3,Yield
            BZ          $2,1F
            CMP         $2,$3,Create
            BZ          $2,2F
            CMP         $2,$3,Clone
            BZ          $2,3F
            CMP         $2,$3,Exit
            BZ          $2,4F
            LDA         $3,:MM:__INTERNAL:STRS:Unhandled
            PUSHJ       $2,:MM:__ERROR:IError1
            SET         $255,$0
            PUT         :rJ,$1
            POP 0
1H          SWYM % yield
            JMP         9F
2H          SWYM % create
            JMP         9F
3H          SWYM % clone
            JMP         9F
4H          SWYM % exit
            JMP         9F
            % reenable timer
9H          LDA         $2,:MM:__THREAD:interval
            LDO         $2,$2
            PUT         :rI,$2
            SET         $255,$0
            PUT         :rJ,$1
            POP 0
