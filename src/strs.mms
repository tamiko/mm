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

% TODO: Restructure

            .section .data,"wa",@progbits
            .global :MM:__STRS:Terminated
            .global :MM:__STRS:Continued1
            .global :MM:__STRS:Continued2
            .global :MM:__STRS:Continued3
            .global :MM:__STRS:InternErro
            .global :MM:__STRS:Error1
            .global :MM:__STRS:Error2
            .global :MM:__STRS:ErrorHndlC1
            .global :MM:__STRS:ErrorHndlC2
            .global :MM:__STRS:ExcNotImpl
            .global :MM:__STRS:Generic
            .global :MM:__STRS:PoolGrow1
            .global :MM:__STRS:PoolDeallo1
            .global :MM:__STRS:HeapAlloc1
            .global :MM:__STRS:HeapAlloc2
            .global :MM:__STRS:HeapFree1
            .global :MM:__STRS:HeapFree2
            .global :MM:__STRS:HeapSize1
            .global :MM:__STRS:HeapSize2
            .global :MM:__STRS:HeapMove1
            .global :MM:__STRS:HeapMove2
            .global :MM:__STRS:HeapMove3
            .global :MM:__STRS:HeapMove4
            .global :MM:__STRS:HeapReallo1
            .global :MM:__STRS:HeapReallo2
            .global :MM:__STRS:HeapReallo3
            .global :MM:__STRS:HeapReallo4
            .global :MM:__STRS:HeapReallo5
            .global :MM:__STRS:HeapSet1
            .global :MM:__STRS:HeapSet2
            .global :MM:__STRS:HeapZero1
            .global :MM:__STRS:HeapZero2
            .global :MM:__STRS:HeapSetZero
            .global :MM:__STRS:HeapRand1
            .global :MM:__STRS:HeapRand2
            .global :MM:__STRS:HeapRand3
            .global :MM:__STRS:MemCopy1
            .global :MM:__STRS:MemCopy2
            .global :MM:__STRS:MemCopy3
            .global :MM:__STRS:MemCopy4
            .global :MM:__STRS:MemCopy5
            .global :MM:__STRS:MemSet1
            .global :MM:__STRS:MemSet2
            .global :MM:__STRS:MemSet3
            .global :MM:__STRS:MemSet4
            .global :MM:__STRS:MemZero1
            .global :MM:__STRS:MemZero2
            .global :MM:__STRS:MemZero3
            .global :MM:__STRS:MemZero4
            .global :MM:__STRS:MemRand1
            .global :MM:__STRS:MemRand2
            .global :MM:__STRS:MemRand3
            .global :MM:__STRS:MemRand4
            .global :MM:__STRS:MemCmp1
            .global :MM:__STRS:MemCmp2
            .global :MM:__STRS:MemCmp3
            .global :MM:__STRS:MemCmp4
            .global :MM:__STRS:RandUrandom
            .global :MM:__STRS:RandInit1
            .global :MM:__STRS:RandInit2
            .global :MM:__STRS:RandInit3
            .global :MM:__STRS:RandInit4
            .global :MM:__STRS:RandOcta1
            .global :MM:__STRS:RandOctaG1
            .global :MM:__STRS:RandRange1
            .global :MM:__STRS:RandRange2
            .global :MM:__STRS:RandRange3
            .global :MM:__STRS:RandRange4
            .global :MM:__STRS:FileLock1
            .global :MM:__STRS:FileLock2
            .global :MM:__STRS:FileUnlock1
            .global :MM:__STRS:FileUnlock2
            .global :MM:__STRS:FileOpen1
            .global :MM:__STRS:FileOpen2
            .global :MM:__STRS:FileOpen3
            .global :MM:__STRS:FileClose1
            .global :MM:__STRS:FileClose2
            .global :MM:__STRS:FileClose3
            .global :MM:__STRS:FileClose4
            .global :MM:__STRS:FileClose5
            .global :MM:__STRS:FileRead1
            .global :MM:__STRS:FileRead2
            .global :MM:__STRS:PrintLn
            .global :MM:__STRS:StackUnderf
            .global :MM:__STRS:StackOverfl

            PREFIX      :MM:__STRS:

% Error messages:

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

% Literals used in __RAW_POOL:

PoolGrow1   BYTE        "__RAW_POOL::Grow failed. "
            BYTE        "Out of memory.",10,0
PoolDeallo1 BYTE        "__RAW_POOL::Dealloc called with invalid "
            BYTE        "range specified.",10,0

% Literals used in __HEAP:

HeapAlloc1  BYTE        "Heap:Alloc failed. Could not request a memory "
            BYTE        "block of size [arg0=",0
HeapAlloc2  BYTE        "]. Out of memory.",10,0
HeapFree1   BYTE        "Heap:Free failed. Invalid pointer [arg0=",0
HeapFree2   BYTE        "]. Double free or corruption.",10,0
HeapSize1   BYTE        "Heap:Size failed. Invalid pointer [arg0=",0
HeapSize2   BYTE        "].",10,0
HeapMove1   BYTE        "Heap:Move failed. Invalid pointer [arg0=",0
HeapMove2   BYTE        "Heap:Move failed. Invalid pointer [arg1=",0
HeapMove3   BYTE        "].",10,0
HeapMove4   BYTE        "Heap::Move failed. Something went horribly "
            BYTE        "wrong",10,0
