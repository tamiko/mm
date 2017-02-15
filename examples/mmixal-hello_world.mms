			SWYM
#include <mm/print>
#include <mm/sys>

Position    IS		@
			LOC		Data_Segment
HelloString	BYTE	"Hello World!",10,0

			LOC		Position
Main		LDA		$255,HelloString
			PUSHJ	$255,MM:Print:StrG
			PUSHJ	$255,MM:Sys:Exit
