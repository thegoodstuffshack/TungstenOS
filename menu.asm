[bits 16]
[org 0x7c00]
jmp start

;; CONSTANTS
boot_msg	db 'Booting '
os_name		db 'TungstenOS'
trailing	db '...'
msg_len		equ ($-boot_msg)
name_len	equ	(trailing - os_name)

slot_amount	db 4

;;	menu option names
slot00		db 'Bad Apple Video'
slot00_len	db ($-slot00)

slot01		db 'blank'
slot01_len	db ($-slot01)

slot02		db 'Bad Apple 1-bit Audio'
slot02_len	db ($-slot02)

slot03		db 'lorem ipsum'
slot03_len	db ($-slot03)

; nasm -f bin menu.asm -o menu.bin
; qemu-system-x86_64 menu.bin

start:
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x8000

	mov al, [slot00_len]
	call print_char
	mov al, [slot01_len]
	call print_char

	mov si, boot_msg
	mov cl, msg_len
	call print_string

	
; _Title	 40 -(name_length * 0.5)
; p blank lines
; menu title name
; r blank lines
; menu title name
; r blank lines
; ...

initial_screen:
	call clear_screen
	mov dx, 0x0023
	call move_cursor
	
	;mov 
	
	mov si, os_name
	mov cl, name_len
	call print_string
	
	
.menu_slots:
	mov dx, 0x0200
	mov si, slot00
	mov cl, [slot00_len]
	push cx
	call gen_menu_slot
	add dx, 0x0100
	mov si, slot01
	mov cl, [slot01_len]
	push cx
	call gen_menu_slot
	add dx, 0x0100
	mov si, slot02
	mov cl, [slot02_len]
	push cx
	call gen_menu_slot
	add dx, 0x0100
	mov si, slot03
	mov cl, [slot03_len]
	push cx
	call gen_menu_slot	
.end:
mov dx, 0x0201
call move_cursor
mov al, '*'
call print_char
jmp _wait

; ==================================================
_wait:	; update loop
	mov ah, 0x00
	int 0x16	; exits after keypress
	
	jmp key_press_handler
; ==================================================
	; jmp _wait

key_press_handler:
	; mov bx, ax
	cmp al, 13
	je menu.select
	cmp al, 0
	je .scancode
	
	;call print_char
	jmp _wait


.scancode: ; arrows keys: ↑'H', ←'K', →'M', ↓'P'
	cmp ah, 'P'
	je menu.down_arrow
	
	cmp ah, 'H'
	je menu.up_arrow

	; mov al, ah
	; call print_char
	jmp _wait

; ==================================================

menu:
	
.select:	; enter
	mov al, 28
	call print_char
	jmp _wait

.up_arrow:
	call move_cursor
	mov al, 24
	call print_char
	inc dl
	jmp _wait

.down_arrow:
	mov ah, [slot_amount]
	inc ah
	cmp dh, ah
	jae .do_nothing
	
	;sub dl, 1
	call move_cursor
	mov al, ' '
	call print_char

.do_nothing:
	jmp _wait

; ==================================================

gen_menu_slot:
	push bp
	mov bp, sp
	call move_cursor
	call init_box
	mov cx, [bp+4]
	call print_string
	pop bp
ret 2

; input dx as dh, dl (row, col)
move_cursor:
	mov ah, 0x02
	int 0x10
	call remove_cursor
ret

init_box:
	mov al, '['
	call print_char
	mov al, ' '
	call print_char
	mov al, ']'
	call print_char
	mov al, ' '
	call print_char
ret

clear_screen:
	mov ah, 0x00
	mov al, 0x02
	int 0x10
ret

remove_cursor:
	mov ah, 0x01
	mov ch, 0b00100000
	mov cl, 0b0000
	int 0x10
ret


%include 'print_functions.asm'

times 510-($-$$) db 0
dw 0xAA55

; \43
;q16 - ]27  enter28	
;a30 - '40
;z44 - /53