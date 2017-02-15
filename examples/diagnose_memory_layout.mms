			SWYM
#include<mm/print>
#include<mm/sys>

#ifdef __GNU_AS
            .section .data,"wa",@progbits
#endif
str_header	BYTE	"Diagnose startup",10,10,0
str_header2	BYTE	"Library specific adresses:",10,10,0
str_text	BYTE	"    Text segment:         [ ",0
str_data	BYTE	"    Data segment:         [ ",0
str_pool	BYTE	"    Pool segment:         [ ",0
str_stack	BYTE	"    Stack segment:        [ ",0
str_main	BYTE	"    Main:                 [ ",0
str_onstart	BYTE	"    :MM:__Init:OnStartup  [ ",0
str_atexit	BYTE	"    :MM:__SYS:AtExitAddr  [ ",0
str_atabort	BYTE	"    :MM:__SYS:AtAbortAddr [ ",0
str_aterror	BYTE	"    :MM:__SYS:AtErrorAddr [ ",0
str_fpool	BYTE	"    :MM:__FILE:Pool       [ ",0
str_buffer	BYTE	"    :MM:__INIT:Buffer     [ ",0
str_between	BYTE	" ]    -->    [ ",0
str_endl	BYTE	" ]",10,0

#ifdef __GNU_AS
#include<mm/gnu_as_init>
#endif
t			IS		$255
arg0		IS		$0
arg1		IS		$1

			% arg0 - string to print
			% arg1 - address to print
AddressOf 	GET     $2,:rJ
			SET		t,arg0
			TRAP	0,Fputs,StdOut
			SET     t,arg1
			PUSHJ	t,MM:Print:RegG
			LDA		t,str_endl
			TRAP	0,Fputs,StdOut
			PUT		:rJ,$2
			POP		0,0

			% arg0 - string to print
			% arg1 - address to print
AddressOf2	GET     $2,:rJ
			SET		t,arg0
			TRAP	0,Fputs,StdOut
			SET     t,arg1
			PUSHJ	t,MM:Print:RegG
			LDA		t,str_between
			TRAP	0,Fputs,StdOut
			LDOU    t,arg1
			PUSHJ	t,MM:Print:RegG
			LDA		t,str_endl
			TRAP	0,Fputs,StdOut
			PUT		:rJ,$2
			POP		0,0

Main		SET		$2,t
			LDA		t,str_header
			TRAP	0,Fputs,StdOut

			LDA		$5,#0
			LDA		$4,str_text
			PUSHJ	$3,AddressOf
			LDA		$5,:Data_Segment
			LDA		$4,str_data
			PUSHJ	$3,AddressOf
			LDA		$5,:Pool_Segment
			LDA		$4,str_pool
			PUSHJ	$3,AddressOf2
			LDA		$5,:Stack_Segment
			LDA		$4,str_stack
			PUSHJ	$3,AddressOf
			PUSHJ   t,MM:Print:Ln

			SET     $5,$2
			LDA		$4,str_main
			PUSHJ	$3,AddressOf
			PUSHJ   t,MM:Print:Ln

			LDA		t,str_header2
			TRAP	0,Fputs,StdOut

			LDA		$5,:MM:__INIT:OnStartup
			LDA		$4,str_onstart
			PUSHJ	$3,AddressOf
			PUSHJ   t,MM:Print:Ln

			LDA		$4,str_atexit
			PUSHJ	$3,AddressOf
			LDA		$5,:MM:__SYS:AtExitAddr
			LDA		$4,str_atexit
			PUSHJ	$3,AddressOf2
			LDA		$5,:MM:__SYS:AtAbortAddr
			LDA		$4,str_atabort
			PUSHJ	$3,AddressOf2
			LDA		$5,:MM:__SYS:AtErrorAddr
			LDA		$4,str_aterror
			PUSHJ	$3,AddressOf2
			LDA		$5,:MM:__FILE:Pool
			LDA		$4,str_fpool
			PUSHJ	$3,AddressOf
			LDA		$5,:MM:__INIT:Buffer
			LDA		$4,str_buffer
			PUSHJ	$3,AddressOf

			PUSHJ	$255,MM:Sys:Exit
