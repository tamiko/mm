			SWYM
#include <mm/print>
#include <mm/sys>

            .section .data,"wa",@progbits
HelloString	BYTE	"Hello World!",10,0

#include <mm/gnu_as_init>
Main		LDA		$255,HelloString
			PUSHJ	$255,MM:Print:StrG
			PUSHJ	$255,MM:Sys:Exit