HeapReallo1 BYTE        "Heap:Realloc failed. Invalid pointer [arg0=",0
HeapReallo2 BYTE        "].",10,0
HeapReallo3 BYTE        "Heap:Realloc failed. Could not request a Heapory "
            BYTE        "block of size [arg1=",0
HeapReallo4 BYTE        "]. Out of Heapory.",10,0
HeapReallo5 BYTE        "Heap::Realloc failed. Something went horribly "
            BYTE        "wrong",10,0
HeapSet1    BYTE        "Heap:Set failed. Invalid pointer [arg0=",0
HeapSet2    BYTE        "].",10,0
HeapZero1   BYTE        "Heap:Zero failed. Invalid pointer [arg0=",0
HeapZero2   BYTE        "].",10,0
HeapSetZero BYTE        "Heap:Set/Zero failed. Something went horribly "
            BYTE        "wrong",10,0
HeapRand1   BYTE        "Heap:Rand failed. Invalid pointer [arg0=",0
HeapRand2   BYTE        "].",10,0
HeapRand3   BYTE        "Heap:Rand failed. Something went horribly "
            BYTE        "wrong",10,0

% Literals used in __MEM:

MemCopy1    BYTE        "Mem:Copy failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
MemCopy2    BYTE        "Mem:Copy failed. Invalid data range specified. "
            BYTE        "Memory region [arg1,arg1+arg2), with [arg1=",0
MemCopy3    BYTE        "] and [arg2=",0
MemCopy4    BYTE        "], wraps.",10,0
MemCopy5    BYTE        "Mem:Copy failed. Something went horribly "
            BYTE        "wrong",10,0
MemSet1     BYTE        "Mem:Set failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
MemSet2     BYTE        "] and [arg2=",0
MemSet3     BYTE        "], wraps.",10,0
MemSet4     BYTE        "Mem:Set failed. Something went horribly "
            BYTE        "wrong",10,0
MemZero1    BYTE        "Mem:Zero failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
MemZero2    BYTE        "] and [arg2=",0
MemZero3    BYTE        "], wraps.",10,0
MemZero4    BYTE        "Mem:Zero failed. Something went horribly "
            BYTE        "wrong",10,0
MemRand1    BYTE        "Mem:Rand failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
MemRand2    BYTE        "] and [arg2=",0
MemRand3    BYTE        "], wraps.",10,0
MemRand4    BYTE        "Mem:Rand failed. Something went horribly "
            BYTE        "wrong",10,0
MemCmp1     BYTE        "Mem:Cmp failed. Invalid data range specified. "
            BYTE        "Memory region [arg0,arg0+arg2), with [arg0=",0
MemCmp2     BYTE        "Mem:Cmp failed. Invalid data range specified. "
            BYTE        "Memory region [arg1,arg1+arg2), with [arg1=",0
MemCmp3     BYTE        "] and [arg2=",0
MemCmp4     BYTE        "], wraps.",10,0

% Literals used in __RAND:
RandUrandom BYTE        "/dev/urandom",0
RandInit1   BYTE        "__RAND:Init failed. Unable to open '/dev/urandom'",0
RandInit2   BYTE        ". Internal error. File handle [",0
RandInit3   BYTE        "] invalid.",10,0
RandInit4   BYTE        ".",10,0
RandOcta1   BYTE        "Rand:Octa failed. Could not read random data.",10,0
RandRange1  BYTE        "Rand:Range failed. Invalid range specified, [arg0=",0
RandRange2  BYTE        "] and [arg1=",0
RandRange3  BYTE        "] do not define a valid interval.",10,0
RandRange4  BYTE        "Heap:Range failed. Could not read from "
            BYTE        "filehandler [",0

% Literals used in __PRINT:
PrintLn     BYTE        10,0

% Literals used in __FILE:
FileLock1   BYTE        "File:Lock failed. Could not lock handle [arg0=",0
FileLock2   BYTE        "]. Already locked.",10,0
FileUnlock1 BYTE        "File:Unlock failed. Could not unlock handle [arg0=",0
FileUnlock2 BYTE        "]. File handle is not locked.",10,0
FileOpen1   BYTE        "File:Open failed. Invalid file mode [arg1=",0
FileOpen2   BYTE        "] specified.",10,0
FileOpen3   BYTE        "File:Open failed. No free file handler "
            BYTE        "available.",10,0
FileClose1  BYTE        "File:Close failed. File handle [arg0=",0
FileClose2  BYTE        "] locked by user or system.",10,0
FileClose3  BYTE        "] not opened.",10,0
FileClose4  BYTE        "File:Close failed. Could not close file handle [arg0=",0
FileClose5  BYTE        "]. Internal state corrupted.",10,0
FileRead1   BYTE        "File.Read failed. Could not read from file handle [arg2=",0
FileRead2   BYTE        "].",10,0

% Literals used in stack:
StackUnderf BYTE        "Stack:Pop failed. Underflow - stack empty.",10,0
StackOverfl BYTE        "Stack:Push failed. Overflow - stack full.",10,0

