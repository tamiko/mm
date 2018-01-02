%%
% MMIX support library for various purposes.
%
% Copyright (C) 2013-2014 Matthias Maier <tamiko@kyomu.43-1.org>
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
            .global :MM:__ERROR:STRS:Terminated
            .global :MM:__ERROR:STRS:Continued1
            .global :MM:__ERROR:STRS:Continued2
            .global :MM:__ERROR:STRS:Continued3
            .global :MM:__ERROR:STRS:InternErro
            .global :MM:__ERROR:STRS:Error1
            .global :MM:__ERROR:STRS:Error2
            .global :MM:__ERROR:STRS:ErrorHndlC1
            .global :MM:__ERROR:STRS:ErrorHndlC2
            .global :MM:__ERROR:STRS:ExcNotImpl
            .global :MM:__ERROR:STRS:Generic
            PREFIX      :MM:__ERROR:STRS:
Terminated  BYTE        "[MM library]   Program terminated.",10,0
Continued1  BYTE        "[MM library]   Error handler returned. "
            BYTE        "Continue execution at [",0
Continued2  BYTE        "[MM library]   Special handler value #FFFFFFFFFFFFFFFF. "
            BYTE        "Continue execution at [",0
Continued3  BYTE        "].",10,0
InternErro  BYTE        "[MM library] Internal error: ",10
            BYTE        "[MM library]   ",0
Error1      BYTE        "[MM library] Called from [rJ=",0
Error2      BYTE        "]:",10,"[MM library]   ",0
ErrorHndlC1 BYTE        "[MM library]   Calling error handler [",0
ErrorHndlC2 BYTE        "].",10,0
ExcNotImpl  BYTE        "I'm sorry Dave. I'm afraid I can't do that "
            BYTE        "(ExcNotImpl).",10,0
Generic     BYTE        "Something went horribly wrong...",10,0


            .section .text,"ax",@progbits
            PREFIX      :MM:__ERROR:
            .global :MM:__ERROR:__rJ
__rJ        GREG        0

Fputs       IS          :Fputs
StdErr      IS          :StdErr
Halt        IS          :Halt

t           IS          $255
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
buffer      IS          $1
ErrByteG    SET         arg0,t
            LDA         buffer,:MM:__INTERNAL:Buffer
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
            SET         t,buffer
            TRAP        0,Fputs,StdErr
            POP         0,0


%%
% ErrRegG - internally used
%
buffer      IS          $1
ptr         IS          $2
ErrRegG     SET         $0,t
            SET         $1,0
            SET         $2,8
            ADD         $5,$1,$1
            ADD         $6,$2,$2
            LDA         buffer,:MM:__INTERNAL:Buffer
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
            SET         t,buffer
            TRAP        0,Fputs,StdErr
            SET         t,$4 % restore original value
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
IError0     LDA         t,:MM:__ERROR:STRS:InternErro
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
IError1     LDA         t,:MM:__ERROR:STRS:InternErro
            TRAP        0,Fputs,StdErr
            SET         t,arg0
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
IError2     LDA         t,:MM:__ERROR:STRS:InternErro
            TRAP        0,Fputs,StdErr
            SET         t,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__SYS:Abort


