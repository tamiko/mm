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
% :MM:__File:
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__FILE:STRS:
Lock1       BYTE        "File:Lock failed. Could not lock handle [arg0=",0
Lock2       BYTE        "]. Already locked.",10,0
Unlock1     BYTE        "File:Unlock failed. Could not unlock handle [arg0=",0
Unlock2     BYTE        "]. File handle is not locked.",10,0
Open1       BYTE        "File:Open failed. Invalid file mode [arg1=",0
Open2       BYTE        "] specified.",10,0
Open3       BYTE        "File:Open failed. No free file handler "
            BYTE        "available.",10,0
Open4       BYTE        "File:Open failed. Could not open file with "
            BYTE        "specified file mode [arg1=",0
Open5       BYTE        "].",10,0
Close1      BYTE        "File:Close failed. File handle [arg0=",0
Close2      BYTE        "] locked by user or system.",10,0
Close3      BYTE        "] not opened.",10,0
Close4      BYTE        "File:Close failed. Could not close file handle [arg0=",0
Close5      BYTE        "]. Internal state corrupted.",10,0
Tell1       BYTE        "File:Tell failed. Could not read from file handle [arg0=",0
Tell2       BYTE        "].",10,0
Size1       BYTE        "File:Size failed. Could not read from file handle [arg0=",0
Size2       BYTE        "].",10,0
Seek1       BYTE        "File:Seek failed. Could not seek file handle [arg0=",0
Seek2       BYTE        "] to position [arg1=",0
Seek3       BYTE        "].",10,0
Read1       BYTE        "File:Read failed. Could not read from file handle [arg0=",0
Read2       BYTE        "].",10,0
Write1      BYTE        "File:Write failed. Could not write to file handle [arg0=",0
Write2      BYTE        "].",10,0


%
% We have 256 Bytes at address :MM:__FILE:Pool to store some internal
% data for file descriptors. Therefore,
%   #00        - not in use
%   #08 - #C   - in use (by us) and opened with the respective mode
%                +#8.
%   #EE        - marked as 'controlled by the system' (e.g. fh 0 - 2)
%   #FF        - marked as 'manually controlled by the user'
%
            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__FILE:Pool
            PREFIX      :MM:__FILE:
PoolMutex   OCTA        #0000000000000000
Pool        BYTE        #EE,#EE,#EE
            .fill 253*1


            .section .text,"ax",@progbits
            PREFIX      :MM:__FILE:
t           IS          $255
arg0        IS          $0
arg1        IS          $1
arg2        IS          $2
ret0        IS          $0

Fopen       IS          :Fopen
Fclose      IS          :Fclose
Ftell       IS          :Ftell
Fread       IS          :Fread
Fwrite      IS          :Fwrite
Fseek       IS          :Fseek
TextRead    IS          :TextRead
TextWrite   IS          :TextWrite
BinaryRead  IS          :BinaryRead
BinaryWrite IS          :BinaryWrite
BinaryReadWrite IS      :BinaryReadWrite


%%
% :MM:__FILE:LockJ
%   arg0 - file handle to lock
%   no return value
%
% :MM:__FILE:Lock
%   arg0 - file handle to lock
%   no return value
%
% :MM:__FILE:LockG
%

            .global :MM:__FILE:LockJ
            .global :MM:__FILE:LockG
            .global :MM:__FILE:Lock
pool        IS          $2
            % Select lowest byte:
LockJ       AND         arg0,arg0,#FF
            GET         $5,:rJ
            LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            LDA         pool,:MM:__FILE:Pool
2H          LDBU        $4,pool,arg0
            BNZ         $4,9F % already in use
            SET         $4,#FF
2H          STB         $4,pool,arg0
            LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$5
            POP         0,1
9H          LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$5
            POP         0,0
LockG       SET         $0,t
Lock        SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,LockJ
            JMP         9F
            PUT         :rJ,$1
            SET         t,arg0
            POP         0
9H          SET         t,$1 % :rJ
            LDA         $1,:MM:__FILE:STRS:Lock1
            SET         $2,arg0
            LDA         $3,:MM:__FILE:STRS:Lock2
            PUSHJ       $0,:MM:__ERROR:Error3RB2

%%
% :MM:__FILE:UnlockJ
%   arg0 - file handle to unlock
%   no return value
%
% :MM:__FILE:Unlock
%   arg0 - file handle to unlock
%   no return value
%
% :MM:__FILE:UnlockG
%

            .global :MM:__FILE:UnlockJ
            .global :MM:__FILE:UnlockG
            .global :MM:__FILE:Unlock
            % Select lowest byte:
pool        IS          $2
UnlockJ     CMPU        arg0,arg0,#FF
            GET         $5,:rJ
            LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            LDA         pool,:MM:__FILE:Pool
2H          LDBU        $4,pool,arg0
            XOR         $4,$4,#FF
            BNZ         $4,9F % not locked
            SET         $4,#00
2H          STB         $4,pool,arg0
            LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$5
            POP         1,1
9H          LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$5
            POP         0,0
UnlockG     SET         $0,t
Unlock      SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,UnlockJ
            JMP         9F
            PUT         :rJ,$1
            SET         t,arg0
            POP         0
9H          SET         t,$1 % :rJ
            LDA         $1,:MM:__FILE:STRS:Unlock1
            SET         $2,arg0
            LDA         $3,:MM:__FILE:STRS:Unlock2
            PUSHJ       $0,:MM:__ERROR:Error3RB2


%%
% :MM:__FILE:OpenJ
%   arg0 - pointer to string containing filename
%   arg1 - mode
%   retm - file handle on success / 0 on error
%

            .global :MM:__FILE:OpenJ
            % A lot of table...
OpenTable   TRAP 0,Fopen,0; JMP 7F
            TRAP 0,Fopen,1; JMP 7F
            TRAP 0,Fopen,2; JMP 7F
            TRAP 0,Fopen,3; JMP 7F
            TRAP 0,Fopen,4; JMP 7F
            TRAP 0,Fopen,5; JMP 7F
            TRAP 0,Fopen,6; JMP 7F
            TRAP 0,Fopen,7; JMP 7F
            TRAP 0,Fopen,8; JMP 7F
            TRAP 0,Fopen,9; JMP 7F
            TRAP 0,Fopen,10; JMP 7F
            TRAP 0,Fopen,11; JMP 7F
            TRAP 0,Fopen,12; JMP 7F
            TRAP 0,Fopen,13; JMP 7F
            TRAP 0,Fopen,14; JMP 7F
            TRAP 0,Fopen,15; JMP 7F
            TRAP 0,Fopen,16; JMP 7F
            TRAP 0,Fopen,17; JMP 7F
            TRAP 0,Fopen,18; JMP 7F
            TRAP 0,Fopen,19; JMP 7F
            TRAP 0,Fopen,20; JMP 7F
            TRAP 0,Fopen,21; JMP 7F
            TRAP 0,Fopen,22; JMP 7F
            TRAP 0,Fopen,23; JMP 7F
            TRAP 0,Fopen,24; JMP 7F
            TRAP 0,Fopen,25; JMP 7F
            TRAP 0,Fopen,26; JMP 7F
            TRAP 0,Fopen,27; JMP 7F
            TRAP 0,Fopen,28; JMP 7F
            TRAP 0,Fopen,29; JMP 7F
            TRAP 0,Fopen,30; JMP 7F
            TRAP 0,Fopen,31; JMP 7F
            TRAP 0,Fopen,32; JMP 7F
            TRAP 0,Fopen,33; JMP 7F
            TRAP 0,Fopen,34; JMP 7F
            TRAP 0,Fopen,35; JMP 7F
            TRAP 0,Fopen,36; JMP 7F
            TRAP 0,Fopen,37; JMP 7F
            TRAP 0,Fopen,38; JMP 7F
            TRAP 0,Fopen,39; JMP 7F
            TRAP 0,Fopen,40; JMP 7F
            TRAP 0,Fopen,41; JMP 7F
            TRAP 0,Fopen,42; JMP 7F
            TRAP 0,Fopen,43; JMP 7F
            TRAP 0,Fopen,44; JMP 7F
            TRAP 0,Fopen,45; JMP 7F
            TRAP 0,Fopen,46; JMP 7F
            TRAP 0,Fopen,47; JMP 7F
            TRAP 0,Fopen,48; JMP 7F
            TRAP 0,Fopen,49; JMP 7F
            TRAP 0,Fopen,50; JMP 7F
            TRAP 0,Fopen,51; JMP 7F
            TRAP 0,Fopen,52; JMP 7F
            TRAP 0,Fopen,53; JMP 7F
            TRAP 0,Fopen,54; JMP 7F
            TRAP 0,Fopen,55; JMP 7F
            TRAP 0,Fopen,56; JMP 7F
            TRAP 0,Fopen,57; JMP 7F
            TRAP 0,Fopen,58; JMP 7F
            TRAP 0,Fopen,59; JMP 7F
            TRAP 0,Fopen,60; JMP 7F
            TRAP 0,Fopen,61; JMP 7F
            TRAP 0,Fopen,62; JMP 7F
            TRAP 0,Fopen,63; JMP 7F
            TRAP 0,Fopen,64; JMP 7F
            TRAP 0,Fopen,65; JMP 7F
            TRAP 0,Fopen,66; JMP 7F
            TRAP 0,Fopen,67; JMP 7F
            TRAP 0,Fopen,68; JMP 7F
            TRAP 0,Fopen,69; JMP 7F
            TRAP 0,Fopen,70; JMP 7F
            TRAP 0,Fopen,71; JMP 7F
            TRAP 0,Fopen,72; JMP 7F
            TRAP 0,Fopen,73; JMP 7F
            TRAP 0,Fopen,74; JMP 7F
            TRAP 0,Fopen,75; JMP 7F
            TRAP 0,Fopen,76; JMP 7F
            TRAP 0,Fopen,77; JMP 7F
            TRAP 0,Fopen,78; JMP 7F
            TRAP 0,Fopen,79; JMP 7F
            TRAP 0,Fopen,80; JMP 7F
            TRAP 0,Fopen,81; JMP 7F
            TRAP 0,Fopen,82; JMP 7F
            TRAP 0,Fopen,83; JMP 7F
            TRAP 0,Fopen,84; JMP 7F
            TRAP 0,Fopen,85; JMP 7F
            TRAP 0,Fopen,86; JMP 7F
            TRAP 0,Fopen,87; JMP 7F
            TRAP 0,Fopen,88; JMP 7F
            TRAP 0,Fopen,89; JMP 7F
            TRAP 0,Fopen,90; JMP 7F
            TRAP 0,Fopen,91; JMP 7F
            TRAP 0,Fopen,92; JMP 7F
            TRAP 0,Fopen,93; JMP 7F
            TRAP 0,Fopen,94; JMP 7F
            TRAP 0,Fopen,95; JMP 7F
            TRAP 0,Fopen,96; JMP 7F
            TRAP 0,Fopen,97; JMP 7F
            TRAP 0,Fopen,98; JMP 7F
            TRAP 0,Fopen,99; JMP 7F
            TRAP 0,Fopen,100; JMP 7F
            TRAP 0,Fopen,101; JMP 7F
            TRAP 0,Fopen,102; JMP 7F
            TRAP 0,Fopen,103; JMP 7F
            TRAP 0,Fopen,104; JMP 7F
            TRAP 0,Fopen,105; JMP 7F
            TRAP 0,Fopen,106; JMP 7F
            TRAP 0,Fopen,107; JMP 7F
            TRAP 0,Fopen,108; JMP 7F
            TRAP 0,Fopen,109; JMP 7F
            TRAP 0,Fopen,110; JMP 7F
            TRAP 0,Fopen,111; JMP 7F
            TRAP 0,Fopen,112; JMP 7F
            TRAP 0,Fopen,113; JMP 7F
            TRAP 0,Fopen,114; JMP 7F
            TRAP 0,Fopen,115; JMP 7F
            TRAP 0,Fopen,116; JMP 7F
            TRAP 0,Fopen,117; JMP 7F
            TRAP 0,Fopen,118; JMP 7F
            TRAP 0,Fopen,119; JMP 7F
            TRAP 0,Fopen,120; JMP 7F
            TRAP 0,Fopen,121; JMP 7F
            TRAP 0,Fopen,122; JMP 7F
            TRAP 0,Fopen,123; JMP 7F
            TRAP 0,Fopen,124; JMP 7F
            TRAP 0,Fopen,125; JMP 7F
            TRAP 0,Fopen,126; JMP 7F
            TRAP 0,Fopen,127; JMP 7F
            TRAP 0,Fopen,128; JMP 7F
            TRAP 0,Fopen,129; JMP 7F
            TRAP 0,Fopen,130; JMP 7F
            TRAP 0,Fopen,131; JMP 7F
            TRAP 0,Fopen,132; JMP 7F
            TRAP 0,Fopen,133; JMP 7F
            TRAP 0,Fopen,134; JMP 7F
            TRAP 0,Fopen,135; JMP 7F
            TRAP 0,Fopen,136; JMP 7F
            TRAP 0,Fopen,137; JMP 7F
            TRAP 0,Fopen,138; JMP 7F
            TRAP 0,Fopen,139; JMP 7F
            TRAP 0,Fopen,140; JMP 7F
            TRAP 0,Fopen,141; JMP 7F
            TRAP 0,Fopen,142; JMP 7F
            TRAP 0,Fopen,143; JMP 7F
            TRAP 0,Fopen,144; JMP 7F
            TRAP 0,Fopen,145; JMP 7F
            TRAP 0,Fopen,146; JMP 7F
            TRAP 0,Fopen,147; JMP 7F
            TRAP 0,Fopen,148; JMP 7F
            TRAP 0,Fopen,149; JMP 7F
            TRAP 0,Fopen,150; JMP 7F
            TRAP 0,Fopen,151; JMP 7F
            TRAP 0,Fopen,152; JMP 7F
            TRAP 0,Fopen,153; JMP 7F
            TRAP 0,Fopen,154; JMP 7F
            TRAP 0,Fopen,155; JMP 7F
            TRAP 0,Fopen,156; JMP 7F
            TRAP 0,Fopen,157; JMP 7F
            TRAP 0,Fopen,158; JMP 7F
            TRAP 0,Fopen,159; JMP 7F
            TRAP 0,Fopen,160; JMP 7F
            TRAP 0,Fopen,161; JMP 7F
            TRAP 0,Fopen,162; JMP 7F
            TRAP 0,Fopen,163; JMP 7F
            TRAP 0,Fopen,164; JMP 7F
            TRAP 0,Fopen,165; JMP 7F
            TRAP 0,Fopen,166; JMP 7F
            TRAP 0,Fopen,167; JMP 7F
            TRAP 0,Fopen,168; JMP 7F
            TRAP 0,Fopen,169; JMP 7F
            TRAP 0,Fopen,170; JMP 7F
            TRAP 0,Fopen,171; JMP 7F
            TRAP 0,Fopen,172; JMP 7F
            TRAP 0,Fopen,173; JMP 7F
            TRAP 0,Fopen,174; JMP 7F
            TRAP 0,Fopen,175; JMP 7F
            TRAP 0,Fopen,176; JMP 7F
            TRAP 0,Fopen,177; JMP 7F
            TRAP 0,Fopen,178; JMP 7F
            TRAP 0,Fopen,179; JMP 7F
            TRAP 0,Fopen,180; JMP 7F
            TRAP 0,Fopen,181; JMP 7F
            TRAP 0,Fopen,182; JMP 7F
            TRAP 0,Fopen,183; JMP 7F
            TRAP 0,Fopen,184; JMP 7F
            TRAP 0,Fopen,185; JMP 7F
            TRAP 0,Fopen,186; JMP 7F
            TRAP 0,Fopen,187; JMP 7F
            TRAP 0,Fopen,188; JMP 7F
            TRAP 0,Fopen,189; JMP 7F
            TRAP 0,Fopen,190; JMP 7F
            TRAP 0,Fopen,191; JMP 7F
            TRAP 0,Fopen,192; JMP 7F
            TRAP 0,Fopen,193; JMP 7F
            TRAP 0,Fopen,194; JMP 7F
            TRAP 0,Fopen,195; JMP 7F
            TRAP 0,Fopen,196; JMP 7F
            TRAP 0,Fopen,197; JMP 7F
            TRAP 0,Fopen,198; JMP 7F
            TRAP 0,Fopen,199; JMP 7F
            TRAP 0,Fopen,200; JMP 7F
            TRAP 0,Fopen,201; JMP 7F
            TRAP 0,Fopen,202; JMP 7F
            TRAP 0,Fopen,203; JMP 7F
            TRAP 0,Fopen,204; JMP 7F
            TRAP 0,Fopen,205; JMP 7F
            TRAP 0,Fopen,206; JMP 7F
            TRAP 0,Fopen,207; JMP 7F
            TRAP 0,Fopen,208; JMP 7F
            TRAP 0,Fopen,209; JMP 7F
            TRAP 0,Fopen,210; JMP 7F
            TRAP 0,Fopen,211; JMP 7F
            TRAP 0,Fopen,212; JMP 7F
            TRAP 0,Fopen,213; JMP 7F
            TRAP 0,Fopen,214; JMP 7F
            TRAP 0,Fopen,215; JMP 7F
            TRAP 0,Fopen,216; JMP 7F
            TRAP 0,Fopen,217; JMP 7F
            TRAP 0,Fopen,218; JMP 7F
            TRAP 0,Fopen,219; JMP 7F
            TRAP 0,Fopen,220; JMP 7F
            TRAP 0,Fopen,221; JMP 7F
            TRAP 0,Fopen,222; JMP 7F
            TRAP 0,Fopen,223; JMP 7F
            TRAP 0,Fopen,224; JMP 7F
            TRAP 0,Fopen,225; JMP 7F
            TRAP 0,Fopen,226; JMP 7F
            TRAP 0,Fopen,227; JMP 7F
            TRAP 0,Fopen,228; JMP 7F
            TRAP 0,Fopen,229; JMP 7F
            TRAP 0,Fopen,230; JMP 7F
            TRAP 0,Fopen,231; JMP 7F
            TRAP 0,Fopen,232; JMP 7F
            TRAP 0,Fopen,233; JMP 7F
            TRAP 0,Fopen,234; JMP 7F
            TRAP 0,Fopen,235; JMP 7F
            TRAP 0,Fopen,236; JMP 7F
            TRAP 0,Fopen,237; JMP 7F
            TRAP 0,Fopen,238; JMP 7F
            TRAP 0,Fopen,239; JMP 7F
            TRAP 0,Fopen,240; JMP 7F
            TRAP 0,Fopen,241; JMP 7F
            TRAP 0,Fopen,242; JMP 7F
            TRAP 0,Fopen,243; JMP 7F
            TRAP 0,Fopen,244; JMP 7F
            TRAP 0,Fopen,245; JMP 7F
            TRAP 0,Fopen,246; JMP 7F
            TRAP 0,Fopen,247; JMP 7F
            TRAP 0,Fopen,248; JMP 7F
            TRAP 0,Fopen,249; JMP 7F
            TRAP 0,Fopen,250; JMP 7F
            TRAP 0,Fopen,251; JMP 7F
            TRAP 0,Fopen,252; JMP 7F
            TRAP 0,Fopen,253; JMP 7F
            TRAP 0,Fopen,254; JMP 7F
            TRAP 0,Fopen,255; JMP 7F
