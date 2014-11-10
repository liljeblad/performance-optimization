.section .data
output:	.asciz "LEN: %d\nAPPLES: %d\n"
len:	.long 0
apples:	.long 0

.section .text
.globl start_game
start_game:
	
	movl	8(%esp), %eax
	movl	%eax, len
	movl	4(%esp), %eax
	movl	%eax, apples

	pushl	len
	pushl	apples
	pushl	$output
	call	printf

	movl	$1, %eax
	movl	$0, %ebx
	int		$0x80
