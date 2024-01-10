[bits 16]
;[org 0x7c00]	; remove when adding to full program
audio_beginning:
jmp audio_1bit	; desired frequency = 1193181.666... / input value

;; CONSTANTS
RELOAD_VALUE_AUDIO	equ 0xA8F4	; music timings
;TIMER_ADDRESS		equ 0x046c	; PIT 0 count address
MAX_BARS		equ song_end-song

;; VARIABLES
;BOOT_DRIVE	db 0
BAR_COUNT	dw 0
note_count	dw 0

; nasm -f bin audio.asm -o test.bin
; qemu-system-x86_64 -audiodev dsound,id=id -machine pcspk-audiodev=id test.bin

audio_1bit:
	xor ax, ax
	mov ds, ax
	mov si, ax
	mov es, ax
	mov di, ax
	
	mov ax, 0x9000
	mov ss, ax
	mov sp, 0x0000

	;mov [BOOT_DRIVE], dl

	; mov [cylinder_count]
	; mov [head_count]
	; mov [sector_count]
	; mov [frame_address]


	mov al, 1
	call audio_print
	
	call load_audio
	
	mov al, 2
	call audio_print
	
	mov al, 3
	call audio_print
	
	cli
	call audio_speaker_init
	call audio_PIT_INIT
	sti

loop:
	mov bx, [BAR_COUNT]
	cmp bl, MAX_BARS
	jz .end_audio
	inc word [BAR_COUNT]
	
	add bx, song	; addr of song offset by bar_count
	mov bl, [bx]
	
	mov al, 2
	mul bl
	
	mov di, bar_addresses
	add di, ax
	mov di, [di]

	call bar_player
	
	jmp loop

.end_audio:
	mov al, 14
	call audio_print
	call off
cli
hlt

bar_player:	; di is address of bar to play
	mov word [note_count], 0
.loop:
	mov bx, [note_count]
	mov al, [di+bx]
	cmp al, 255
	je .end
	
	mov cl, al
	
	and al, 0b00011111	; offset of note Hz
	mov si, BASS
	
	xor ah, ah
	add si, ax
	mov ax, [si]
	call hz_change
	call on
	
	mov al, bl
	call audio_print
	
	shr cl, 5
	xor ch, ch
	mov si, SEMIQUAVER
	add si, cx
	mov cl, [si]
	mov al, cl
	call audio_print
	call audio_PIT_timer
	
	call off
	; call PIT_timer
	inc word [note_count]
	jmp .loop

.end:
	mov ax, di
	mov al, ah
	call audio_print
	mov ax, di
	call audio_print
ret
	
hz_change:	; needs ax input
	; or ax, ax
	; jnz .continue
	; call off
	; jmp .end
.continue:
	cli
	out 0x42, al
	mov al, ah
	out 0x42, al
	sti
.end:
ret

on:	; enable speaker
	in al, 0x61
	or al, 0b00000011
	out 0x61, al
ret

off:		; disable speaker
	in al, 0x61
	and al, 0b11111100
	out 0x61, al
ret

audio_speaker_init:	; program PIT 2 for pcspk
	mov al, 0b10110110 ; channel 2, hi/lo, mode 3
	out 0x43, al
ret

audio_PIT_INIT:
	mov al, 0b00110100	; channel 0, hi/lo, mode 2
	out 0x43, al
	mov ax, RELOAD_VALUE_AUDIO
	out 0x40, al
	mov al, ah
	out 0x40, al
ret

audio_PIT_timer:	; not the 'proper way' to implement pit
			; needs cx input for cycle delay
	
	.timer:
	mov ax, [TIMER_ADDRESS]
	mov bx, ax
	; inc bx
	add bx, cx
	
	.loop:
	cmp ax, bx
	jae .tick		; wait til PIT ticks
	
	mov ax, [TIMER_ADDRESS]
	jmp .loop

	.tick:
ret

audio_print:	; al as input
	mov ah, 0x0e
	int 0x10
ret

setup_iv:
	mov ax, loop
	mov [es:4 * 8], ax
	mov word [es:4 * 8 + 2], 0
ret

load_audio:
	mov ah, 0x02	; read data to memory
	mov al, 1	; no. of sectors
	mov ch, [cylinder_count] ; cylinder_count 
	mov cl, [sector_count]	; sector in head
	mov dh, [head_count] 	; head_count
	mov dl, [BOOT_DRIVE]	; boot_drive
	xor bx, bx
	mov es, bx
	mov bx, [frame_address]	; frame_address
	int 0x13
	jc audio_disk_error
ret

audio_disk_error:
	mov al, 48
	call audio_print
	jmp $

times 512-($-audio_beginning) db 0

;; SONG
%include "Bad Apple 1-bit Audio/song.data"
%include "Bad Apple 1-bit Audio/note_defs.data"

times 512*2-($-audio_beginning) db 0