pool        IS          $2
fh          IS          $3
OpenJ       GET         $6,:rJ
            LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            CMPU        t,arg1,4
            BP          t,9F
            % Find an unused fh:
            LDA         pool,:MM:__FILE:Pool
            SET         fh,0
2H          LDBU        $4,pool,fh
            BZ          $4,1F % success
            ADDU        fh,fh,1
            CMPU        t,fh,255
            BP          t,9F
            JMP         2B
            % So we found an unused fh:
1H          ORL         arg1,#8
            STB         arg1,pool,fh
            ANDNL       arg1,#8
            LDA         $4,:MM:__INTERNAL:Buffer
            STO         arg0,$4,0
            STO         arg1,$4,8
            SLU         $3,fh,3 % *8
            LDA         $5,OpenTable
            SET         t,$4
            GO          $4,$5,$3
7H          BN          t,1F
            SRU         $3,fh,3 % /8
            SET         $0,fh
            LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$6
            POP         1,1
1H          SRU         fh,$3,3 % fh
            SET         $0,0
            STB         $0,pool,fh
9H          LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$6
            POP         0,0


%%
% :MM:__FILE:Open
%   arg0 - pointer to string containing filename
%   arg1 - mode
%   retm - file handle
%

            .global :MM:__FILE:Open
Open        CMPU        t,arg1,4
            BP          t,9F
            % Are any file handles available?
            % TODO: This check is a bit racy...
            LDA         pool,:MM:__FILE:Pool
            SET         fh,0
2H          LDBU        $4,pool,fh
            BZ          $4,1F % success
            ADDU        fh,fh,1
            CMPU        t,fh,255
            BP          t,8F
            JMP         2B
1H          GET         $2,:rJ
            SET         $4,arg0
            SET         $5,arg1
            PUSHJ       $3,OpenJ
            JMP         7F
            SET         $0,$3
            PUT         :rJ,$2
            POP         1,0
7H          SET         t,$2 % :rJ
            SET         $2,arg1
            LDA         $1,:MM:__FILE:STRS:Open4
            LDA         $3,:MM:__FILE:STRS:Open5
            PUSHJ       $0,:MM:__ERROR:Error3RB2
8H          GET         t,:rJ % :rJ
            LDA         $1,:MM:__FILE:STRS:Open3
            PUSHJ       $0,:MM:__ERROR:Error1
9H          GET         t,:rJ % :rJ
            SET         $2,arg1
            LDA         $1,:MM:__FILE:STRS:Open1
            LDA         $3,:MM:__FILE:STRS:Open2
            PUSHJ       $0,:MM:__ERROR:Error3RB2


%%
% :MM:__FILE:CloseJ
%
% PUSHJ:
%   arg0 - lowest byte defines the file handle
%   no return value
%

            .global :MM:__FILE:CloseJ
