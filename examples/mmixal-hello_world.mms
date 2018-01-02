%
% A minimal hello world example
%

Position    IS          @
            LOC         Data_Segment
HelloString BYTE        "Hello World!",10,0

            LOC         100
Main        LDA         $0,HelloString
            TRAP        0,Fputs,StdOut
            TRAP        0,0
