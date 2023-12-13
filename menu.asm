[bits 16]
[org 0x7c00]
jmp start

;; CONSTANTS
boot_msg	db 'Booting '
os_name		db 'TungstenOS'
trailing	db '...'
msg_len		equ ($-boot_msg)
name_len	equ	(trailing - os_name)

;;	menu option names
slot01		db 'Bad Apple Video'
slot01_len	equ ($-slot01)


; nasm -f bin menu.asm -o menu.bin
; qemu-system-x86_64 menu.bin

start:
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x8000

	mov al, msg_len
	call print_char
	mov al, name_len
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
	
	
.second:
	mov dx, 0x0300
	call move_cursor

	mov si, slot01
	mov cl, slot01_len
	call print_string



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
	mov al, 24
	call print_char
	jmp _wait

.down_arrow:
	mov al, 25
	call print_char
	jmp _wait

; ==================================================

; new_line:
	; mov al, 0x0A
	; call print_char
	; mov al, 0x0D
	; call print_char
; ret

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

; input dx as dh, dl (row, col)
move_cursor:
	mov ah, 0x02
	int 0x10
	call remove_cursor
ret

%include 'print_functions.asm'

times 510-($-$$) db 0
dw 0xAA55

; \43
;q16 - ]27  enter28	
;a30 - '40
;z44 - /53