CloseTable  TRAP 0,Fclose,0; JMP 7F
            TRAP 0,Fclose,1; JMP 7F
            TRAP 0,Fclose,2; JMP 7F
            TRAP 0,Fclose,3; JMP 7F
            TRAP 0,Fclose,4; JMP 7F
            TRAP 0,Fclose,5; JMP 7F
            TRAP 0,Fclose,6; JMP 7F
            TRAP 0,Fclose,7; JMP 7F
            TRAP 0,Fclose,8; JMP 7F
            TRAP 0,Fclose,9; JMP 7F
            TRAP 0,Fclose,10; JMP 7F
            TRAP 0,Fclose,11; JMP 7F
            TRAP 0,Fclose,12; JMP 7F
            TRAP 0,Fclose,13; JMP 7F
            TRAP 0,Fclose,14; JMP 7F
            TRAP 0,Fclose,15; JMP 7F
            TRAP 0,Fclose,16; JMP 7F
            TRAP 0,Fclose,17; JMP 7F
            TRAP 0,Fclose,18; JMP 7F
            TRAP 0,Fclose,19; JMP 7F
            TRAP 0,Fclose,20; JMP 7F
            TRAP 0,Fclose,21; JMP 7F
            TRAP 0,Fclose,22; JMP 7F
            TRAP 0,Fclose,23; JMP 7F
            TRAP 0,Fclose,24; JMP 7F
            TRAP 0,Fclose,25; JMP 7F
            TRAP 0,Fclose,26; JMP 7F
            TRAP 0,Fclose,27; JMP 7F
            TRAP 0,Fclose,28; JMP 7F
            TRAP 0,Fclose,29; JMP 7F
            TRAP 0,Fclose,30; JMP 7F
            TRAP 0,Fclose,31; JMP 7F
            TRAP 0,Fclose,32; JMP 7F
            TRAP 0,Fclose,33; JMP 7F
            TRAP 0,Fclose,34; JMP 7F
            TRAP 0,Fclose,35; JMP 7F
            TRAP 0,Fclose,36; JMP 7F
            TRAP 0,Fclose,37; JMP 7F
            TRAP 0,Fclose,38; JMP 7F
            TRAP 0,Fclose,39; JMP 7F
            TRAP 0,Fclose,40; JMP 7F
            TRAP 0,Fclose,41; JMP 7F
            TRAP 0,Fclose,42; JMP 7F
            TRAP 0,Fclose,43; JMP 7F
            TRAP 0,Fclose,44; JMP 7F
            TRAP 0,Fclose,45; JMP 7F
            TRAP 0,Fclose,46; JMP 7F
            TRAP 0,Fclose,47; JMP 7F
            TRAP 0,Fclose,48; JMP 7F
            TRAP 0,Fclose,49; JMP 7F
            TRAP 0,Fclose,50; JMP 7F
            TRAP 0,Fclose,51; JMP 7F
            TRAP 0,Fclose,52; JMP 7F
            TRAP 0,Fclose,53; JMP 7F
            TRAP 0,Fclose,54; JMP 7F
            TRAP 0,Fclose,55; JMP 7F
            TRAP 0,Fclose,56; JMP 7F
            TRAP 0,Fclose,57; JMP 7F
            TRAP 0,Fclose,58; JMP 7F
            TRAP 0,Fclose,59; JMP 7F
            TRAP 0,Fclose,60; JMP 7F
            TRAP 0,Fclose,61; JMP 7F
            TRAP 0,Fclose,62; JMP 7F
            TRAP 0,Fclose,63; JMP 7F
            TRAP 0,Fclose,64; JMP 7F
            TRAP 0,Fclose,65; JMP 7F
            TRAP 0,Fclose,66; JMP 7F
            TRAP 0,Fclose,67; JMP 7F
            TRAP 0,Fclose,68; JMP 7F
            TRAP 0,Fclose,69; JMP 7F
            TRAP 0,Fclose,70; JMP 7F
            TRAP 0,Fclose,71; JMP 7F
            TRAP 0,Fclose,72; JMP 7F
            TRAP 0,Fclose,73; JMP 7F
            TRAP 0,Fclose,74; JMP 7F
            TRAP 0,Fclose,75; JMP 7F
            TRAP 0,Fclose,76; JMP 7F
            TRAP 0,Fclose,77; JMP 7F
            TRAP 0,Fclose,78; JMP 7F
            TRAP 0,Fclose,79; JMP 7F
            TRAP 0,Fclose,80; JMP 7F
            TRAP 0,Fclose,81; JMP 7F
            TRAP 0,Fclose,82; JMP 7F
            TRAP 0,Fclose,83; JMP 7F
            TRAP 0,Fclose,84; JMP 7F
            TRAP 0,Fclose,85; JMP 7F
            TRAP 0,Fclose,86; JMP 7F
            TRAP 0,Fclose,87; JMP 7F
            TRAP 0,Fclose,88; JMP 7F
            TRAP 0,Fclose,89; JMP 7F
            TRAP 0,Fclose,90; JMP 7F
            TRAP 0,Fclose,91; JMP 7F
            TRAP 0,Fclose,92; JMP 7F
            TRAP 0,Fclose,93; JMP 7F
            TRAP 0,Fclose,94; JMP 7F
            TRAP 0,Fclose,95; JMP 7F
            TRAP 0,Fclose,96; JMP 7F
            TRAP 0,Fclose,97; JMP 7F
            TRAP 0,Fclose,98; JMP 7F
            TRAP 0,Fclose,99; JMP 7F
            TRAP 0,Fclose,100; JMP 7F
            TRAP 0,Fclose,101; JMP 7F
            TRAP 0,Fclose,102; JMP 7F
            TRAP 0,Fclose,103; JMP 7F
            TRAP 0,Fclose,104; JMP 7F
            TRAP 0,Fclose,105; JMP 7F
            TRAP 0,Fclose,106; JMP 7F
            TRAP 0,Fclose,107; JMP 7F
            TRAP 0,Fclose,108; JMP 7F
            TRAP 0,Fclose,109; JMP 7F
            TRAP 0,Fclose,110; JMP 7F
            TRAP 0,Fclose,111; JMP 7F
            TRAP 0,Fclose,112; JMP 7F
            TRAP 0,Fclose,113; JMP 7F
            TRAP 0,Fclose,114; JMP 7F
            TRAP 0,Fclose,115; JMP 7F
            TRAP 0,Fclose,116; JMP 7F
            TRAP 0,Fclose,117; JMP 7F
            TRAP 0,Fclose,118; JMP 7F
            TRAP 0,Fclose,119; JMP 7F
            TRAP 0,Fclose,120; JMP 7F
            TRAP 0,Fclose,121; JMP 7F
            TRAP 0,Fclose,122; JMP 7F
            TRAP 0,Fclose,123; JMP 7F
            TRAP 0,Fclose,124; JMP 7F
            TRAP 0,Fclose,125; JMP 7F
            TRAP 0,Fclose,126; JMP 7F
            TRAP 0,Fclose,127; JMP 7F
            TRAP 0,Fclose,128; JMP 7F
            TRAP 0,Fclose,129; JMP 7F
            TRAP 0,Fclose,130; JMP 7F
            TRAP 0,Fclose,131; JMP 7F
            TRAP 0,Fclose,132; JMP 7F
            TRAP 0,Fclose,133; JMP 7F
            TRAP 0,Fclose,134; JMP 7F
            TRAP 0,Fclose,135; JMP 7F
            TRAP 0,Fclose,136; JMP 7F
            TRAP 0,Fclose,137; JMP 7F
            TRAP 0,Fclose,138; JMP 7F
            TRAP 0,Fclose,139; JMP 7F
            TRAP 0,Fclose,140; JMP 7F
            TRAP 0,Fclose,141; JMP 7F
            TRAP 0,Fclose,142; JMP 7F
            TRAP 0,Fclose,143; JMP 7F
            TRAP 0,Fclose,144; JMP 7F
            TRAP 0,Fclose,145; JMP 7F
            TRAP 0,Fclose,146; JMP 7F
            TRAP 0,Fclose,147; JMP 7F
            TRAP 0,Fclose,148; JMP 7F
            TRAP 0,Fclose,149; JMP 7F
            TRAP 0,Fclose,150; JMP 7F
            TRAP 0,Fclose,151; JMP 7F
            TRAP 0,Fclose,152; JMP 7F
            TRAP 0,Fclose,153; JMP 7F
            TRAP 0,Fclose,154; JMP 7F
            TRAP 0,Fclose,155; JMP 7F
            TRAP 0,Fclose,156; JMP 7F
            TRAP 0,Fclose,157; JMP 7F
            TRAP 0,Fclose,158; JMP 7F
            TRAP 0,Fclose,159; JMP 7F
            TRAP 0,Fclose,160; JMP 7F
            TRAP 0,Fclose,161; JMP 7F
            TRAP 0,Fclose,162; JMP 7F
            TRAP 0,Fclose,163; JMP 7F
            TRAP 0,Fclose,164; JMP 7F
            TRAP 0,Fclose,165; JMP 7F
            TRAP 0,Fclose,166; JMP 7F
            TRAP 0,Fclose,167; JMP 7F
            TRAP 0,Fclose,168; JMP 7F
            TRAP 0,Fclose,169; JMP 7F
            TRAP 0,Fclose,170; JMP 7F
            TRAP 0,Fclose,171; JMP 7F
            TRAP 0,Fclose,172; JMP 7F
            TRAP 0,Fclose,173; JMP 7F
            TRAP 0,Fclose,174; JMP 7F
            TRAP 0,Fclose,175; JMP 7F
            TRAP 0,Fclose,176; JMP 7F
            TRAP 0,Fclose,177; JMP 7F
            TRAP 0,Fclose,178; JMP 7F
            TRAP 0,Fclose,179; JMP 7F
            TRAP 0,Fclose,180; JMP 7F
            TRAP 0,Fclose,181; JMP 7F
            TRAP 0,Fclose,182; JMP 7F
            TRAP 0,Fclose,183; JMP 7F
            TRAP 0,Fclose,184; JMP 7F
            TRAP 0,Fclose,185; JMP 7F
            TRAP 0,Fclose,186; JMP 7F
            TRAP 0,Fclose,187; JMP 7F
            TRAP 0,Fclose,188; JMP 7F
            TRAP 0,Fclose,189; JMP 7F
            TRAP 0,Fclose,190; JMP 7F
            TRAP 0,Fclose,191; JMP 7F
            TRAP 0,Fclose,192; JMP 7F
            TRAP 0,Fclose,193; JMP 7F
            TRAP 0,Fclose,194; JMP 7F
            TRAP 0,Fclose,195; JMP 7F
            TRAP 0,Fclose,196; JMP 7F
            TRAP 0,Fclose,197; JMP 7F
            TRAP 0,Fclose,198; JMP 7F
            TRAP 0,Fclose,199; JMP 7F
            TRAP 0,Fclose,200; JMP 7F
            TRAP 0,Fclose,201; JMP 7F
            TRAP 0,Fclose,202; JMP 7F
            TRAP 0,Fclose,203; JMP 7F
            TRAP 0,Fclose,204; JMP 7F
            TRAP 0,Fclose,205; JMP 7F
            TRAP 0,Fclose,206; JMP 7F
            TRAP 0,Fclose,207; JMP 7F
            TRAP 0,Fclose,208; JMP 7F
            TRAP 0,Fclose,209; JMP 7F
            TRAP 0,Fclose,210; JMP 7F
            TRAP 0,Fclose,211; JMP 7F
            TRAP 0,Fclose,212; JMP 7F
            TRAP 0,Fclose,213; JMP 7F
            TRAP 0,Fclose,214; JMP 7F
            TRAP 0,Fclose,215; JMP 7F
            TRAP 0,Fclose,216; JMP 7F
            TRAP 0,Fclose,217; JMP 7F
            TRAP 0,Fclose,218; JMP 7F
            TRAP 0,Fclose,219; JMP 7F
            TRAP 0,Fclose,220; JMP 7F
            TRAP 0,Fclose,221; JMP 7F
            TRAP 0,Fclose,222; JMP 7F
            TRAP 0,Fclose,223; JMP 7F
            TRAP 0,Fclose,224; JMP 7F
            TRAP 0,Fclose,225; JMP 7F
            TRAP 0,Fclose,226; JMP 7F
            TRAP 0,Fclose,227; JMP 7F
            TRAP 0,Fclose,228; JMP 7F
            TRAP 0,Fclose,229; JMP 7F
            TRAP 0,Fclose,230; JMP 7F
            TRAP 0,Fclose,231; JMP 7F
            TRAP 0,Fclose,232; JMP 7F
            TRAP 0,Fclose,233; JMP 7F
            TRAP 0,Fclose,234; JMP 7F
            TRAP 0,Fclose,235; JMP 7F
            TRAP 0,Fclose,236; JMP 7F
            TRAP 0,Fclose,237; JMP 7F
            TRAP 0,Fclose,238; JMP 7F
            TRAP 0,Fclose,239; JMP 7F
            TRAP 0,Fclose,240; JMP 7F
            TRAP 0,Fclose,241; JMP 7F
            TRAP 0,Fclose,242; JMP 7F
            TRAP 0,Fclose,243; JMP 7F
            TRAP 0,Fclose,244; JMP 7F
            TRAP 0,Fclose,245; JMP 7F
            TRAP 0,Fclose,246; JMP 7F
            TRAP 0,Fclose,247; JMP 7F
            TRAP 0,Fclose,248; JMP 7F
            TRAP 0,Fclose,249; JMP 7F
            TRAP 0,Fclose,250; JMP 7F
            TRAP 0,Fclose,251; JMP 7F
            TRAP 0,Fclose,252; JMP 7F
            TRAP 0,Fclose,253; JMP 7F
            TRAP 0,Fclose,254; JMP 7F
            TRAP 0,Fclose,255; JMP 7F
pool        IS          $2
            % sanitize arg0:
CloseJ      AND         arg0,arg0,#FF
            GET         $5,:rJ
            LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            LDA         pool,:MM:__FILE:Pool
            LDBU        $3,pool,arg0
            BZ          $3,9F
            CMPU        t,$3,#FF
            BZ          t,9F
            CMPU        t,$3,#EE
            BZ          t,9F
            SLU         arg0,arg0,3 % *8
            LDA         $4,CloseTable
            GO          $4,$4,arg0
7H          SRU         arg0,arg0,3 % /8
            BN          t,9F
            SET         $3,0
            STBU        $3,pool,arg0
            LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$5
            POP         0,1
9H          LDA         t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$5
            POP         0,0


%%
% :MM:__FILE:Close
%   arg0 - file handle to close
%   no return value
%

            .global :MM:__FILE:CloseG
            .global :MM:__FILE:Close
CloseG      SET         arg0,t
Close       AND         $3,arg0,#FF
            % TODO: This check is a bit racy...
            LDA         pool,:MM:__FILE:Pool
            LDBU        $3,pool,$3
            BZ          $3,9F
            CMPU        t,$3,#FF
            BZ          t,8F
            CMPU        t,$3,#EE
            BZ          t,8F
            GET         $1,:rJ
            SET         $4,arg0
            PUSHJ       $3,CloseJ
            JMP         7F
            PUT         :rJ,$1
            SET         t,arg0
            POP         0
7H          AND         $3,arg0,#FF
            SET         $4,0
            STBU        $4,pool,$3
            SET         t,$1 % :rJ
            LDA         $3,:MM:__FILE:STRS:Close4
            SET         $4,arg0
            LDA         $5,:MM:__FILE:STRS:Close5
            PUSHJ       $2,:MM:__ERROR:Error3RB2
8H          SET         t,$1 % :rJ
            LDA         $1,:MM:__FILE:STRS:Close1
            SET         $2,arg0
            LDA         $3,:MM:__FILE:STRS:Close2
            PUSHJ       $0,:MM:__ERROR:Error3RB2
9H          GET         t,:rJ % :rJ
            LDA         $1,:MM:__FILE:STRS:Close1
            SET         $2,arg0
            LDA         $3,:MM:__FILE:STRS:Close3
            PUSHJ       $0,:MM:__ERROR:Error3RB2


%%
% :MM:__FILE:IsOpenJ
%
% PUSHJ:
%   arg0 - lowest byte defines the file handle
%   no return value
%
% :MM:__FILE:IsOpenG
% :MM:__FILE:IsOpen
%

            .global :MM:__FILE:IsOpenJ
            .global :MM:__FILE:IsOpenG
            .global :MM:__FILE:IsOpen
pool        IS          $2
IsOpenJ     AND         arg0,arg0,#FF
            LDA         pool,:MM:__FILE:Pool
            LDBU        $1,pool,arg0
            BZ          $1,9F
            CMPU        t,$1,#FF
            BZ          t,9F
            CMPU        t,$1,#EE
            BZ          t,9F
            POP         0,1
9H          POP         0,0
IsOpenG     SET         $0,t
IsOpen      GET         $1,:rJ
            SET         $3,arg0
            PUSHJ       $2,IsOpenJ
            JMP         1F
            SET         $0,0
            PUT         :rJ,$1
            SET         t,$0
            POP         1,0
