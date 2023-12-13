; input al as char
print_char:
	mov ah, 0x0e
	int 0x10
ret

; input si as string address
; print_string:
	; mov ah, 0x0e
; .loop:
	; lodsb
	; or al, al
	; jz .end
	; int 0x10
	; jmp .loop
; .end:
; ret

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