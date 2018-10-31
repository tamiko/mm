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
% :MM:__FILE:
%

            .section .data,"wa",@progbits
            PREFIX      :MM:__FILE:STRS:
            .balign 4
Lock1       BYTE        "File:Lock failed. Could not lock handle [arg0=",0
            .balign 4
Lock2       BYTE        "]. Already locked.",10,0
            .balign 4
Unlock1     BYTE        "File:Unlock failed. Could not unlock handle [arg0=",0
            .balign 4
Unlock2     BYTE        "]. File handle is not locked.",10,0
            .balign 4
Open1       BYTE        "File:Open failed. Invalid file mode [arg1=",0
            .balign 4
Open2       BYTE        "] specified.",10,0
            .balign 4
Open3       BYTE        "File:Open failed. No free file handle "
            BYTE        "available.",10,0
            .balign 4
Open4       BYTE        "File:Open failed. Could not open file with "
            BYTE        "specified file mode [arg1=",0
            .balign 4
Open5       BYTE        "].",10,0
            .balign 4
Close1      BYTE        "File:Close failed. File handle [arg0=",0
            .balign 4
Close2      BYTE        "] locked by user or system.",10,0
            .balign 4
Close3      BYTE        "] not opened.",10,0
            .balign 4
Close4      BYTE        "File:Close failed. Could not close file handle [arg0=",0
            .balign 4
Close5      BYTE        "]. Internal state corrupted.",10,0
            .balign 4
Tell1       BYTE        "File:Tell failed. Could not read from file handle [arg0=",0
            .balign 4
Tell2       BYTE        "].",10,0
            .balign 4
Size1       BYTE        "File:Size failed. Could not read from file handle [arg0=",0
            .balign 4
Size2       BYTE        "].",10,0
            .balign 4
Seek1       BYTE        "File:Seek failed. Could not seek file handle [arg0=",0
            .balign 4
Seek2       BYTE        "] to position [arg1=",0
            .balign 4
Seek3       BYTE        "].",10,0
            .balign 4
Read1       BYTE        "File:Read failed. Could not read from file handle [arg0=",0
            .balign 4
Read2       BYTE        "].",10,0
            .balign 4
Write1      BYTE        "File:Write failed. Could not write to file handle [arg0=",0
            .balign 4
Write2      BYTE        "].",10,0
Gets1       BYTE        "File:Gets failed. Could not read from file handle [arg0=",0
            .balign 4
Gets2       BYTE        "].",10,0
            .balign 4
Puts1       BYTE        "File:Puts failed. Could not write to file handle [arg0=",0
            .balign 4
Puts2       BYTE        "].",10,0
            .balign 4
ReadIn1     BYTE        "File:ReadIn failed. Could not open file for reading. ",10,0
            .balign 4


%
% We have 256 Bytes at address :MM:__FILE:Pool to store some internal
% data for file descriptors. Therefore,
%   #00        - not in use
%   #08 - #C   - in use (by us) and opened with the respective mode
%                +#8.
%   #FF        - marked as 'manually controlled by the user'
%
            .section .data,"wa",@progbits
            .balign 8
            .global :MM:__FILE:Pool
            PREFIX      :MM:__FILE:
PoolMutex   OCTA        #0000000000000000
Pool        BYTE        #08,#09,#09
            .fill 253*1


            .section .text,"ax",@progbits
            PREFIX      :MM:__FILE:
t           IS          :MM:t
arg0        IS          $0
arg1        IS          $1
arg2        IS          $2
ret0        IS          $0

Fclose      IS          :Fclose
Fgets       IS          :Fgets
Fopen       IS          :Fopen
Fputs       IS          :Fputs
Fread       IS          :Fread
Fseek       IS          :Fseek
Ftell       IS          :Ftell
Fwrite      IS          :Fwrite
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
            GETA        t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            GETA        pool,:MM:__FILE:Pool
2H          LDBU        $4,pool,arg0
            BNZ         $4,9F % already in use
            SET         $4,#FF
2H          STB         $4,pool,arg0
            GETA        t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$5
            POP         0,1
9H          GETA        t,:MM:__FILE:PoolMutex
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
            GETA        $1,:MM:__FILE:STRS:Lock1
            SET         $2,arg0
            GETA        $3,:MM:__FILE:STRS:Lock2
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
            GETA        t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            GETA        pool,:MM:__FILE:Pool
2H          LDBU        $4,pool,arg0
            XOR         $4,$4,#FF
            BNZ         $4,9F % not locked
            SET         $4,#00
2H          STB         $4,pool,arg0
            GETA        t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$5
            POP         1,1