1H          SET         $0,1
            NEG         $0,$0
            PUT         :rJ,$1
            SET         t,$0
            POP         1,0


%%
% :MM:__FILE:IsReadableJ
%
% PUSHJ:
%   arg0 - lowest byte defines the file handle
%   no return value
%
% :MM:__FILE:IsReadableG
% :MM:__FILE:IsReadable
%

            .global :MM:__FILE:IsReadableJ
            .global :MM:__FILE:IsReadableG
            .global :MM:__FILE:IsReadable
pool        IS          $2
IsReadableJ AND         arg0,arg0,#FF
            LDA         pool,:MM:__FILE:Pool
            LDBU        $1,pool,arg0
            CMPU        t,$1,#8 % :TextRead
            BZ          t,1F
            CMPU        t,$1,#A % :BinaryRead
            BZ          t,1F
            CMPU        t,$1,#C % :BinaryReadWrite
            BZ          t,1F
            POP         0,0
1H          POP         0,1
IsReadableG SET         $0,t
IsReadable  GET         $1,:rJ
            SET         $3,arg0
            PUSHJ       $2,IsReadableJ
            JMP         1F
            SET         $0,0
            PUT         :rJ,$1
            SET         t,$0
            POP         1,0
1H          SET         $0,1
            NEG         $0,$0
            PUT         :rJ,$1
            SET         t,$0
            POP         1,0


%%
% :MM:__FILE:IsWritableJ
%
% PUSHJ:
%   arg0 - lowest byte defines the file handle
%   no return value
%
% :MM:__FILE:IsWritableG
% :MM:__FILE:IsWritable
%

            .global :MM:__FILE:IsWritableJ
            .global :MM:__FILE:IsWritableG
            .global :MM:__FILE:IsWritable
pool        IS          $2
IsWritableJ AND         arg0,arg0,#FF
            LDA         pool,:MM:__FILE:Pool
            LDBU        $1,pool,arg0
            CMPU        t,$1,#9 % :TextRead
            BZ          t,1F
            CMPU        t,$1,#B % :BinaryRead
            BZ          t,1F
            CMPU        t,$1,#C % :BinaryReadWrite
            BZ          t,1F
            POP         0,0
1H          POP         0,1
IsWritableG SET         $0,t
IsWritable  GET         $1,:rJ
            SET         $3,arg0
            PUSHJ       $2,IsWritableJ
            JMP         1F
            SET         $0,0
            PUT         :rJ,$1
            SET         t,$0
            POP         1,0
1H          SET         $0,1
            NEG         $0,$0
            PUT         :rJ,$1
            SET         t,$0
            POP         1,0


%%
% :MM:__FILE:TellJ
%
% PUSHJ:
%   arg0 - file handle
%   retm - current file position in bytes from the beginning
%
% :MM:__FILE:Tell
% :MM:__FILE:TellG
%

            .global :MM:__FILE:TellJ
            .global :MM:__FILE:TellG
            .global :MM:__FILE:Tell
TellTable   TRAP 0,Ftell,0; JMP 7F
            TRAP 0,Ftell,1; JMP 7F
            TRAP 0,Ftell,2; JMP 7F
            TRAP 0,Ftell,3; JMP 7F
            TRAP 0,Ftell,4; JMP 7F
            TRAP 0,Ftell,5; JMP 7F
            TRAP 0,Ftell,6; JMP 7F
            TRAP 0,Ftell,7; JMP 7F
            TRAP 0,Ftell,8; JMP 7F
            TRAP 0,Ftell,9; JMP 7F
            TRAP 0,Ftell,10; JMP 7F
            TRAP 0,Ftell,11; JMP 7F
            TRAP 0,Ftell,12; JMP 7F
            TRAP 0,Ftell,13; JMP 7F
            TRAP 0,Ftell,14; JMP 7F
            TRAP 0,Ftell,15; JMP 7F
            TRAP 0,Ftell,16; JMP 7F
            TRAP 0,Ftell,17; JMP 7F
            TRAP 0,Ftell,18; JMP 7F
            TRAP 0,Ftell,19; JMP 7F
            TRAP 0,Ftell,20; JMP 7F
            TRAP 0,Ftell,21; JMP 7F
            TRAP 0,Ftell,22; JMP 7F
            TRAP 0,Ftell,23; JMP 7F
            TRAP 0,Ftell,24; JMP 7F
            TRAP 0,Ftell,25; JMP 7F
            TRAP 0,Ftell,26; JMP 7F
            TRAP 0,Ftell,27; JMP 7F
            TRAP 0,Ftell,28; JMP 7F
            TRAP 0,Ftell,29; JMP 7F
            TRAP 0,Ftell,30; JMP 7F
            TRAP 0,Ftell,31; JMP 7F
            TRAP 0,Ftell,32; JMP 7F
            TRAP 0,Ftell,33; JMP 7F
            TRAP 0,Ftell,34; JMP 7F
            TRAP 0,Ftell,35; JMP 7F
            TRAP 0,Ftell,36; JMP 7F
            TRAP 0,Ftell,37; JMP 7F
            TRAP 0,Ftell,38; JMP 7F
            TRAP 0,Ftell,39; JMP 7F
            TRAP 0,Ftell,40; JMP 7F
            TRAP 0,Ftell,41; JMP 7F
            TRAP 0,Ftell,42; JMP 7F
            TRAP 0,Ftell,43; JMP 7F
            TRAP 0,Ftell,44; JMP 7F
            TRAP 0,Ftell,45; JMP 7F
            TRAP 0,Ftell,46; JMP 7F
            TRAP 0,Ftell,47; JMP 7F
            TRAP 0,Ftell,48; JMP 7F
            TRAP 0,Ftell,49; JMP 7F
            TRAP 0,Ftell,50; JMP 7F
            TRAP 0,Ftell,51; JMP 7F
            TRAP 0,Ftell,52; JMP 7F
            TRAP 0,Ftell,53; JMP 7F
            TRAP 0,Ftell,54; JMP 7F
            TRAP 0,Ftell,55; JMP 7F
            TRAP 0,Ftell,56; JMP 7F
            TRAP 0,Ftell,57; JMP 7F
            TRAP 0,Ftell,58; JMP 7F
            TRAP 0,Ftell,59; JMP 7F
            TRAP 0,Ftell,60; JMP 7F
            TRAP 0,Ftell,61; JMP 7F
            TRAP 0,Ftell,62; JMP 7F
            TRAP 0,Ftell,63; JMP 7F
            TRAP 0,Ftell,64; JMP 7F
            TRAP 0,Ftell,65; JMP 7F
            TRAP 0,Ftell,66; JMP 7F
            TRAP 0,Ftell,67; JMP 7F
            TRAP 0,Ftell,68; JMP 7F
            TRAP 0,Ftell,69; JMP 7F
            TRAP 0,Ftell,70; JMP 7F
            TRAP 0,Ftell,71; JMP 7F
            TRAP 0,Ftell,72; JMP 7F
            TRAP 0,Ftell,73; JMP 7F
            TRAP 0,Ftell,74; JMP 7F
            TRAP 0,Ftell,75; JMP 7F
            TRAP 0,Ftell,76; JMP 7F
            TRAP 0,Ftell,77; JMP 7F
            TRAP 0,Ftell,78; JMP 7F
            TRAP 0,Ftell,79; JMP 7F
            TRAP 0,Ftell,80; JMP 7F
            TRAP 0,Ftell,81; JMP 7F
            TRAP 0,Ftell,82; JMP 7F
            TRAP 0,Ftell,83; JMP 7F
            TRAP 0,Ftell,84; JMP 7F
            TRAP 0,Ftell,85; JMP 7F
            TRAP 0,Ftell,86; JMP 7F
            TRAP 0,Ftell,87; JMP 7F
            TRAP 0,Ftell,88; JMP 7F
            TRAP 0,Ftell,89; JMP 7F
            TRAP 0,Ftell,90; JMP 7F
            TRAP 0,Ftell,91; JMP 7F
            TRAP 0,Ftell,92; JMP 7F
            TRAP 0,Ftell,93; JMP 7F
            TRAP 0,Ftell,94; JMP 7F
            TRAP 0,Ftell,95; JMP 7F
            TRAP 0,Ftell,96; JMP 7F
            TRAP 0,Ftell,97; JMP 7F
            TRAP 0,Ftell,98; JMP 7F
            TRAP 0,Ftell,99; JMP 7F
            TRAP 0,Ftell,100; JMP 7F
            TRAP 0,Ftell,101; JMP 7F
            TRAP 0,Ftell,102; JMP 7F
            TRAP 0,Ftell,103; JMP 7F
            TRAP 0,Ftell,104; JMP 7F
            TRAP 0,Ftell,105; JMP 7F
            TRAP 0,Ftell,106; JMP 7F
            TRAP 0,Ftell,107; JMP 7F
            TRAP 0,Ftell,108; JMP 7F
            TRAP 0,Ftell,109; JMP 7F
            TRAP 0,Ftell,110; JMP 7F
            TRAP 0,Ftell,111; JMP 7F
            TRAP 0,Ftell,112; JMP 7F
            TRAP 0,Ftell,113; JMP 7F
            TRAP 0,Ftell,114; JMP 7F
            TRAP 0,Ftell,115; JMP 7F
            TRAP 0,Ftell,116; JMP 7F
            TRAP 0,Ftell,117; JMP 7F
            TRAP 0,Ftell,118; JMP 7F
            TRAP 0,Ftell,119; JMP 7F
            TRAP 0,Ftell,120; JMP 7F
            TRAP 0,Ftell,121; JMP 7F
            TRAP 0,Ftell,122; JMP 7F
            TRAP 0,Ftell,123; JMP 7F
            TRAP 0,Ftell,124; JMP 7F
            TRAP 0,Ftell,125; JMP 7F
            TRAP 0,Ftell,126; JMP 7F
            TRAP 0,Ftell,127; JMP 7F
            TRAP 0,Ftell,128; JMP 7F
            TRAP 0,Ftell,129; JMP 7F
            TRAP 0,Ftell,130; JMP 7F
            TRAP 0,Ftell,131; JMP 7F
            TRAP 0,Ftell,132; JMP 7F
            TRAP 0,Ftell,133; JMP 7F
            TRAP 0,Ftell,134; JMP 7F
            TRAP 0,Ftell,135; JMP 7F
            TRAP 0,Ftell,136; JMP 7F
            TRAP 0,Ftell,137; JMP 7F
            TRAP 0,Ftell,138; JMP 7F
            TRAP 0,Ftell,139; JMP 7F
            TRAP 0,Ftell,140; JMP 7F
            TRAP 0,Ftell,141; JMP 7F
            TRAP 0,Ftell,142; JMP 7F
            TRAP 0,Ftell,143; JMP 7F
            TRAP 0,Ftell,144; JMP 7F
            TRAP 0,Ftell,145; JMP 7F
            TRAP 0,Ftell,146; JMP 7F
            TRAP 0,Ftell,147; JMP 7F
            TRAP 0,Ftell,148; JMP 7F
            TRAP 0,Ftell,149; JMP 7F
            TRAP 0,Ftell,150; JMP 7F
            TRAP 0,Ftell,151; JMP 7F
            TRAP 0,Ftell,152; JMP 7F
            TRAP 0,Ftell,153; JMP 7F
            TRAP 0,Ftell,154; JMP 7F
            TRAP 0,Ftell,155; JMP 7F
            TRAP 0,Ftell,156; JMP 7F
            TRAP 0,Ftell,157; JMP 7F
            TRAP 0,Ftell,158; JMP 7F
            TRAP 0,Ftell,159; JMP 7F
            TRAP 0,Ftell,160; JMP 7F
            TRAP 0,Ftell,161; JMP 7F
            TRAP 0,Ftell,162; JMP 7F
            TRAP 0,Ftell,163; JMP 7F
            TRAP 0,Ftell,164; JMP 7F
            TRAP 0,Ftell,165; JMP 7F
            TRAP 0,Ftell,166; JMP 7F
            TRAP 0,Ftell,167; JMP 7F
            TRAP 0,Ftell,168; JMP 7F
            TRAP 0,Ftell,169; JMP 7F
            TRAP 0,Ftell,170; JMP 7F
            TRAP 0,Ftell,171; JMP 7F
            TRAP 0,Ftell,172; JMP 7F
            TRAP 0,Ftell,173; JMP 7F
            TRAP 0,Ftell,174; JMP 7F
            TRAP 0,Ftell,175; JMP 7F
            TRAP 0,Ftell,176; JMP 7F
            TRAP 0,Ftell,177; JMP 7F
            TRAP 0,Ftell,178; JMP 7F
            TRAP 0,Ftell,179; JMP 7F
            TRAP 0,Ftell,180; JMP 7F
            TRAP 0,Ftell,181; JMP 7F
            TRAP 0,Ftell,182; JMP 7F
            TRAP 0,Ftell,183; JMP 7F
            TRAP 0,Ftell,184; JMP 7F
            TRAP 0,Ftell,185; JMP 7F
            TRAP 0,Ftell,186; JMP 7F
            TRAP 0,Ftell,187; JMP 7F
            TRAP 0,Ftell,188; JMP 7F
            TRAP 0,Ftell,189; JMP 7F
            TRAP 0,Ftell,190; JMP 7F
            TRAP 0,Ftell,191; JMP 7F
            TRAP 0,Ftell,192; JMP 7F
            TRAP 0,Ftell,193; JMP 7F
            TRAP 0,Ftell,194; JMP 7F
            TRAP 0,Ftell,195; JMP 7F
            TRAP 0,Ftell,196; JMP 7F
            TRAP 0,Ftell,197; JMP 7F
            TRAP 0,Ftell,198; JMP 7F
            TRAP 0,Ftell,199; JMP 7F
            TRAP 0,Ftell,200; JMP 7F
            TRAP 0,Ftell,201; JMP 7F
            TRAP 0,Ftell,202; JMP 7F
            TRAP 0,Ftell,203; JMP 7F
            TRAP 0,Ftell,204; JMP 7F
            TRAP 0,Ftell,205; JMP 7F
            TRAP 0,Ftell,206; JMP 7F
            TRAP 0,Ftell,207; JMP 7F
            TRAP 0,Ftell,208; JMP 7F
            TRAP 0,Ftell,209; JMP 7F
            TRAP 0,Ftell,210; JMP 7F
            TRAP 0,Ftell,211; JMP 7F
            TRAP 0,Ftell,212; JMP 7F
            TRAP 0,Ftell,213; JMP 7F
            TRAP 0,Ftell,214; JMP 7F
            TRAP 0,Ftell,215; JMP 7F
            TRAP 0,Ftell,216; JMP 7F
            TRAP 0,Ftell,217; JMP 7F
            TRAP 0,Ftell,218; JMP 7F
            TRAP 0,Ftell,219; JMP 7F
            TRAP 0,Ftell,220; JMP 7F
            TRAP 0,Ftell,221; JMP 7F
            TRAP 0,Ftell,222; JMP 7F
            TRAP 0,Ftell,223; JMP 7F
            TRAP 0,Ftell,224; JMP 7F
            TRAP 0,Ftell,225; JMP 7F
            TRAP 0,Ftell,226; JMP 7F
            TRAP 0,Ftell,227; JMP 7F
            TRAP 0,Ftell,228; JMP 7F
            TRAP 0,Ftell,229; JMP 7F
            TRAP 0,Ftell,230; JMP 7F
            TRAP 0,Ftell,231; JMP 7F
            TRAP 0,Ftell,232; JMP 7F
            TRAP 0,Ftell,233; JMP 7F
            TRAP 0,Ftell,234; JMP 7F
            TRAP 0,Ftell,235; JMP 7F
            TRAP 0,Ftell,236; JMP 7F
            TRAP 0,Ftell,237; JMP 7F
            TRAP 0,Ftell,238; JMP 7F
            TRAP 0,Ftell,239; JMP 7F
            TRAP 0,Ftell,240; JMP 7F
            TRAP 0,Ftell,241; JMP 7F
            TRAP 0,Ftell,242; JMP 7F
            TRAP 0,Ftell,243; JMP 7F
            TRAP 0,Ftell,244; JMP 7F
            TRAP 0,Ftell,245; JMP 7F
            TRAP 0,Ftell,246; JMP 7F
            TRAP 0,Ftell,247; JMP 7F
            TRAP 0,Ftell,248; JMP 7F
            TRAP 0,Ftell,249; JMP 7F
            TRAP 0,Ftell,250; JMP 7F
            TRAP 0,Ftell,251; JMP 7F
            TRAP 0,Ftell,252; JMP 7F
            TRAP 0,Ftell,253; JMP 7F
            TRAP 0,Ftell,254; JMP 7F
            TRAP 0,Ftell,255; JMP 7F
