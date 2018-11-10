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
% :MM:__ERROR:
%
% Facilities for error messages and program termination.
%
% :MM:__ERROR:IError.*
%   Fatal, internal errors. Aborts the program by calling
%   :MM:Sys:Abort
%
% :MM:__ERROR:Error.*
%   Error condition caused by invalid user input. Respect Sys:AtError
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__ERROR:STRS:
            .balign 4
Terminated  BYTE        "[MM library] Program terminated.",10,0
            .balign 4
Continued1  BYTE        "Error handler returned.",10
            BYTE        "[MM library]     Continue execution at [",0
            .balign 4
Continued2  BYTE        "Special handler value #FFFFFFFFFFFFFFFF.",10
            BYTE        "[MM library]     Continue execution at [",0
            .balign 4
Continued3  BYTE        "].",10,0
            .balign 4
InternErro  BYTE        "[MM library] Internal error: ",10
            BYTE        "[MM library]     ",0
            .balign 4
Error1      BYTE        "[MM library] Called from [:rJ-4 = ",0
            .balign 4
Error2      BYTE        "] on thread [ThreadID = ",0
            .balign 4
Error3      BYTE        "]:",10,"[MM library]     ",0
            .balign 4
ErrorHndlC1 BYTE        "Calling error handler [",0
            .balign 4
ErrorHndlC2 BYTE        "].",10,0
            .balign 4
ExcNotImpl  BYTE        "I'm sorry Dave. I'm afraid I can't do that "
            BYTE        "(ExcNotImpl).",10,0
            .balign 4
Generic     BYTE        "Something went horribly wrong...",10,0

            .section .data,"wa",@progbits
            PREFIX      :MM:__ERROR:
            .balign 8
Buffer      IS          @
            .fill 128*8

            .section .text,"ax",@progbits
            PREFIX      :MM:__ERROR:
Fputs       IS          :Fputs
StdErr      IS          :StdErr
Halt        IS          :Halt

t           IS          :MM:t
arg0        IS          $0
arg1        IS          $1
arg2        IS          $2
arg3        IS          $3
arg4        IS          $4


%
% Internal error handler:
%

%%
% ErrByteG - internally used
%
            .global     :MM:__ERROR:ErrByteG
buffer      IS          $1
ErrByteG    SET         arg0,t
            GETA        buffer,:MM:__ERROR:Buffer
            SET         $2,'#'
            STB         $2,buffer,0
            SET         $2,0
            STB         $2,buffer,3
            AND         $2,arg0,#F
            CMP         t,$2,10
            BN          t,1F
            ADDU        $2,$2,7
1H          ADD         $2,$2,48
            STB         $2,buffer,2
            GET         $10,:rJ
            SRU         $2,arg0,4
            AND         $2,$2,#F
            CMP         t,$2,10
            BN          t,1F
            ADDU        $2,$2,7
1H          ADD         $2,$2,48
            STB         $2,buffer,1
            SET         $255,buffer
            TRAP        0,Fputs,StdErr
            POP         0,0


%%
% ErrRegG - internally used
%
            .global     :MM:__ERROR:ErrRegG
buffer      IS          $1
ptr         IS          $2
ErrRegG     SET         $0,t
            SET         $1,0
            SET         $2,8
            ADD         $5,$1,$1
            ADD         $6,$2,$2
            GETA        buffer,:MM:__ERROR:Buffer
            SET         $3,0
            STB         $3,buffer,17
1H          SET         $4,$0 % save original value
            SET         ptr,16
2H          AND         $3,$0,#F
            CMP         t,$3,10
            BN          t,1F
            ADDU        $3,$3,7
1H          ADD         $3,$3,48
            CMPU        t,ptr,$5
            CSNP        $3,t,'_'
            CMPU        t,ptr,$6
            CSP         $3,t,'_'
            STB         $3,buffer,ptr
            SUBU        ptr,ptr,1
            SRU         $0,$0,4
            PBNZ        ptr,2B
            SET         $3,'#'
            STB         $3,buffer,0
            SET         $255,buffer
            TRAP        0,Fputs,StdErr
            SET         t,$4 % restore original value
            POP         0,0


%%
% ErrRegG - internally used
%
            .global     :MM:__ERROR:ErrorBanner
ErrorBanner GET         $0,:rJ
            SET         $10,t
            GETA        $255,:MM:__ERROR:STRS:Error1
            TRAP        0,Fputs,StdErr
            SET         t,$10
            SUBU        t,t,#4
            PUSHJ       t,ErrRegG
            GETA        $255,:MM:__ERROR:STRS:Error2
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__THREAD:ThreadIDG
            PUSHJ       t,ErrRegG
            GETA        $255,:MM:__ERROR:STRS:Error3
            TRAP        0,Fputs,StdErr
            SET         t,$10
            PUT         :rJ,$0
            POP         0,0


%%
% :MM:__ERROR:IError0
%   Print an internal error message and terminate the program.
%
% PUSHJ, JMP:
%   no parameters
%   - routine does not return -
%
            .global :MM:__ERROR:IError0
IError0     PUSHJ       t,:MM:__INTERNAL:EnterCritical
            GETA        $255,:MM:__ERROR:STRS:InternErro
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__SYS:Abort


%%
% :MM:__ERROR:IError1
%   Print an internal error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:IError1
IError1     PUSHJ       t,:MM:__INTERNAL:EnterCritical
            GETA        $255,:MM:__ERROR:STRS:InternErro
            TRAP        0,Fputs,StdErr
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__SYS:Abort


