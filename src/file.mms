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
Close1      BYTE        "File:Close failed. File handle [arg0=",0
Close2      BYTE        "] locked by user or system.",10,0
Close3      BYTE        "] not opened.",10,0
Close4      BYTE        "File:Close failed. Could not close file handle [arg0=",0
Close5      BYTE        "]. Internal state corrupted.",10,0
Read1       BYTE        "File.Read failed. Could not read from file handle [arg2=",0
Read2       BYTE        "].",10,0


%
% We have 256 Bytes at address :MM:__FILE:Pool to store some internal
% data for file descriptors. Therefore,
%   #00        - not in use
%   #08 - #C   - in use (by us) and opened with the respective mode
%                +#8.
%   #EE        - marked as 'controlled by the system' (e.g. fh 0 - 2)
%   #FF        - markes as 'manually controlled by the user'
%
            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__FILE:Pool
            PREFIX      :MM:__FILE:
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
Fread       IS          :Fread
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
            % Select lowest byte:
LockJ       AND         arg0,arg0,#FF
pool        IS          $2
            LDA         pool,:MM:__FILE:Pool
2H          LDBU        $4,pool,arg0
            BNZ         $4,9F % already in use
            SET         $4,#FF
2H          STB         $4,pool,arg0
            POP         0,1
9H          POP         0,0
LockG       SET         $0,t
Lock        SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,LockJ
            JMP         9F
            PUT         :rJ,$1
            SET         t,arg0
            POP         0
9H          SET         :MM:__ERROR:__rJ,$1
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
UnlockJ     CMPU        arg0,arg0,#FF
pool        IS          $2
            LDA         pool,:MM:__FILE:Pool
2H          LDBU        $4,pool,arg0
            XOR         $4,$4,#FF
            BNZ         $4,9F % not locked
            SET         $4,#00
2H          STB         $4,pool,arg0
            POP         1,1
9H          POP         0,0
UnlockG     SET         $0,t
Unlock      SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,UnlockJ
            JMP         9F
            PUT         :rJ,$1
            SET         t,arg0
            POP         0
9H          SET         :MM:__ERROR:__rJ,$1
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
OpenJ       CMPU        t,arg1,4
            BP          t,9F
pool        IS          $2
fh          IS          $3
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
            POP         1,1
1H          SRU         fh,$3,3 % fh
            SET         $0,0
            STB         $0,pool,fh
9H          POP         0,0


%%
% :MM:__FILE:Open
%   arg0 - pointer to string containing filename
%   arg1 - mode
%   retm - file handle on success / -1 on error
%

            .global :MM:__FILE:Open
Open        CMPU        t,arg1,4
            BP          t,9F
            % Are any file handles available?
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
7H          SET         $0,1
            NEG         $0,$0
            PUT         :rJ,$2
            POP         1,0
8H          GET         :MM:__ERROR:__rJ,:rJ
            LDA         $1,:MM:__FILE:STRS:Open3
            PUSHJ       $0,:MM:__ERROR:Error1
9H          GET         :MM:__ERROR:__rJ,:rJ
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
            POP         0,1
9H          POP         0,0


%%
% :MM:__FILE:Close
%   arg0 - file handle to close
%   no return value
%

            .global :MM:__FILE:CloseG
            .global :MM:__FILE:Close
CloseG      SET         arg0,t
Close       AND         $3,arg0,#FF
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
            SET         :MM:__ERROR:__rJ,$1
            LDA         $3,:MM:__FILE:STRS:Close4
            SET         $4,arg0
            LDA         $5,:MM:__FILE:STRS:Close5
            PUSHJ       $2,:MM:__ERROR:Error3RB2
8H          SET         :MM:__ERROR:__rJ,$1
            LDA         $1,:MM:__FILE:STRS:Close1
            SET         $2,arg0
            LDA         $3,:MM:__FILE:STRS:Close2
            PUSHJ       $0,:MM:__ERROR:Error3RB2
9H          GET         :MM:__ERROR:__rJ,:rJ
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
% :MM:__FILE:ReadJ
%
% PUSHJ:
%   arg0 - lowest byte defines the file handle
%   no return value
%
% :MM:__FILE:Read
%

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
            OCTA        #0,#0
ReadJ       BN          arg1,9F % invalid size
            AND         arg2,arg2,#FF
            GET         $3,:rJ
            SET         $5,arg2
            PUSHJ       $4,IsReadableJ
            JMP         9F % not readable
            SLU         arg2,arg2,3 % *8
            LDA         $4,ReadTable
            LDA         t,ReadJ
            SUBU        t,t,#10
            STO         arg0,t,#0
            STO         arg1,t,#8
            GO          $4,$4,arg2
7H          SET         ret0,t
            PUT         :rJ,$3
            POP         1,1
9H          POP         0,0
Read        SET         $4,arg2
            SET         $3,arg1
            SET         $2,arg0
            GET         $0,:rJ
            PUSHJ       $1,ReadJ
            JMP         9F
            PUT         :rJ,$0
            POP         0,0
9H          SET         :MM:__ERROR:__rJ,$0
            LDA         $1,:MM:__FILE:STRS:Read1
            LDA         $3,:MM:__FILE:STRS:Read2
            PUSHJ       $0,:MM:__ERROR:Error3RB2