TellJ       AND         arg0,arg0,#FF
            GET         $1,:rJ
            SLU         arg0,arg0,3 % *8
            LDA         $2,TellTable
            GO          $2,$2,arg0
7H          SET         ret0,t
            % check that ret0 >= 0
            BN          $0,9F
            PUT         :rJ,$1
            POP         1,1
9H          PUT         :rJ,$1
            POP         0,0
Tell        SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,TellJ
            JMP         9F
            PUT         :rJ,$1
            SET         ret0,$2
            POP         1,0
9H          SET         t,$1 % :rJ
            LDA         $1,:MM:__FILE:STRS:Tell1
            SET         $2,arg0
            LDA         $3,:MM:__FILE:STRS:Tell2
            PUSHJ       $0,:MM:__ERROR:Error3RB2
TellG       SET         $2,t
            GET         $0,:rJ
            PUSHJ       $1,Tell
            SET         t,$1
            PUT         :rJ,$0
            POP         0,0


%%
% :MM:__FILE:SizeJ
%
% PUSHJ:
%   arg0 - file handle
%   retm - file size in bytes
%
% :MM:__FILE:Size
% :MM:__FILE:SizeG
%
            .global :MM:__FILE:SizeJ
            .global :MM:__FILE:SizeG
            .global :MM:__FILE:Size
SizeJ       GET         $1,:rJ
            SET         $3,arg0
            PUSHJ       $2,TellJ % save pointer
            JMP         9F
            SET         $4,arg0
            NEG         $5,0,1
            PUSHJ       $3,SeekJ % move pointer to end
            JMP         9F
            SET         $4,arg0
            PUSHJ       $3,TellJ % get file size
            JMP         9F
            SET         $5,arg0
            SET         $6,$2
            PUSHJ       $4,SeekJ % restore file pointer
            JMP         9F
            PUT         :rJ,$1
            SET         ret0,$3
            POP         1,1
9H          PUT         :rJ,$1
            POP         0,0
Size        GET         $1,:rJ
            SET         $3,arg0
            PUSHJ       $2,SizeJ
            JMP         9F
            PUT         :rJ,$1
            SET         ret0,$2
            POP         1,0
9H          SET         t,$1 % :rJ
            LDA         $1,:MM:__FILE:STRS:Size1
            SET         $2,arg0
            LDA         $3,:MM:__FILE:STRS:Size2
            PUSHJ       $0,:MM:__ERROR:Error3RB2
SizeG       GET         $0,:rJ
            SET         $2,t
            PUSHJ       $1,Size
            SET         t,$1
            PUT         :rJ,$0
            POP         1,0


%%
% :MM:__FILE:SeekJ
%
% PUSHJ:
%   arg0 - file handle
%   arg1 - offset
%   no return values
%
% :MM:__FILE:Seek
%

            .global :MM:__FILE:SeekJ
            .global :MM:__FILE:Seek