9H          GETA        t,:MM:__FILE:PoolMutex
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
            GETA        $1,:MM:__FILE:STRS:Unlock1
            SET         $2,arg0
            GETA        $3,:MM:__FILE:STRS:Unlock2
            PUSHJ       $0,:MM:__ERROR:Error3RB2


            %
            % A macro to build the call tables for our system calls:
            %

            .macro      build_table_rec call from to
            TRAP        0,\call ,\from
            JMP 7F
            .if \from < \to
            build_table_rec \call ,\from+1 ,\to
            .endif
            .endm

            .macro      build_table call
            build_table_rec \call,  0,  63
            build_table_rec \call, 64, 127
            build_table_rec \call,128, 191
            build_table_rec \call,192, 255
            .endm


%%
% :MM:__FILE:OpenJ
%   arg0 - pointer to string containing filename
%   arg1 - mode
%   retm - file handle on success / 0 on error
%
            .section .data,"wa",@progbits
OpenBuffer  OCTA        #0,#0

            .section .text,"ax",@progbits
            .global :MM:__FILE:OpenTable
            .global :MM:__FILE:OpenJ
            % A lot of table...
OpenTable
            build_table Fopen
pool        IS          $2
fh          IS          $3
OpenJ       GET         $6,:rJ
            GETA        t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            CMPU        t,arg1,4
            BP          t,9F
            % Find an unused fh:
            GETA        pool,:MM:__FILE:Pool
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
            GETA        $4,OpenBuffer % we already hold the PoolMutex
            STO         arg0,$4,0
            STO         arg1,$4,8
            SLU         $3,fh,3 % *8
            GETA        $5,OpenTable
            SET         $255,$4
            GO          $4,$5,$3
7H          BN          $255,1F
            SRU         $3,fh,3 % /8
            SET         $0,fh
            GETA        t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$6
            POP         1,1
1H          SRU         fh,$3,3 % fh
            SET         $0,0
            STB         $0,pool,fh
9H          GETA        t,:MM:__FILE:PoolMutex
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
            GETA        pool,:MM:__FILE:Pool
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
            GETA        $1,:MM:__FILE:STRS:Open4
            GETA        $3,:MM:__FILE:STRS:Open5
            PUSHJ       $0,:MM:__ERROR:Error3RB2
8H          GET         t,:rJ % :rJ
            GETA        $1,:MM:__FILE:STRS:Open3
            PUSHJ       $0,:MM:__ERROR:Error1
9H          GET         t,:rJ % :rJ
            SET         $2,arg1
            GETA        $1,:MM:__FILE:STRS:Open1
            GETA        $3,:MM:__FILE:STRS:Open2
            PUSHJ       $0,:MM:__ERROR:Error3RB2


%%
% :MM:__FILE:CloseJ
%
% PUSHJ:
%   arg0 - lowest byte defines the file handle
%   no return value
%

            .global :MM:__FILE:CloseTable
            .global :MM:__FILE:CloseJ
CloseTable
            build_table Fclose
pool        IS          $2
            % sanitize arg0:
CloseJ      AND         arg0,arg0,#FF
            GET         $5,:rJ
            GETA        t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:LockMutexG
            GETA        pool,:MM:__FILE:Pool
            LDBU        $3,pool,arg0
            BZ          $3,9F
            CMPU        t,$3,#FF
            BZ          t,9F
            CMPU        t,$3,#EE
            BZ          t,9F
            SLU         arg0,arg0,3 % *8
            GETA        $4,CloseTable
            GO          $4,$4,arg0
7H          SRU         arg0,arg0,3 % /8
            BN          $255,9F
            SET         $3,0
            STBU        $3,pool,arg0
            GETA        t,:MM:__FILE:PoolMutex
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            PUT         :rJ,$5
            POP         0,1
9H          GETA        t,:MM:__FILE:PoolMutex
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
            GETA        pool,:MM:__FILE:Pool
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
            GETA        $3,:MM:__FILE:STRS:Close4
            SET         $4,arg0
            GETA        $5,:MM:__FILE:STRS:Close5
            PUSHJ       $2,:MM:__ERROR:Error3RB2
8H          SET         t,$1 % :rJ
            GETA        $1,:MM:__FILE:STRS:Close1
            SET         $2,arg0
            GETA        $3,:MM:__FILE:STRS:Close2
            PUSHJ       $0,:MM:__ERROR:Error3RB2
9H          GET         t,:rJ % :rJ
            GETA        $1,:MM:__FILE:STRS:Close1
            SET         $2,arg0
            GETA        $3,:MM:__FILE:STRS:Close3
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
            GETA        pool,:MM:__FILE:Pool
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
            GETA        pool,:MM:__FILE:Pool
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
            GETA        pool,:MM:__FILE:Pool
            LDBU        $1,pool,arg0
            CMPU        t,$1,#9 % :TextWrite
            BZ          t,1F
            CMPU        t,$1,#B % :BinaryWrite
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

            .global :MM:__FILE:TellTable
            .global :MM:__FILE:TellJ
            .global :MM:__FILE:TellG
            .global :MM:__FILE:Tell
