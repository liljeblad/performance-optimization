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
apples:			.fill 30, 4, 1
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
	pushl	$100000
	call 	usleep
	addl	$4, %esp
	call 	clear
	call 	handle_input

# Gets called when the game is over
end_game:
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
	# Call function rand to get a "random" number,
	# which is masked with the max width/height of the screen
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

# Move the coords in the snake array
move_snake:
	movl	$snake, %esi

	movl	(%esi), %eax	# Save the x and y positions of the head
	movl	%eax, pos_x		# To be used later when the tail will move
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

# Move the head
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

# After the head is moved, just use the previous
# coords to move the rest of the tail
move_tail:
	movl 	$1, %ebx

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
	cmpl	snake_len, %ebx
	jne		tail_loop

	ret

# Check if the snake hit itself during last move
check_snake_collision:
	movl 	$snake, %esi
	movl	(%esi), %eax	# Save the x and y positions of the head
	movl	4(%esi), %ebx

	movl 	$1, %ecx

snake_collision_loop:
	addl	$8, %esi

	cmpl	%eax, (%esi)
	jne 	end_snake_collision_loop

	cmpl	%ebx, 4(%esi)
	jne 	end_snake_collision_loop

	# If the snake hits itself, game over!
	jmp 	end_game

end_snake_collision_loop:
	incl	%ecx
	cmpl	snake_len, %ecx
	jne 	snake_collision_loop

	ret

# Check if the snake ate an apple during last move
check_apple_collision:
	movl 	$snake, %esi
	movl	(%esi), %eax	# Save the x and y positions of the snake's head
	movl	4(%esi), %ebx	# if they are the same as any coords in the 
							# apples array there will be a collision
	movl 	$apples, %esi
	movl 	$0, %ecx

apple_collision_loop:
	cmpl	%eax, (%esi)
	jne 	iterate_apple_collision_loop

	cmpl	%ebx, 4(%esi)
	jne 	iterate_apple_collision_loop

	call 	respawn_apple
	incl 	snake_len
	jmp 	end_apple_collision_loop

iterate_apple_collision_loop:
	addl	$8, %esi
	incl	%ecx
	cmpl	apples_n, %ecx
	jne 	apple_collision_loop

end_apple_collision_loop:
	ret

# An apple was eaten, spawn a new one on the board
respawn_apple:
	# Gets new "random" x and y position and puts it in the apples array
	call	rand
	andl	MAX_X, %eax
	movl	%eax, (%esi)

	call	rand
	andl	MAX_Y, %eax
	movl	%eax, 4(%esi)

	ret

# Draw the snake, i.e. put an "O" in all coords in the snake array
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

# Draw the apples, i.e. put an "*" in all coords in the apples array
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

handle_input:
	call 	nib_poll_kbd

	cmpl	%eax, KBD_QUIT
	je 		end_game

	cmpl	%eax, KBD_LEFT
	je 		turn_left

	cmpl	%eax, KBD_RIGHT
	je 		turn_right

	cmpl	%eax, KBD_UP
	je 		turn_up

	cmpl	%eax, KBD_DOWN
	je 		turn_down

	jmp		update_game

turn_left:
	cmpl	$1, dir_x
	je 		update_game

	movl 	$-1, dir_x
	movl 	$0, dir_y
	jmp 	update_game

turn_right:
	cmpl	$-1, dir_x
	je 		update_game

	movl 	$1, dir_x
	movl 	$0, dir_y
	jmp 	update_game

turn_up:
	cmpl	$1, dir_y
	je 		update_game

	movl 	$-1, dir_y
	movl 	$0, dir_x
	jmp 	update_game

turn_down:
	cmpl	$-1, dir_y
	je 		update_game

	movl 	$1, dir_y
	movl 	$0, dir_x
	jmp 	update_game