SeekTable   TRAP 0,Fseek,0; JMP 7F
            TRAP 0,Fseek,1; JMP 7F
            TRAP 0,Fseek,2; JMP 7F
            TRAP 0,Fseek,3; JMP 7F
            TRAP 0,Fseek,4; JMP 7F
            TRAP 0,Fseek,5; JMP 7F
            TRAP 0,Fseek,6; JMP 7F
            TRAP 0,Fseek,7; JMP 7F
            TRAP 0,Fseek,8; JMP 7F
            TRAP 0,Fseek,9; JMP 7F
            TRAP 0,Fseek,10; JMP 7F
            TRAP 0,Fseek,11; JMP 7F
            TRAP 0,Fseek,12; JMP 7F
            TRAP 0,Fseek,13; JMP 7F
            TRAP 0,Fseek,14; JMP 7F
            TRAP 0,Fseek,15; JMP 7F
            TRAP 0,Fseek,16; JMP 7F
            TRAP 0,Fseek,17; JMP 7F
            TRAP 0,Fseek,18; JMP 7F
            TRAP 0,Fseek,19; JMP 7F
            TRAP 0,Fseek,20; JMP 7F
            TRAP 0,Fseek,21; JMP 7F
            TRAP 0,Fseek,22; JMP 7F
            TRAP 0,Fseek,23; JMP 7F
            TRAP 0,Fseek,24; JMP 7F
            TRAP 0,Fseek,25; JMP 7F
            TRAP 0,Fseek,26; JMP 7F
            TRAP 0,Fseek,27; JMP 7F
            TRAP 0,Fseek,28; JMP 7F
            TRAP 0,Fseek,29; JMP 7F
            TRAP 0,Fseek,30; JMP 7F
            TRAP 0,Fseek,31; JMP 7F
            TRAP 0,Fseek,32; JMP 7F
            TRAP 0,Fseek,33; JMP 7F
            TRAP 0,Fseek,34; JMP 7F
            TRAP 0,Fseek,35; JMP 7F
            TRAP 0,Fseek,36; JMP 7F
            TRAP 0,Fseek,37; JMP 7F
            TRAP 0,Fseek,38; JMP 7F
            TRAP 0,Fseek,39; JMP 7F
            TRAP 0,Fseek,40; JMP 7F
            TRAP 0,Fseek,41; JMP 7F
            TRAP 0,Fseek,42; JMP 7F
            TRAP 0,Fseek,43; JMP 7F
            TRAP 0,Fseek,44; JMP 7F
            TRAP 0,Fseek,45; JMP 7F
            TRAP 0,Fseek,46; JMP 7F
            TRAP 0,Fseek,47; JMP 7F
            TRAP 0,Fseek,48; JMP 7F
            TRAP 0,Fseek,49; JMP 7F
            TRAP 0,Fseek,50; JMP 7F
            TRAP 0,Fseek,51; JMP 7F
            TRAP 0,Fseek,52; JMP 7F
            TRAP 0,Fseek,53; JMP 7F
            TRAP 0,Fseek,54; JMP 7F
            TRAP 0,Fseek,55; JMP 7F
            TRAP 0,Fseek,56; JMP 7F
            TRAP 0,Fseek,57; JMP 7F
            TRAP 0,Fseek,58; JMP 7F
            TRAP 0,Fseek,59; JMP 7F
            TRAP 0,Fseek,60; JMP 7F
            TRAP 0,Fseek,61; JMP 7F
            TRAP 0,Fseek,62; JMP 7F
            TRAP 0,Fseek,63; JMP 7F
            TRAP 0,Fseek,64; JMP 7F
            TRAP 0,Fseek,65; JMP 7F
            TRAP 0,Fseek,66; JMP 7F
            TRAP 0,Fseek,67; JMP 7F
            TRAP 0,Fseek,68; JMP 7F
            TRAP 0,Fseek,69; JMP 7F
            TRAP 0,Fseek,70; JMP 7F
            TRAP 0,Fseek,71; JMP 7F
            TRAP 0,Fseek,72; JMP 7F
            TRAP 0,Fseek,73; JMP 7F
            TRAP 0,Fseek,74; JMP 7F
            TRAP 0,Fseek,75; JMP 7F
            TRAP 0,Fseek,76; JMP 7F
            TRAP 0,Fseek,77; JMP 7F
            TRAP 0,Fseek,78; JMP 7F
            TRAP 0,Fseek,79; JMP 7F
            TRAP 0,Fseek,80; JMP 7F
            TRAP 0,Fseek,81; JMP 7F
            TRAP 0,Fseek,82; JMP 7F
            TRAP 0,Fseek,83; JMP 7F
            TRAP 0,Fseek,84; JMP 7F
            TRAP 0,Fseek,85; JMP 7F
            TRAP 0,Fseek,86; JMP 7F
            TRAP 0,Fseek,87; JMP 7F
            TRAP 0,Fseek,88; JMP 7F
            TRAP 0,Fseek,89; JMP 7F
            TRAP 0,Fseek,90; JMP 7F
            TRAP 0,Fseek,91; JMP 7F
            TRAP 0,Fseek,92; JMP 7F
            TRAP 0,Fseek,93; JMP 7F
            TRAP 0,Fseek,94; JMP 7F
            TRAP 0,Fseek,95; JMP 7F
            TRAP 0,Fseek,96; JMP 7F
            TRAP 0,Fseek,97; JMP 7F
            TRAP 0,Fseek,98; JMP 7F
            TRAP 0,Fseek,99; JMP 7F
            TRAP 0,Fseek,100; JMP 7F
            TRAP 0,Fseek,101; JMP 7F
            TRAP 0,Fseek,102; JMP 7F
            TRAP 0,Fseek,103; JMP 7F
            TRAP 0,Fseek,104; JMP 7F
            TRAP 0,Fseek,105; JMP 7F
            TRAP 0,Fseek,106; JMP 7F
            TRAP 0,Fseek,107; JMP 7F
            TRAP 0,Fseek,108; JMP 7F
            TRAP 0,Fseek,109; JMP 7F
            TRAP 0,Fseek,110; JMP 7F
            TRAP 0,Fseek,111; JMP 7F
            TRAP 0,Fseek,112; JMP 7F
            TRAP 0,Fseek,113; JMP 7F
            TRAP 0,Fseek,114; JMP 7F
            TRAP 0,Fseek,115; JMP 7F
            TRAP 0,Fseek,116; JMP 7F
            TRAP 0,Fseek,117; JMP 7F
            TRAP 0,Fseek,118; JMP 7F
            TRAP 0,Fseek,119; JMP 7F
            TRAP 0,Fseek,120; JMP 7F
            TRAP 0,Fseek,121; JMP 7F
            TRAP 0,Fseek,122; JMP 7F
            TRAP 0,Fseek,123; JMP 7F
            TRAP 0,Fseek,124; JMP 7F
            TRAP 0,Fseek,125; JMP 7F
            TRAP 0,Fseek,126; JMP 7F
            TRAP 0,Fseek,127; JMP 7F
            TRAP 0,Fseek,128; JMP 7F
            TRAP 0,Fseek,129; JMP 7F
            TRAP 0,Fseek,130; JMP 7F
            TRAP 0,Fseek,131; JMP 7F
            TRAP 0,Fseek,132; JMP 7F
            TRAP 0,Fseek,133; JMP 7F
            TRAP 0,Fseek,134; JMP 7F
            TRAP 0,Fseek,135; JMP 7F
            TRAP 0,Fseek,136; JMP 7F
            TRAP 0,Fseek,137; JMP 7F
            TRAP 0,Fseek,138; JMP 7F
            TRAP 0,Fseek,139; JMP 7F
            TRAP 0,Fseek,140; JMP 7F
            TRAP 0,Fseek,141; JMP 7F
            TRAP 0,Fseek,142; JMP 7F
            TRAP 0,Fseek,143; JMP 7F
            TRAP 0,Fseek,144; JMP 7F
            TRAP 0,Fseek,145; JMP 7F
            TRAP 0,Fseek,146; JMP 7F
            TRAP 0,Fseek,147; JMP 7F
            TRAP 0,Fseek,148; JMP 7F
            TRAP 0,Fseek,149; JMP 7F
            TRAP 0,Fseek,150; JMP 7F
            TRAP 0,Fseek,151; JMP 7F
            TRAP 0,Fseek,152; JMP 7F
            TRAP 0,Fseek,153; JMP 7F
            TRAP 0,Fseek,154; JMP 7F
            TRAP 0,Fseek,155; JMP 7F
            TRAP 0,Fseek,156; JMP 7F
            TRAP 0,Fseek,157; JMP 7F
            TRAP 0,Fseek,158; JMP 7F
            TRAP 0,Fseek,159; JMP 7F
            TRAP 0,Fseek,160; JMP 7F
            TRAP 0,Fseek,161; JMP 7F
            TRAP 0,Fseek,162; JMP 7F
            TRAP 0,Fseek,163; JMP 7F
            TRAP 0,Fseek,164; JMP 7F
            TRAP 0,Fseek,165; JMP 7F
            TRAP 0,Fseek,166; JMP 7F
            TRAP 0,Fseek,167; JMP 7F
            TRAP 0,Fseek,168; JMP 7F
            TRAP 0,Fseek,169; JMP 7F
            TRAP 0,Fseek,170; JMP 7F
            TRAP 0,Fseek,171; JMP 7F
            TRAP 0,Fseek,172; JMP 7F
            TRAP 0,Fseek,173; JMP 7F
            TRAP 0,Fseek,174; JMP 7F
            TRAP 0,Fseek,175; JMP 7F
            TRAP 0,Fseek,176; JMP 7F
            TRAP 0,Fseek,177; JMP 7F
            TRAP 0,Fseek,178; JMP 7F
            TRAP 0,Fseek,179; JMP 7F
            TRAP 0,Fseek,180; JMP 7F
            TRAP 0,Fseek,181; JMP 7F
            TRAP 0,Fseek,182; JMP 7F
            TRAP 0,Fseek,183; JMP 7F
            TRAP 0,Fseek,184; JMP 7F
            TRAP 0,Fseek,185; JMP 7F
            TRAP 0,Fseek,186; JMP 7F
            TRAP 0,Fseek,187; JMP 7F
            TRAP 0,Fseek,188; JMP 7F
            TRAP 0,Fseek,189; JMP 7F
            TRAP 0,Fseek,190; JMP 7F
            TRAP 0,Fseek,191; JMP 7F
            TRAP 0,Fseek,192; JMP 7F
            TRAP 0,Fseek,193; JMP 7F
            TRAP 0,Fseek,194; JMP 7F
            TRAP 0,Fseek,195; JMP 7F
            TRAP 0,Fseek,196; JMP 7F
            TRAP 0,Fseek,197; JMP 7F
            TRAP 0,Fseek,198; JMP 7F
            TRAP 0,Fseek,199; JMP 7F
            TRAP 0,Fseek,200; JMP 7F
            TRAP 0,Fseek,201; JMP 7F
            TRAP 0,Fseek,202; JMP 7F
            TRAP 0,Fseek,203; JMP 7F
            TRAP 0,Fseek,204; JMP 7F
            TRAP 0,Fseek,205; JMP 7F
            TRAP 0,Fseek,206; JMP 7F
            TRAP 0,Fseek,207; JMP 7F
            TRAP 0,Fseek,208; JMP 7F
            TRAP 0,Fseek,209; JMP 7F
            TRAP 0,Fseek,210; JMP 7F
            TRAP 0,Fseek,211; JMP 7F
            TRAP 0,Fseek,212; JMP 7F
            TRAP 0,Fseek,213; JMP 7F
            TRAP 0,Fseek,214; JMP 7F
            TRAP 0,Fseek,215; JMP 7F
            TRAP 0,Fseek,216; JMP 7F
            TRAP 0,Fseek,217; JMP 7F
            TRAP 0,Fseek,218; JMP 7F
            TRAP 0,Fseek,219; JMP 7F
            TRAP 0,Fseek,220; JMP 7F
            TRAP 0,Fseek,221; JMP 7F
            TRAP 0,Fseek,222; JMP 7F
            TRAP 0,Fseek,223; JMP 7F
            TRAP 0,Fseek,224; JMP 7F
            TRAP 0,Fseek,225; JMP 7F
            TRAP 0,Fseek,226; JMP 7F
            TRAP 0,Fseek,227; JMP 7F
            TRAP 0,Fseek,228; JMP 7F
            TRAP 0,Fseek,229; JMP 7F
            TRAP 0,Fseek,230; JMP 7F
            TRAP 0,Fseek,231; JMP 7F
            TRAP 0,Fseek,232; JMP 7F
            TRAP 0,Fseek,233; JMP 7F
            TRAP 0,Fseek,234; JMP 7F
            TRAP 0,Fseek,235; JMP 7F
            TRAP 0,Fseek,236; JMP 7F
            TRAP 0,Fseek,237; JMP 7F
            TRAP 0,Fseek,238; JMP 7F
            TRAP 0,Fseek,239; JMP 7F
            TRAP 0,Fseek,240; JMP 7F
            TRAP 0,Fseek,241; JMP 7F
            TRAP 0,Fseek,242; JMP 7F
            TRAP 0,Fseek,243; JMP 7F
            TRAP 0,Fseek,244; JMP 7F
            TRAP 0,Fseek,245; JMP 7F
            TRAP 0,Fseek,246; JMP 7F
            TRAP 0,Fseek,247; JMP 7F
            TRAP 0,Fseek,248; JMP 7F
            TRAP 0,Fseek,249; JMP 7F
            TRAP 0,Fseek,250; JMP 7F
            TRAP 0,Fseek,251; JMP 7F
            TRAP 0,Fseek,252; JMP 7F
            TRAP 0,Fseek,253; JMP 7F
            TRAP 0,Fseek,254; JMP 7F
            TRAP 0,Fseek,255; JMP 7F
SeekJ       AND         arg0,arg0,#FF
            GET         $2,:rJ
            SLU         arg0,arg0,3 % *8
            LDA         $3,SeekTable
            SET         t,arg1
            GO          $3,$3,arg0
7H          SET         ret0,t
            % check that ret0 >= 0
            BN          $0,9F
            PUT         :rJ,$2
            POP         0,1
9H          PUT         :rJ,$2
            POP         0,0
Seek        SET         $4,arg0
            SET         $5,arg1
            GET         $2,:rJ
            PUSHJ       $3,SeekJ
            JMP         9F
            PUT         :rJ,$2
            POP         0,0
9H          SET         t,$2 % :rJ
            SET         $2,arg0
            SET         $4,arg1
            LDA         $1,:MM:__FILE:STRS:Seek1
            LDA         $3,:MM:__FILE:STRS:Seek2
            LDA         $5,:MM:__FILE:STRS:Seek3
            PUSHJ       $0,:MM:__ERROR:Error5RB24


%%
% :MM:__FILE:ReadJ
%
% PUSHJ:
%   arg0 - file handle
%   arg1 - pointer to buffer
%   arg2 - number of bytes to read
%   retm - (n - arg2), where n is the number of bytes that have been read
%
% :MM:__FILE:Read
%

            .section .data,"wa",@progbits
ReadBuffer  OCTA        #0,#0,#0

            .section .text,"ax",@progbits
            .global :MM:__FILE:ReadJ
            .global :MM:__FILE:Read