TellTable
            build_table Ftell
TellJ       AND         arg0,arg0,#FF
            GET         $1,:rJ
            SLU         arg0,arg0,3 % *8
            GETA        $2,TellTable
            GO          $2,$2,arg0
7H          SET         ret0,$255
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
            GETA        $1,:MM:__FILE:STRS:Tell1
            SET         $2,arg0
            GETA        $3,:MM:__FILE:STRS:Tell2
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
            GETA        $1,:MM:__FILE:STRS:Size1
            SET         $2,arg0
            GETA        $3,:MM:__FILE:STRS:Size2
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

            .global :MM:__FILE:SeekTable
            .global :MM:__FILE:SeekJ
            .global :MM:__FILE:Seek
SeekTable
            build_table Fseek
SeekJ       AND         arg0,arg0,#FF
            GET         $2,:rJ
            SLU         arg0,arg0,3 % *8
            GETA        $3,SeekTable
            SET         $255,arg1
            GO          $3,$3,arg0
7H          SET         ret0,$255
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
            GETA        $1,:MM:__FILE:STRS:Seek1
            GETA        $3,:MM:__FILE:STRS:Seek2
            GETA        $5,:MM:__FILE:STRS:Seek3
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
            .global :MM:__FILE:ReadTable
            .global :MM:__FILE:ReadJ
            .global :MM:__FILE:Read
ReadTable
            build_table Fread
ReadJ       BN          arg2,9F % invalid size
            AND         arg0,arg0,#FF
            GET         $3,:rJ
            SET         $5,arg0
            PUSHJ       $4,IsReadableJ
            JMP         9F % not readable
            SLU         arg0,arg0,3 % *8
            GETA        $4,ReadTable
            GETA        t,ReadBuffer
            PUSHJ       t,:MM:__THREAD:LockMutexG
            ADDU        $255,t,#8
            STO         arg1,$255,#0
            STO         arg2,$255,#8
            GO          $4,$4,arg0
7H          SET         ret0,$255
            GETA        t,ReadBuffer
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
Read        SET         $5,arg2
            SET         $4,arg1
            SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,ReadJ
            JMP         9F
            PUT         :rJ,$1
            SET         ret0,$2
            POP         1,0
9H          SET         t,$1 % :rJ
            GETA        $1,:MM:__FILE:STRS:Read1
            SET         $2,$0
            GETA        $3,:MM:__FILE:STRS:Read2
            PUSHJ       $0,:MM:__ERROR:Error3RB2


%%
% :MM:__FILE:GetsJ
%
% PUSHJ:
%   arg0 - file handle
%   arg1 - pointer to buffer
%   arg2 - number of bytes to read
%   retm - n is the number of string characters that have been read
%          (excluding terminating null byte for string)
%
% :MM:__FILE:Gets
%

            .section .data,"wa",@progbits
GetsBuffer  OCTA        #0,#0,#0

            .section .text,"ax",@progbits
            .global :MM:__FILE:GetsTable
            .global :MM:__FILE:GetsJ
            .global :MM:__FILE:Gets
GetsTable
            build_table Fgets
GetsJ       BN          arg2,9F % invalid size
            AND         arg0,arg0,#FF
            GET         $3,:rJ
            SET         $5,arg0
            PUSHJ       $4,IsReadableJ
            JMP         9F % not Getsable
            SLU         arg0,arg0,3 % *8
            GETA        $4,GetsTable
            GETA        t,GetsBuffer
            PUSHJ       t,:MM:__THREAD:LockMutexG
            ADDU        $255,t,#8
            STO         arg1,$255,#0
            STO         arg2,$255,#8
            GO          $4,$4,arg0
7H          SET         ret0,$255
            GETA        t,GetsBuffer
            PUSHJ       t,:MM:__THREAD:UnlockMutexG
            % check that ret0 >= 0
            BN          $0,9F
            PUT         :rJ,$3
            POP         1,1
9H          PUT         :rJ,$3
            POP         0,0
Gets        SET         $5,arg2
            SET         $4,arg1
            SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,GetsJ
            JMP         9F
            PUT         :rJ,$1
            SET         ret0,$2
            POP         1,0
9H          SET         t,$1 % :rJ
            GETA        $1,:MM:__FILE:STRS:Gets1
            SET         $2,$0
            GETA        $3,:MM:__FILE:STRS:Gets2
            PUSHJ       $0,:MM:__ERROR:Error3RB2


%%
% :MM:File:WriteJ
%   arg0 - file handle
%   arg1 - pointer to buffer
%   arg2 - number of bytes to write
%   retm - (n - arg2), where n is the number of bytes actually written
%
% :MM:File:Write
%

            .section .data,"wa",@progbits
