; ==================================================
; input dx as cursor start
; input si as string address
; push cl as string length
gen_menu_slot:
	push bp
	mov bp, sp
	call move_cursor
	call init_box
	mov cx, [bp+4]
	call print_string
	pop bp
ret 2
; ==================================================
display_mouse_coords:	; convert 0x0000 to x, y
	mov dx, 0x1848
	call move_cursor

.x_coords:	
	mov ax, [MOUSE_POS]
	cmp al, 10
	jb .x_continue		; 62, 3E, 0011 1110
	
	mov ah, 0
	mov bl, 10
	div bl
	
	mov bl, ah
	add al, 48
	call print_char
	mov al, bl
	
.x_continue:
	add al, 48
	call print_char
	mov al, ','
	call print_char
	
.y_coords:
	mov ax, [MOUSE_POS]
	cmp ah, 10
	jb .y_continue
	
	shr ax, 8	;FF 0000 0000 0000 0000
	mov bl, 10
	div bl
	
	mov bl, ah
	add al, 48
	call print_char
	mov ah, bl
	
.y_continue:
	mov al, ah
	add al, 48
	call print_char
	
.end:
	mov dx, [MOUSE_POS]
	call move_cursor
ret
; ==================================================
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
; ==================================================
; input dx as dh, dl (row, col)
move_cursor:
	mov ah, 0x02
	xor bx, bx
	int 0x10
	call remove_cursor
ret
; ==================================================
; input al as char
print_char:
	mov ah, 0x0e
	int 0x10
ret
; ==================================================
; input si as string address
; input cl as string length
print_string:
	mov ch, 0
	mov ah, 0x0e
.loop:
	lodsb
	int 0x10
	loop .loop
ret
; ==================================================
clear_screen:
	mov ah, 0x00
	mov al, 0x02
	int 0x10
ret
; ==================================================
remove_cursor:
	mov ah, 0x01
	mov ch, 0b00100000
	mov cl, 0b0000
	int 0x10
ret
; ==================================================
; ==================================================
; ==================================================
; ==================================================