ReadTable   TRAP 0,Fread,0; JMP 7F
            TRAP 0,Fread,1; JMP 7F
            TRAP 0,Fread,2; JMP 7F
            TRAP 0,Fread,3; JMP 7F
            TRAP 0,Fread,4; JMP 7F
            TRAP 0,Fread,5; JMP 7F
            TRAP 0,Fread,6; JMP 7F
            TRAP 0,Fread,7; JMP 7F
            TRAP 0,Fread,8; JMP 7F
            TRAP 0,Fread,9; JMP 7F
            TRAP 0,Fread,10; JMP 7F
            TRAP 0,Fread,11; JMP 7F
            TRAP 0,Fread,12; JMP 7F
            TRAP 0,Fread,13; JMP 7F
            TRAP 0,Fread,14; JMP 7F
            TRAP 0,Fread,15; JMP 7F
            TRAP 0,Fread,16; JMP 7F
            TRAP 0,Fread,17; JMP 7F
            TRAP 0,Fread,18; JMP 7F
            TRAP 0,Fread,19; JMP 7F
            TRAP 0,Fread,20; JMP 7F
            TRAP 0,Fread,21; JMP 7F
            TRAP 0,Fread,22; JMP 7F
            TRAP 0,Fread,23; JMP 7F
            TRAP 0,Fread,24; JMP 7F
            TRAP 0,Fread,25; JMP 7F
            TRAP 0,Fread,26; JMP 7F
            TRAP 0,Fread,27; JMP 7F
            TRAP 0,Fread,28; JMP 7F
            TRAP 0,Fread,29; JMP 7F
            TRAP 0,Fread,30; JMP 7F
            TRAP 0,Fread,31; JMP 7F
            TRAP 0,Fread,32; JMP 7F
            TRAP 0,Fread,33; JMP 7F
            TRAP 0,Fread,34; JMP 7F
            TRAP 0,Fread,35; JMP 7F
            TRAP 0,Fread,36; JMP 7F
            TRAP 0,Fread,37; JMP 7F
            TRAP 0,Fread,38; JMP 7F
            TRAP 0,Fread,39; JMP 7F
            TRAP 0,Fread,40; JMP 7F
            TRAP 0,Fread,41; JMP 7F
            TRAP 0,Fread,42; JMP 7F
            TRAP 0,Fread,43; JMP 7F
            TRAP 0,Fread,44; JMP 7F
            TRAP 0,Fread,45; JMP 7F
            TRAP 0,Fread,46; JMP 7F
            TRAP 0,Fread,47; JMP 7F
            TRAP 0,Fread,48; JMP 7F
            TRAP 0,Fread,49; JMP 7F
            TRAP 0,Fread,50; JMP 7F
            TRAP 0,Fread,51; JMP 7F
            TRAP 0,Fread,52; JMP 7F
            TRAP 0,Fread,53; JMP 7F
            TRAP 0,Fread,54; JMP 7F
            TRAP 0,Fread,55; JMP 7F
            TRAP 0,Fread,56; JMP 7F
            TRAP 0,Fread,57; JMP 7F
            TRAP 0,Fread,58; JMP 7F
            TRAP 0,Fread,59; JMP 7F
            TRAP 0,Fread,60; JMP 7F
            TRAP 0,Fread,61; JMP 7F
            TRAP 0,Fread,62; JMP 7F
            TRAP 0,Fread,63; JMP 7F
            TRAP 0,Fread,64; JMP 7F
            TRAP 0,Fread,65; JMP 7F
            TRAP 0,Fread,66; JMP 7F
            TRAP 0,Fread,67; JMP 7F
            TRAP 0,Fread,68; JMP 7F
            TRAP 0,Fread,69; JMP 7F
            TRAP 0,Fread,70; JMP 7F
            TRAP 0,Fread,71; JMP 7F
            TRAP 0,Fread,72; JMP 7F
            TRAP 0,Fread,73; JMP 7F
            TRAP 0,Fread,74; JMP 7F
            TRAP 0,Fread,75; JMP 7F
            TRAP 0,Fread,76; JMP 7F
            TRAP 0,Fread,77; JMP 7F
            TRAP 0,Fread,78; JMP 7F
            TRAP 0,Fread,79; JMP 7F
            TRAP 0,Fread,80; JMP 7F
            TRAP 0,Fread,81; JMP 7F
            TRAP 0,Fread,82; JMP 7F
            TRAP 0,Fread,83; JMP 7F
            TRAP 0,Fread,84; JMP 7F
            TRAP 0,Fread,85; JMP 7F
            TRAP 0,Fread,86; JMP 7F
            TRAP 0,Fread,87; JMP 7F
            TRAP 0,Fread,88; JMP 7F
            TRAP 0,Fread,89; JMP 7F
            TRAP 0,Fread,90; JMP 7F
            TRAP 0,Fread,91; JMP 7F
            TRAP 0,Fread,92; JMP 7F
            TRAP 0,Fread,93; JMP 7F
            TRAP 0,Fread,94; JMP 7F
            TRAP 0,Fread,95; JMP 7F
            TRAP 0,Fread,96; JMP 7F
            TRAP 0,Fread,97; JMP 7F
            TRAP 0,Fread,98; JMP 7F
            TRAP 0,Fread,99; JMP 7F
            TRAP 0,Fread,100; JMP 7F
            TRAP 0,Fread,101; JMP 7F
            TRAP 0,Fread,102; JMP 7F
            TRAP 0,Fread,103; JMP 7F
            TRAP 0,Fread,104; JMP 7F
            TRAP 0,Fread,105; JMP 7F
            TRAP 0,Fread,106; JMP 7F
            TRAP 0,Fread,107; JMP 7F
            TRAP 0,Fread,108; JMP 7F
            TRAP 0,Fread,109; JMP 7F
            TRAP 0,Fread,110; JMP 7F
            TRAP 0,Fread,111; JMP 7F
            TRAP 0,Fread,112; JMP 7F
            TRAP 0,Fread,113; JMP 7F
            TRAP 0,Fread,114; JMP 7F
            TRAP 0,Fread,115; JMP 7F
            TRAP 0,Fread,116; JMP 7F
            TRAP 0,Fread,117; JMP 7F
            TRAP 0,Fread,118; JMP 7F
            TRAP 0,Fread,119; JMP 7F
            TRAP 0,Fread,120; JMP 7F
            TRAP 0,Fread,121; JMP 7F
            TRAP 0,Fread,122; JMP 7F
            TRAP 0,Fread,123; JMP 7F
            TRAP 0,Fread,124; JMP 7F
            TRAP 0,Fread,125; JMP 7F
            TRAP 0,Fread,126; JMP 7F
            TRAP 0,Fread,127; JMP 7F
            TRAP 0,Fread,128; JMP 7F
            TRAP 0,Fread,129; JMP 7F
            TRAP 0,Fread,130; JMP 7F
            TRAP 0,Fread,131; JMP 7F
            TRAP 0,Fread,132; JMP 7F
            TRAP 0,Fread,133; JMP 7F
            TRAP 0,Fread,134; JMP 7F
            TRAP 0,Fread,135; JMP 7F
            TRAP 0,Fread,136; JMP 7F
            TRAP 0,Fread,137; JMP 7F
            TRAP 0,Fread,138; JMP 7F
            TRAP 0,Fread,139; JMP 7F
            TRAP 0,Fread,140; JMP 7F
            TRAP 0,Fread,141; JMP 7F
            TRAP 0,Fread,142; JMP 7F
            TRAP 0,Fread,143; JMP 7F
            TRAP 0,Fread,144; JMP 7F
            TRAP 0,Fread,145; JMP 7F
            TRAP 0,Fread,146; JMP 7F
            TRAP 0,Fread,147; JMP 7F
            TRAP 0,Fread,148; JMP 7F
            TRAP 0,Fread,149; JMP 7F
            TRAP 0,Fread,150; JMP 7F
            TRAP 0,Fread,151; JMP 7F
            TRAP 0,Fread,152; JMP 7F
            TRAP 0,Fread,153; JMP 7F
            TRAP 0,Fread,154; JMP 7F
            TRAP 0,Fread,155; JMP 7F
            TRAP 0,Fread,156; JMP 7F
            TRAP 0,Fread,157; JMP 7F
            TRAP 0,Fread,158; JMP 7F
            TRAP 0,Fread,159; JMP 7F
            TRAP 0,Fread,160; JMP 7F
            TRAP 0,Fread,161; JMP 7F
            TRAP 0,Fread,162; JMP 7F
            TRAP 0,Fread,163; JMP 7F
            TRAP 0,Fread,164; JMP 7F
            TRAP 0,Fread,165; JMP 7F
            TRAP 0,Fread,166; JMP 7F
            TRAP 0,Fread,167; JMP 7F
            TRAP 0,Fread,168; JMP 7F
            TRAP 0,Fread,169; JMP 7F
            TRAP 0,Fread,170; JMP 7F
            TRAP 0,Fread,171; JMP 7F
            TRAP 0,Fread,172; JMP 7F
            TRAP 0,Fread,173; JMP 7F
            TRAP 0,Fread,174; JMP 7F
            TRAP 0,Fread,175; JMP 7F
            TRAP 0,Fread,176; JMP 7F
            TRAP 0,Fread,177; JMP 7F
            TRAP 0,Fread,178; JMP 7F
            TRAP 0,Fread,179; JMP 7F
            TRAP 0,Fread,180; JMP 7F
            TRAP 0,Fread,181; JMP 7F
            TRAP 0,Fread,182; JMP 7F
            TRAP 0,Fread,183; JMP 7F
            TRAP 0,Fread,184; JMP 7F
            TRAP 0,Fread,185; JMP 7F
            TRAP 0,Fread,186; JMP 7F
            TRAP 0,Fread,187; JMP 7F
            TRAP 0,Fread,188; JMP 7F
            TRAP 0,Fread,189; JMP 7F
            TRAP 0,Fread,190; JMP 7F
            TRAP 0,Fread,191; JMP 7F
            TRAP 0,Fread,192; JMP 7F
            TRAP 0,Fread,193; JMP 7F
            TRAP 0,Fread,194; JMP 7F
            TRAP 0,Fread,195; JMP 7F
            TRAP 0,Fread,196; JMP 7F
            TRAP 0,Fread,197; JMP 7F
            TRAP 0,Fread,198; JMP 7F
            TRAP 0,Fread,199; JMP 7F
            TRAP 0,Fread,200; JMP 7F
            TRAP 0,Fread,201; JMP 7F
            TRAP 0,Fread,202; JMP 7F
            TRAP 0,Fread,203; JMP 7F
            TRAP 0,Fread,204; JMP 7F
            TRAP 0,Fread,205; JMP 7F
            TRAP 0,Fread,206; JMP 7F
            TRAP 0,Fread,207; JMP 7F
            TRAP 0,Fread,208; JMP 7F
            TRAP 0,Fread,209; JMP 7F
            TRAP 0,Fread,210; JMP 7F
            TRAP 0,Fread,211; JMP 7F
            TRAP 0,Fread,212; JMP 7F
            TRAP 0,Fread,213; JMP 7F
            TRAP 0,Fread,214; JMP 7F
            TRAP 0,Fread,215; JMP 7F
            TRAP 0,Fread,216; JMP 7F
            TRAP 0,Fread,217; JMP 7F
            TRAP 0,Fread,218; JMP 7F
            TRAP 0,Fread,219; JMP 7F
            TRAP 0,Fread,220; JMP 7F
            TRAP 0,Fread,221; JMP 7F
            TRAP 0,Fread,222; JMP 7F
            TRAP 0,Fread,223; JMP 7F
            TRAP 0,Fread,224; JMP 7F
            TRAP 0,Fread,225; JMP 7F
            TRAP 0,Fread,226; JMP 7F
            TRAP 0,Fread,227; JMP 7F
            TRAP 0,Fread,228; JMP 7F
            TRAP 0,Fread,229; JMP 7F
            TRAP 0,Fread,230; JMP 7F
            TRAP 0,Fread,231; JMP 7F
            TRAP 0,Fread,232; JMP 7F
            TRAP 0,Fread,233; JMP 7F
            TRAP 0,Fread,234; JMP 7F
            TRAP 0,Fread,235; JMP 7F
            TRAP 0,Fread,236; JMP 7F
            TRAP 0,Fread,237; JMP 7F
            TRAP 0,Fread,238; JMP 7F
            TRAP 0,Fread,239; JMP 7F
            TRAP 0,Fread,240; JMP 7F
            TRAP 0,Fread,241; JMP 7F
            TRAP 0,Fread,242; JMP 7F
            TRAP 0,Fread,243; JMP 7F
            TRAP 0,Fread,244; JMP 7F
            TRAP 0,Fread,245; JMP 7F
            TRAP 0,Fread,246; JMP 7F
            TRAP 0,Fread,247; JMP 7F
            TRAP 0,Fread,248; JMP 7F
            TRAP 0,Fread,249; JMP 7F
            TRAP 0,Fread,250; JMP 7F
            TRAP 0,Fread,251; JMP 7F
            TRAP 0,Fread,252; JMP 7F
            TRAP 0,Fread,253; JMP 7F
            TRAP 0,Fread,254; JMP 7F
            TRAP 0,Fread,255; JMP 7F
ReadJ       BN          arg2,9F % invalid size
            AND         arg0,arg0,#FF
            GET         $3,:rJ
            SET         $5,arg0
            PUSHJ       $4,IsReadableJ
            JMP         9F % not readable
            SLU         arg0,arg0,3 % *8
            LDA         $4,ReadTable
            LDA         t,ReadBuffer
            PUSHJ       t,:MM:__THREAD:LockMutexG
            ADDU        t,t,#8
            STO         arg1,t,#0
            STO         arg2,t,#8
            GO          $4,$4,arg0
7H          SET         ret0,t
            LDA         t,ReadBuffer
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            % check that ret0 != - size - 1
            NEG         $1,0,$1
            SUB         $1,$1,1
            CMP         $1,$1,$0
            BZ          $1,9F
            PUT         :rJ,$3
            POP         1,1
9H          PUT         :rJ,$3
            POP         0,0
Read        SET         $4,arg2
            SET         $3,arg1
            SET         $2,arg0
            GET         $0,:rJ
            PUSHJ       $1,ReadJ
            JMP         9F
            PUT         :rJ,$0
            SET         ret0,$1
            POP         1,0
9H          SET         t,$0 % :rJ
            LDA         $1,:MM:__FILE:STRS:Read1
            LDA         $3,:MM:__FILE:STRS:Read2
            PUSHJ       $0,:MM:__ERROR:Error3RB2


%%
% :MM:__FILE:WriteJ
%
% PUSHJ:
%   arg0 - lowest byte defines the file handle
%   no return value
%
% :MM:__FILE:Write
%

            .section .data,"wa",@progbits
WriteBuffer OCTA        #0,#0,#0

            .section .text,"ax",@progbits
            .global :MM:__FILE:WriteJ
            .global :MM:__FILE:Write
