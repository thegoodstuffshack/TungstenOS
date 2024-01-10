[bits 16]
[org 0x7c00]
jmp start

;; CONSTANTS
boot_msg	db 'Booting '
os_name		db 'TungstenOS'
trailing	db '...'
msg_len		equ ($-boot_msg)
name_len	equ	(trailing - os_name)
; ==================================================
;;
MOUSE_POS	dw	0x0000
slot_amount	dw 4

; default values set in case of failed parameter check
BOOT_DRIVE	db 0 	; si 	
max_sectors	db 15 	; si+1
max_heads	db 255	; si+2
max_cylinders 	db 255 	; si+3

sector_count	db 1		; si+4
sec_count		equ 1
head_count		db 0	 	; si+5
hed_count		equ 0
cylinder_count	db 0		; si+6
cyl_count		equ 0
frame_address	dw 0x7e00	; si+7

; EDIT THESE VALUES FOR BOOTING USING BARE-METAL
; sector_count	db 37		; si+4
; sec_count		equ 37
; head_count		db 101	 	; si+5
; hed_count		equ 101
; cylinder_count	db 65		; si+6
; cyl_count		equ 65
; frame_address	dw 0x7e00	; si+7

; ==================================================
;;	menu option names
slot00		db 'Bad Apple Video'
slot00_len	db ($-slot00)	

slot01		db 'blank'
slot01_len	db ($-slot01)

slot02		db 'Bad Apple 1-bit Audio'
slot02_len	db ($-slot02)

slot03		db 'lorem ipsum'
slot03_len	db ($-slot03)

; CHS offset from this program
slot00_CHS	db	cyl_count+0,	hed_count+0,	sec_count+2
slot01_CHS	db	cyl_count+3,	hed_count+3,	sec_count+3
slot02_CHS	db	cyl_count+3,	hed_count+52,	sec_count+10
slot03_CHS	db	cyl_count+3,	hed_count+3,	sec_count+3

; ==================================================
; nasm -f bin menu.asm -o menu.bin
; qemu-system-x86_64 menu.bin
; ==================================================
start:
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00
	
	mov [BOOT_DRIVE], dl
	call check_disk_CHS
	call disk_handler
	call load_sector

	mov al, [slot00_len]
	call print_char
	mov al, [slot01_len]
	call print_char

	mov si, boot_msg
	mov cl, msg_len
	call print_string

initial_screen:
	call clear_screen
.error:
	mov dx, 0x0023
	call move_cursor

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
mov [MOUSE_POS], dx
call move_cursor
mov al, '*'
call print_char
jmp _wait

; ==================================================
_wait:	; update loop
	call display_mouse_coords
	mov ah, 0x00
	int 0x16	; exits after keypress
	jmp key_press_handler
; ==================================================

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


%include 'src/load.asm'
%include 'src/disk.asm'

times 510-($-$$) db 0
dw 0xAA55

; ==================================================
; 1. check, handle, load
; 2. stuff that calls functions
; 3. functions
; ==================================================
menu:
	
.select:	; enter
	mov dx, [MOUSE_POS]
	sub dh, 2
	mov bl, dh
	xor bh, bh
	mov ax, 3
	mul bx
	mov bx, ax
	add bx, slot00_CHS
	
	mov ah, 0x02	; read data to memory
	mov al, 1		; no. of sectors
	mov ch, [bx]	; cylinder_count 
	mov cl, [bx+2]	; sector in head
	mov dh, [bx+1]	; head_count
	mov dl, [BOOT_DRIVE]	; boot_drive
	xor bx, bx
	mov es, bx
	mov bx, 0x8000	; frame_address
	int 0x13
	jc disk_error
	
	jmp 0x0000:0x8000
	
.up_arrow:
	mov dx, [MOUSE_POS]
	cmp dh, 2
	jle _wait
	
	mov dx, [MOUSE_POS]
	call move_cursor
	mov al, ' '
	call print_char
	
	sub word [MOUSE_POS], 0x0100
	mov dx, [MOUSE_POS]
	call move_cursor
	mov al, '*'
	call print_char

	jmp _wait

.down_arrow:
	mov ah, [slot_amount]
	inc ah
	cmp dh, ah
	jae _wait
	
	mov dx, [MOUSE_POS]
	call move_cursor
	mov al, ' '
	call print_char
	
	add word [MOUSE_POS], 0x0100
	mov dx, [MOUSE_POS]
	call move_cursor
	mov al, '*'
	call print_char

	jmp _wait

; ==================================================

%include 'src/functions.asm'

; %include 'functions2.asm'
times 1024-($-$$) db 0

%include 'src/vid/boot.asm'
incbin 'Bad Apple Video/bad_apple_video.bin'
times 3284*512-($-$$) db 0
%include 'Bad Apple 1-bit Audio/audio.asm'
times 3286*512-($-$$) db 0
;52 heads, 8 sectors