%%
% :MM:__ERROR:IError2
%   Print an internal error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:IError2
IError2     PUSHJ       t,:MM:__INTERNAL:EnterCritical
            GETA        $255,:MM:__ERROR:STRS:InternErro
            TRAP        0,Fputs,StdErr
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            SET         $255,arg1
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__SYS:Abort


%%
% :MM:__ERROR:IError3
%   Print an internal error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:IError3
IError3     PUSHJ       t,:MM:__INTERNAL:EnterCritical
            GETA        $255,:MM:__ERROR:STRS:InternErro
            TRAP        0,Fputs,StdErr
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            SET         $255,arg1
            TRAP        0,Fputs,StdErr
            SET         $255,arg2
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__SYS:Abort


%%
% :MM:__ERROR:IError4R3
%   Print an internal error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - address of an error string
%   arg2 - Octa to print between arg1 and arg3
%   arg3 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:IError4R3
IError4R3   PUSHJ       t,:MM:__INTERNAL:EnterCritical
            GETA        $255,:MM:__ERROR:STRS:InternErro
            TRAP        0,Fputs,StdErr
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            SET         $255,arg1
            TRAP        0,Fputs,StdErr
            SET         t,arg2
            PUSHJ       t,ErrRegG
            SET         $255,arg3
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__SYS:Abort


%
% Error condition caused by invalid user input. Respect Sys:AtError
%

%%
% :MM:__ERROR:Error0
%   Print an error message and terminate the program.
%
% PUSHJ, JMP:
%   no parameters
%   - routine does not return -
%
            .global :MM:__ERROR:Error0
Error0      SET         $10,t
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            JMP         ErrorHndl


%%
% :MM:__ERROR:Error1
%   Print an error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:Error1
Error1      SET         $10,t
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            JMP         ErrorHndl


%%
% :MM:__ERROR:Error2
%   Print an error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:Error2
Error2      SET         $10,t
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            SET         $255,arg1
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            JMP         ErrorHndl


%%
% :MM:__ERROR:Error3R2
%   Print an error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - Octa to print between arg0 and arg2
%   arg2 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:Error3R2
Error3R2    SET         $10,t
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            PUSHJ       t,ErrRegG
            SET         $255,arg2
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            JMP         ErrorHndl


%%
% :MM:__ERROR:Error3RB2
%   Print an error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - Byte to print between arg0 and arg2
%   arg2 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:Error3RB2
Error3RB2   SET         $10,t
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            PUSHJ       t,ErrByteG
            SET         $255,arg2
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            JMP         ErrorHndl


%%
% :MM:__ERROR:Error5R24
%   Print an error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - Octa to print between arg0 and arg2
%   arg2 - address of an error string
%   arg3 - Octa to print between arg2 and arg4
%   arg4 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:Error5R24
Error5R24   SET         $10,t
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            PUSHJ       t,ErrRegG
            SET         $255,arg2
            TRAP        0,Fputs,StdErr
            SET         t,arg3
            PUSHJ       t,ErrRegG
            SET         $255,arg4
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            JMP         ErrorHndl


%%
% :MM:__ERROR:Error5RB24
%   Print an error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - Octa to print between arg0 and arg2
%   arg2 - address of an error string
%   arg3 - Octa to print between argr2 and arg4
%   arg4 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:Error5RB24
Error5RB24  SET         $10,t
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            SET         $255,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            PUSHJ       t,ErrByteG
            SET         $255,arg2
            TRAP        0,Fputs,StdErr
            SET         t,arg3
            PUSHJ       t,ErrRegG
            SET         $255,arg4
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            JMP         ErrorHndl


            % Respect a possible error handler:
            .global     :MM:__ERROR:ErrorHndl
ErrorHndl   GETA        $0,:MM:__SYS:AtErrorAddr
            LDO         $0,$0
            BNZ         $0,1F
            % Abort program:
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            GETA        $255,:MM:__ERROR:STRS:Terminated
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__SYS:Abort
            % Continue execution if we encounter the special value -1:
1H          NEG         $1,0,1
            CMP         $1,$1,$0
            BNZ         $1,1F
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            SET         t,$10
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            GETA        $255,:MM:__ERROR:STRS:Continued2
            TRAP        0,Fputs,StdErr
            SET         t,$10
            PUSHJ       t,ErrRegG
            GETA        $255,:MM:__ERROR:STRS:Continued3
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            SET         t,$10
            PUT         :rJ,$10
            POP         0,0
            % Print a message and hand over to error handler:
1H          PUSHJ       t,:MM:__INTERNAL:EnterCritical
            SET         t,$10
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            GETA        $255,:MM:__ERROR:STRS:ErrorHndlC1
            TRAP        0,Fputs,StdErr
            GETA        t,:MM:__SYS:AtErrorAddr
            LDO         t,t,0
            PUSHJ       t,ErrRegG
            GETA        $255,:MM:__ERROR:STRS:ErrorHndlC2
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            SET         t,$10
            GO          $0,$0 % call error handler
            PUSHJ       t,:MM:__INTERNAL:EnterCritical
            SET         t,$10
            PUSHJ       t,:MM:__ERROR:ErrorBanner
            GETA        $255,:MM:__ERROR:STRS:Continued1
            TRAP        0,Fputs,StdErr
            SET         t,$10
            PUSHJ       t,ErrRegG
            GETA        $255,:MM:__ERROR:STRS:Continued3
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__INTERNAL:LeaveCritical
            SET         t,$10
            PUT         :rJ,$10
            POP         0,0
