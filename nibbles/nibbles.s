.section .data
# Debug
output:	.asciz "VALUE: %d\n"

# Variables that will hold positions
pos_x:	.long 40
pos_y:	.long 11

# Variables to keep track of which way the snake moves
dir_x:	.long 1
dir_y:	.long 0

# Size of the screen
MIN_X:	.long 0
MIN_Y:	.long 0
MAX_X:	.long 79
MAX_Y:	.long 23

# All input variables needed to move the snake and quit the game
# TODO Change to byte?
KBD_QUIT:	.long 'q'
KBD_UP:		.long 'w'
KBD_LEFT:	.long 'a'
KBD_DOWN:	.long 's'
KBD_RIGHT:	.long 'd'

# Game variables
snake:			.fill 500, 4, 1
snake_len:		.long 0
snake_symbol:	.byte 'O'
apples:			.fill 30, 4, 0
apples_n:		.long 0
apples_symbol:	.byte '*'

.section .text
########################################################
# Entry point, gets called from either main.c or start.s
########################################################
.globl start_game
start_game:
	call	save_arguments
	call	init_snake
	call 	init_apples
	call	nib_init

# Game loop
update_game:
	call	move_snake		# Performance this!
	call 	check_snake_collision
	call 	check_apple_collision
	call 	draw_snake
	call 	draw_apples

loop:
	jmp loop

	# TODO, make the program sleep less
	pushl	$1000000
	call 	usleep
	addl	$4, %esp
	call 	clear

# Gets called when the game is over
game_over:
	call	nib_end
########################################################
# Game over!
########################################################

# Save arguments from program call to variables
save_arguments:
	movl	12(%esp), %eax
	movl	%eax, apples_n
	movl	8(%esp), %eax
	movl	%eax, snake_len

	ret

# Initialize the snake array
init_snake:
	movl	$snake, %esi

	pushl	pos_x

	movl	$0, %ebx
snake_loop:
	# Save positions to snake array
	movl	pos_x, %ecx
	movl	%ecx, (%esi)
	decl	pos_x		# Only the x position is altered since the snake starts going right
	movl	pos_y, %ecx
	movl	%ecx, 4(%esi)

	# Prepare for next iteration
	addl	$8, %esi
	incl	%ebx
	cmpl	snake_len, %ebx
	jne		snake_loop

	popl	pos_x

	ret

# Initialize the apples array
init_apples:
	movl	$apples, %esi

	movl	$0, %ebx
apples_loop:
	# Call function rand_num to get a random number between 0 and argument passed, stored in %edx
	call	rand
	andl	MAX_X, %eax
	movl	%eax, (%esi)

	call	rand
	andl	MAX_Y, %eax
	movl	%eax, 4(%esi)

	# Prepare for next iteration
	addl	$8, %esi
	incl	%ebx
	cmpl	apples_n, %ebx
	jne		apples_loop

	ret

move_snake:
	movl	$snake, %esi

	movl	(%esi), %eax	# Save the x and y positions of the head
	movl	%eax, pos_x
	movl	4(%esi), %eax
	movl	%eax, pos_y

	pushl	MAX_X
	pushl	MIN_X
	pushl	dir_x
	pushl	(%esi)
	call 	move_head
	addl	$16, %esp
	movl	%eax, (%esi)

	pushl	MAX_Y
	pushl	MIN_Y
	pushl	dir_y
	pushl	4(%esi)
	call 	move_head
	addl	$16, %esp
	movl	%eax, 4(%esi)

	call 	move_tail

	ret	

move_head:
	movl	4(%esp), %eax
	movl	8(%esp), %ebx
	movl	12(%esp), %ecx
	movl	16(%esp), %edx

	cmpl	%ecx, %eax
	jl		case_min

	cmpl	%edx, %eax
	jg		case_max

	addl	%ebx, %eax
	jmp		move_end

case_min:
	movl	%edx, %eax
	jmp		move_end

case_max:
	movl	%ecx, %eax

move_end:
	ret

move_tail:
	movl 	snake_len, %eax
	decl	%eax
	movl 	$0, %ebx

tail_loop:
	addl	$8, %esi
	movl 	(%esi), %ecx
	movl 	4(%esi), %edx

	pushl 	pos_x
	popl	(%esi)
	pushl 	pos_y
	popl	4(%esi)

	movl 	%ecx, pos_x
	movl 	%edx, pos_y

	incl	%ebx
	cmpl	%eax, %ebx
	jne		tail_loop

	ret

check_snake_collision:
	# TODO
	ret

check_apple_collision:
	# TODO
	ret

draw_snake:
	movl 	$snake, %esi
	movl 	$0, %ebx

draw_snake_loop:
	pushl 	snake_symbol
	pushl	4(%esi)
	pushl	(%esi)
	call 	nib_put_scr
	addl	$12, %esp

	addl	$8, %esi
	incl 	%ebx

	cmpl	snake_len, %ebx
	jne		draw_snake_loop

	ret

draw_apples:
	movl 	$apples, %esi
	movl 	$0, %ebx

draw_apples_loop:
	pushl 	apples_symbol
	pushl	4(%esi)
	pushl	(%esi)
	call 	nib_put_scr
	addl	$12, %esp

	addl	$8, %esi
	incl 	%ebx

	cmpl	apples_n, %ebx
	jne		draw_apples_loop

	ret

#####################################
# DEBUG PRINT
#####################################
#	pushl	%eax
#	pushl	$output
#	call 	printf
#	addl	$8, %esp
