.section .text
.globl _start
_start:

	#Starting the game with a length of 5 and 2 apples
	pushl	$2
	pushl	$5
	call	start_game
	addl	$8, %esp
