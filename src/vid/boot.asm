jmp bad_apple

;; CONSTANTS
TIMER_ADDRESS 		equ	0x046c	; location of PIT timer count
RELOAD_VALUE 		equ	0x9b84  ; determines tick speed of PIT
number_of_frames 	equ	3281	; divide frames by 2
FOREGROUND 		equ 	35
BACKGROUND		equ 	32


;; CODE
bad_apple:
	xor ax, ax
	mov ds, ax
	mov si, ax
	mov ds, ax
	mov es, ax
	
	mov ss, ax
	mov sp, 0x7c00
	
	mov bx, slot00_CHS
	mov al, [bx+2]
	mov byte [sector_count], al
	mov al, [bx+1]
	mov byte [head_count], al
	mov al, [bx]
	mov byte [cylinder_count], al
	mov word [frame_address], 0x8200
	
	call PIT_init
	call PIT_timer

	; sets cursor to invisible to remove flickering
	mov ah, 0x01
	mov ch, 0b0010
	mov cl, 0b0000
	int 0x10
	
	mov cx, number_of_frames
run:
	cmp cx, 0
	je .end
	dec cx
	push cx
	
	call PIT_timer
	call frame_handler
	call load_frame
	call reset_cursor

	call frame
	call PIT_timer
	call reset_cursor
	
	mov word [frame_address], 0x8300
	call frame
	mov word [frame_address], 0x8200
	; assuming 2 frames per sector
	
	pop cx
	jmp run
	
	.end:

	jmp initial_screen

cli
hlt

reset_cursor:
	mov ah, 0x02
	mov bh, 0
	xor dx, dx
	int 0x10			; move cursor to 0,0
ret

disk_reset:
	mov ah, 0x00
	mov dl, [BOOT_DRIVE]
	int 0x13
ret


%include "src/vid/disk_functions.asm"
%include "src/vid/pit.asm"
%include "src/vid/print.asm"
%include "src/vid/load.asm"

times 512*3 - ($-$$) db 0

;%include "src/frames.asm"	; append frame data to .bin and compile