WriteTable  TRAP 0,Fwrite,0; JMP 7F
            TRAP 0,Fwrite,1; JMP 7F
            TRAP 0,Fwrite,2; JMP 7F
            TRAP 0,Fwrite,3; JMP 7F
            TRAP 0,Fwrite,4; JMP 7F
            TRAP 0,Fwrite,5; JMP 7F
            TRAP 0,Fwrite,6; JMP 7F
            TRAP 0,Fwrite,7; JMP 7F
            TRAP 0,Fwrite,8; JMP 7F
            TRAP 0,Fwrite,9; JMP 7F
            TRAP 0,Fwrite,10; JMP 7F
            TRAP 0,Fwrite,11; JMP 7F
            TRAP 0,Fwrite,12; JMP 7F
            TRAP 0,Fwrite,13; JMP 7F
            TRAP 0,Fwrite,14; JMP 7F
            TRAP 0,Fwrite,15; JMP 7F
            TRAP 0,Fwrite,16; JMP 7F
            TRAP 0,Fwrite,17; JMP 7F
            TRAP 0,Fwrite,18; JMP 7F
            TRAP 0,Fwrite,19; JMP 7F
            TRAP 0,Fwrite,20; JMP 7F
            TRAP 0,Fwrite,21; JMP 7F
            TRAP 0,Fwrite,22; JMP 7F
            TRAP 0,Fwrite,23; JMP 7F
            TRAP 0,Fwrite,24; JMP 7F
            TRAP 0,Fwrite,25; JMP 7F
            TRAP 0,Fwrite,26; JMP 7F
            TRAP 0,Fwrite,27; JMP 7F
            TRAP 0,Fwrite,28; JMP 7F
            TRAP 0,Fwrite,29; JMP 7F
            TRAP 0,Fwrite,30; JMP 7F
            TRAP 0,Fwrite,31; JMP 7F
            TRAP 0,Fwrite,32; JMP 7F
            TRAP 0,Fwrite,33; JMP 7F
            TRAP 0,Fwrite,34; JMP 7F
            TRAP 0,Fwrite,35; JMP 7F
            TRAP 0,Fwrite,36; JMP 7F
            TRAP 0,Fwrite,37; JMP 7F
            TRAP 0,Fwrite,38; JMP 7F
            TRAP 0,Fwrite,39; JMP 7F
            TRAP 0,Fwrite,40; JMP 7F
            TRAP 0,Fwrite,41; JMP 7F
            TRAP 0,Fwrite,42; JMP 7F
            TRAP 0,Fwrite,43; JMP 7F
            TRAP 0,Fwrite,44; JMP 7F
            TRAP 0,Fwrite,45; JMP 7F
            TRAP 0,Fwrite,46; JMP 7F
            TRAP 0,Fwrite,47; JMP 7F
            TRAP 0,Fwrite,48; JMP 7F
            TRAP 0,Fwrite,49; JMP 7F
            TRAP 0,Fwrite,50; JMP 7F
            TRAP 0,Fwrite,51; JMP 7F
            TRAP 0,Fwrite,52; JMP 7F
            TRAP 0,Fwrite,53; JMP 7F
            TRAP 0,Fwrite,54; JMP 7F
            TRAP 0,Fwrite,55; JMP 7F
            TRAP 0,Fwrite,56; JMP 7F
            TRAP 0,Fwrite,57; JMP 7F
            TRAP 0,Fwrite,58; JMP 7F
            TRAP 0,Fwrite,59; JMP 7F
            TRAP 0,Fwrite,60; JMP 7F
            TRAP 0,Fwrite,61; JMP 7F
            TRAP 0,Fwrite,62; JMP 7F
            TRAP 0,Fwrite,63; JMP 7F
            TRAP 0,Fwrite,64; JMP 7F
            TRAP 0,Fwrite,65; JMP 7F
            TRAP 0,Fwrite,66; JMP 7F
            TRAP 0,Fwrite,67; JMP 7F
            TRAP 0,Fwrite,68; JMP 7F
            TRAP 0,Fwrite,69; JMP 7F
            TRAP 0,Fwrite,70; JMP 7F
            TRAP 0,Fwrite,71; JMP 7F
            TRAP 0,Fwrite,72; JMP 7F
            TRAP 0,Fwrite,73; JMP 7F
            TRAP 0,Fwrite,74; JMP 7F
            TRAP 0,Fwrite,75; JMP 7F
            TRAP 0,Fwrite,76; JMP 7F
            TRAP 0,Fwrite,77; JMP 7F
            TRAP 0,Fwrite,78; JMP 7F
            TRAP 0,Fwrite,79; JMP 7F
            TRAP 0,Fwrite,80; JMP 7F
            TRAP 0,Fwrite,81; JMP 7F
            TRAP 0,Fwrite,82; JMP 7F
            TRAP 0,Fwrite,83; JMP 7F
            TRAP 0,Fwrite,84; JMP 7F
            TRAP 0,Fwrite,85; JMP 7F
            TRAP 0,Fwrite,86; JMP 7F
            TRAP 0,Fwrite,87; JMP 7F
            TRAP 0,Fwrite,88; JMP 7F
            TRAP 0,Fwrite,89; JMP 7F
            TRAP 0,Fwrite,90; JMP 7F
            TRAP 0,Fwrite,91; JMP 7F
            TRAP 0,Fwrite,92; JMP 7F
            TRAP 0,Fwrite,93; JMP 7F
            TRAP 0,Fwrite,94; JMP 7F
            TRAP 0,Fwrite,95; JMP 7F
            TRAP 0,Fwrite,96; JMP 7F
            TRAP 0,Fwrite,97; JMP 7F
            TRAP 0,Fwrite,98; JMP 7F
            TRAP 0,Fwrite,99; JMP 7F
            TRAP 0,Fwrite,100; JMP 7F
            TRAP 0,Fwrite,101; JMP 7F
            TRAP 0,Fwrite,102; JMP 7F
            TRAP 0,Fwrite,103; JMP 7F
            TRAP 0,Fwrite,104; JMP 7F
            TRAP 0,Fwrite,105; JMP 7F
            TRAP 0,Fwrite,106; JMP 7F
            TRAP 0,Fwrite,107; JMP 7F
            TRAP 0,Fwrite,108; JMP 7F
            TRAP 0,Fwrite,109; JMP 7F
            TRAP 0,Fwrite,110; JMP 7F
            TRAP 0,Fwrite,111; JMP 7F
            TRAP 0,Fwrite,112; JMP 7F
            TRAP 0,Fwrite,113; JMP 7F
            TRAP 0,Fwrite,114; JMP 7F
            TRAP 0,Fwrite,115; JMP 7F
            TRAP 0,Fwrite,116; JMP 7F
            TRAP 0,Fwrite,117; JMP 7F
            TRAP 0,Fwrite,118; JMP 7F
            TRAP 0,Fwrite,119; JMP 7F
            TRAP 0,Fwrite,120; JMP 7F
            TRAP 0,Fwrite,121; JMP 7F
            TRAP 0,Fwrite,122; JMP 7F
            TRAP 0,Fwrite,123; JMP 7F
            TRAP 0,Fwrite,124; JMP 7F
            TRAP 0,Fwrite,125; JMP 7F
            TRAP 0,Fwrite,126; JMP 7F
            TRAP 0,Fwrite,127; JMP 7F
            TRAP 0,Fwrite,128; JMP 7F
            TRAP 0,Fwrite,129; JMP 7F
            TRAP 0,Fwrite,130; JMP 7F
            TRAP 0,Fwrite,131; JMP 7F
            TRAP 0,Fwrite,132; JMP 7F
            TRAP 0,Fwrite,133; JMP 7F
            TRAP 0,Fwrite,134; JMP 7F
            TRAP 0,Fwrite,135; JMP 7F
            TRAP 0,Fwrite,136; JMP 7F
            TRAP 0,Fwrite,137; JMP 7F
            TRAP 0,Fwrite,138; JMP 7F
            TRAP 0,Fwrite,139; JMP 7F
            TRAP 0,Fwrite,140; JMP 7F
            TRAP 0,Fwrite,141; JMP 7F
            TRAP 0,Fwrite,142; JMP 7F
            TRAP 0,Fwrite,143; JMP 7F
            TRAP 0,Fwrite,144; JMP 7F
            TRAP 0,Fwrite,145; JMP 7F
            TRAP 0,Fwrite,146; JMP 7F
            TRAP 0,Fwrite,147; JMP 7F
            TRAP 0,Fwrite,148; JMP 7F
            TRAP 0,Fwrite,149; JMP 7F
            TRAP 0,Fwrite,150; JMP 7F
            TRAP 0,Fwrite,151; JMP 7F
            TRAP 0,Fwrite,152; JMP 7F
            TRAP 0,Fwrite,153; JMP 7F
            TRAP 0,Fwrite,154; JMP 7F
            TRAP 0,Fwrite,155; JMP 7F
            TRAP 0,Fwrite,156; JMP 7F
            TRAP 0,Fwrite,157; JMP 7F
            TRAP 0,Fwrite,158; JMP 7F
            TRAP 0,Fwrite,159; JMP 7F
            TRAP 0,Fwrite,160; JMP 7F
            TRAP 0,Fwrite,161; JMP 7F
            TRAP 0,Fwrite,162; JMP 7F
            TRAP 0,Fwrite,163; JMP 7F
            TRAP 0,Fwrite,164; JMP 7F
            TRAP 0,Fwrite,165; JMP 7F
            TRAP 0,Fwrite,166; JMP 7F
            TRAP 0,Fwrite,167; JMP 7F
            TRAP 0,Fwrite,168; JMP 7F
            TRAP 0,Fwrite,169; JMP 7F
            TRAP 0,Fwrite,170; JMP 7F
            TRAP 0,Fwrite,171; JMP 7F
            TRAP 0,Fwrite,172; JMP 7F
            TRAP 0,Fwrite,173; JMP 7F
            TRAP 0,Fwrite,174; JMP 7F
            TRAP 0,Fwrite,175; JMP 7F
            TRAP 0,Fwrite,176; JMP 7F
            TRAP 0,Fwrite,177; JMP 7F
            TRAP 0,Fwrite,178; JMP 7F
            TRAP 0,Fwrite,179; JMP 7F
            TRAP 0,Fwrite,180; JMP 7F
            TRAP 0,Fwrite,181; JMP 7F
            TRAP 0,Fwrite,182; JMP 7F
            TRAP 0,Fwrite,183; JMP 7F
            TRAP 0,Fwrite,184; JMP 7F
            TRAP 0,Fwrite,185; JMP 7F
            TRAP 0,Fwrite,186; JMP 7F
            TRAP 0,Fwrite,187; JMP 7F
            TRAP 0,Fwrite,188; JMP 7F
            TRAP 0,Fwrite,189; JMP 7F
            TRAP 0,Fwrite,190; JMP 7F
            TRAP 0,Fwrite,191; JMP 7F
            TRAP 0,Fwrite,192; JMP 7F
            TRAP 0,Fwrite,193; JMP 7F
            TRAP 0,Fwrite,194; JMP 7F
            TRAP 0,Fwrite,195; JMP 7F
            TRAP 0,Fwrite,196; JMP 7F
            TRAP 0,Fwrite,197; JMP 7F
            TRAP 0,Fwrite,198; JMP 7F
            TRAP 0,Fwrite,199; JMP 7F
            TRAP 0,Fwrite,200; JMP 7F
            TRAP 0,Fwrite,201; JMP 7F
            TRAP 0,Fwrite,202; JMP 7F
            TRAP 0,Fwrite,203; JMP 7F
            TRAP 0,Fwrite,204; JMP 7F
            TRAP 0,Fwrite,205; JMP 7F
            TRAP 0,Fwrite,206; JMP 7F
            TRAP 0,Fwrite,207; JMP 7F
            TRAP 0,Fwrite,208; JMP 7F
            TRAP 0,Fwrite,209; JMP 7F
            TRAP 0,Fwrite,210; JMP 7F
            TRAP 0,Fwrite,211; JMP 7F
            TRAP 0,Fwrite,212; JMP 7F
            TRAP 0,Fwrite,213; JMP 7F
            TRAP 0,Fwrite,214; JMP 7F
            TRAP 0,Fwrite,215; JMP 7F
            TRAP 0,Fwrite,216; JMP 7F
            TRAP 0,Fwrite,217; JMP 7F
            TRAP 0,Fwrite,218; JMP 7F
            TRAP 0,Fwrite,219; JMP 7F
            TRAP 0,Fwrite,220; JMP 7F
            TRAP 0,Fwrite,221; JMP 7F
            TRAP 0,Fwrite,222; JMP 7F
            TRAP 0,Fwrite,223; JMP 7F
            TRAP 0,Fwrite,224; JMP 7F
            TRAP 0,Fwrite,225; JMP 7F
            TRAP 0,Fwrite,226; JMP 7F
            TRAP 0,Fwrite,227; JMP 7F
            TRAP 0,Fwrite,228; JMP 7F
            TRAP 0,Fwrite,229; JMP 7F
            TRAP 0,Fwrite,230; JMP 7F
            TRAP 0,Fwrite,231; JMP 7F
            TRAP 0,Fwrite,232; JMP 7F
            TRAP 0,Fwrite,233; JMP 7F
            TRAP 0,Fwrite,234; JMP 7F
            TRAP 0,Fwrite,235; JMP 7F
            TRAP 0,Fwrite,236; JMP 7F
            TRAP 0,Fwrite,237; JMP 7F
            TRAP 0,Fwrite,238; JMP 7F
            TRAP 0,Fwrite,239; JMP 7F
            TRAP 0,Fwrite,240; JMP 7F
            TRAP 0,Fwrite,241; JMP 7F
            TRAP 0,Fwrite,242; JMP 7F
            TRAP 0,Fwrite,243; JMP 7F
            TRAP 0,Fwrite,244; JMP 7F
            TRAP 0,Fwrite,245; JMP 7F
            TRAP 0,Fwrite,246; JMP 7F
            TRAP 0,Fwrite,247; JMP 7F
            TRAP 0,Fwrite,248; JMP 7F
            TRAP 0,Fwrite,249; JMP 7F
            TRAP 0,Fwrite,250; JMP 7F
            TRAP 0,Fwrite,251; JMP 7F
            TRAP 0,Fwrite,252; JMP 7F
            TRAP 0,Fwrite,253; JMP 7F
            TRAP 0,Fwrite,254; JMP 7F
            TRAP 0,Fwrite,255; JMP 7F
WriteJ      BN          arg2,9F % invalid size
            AND         arg0,arg0,#FF
            GET         $3,:rJ
            SET         $5,arg0
            PUSHJ       $4,IsWritableJ
            JMP         9F % not writable
            SLU         arg0,arg0,3 % *8
            LDA         $4,WriteTable
            LDA         t,WriteBuffer
            PUSHJ       t,:MM:__THREAD:LockMutexG
            ADDU        t,t,#8
            STO         arg1,t,#0
            STO         arg2,t,#8
            GO          $4,$4,arg0
7H          SET         ret0,t
            LDA         t,WriteBuffer
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            % check that ret0 != - size - 1
            NEG         $1,0,$1
            SUB         $1,$1,1
            CMP         $1,$1,$0
            BZ          $1,9F
            PUT         :rJ,$3
            POP         1,1
9H          PUT         :rJ,$3
            POP         0,0
Write       SET         $4,arg2
            SET         $3,arg1
            SET         $2,arg0
            GET         $0,:rJ
            PUSHJ       $1,WriteJ
            JMP         9F
            PUT         :rJ,$0
            SET         ret0,$1
            POP         1,0
9H          SET         t,$0 % :rJ
            LDA         $1,:MM:__FILE:STRS:Write1
            LDA         $3,:MM:__FILE:STRS:Write2
            PUSHJ       $0,:MM:__ERROR:Error3RB2