%%
% :MM:__ERROR:IError4R3
%   Print an internal error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - address of an error string
%   arg2 - Octa to print between arg0 and arg2
%   arg3 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:IError4R3
IError4R3   LDA         t,:MM:__ERROR:STRS:InternErro
            TRAP        0,Fputs,StdErr
            SET         t,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            TRAP        0,Fputs,StdErr
            SET         t,arg2
            PUSHJ       t,ErrRegG
            SET         t,arg3
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
Error0      LDA         t,:MM:__ERROR:STRS:Error1
            TRAP        0,Fputs,StdErr
            SET         t,__rJ
            PUSHJ       t,ErrRegG
            LDA         t,:MM:__ERROR:STRS:Error2
            TRAP        0,Fputs,StdErr
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
Error1      LDA         t,:MM:__ERROR:STRS:Error1
            TRAP        0,Fputs,StdErr
            SET         t,__rJ
            PUSHJ       t,ErrRegG
            LDA         t,:MM:__ERROR:STRS:Error2
            TRAP        0,Fputs,StdErr
            SET         t,arg0
            TRAP        0,Fputs,StdErr
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
Error2      LDA         t,:MM:__ERROR:STRS:Error1
            TRAP        0,Fputs,StdErr
            SET         t,__rJ
            PUSHJ       t,ErrRegG
            LDA         t,:MM:__ERROR:STRS:Error2
            TRAP        0,Fputs,StdErr
            SET         t,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            TRAP        0,Fputs,StdErr
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
Error3R2    LDA         t,:MM:__ERROR:STRS:Error1
            TRAP        0,Fputs,StdErr
            SET         t,__rJ
            PUSHJ       t,ErrRegG
            LDA         t,:MM:__ERROR:STRS:Error2
            TRAP        0,Fputs,StdErr
            SET         t,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            PUSHJ       t,ErrRegG
            SET         t,arg2
            TRAP        0,Fputs,StdErr
            JMP         ErrorHndl


%%
% :MM:__ERROR:Error3RB2
%   Print an error message and terminate the program.
%
% PUSHJ, JMP:
%   arg0 - address of an error string
%   arg1 - Octa to print between arg0 and arg2
%   arg2 - address of an error string
%   - routine does not return -
%
            .global :MM:__ERROR:Error3RB2
Error3RB2   LDA         t,:MM:__ERROR:STRS:Error1
            TRAP        0,Fputs,StdErr
            SET         t,__rJ
            PUSHJ       t,ErrRegG
            LDA         t,:MM:__ERROR:STRS:Error2
            TRAP        0,Fputs,StdErr
            SET         t,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            PUSHJ       t,ErrByteG
            SET         t,arg2
            TRAP        0,Fputs,StdErr
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
Error5R24   LDA         t,:MM:__ERROR:STRS:Error1
            TRAP        0,Fputs,StdErr
            SET         t,__rJ
            PUSHJ       t,ErrRegG
            LDA         t,:MM:__ERROR:STRS:Error2
            TRAP        0,Fputs,StdErr
            SET         t,arg0
            TRAP        0,Fputs,StdErr
            SET         t,arg1
            PUSHJ       t,ErrRegG
            SET         t,arg2
            TRAP        0,Fputs,StdErr
            SET         t,arg3
            PUSHJ       t,ErrRegG
            SET         t,arg4
            TRAP        0,Fputs,StdErr
            JMP         ErrorHndl


            % Respect a possible error handler:
ErrorHndl   LDO         $0,:MM:__SYS:AtErrorAddr
            BZ          $0,1F
            % Check for special value #-1
            SET         $1,1
            NEG         $1,0,$1
            CMP         $1,$1,$0
            BNZ         $1,3F
            LDA         t,:MM:__ERROR:STRS:Continued2
            TRAP        0,Fputs,StdErr
            JMP         2F
            % Print a message and hand over to error handler:
3H          LDA         t,:MM:__ERROR:STRS:ErrorHndlC1
            TRAP        0,Fputs,StdErr
            LDO         t,:MM:__SYS:AtErrorAddr
            PUSHJ       t,ErrRegG
            LDA         t,:MM:__ERROR:STRS:ErrorHndlC2
            TRAP        0,Fputs,StdErr
            SET         t,__rJ
            GO          $0,$0 % call error handler
            LDA         t,:MM:__ERROR:STRS:Continued1
            TRAP        0,Fputs,StdErr
2H          SET         t,__rJ
            PUSHJ       t,ErrRegG
            LDA         t,:MM:__ERROR:STRS:Continued3
            TRAP        0,Fputs,StdErr
            PUT         :rJ,__rJ
            POP         0,0 % continue execution

1H          LDA         t,:MM:__ERROR:STRS:Terminated
            TRAP        0,Fputs,StdErr
            PUSHJ       t,:MM:__SYS:Abort
            SET         t,1
            TRAP        0,Halt,0