WriteBuffer OCTA        #0,#0,#0

            .section .text,"ax",@progbits
            .global :MM:__FILE:WriteTable
            .global :MM:__FILE:WriteJ
            .global :MM:__FILE:Write
WriteTable
            build_table Fwrite
WriteJ      BN          arg2,9F % invalid size
            AND         arg0,arg0,#FF
            GET         $3,:rJ
            SET         $5,arg0
            PUSHJ       $4,IsWritableJ
            JMP         9F % not writable
            SLU         arg0,arg0,3 % *8
            GETA        $4,WriteTable
            GETA        t,WriteBuffer
            PUSHJ       t,:MM:__THREAD:LockMutexG
            ADDU        $255,t,#8
            STO         arg1,$255,#0
            STO         arg2,$255,#8
            GO          $4,$4,arg0
7H          SET         ret0,$255
            GETA        t,WriteBuffer
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
Write       SET         $5,arg2
            SET         $4,arg1
            SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,WriteJ
            JMP         9F
            PUT         :rJ,$1
            SET         ret0,$2
            POP         1,0
9H          SET         t,$1 % :rJ
            GETA        $1,:MM:__FILE:STRS:Write1
            SET         $2,$0
            GETA        $3,:MM:__FILE:STRS:Write2
            PUSHJ       $0,:MM:__ERROR:Error3RB2


%%
% :MM:File:PutsJ
%   arg0 - file handle
%   arg1 - pointer to buffer
%   retm - (n - arg2), where n is the number of bytes actually written
%
% :MM:File:Puts
%

            .section .text,"ax",@progbits
            .global :MM:__FILE:PutsTable
            .global :MM:__FILE:PutsJ
            .global :MM:__FILE:Puts
PutsTable
            build_table Fputs
PutsJ       BN          arg2,9F % invalid size
            AND         arg0,arg0,#FF
            GET         $3,:rJ
            SET         $5,arg0
            PUSHJ       $4,IsWritableJ
            JMP         9F % not writable
            SLU         arg0,arg0,3 % *8
            GETA        $4,PutsTable
            SET         $255,arg1
            GO          $4,$4,arg0
7H          SET         ret0,$255
            % check that ret0 >= 0
            BN          $0,9F
            PUT         :rJ,$3
            POP         1,1
9H          PUT         :rJ,$3
            POP         0,0
Puts        SET         $5,arg2
            SET         $4,arg1
            SET         $3,arg0
            GET         $1,:rJ
            PUSHJ       $2,PutsJ
            JMP         9F
            PUT         :rJ,$1
            SET         ret0,$2
            POP         1,0
9H          SET         t,$1 % :rJ
            GETA        $1,:MM:__FILE:STRS:Puts1
            SET         $2,$0
            GETA        $3,:MM:__FILE:STRS:Puts2
            PUSHJ       $0,:MM:__ERROR:Error3RB2


%%
% :MM:File:ReadInJ
%   arg0 - pointer to string containing filename
%   retm - memory containing file content
%
% :MM:File:ReadIn
% :MM:File:ReadInG
%

            .section .text,"ax",@progbits
            .global :MM:__FILE:ReadInJ
            .global :MM:__FILE:ReadIn
            .global :MM:__FILE:ReadInG
ReadInJ     SWYM
            GET         $1,:rJ
            SET         $3,arg0
            SET         $4,BinaryRead
            PUSHJ       $2,OpenJ
            JMP         9F
            % $2 - file handle
            SET         $4,$2
            NEG         $5,0,1   % seek all the way to the end
            PUSHJ       $3,SeekJ
            JMP         9F
            SET         $4,$2
            PUSHJ       $3,TellJ
            JMP         9F
            % $3 - file size
            SET         $5,$3
            PUSHJ       $4,:MM:__POOL:AllocJ
            JMP         9F
            % $4 - buffer address
            NEG         $7,0     % seek all the way to the beginning
            SET         $6,$2
            PUSHJ       $5,SeekJ
            JMP         9F
            SET         $6,$2
            SET         $7,$4
            SET         $8,$3
            PUSHJ       $5,ReadJ
            JMP         9F
            SET         ret0,$4
            PUT         :rJ,$1
            POP         1,1
9H          PUT         :rJ,$1
            POP         0,0
ReadIn      GET         $1,:rJ
            SET         $3,arg0
            PUSHJ       $2,ReadInJ
            JMP         9F
            PUT         :rJ,$1
            SET         ret0,$2
            POP         1,0
9H          SET         t,$1 % :rJ
            GETA        $1,:MM:__FILE:STRS:ReadIn1
            PUSHJ       $0,:MM:__ERROR:Error1
ReadInG     GET         $0,:rJ
            SET         $2,t
            PUSHJ       $1,ReadIn
            SET         t,$1
            PUT         :rJ,$0
            POP         1,0
