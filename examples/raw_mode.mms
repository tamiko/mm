%
% A small example demonstrating "RAW" terminal mode handling.
%

#include <mm/file>
#include <mm/print>
#include <mm/sys>

            %
            % Instruct the binfmt handler to use RAW mode. This requires
            % mmix-objdump to be in path. Alternatively, invoke the .mmo
            % file with options "-mmix -tty-raw-mode"
            %

            .global MM:Interpreter:TTY_RAW_MODE

            .data
            .balign 8
Buffer      .fill 100
            .balign 4
FileString  BYTE        "/dev/stdin",0
            .balign 4
Msg1        BYTE        "Byte read: >",0
            .balign 4
Msg2        BYTE        "<   (press 'q' to exit)",13,10,0
            .balign 4
Bye         BYTE        "Key 'q' pressed - goodbye!",13,10,0

            .text
            .global Main
t           IS          :MM:t
Main        SWYM

            %
            % Close StdIn and reopen in BinaryRead mode. We conveniently
            % abuse the fact that after closing file handle #0, a
            % subsequent call to File:Open will return file handle #0.
            %

            SET         $1,#0
            PUSHJ       $0,MM:File:Close
            GETA        $1,FileString
            SET         $2,:BinaryRead
            PUSHJ       $0,MM:File:Open

            %
            % Main loop:
            %

1H          SWYM

            %
            % Read one byte from stdin:
            %

            SET         $1,#0
            GETA        $2,Buffer
            SET         $3,#1
            PUSHJ       $0,MM:File:Read

            %
            % If we have a nonnegative return value we actually read a byte!
            %

            BN          $0,1B

            %
            % Right shift the byte into least significant position:
            %

            GETA        $0,Buffer
            LDO         $0,$0,0
            SRU         $0,$0,56

            %
            % Check whether 'q' was pressed:
            %

            SET         $1,#71 % constant 'q'
            CMPU        $1,$0,$1
            BZ          $1,9F

            %
            % Otherwise print out the character:
            %

            GETA        t,Msg1
            PUSHJ       t,MM:Print:StrG
            SET         t,$0
            PUSHJ       t,MM:Print:ByteG
            GETA        t,Msg2
            PUSHJ       t,MM:Print:StrG

            JMP         1B

9H          GETA        t,Bye
            PUSHJ       t,MM:Print:StrG
            PUSHJ       t,MM:Sys:Exit
