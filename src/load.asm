;; load.asm

disk_handler:
	mov si, BOOT_DRIVE
	
	inc byte [si+4]	; inc sector_count
	mov al, [si+4]
	cmp al, [si+1]	; cmp sector_count to max_sectors
	jbe .end		; if below or equal, end
	
	mov byte [si+4], 1	; zero sector_count
	inc byte [si+5]		; inc head_count
	mov al, [si+5]
	cmp al, [si+2]	; cmp head_count to max_heads
	jbe .end		; if below or equal, end
	
	mov byte [si+4], 1	; zero sector_count
	mov byte [si+5], 0	; zero head_count
	inc byte [si+6]		; inc cylinder_count
	mov al, [si+6]
	
	.end:
ret

load_sector:
	; mov si, BOOT_DRIVE
	
	mov ah, 0x02	; read data to memory
	mov al, 1	; no. of sectors
	mov ch, [si+6]	; cylinder_count 
	mov cl, [si+4]	; sector in head
	mov dh, [si+5]	; head_count
	mov dl, [si]	; boot_drive
	xor bx, bx
	mov es, bx
	mov bx, [si+7]	; frame_address
	int 0x13
	jc disk_error
ret
	
