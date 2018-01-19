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
            % :MM:__INTERNAL:EnterCritical
            % :MM:__INTERNAL:LeaveCritical
            %
            %   Enter and leave a critical section. Internally used.
            %

            .section .data,"wa",@progbits
            .balign 8
            PREFIX      :MM:__INTERNAL:
stored_int  OCTA        #FFFFFFFFFFFFFFFF


            .section .text,"ax",@progbits
            PREFIX      :MM:__INTERNAL:
            .global :MM:__INTERNAL:EnterCritical
            .global :MM:__INTERNAL:LeaveCritical
EnterCritical SWYM
            GET         $0,:rI
            NEG         $1,0,1
            GETA        $2,stored_int
            % If :rI is negative we are either in the TripHandler or
            % preemptive threading is disabled. Do not update statistics in
            % either of these cases...
            BN          $0,1F
            INCREMENT_COUNTER :MM:__STATISTICS:ThreadCriti
            STORE_SPECIAL :rU,:MM:__STATISTICS:__buffer
            PUT         :rI,$1
            STO         $0,$2
            POP         0,0
1H          STO         $1,$2
2H          POP         0,0


LeaveCritical SWYM
            GETA        $0,stored_int
            LDO         $0,$0
            % If the stored :rI is negative we are either in the
            % TripHandler or preemptive threading is disabled. Do not
            % update statistics in either of these cases...
            BN          $0,1F
            STORE_DIFFERENCE :rU,:MM:__STATISTICS:__buffer,:MM:__STATISTICS:TimingCriti
            PUT         :rI,$0
1H          POP         0,0
