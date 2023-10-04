cpu 8086
org 0

section .text

	db 0x55, 0xaa ; BIOS marker
	db 0 ; BIOS size / 512 bytes

entry:	
	mov ah, 0
	mov al, 6
	int 10h

	call draw_pattern
	call read_char

	mov ah, 0
	mov al, 4
	int 10h

	mov ah, 0xb
	mov bh, 1
	mov bl, 0
	int 10h

	call draw_pattern
	call read_char

	mov ah, 0
	mov al, 4
	int 10h

	mov ah, 0xb
	mov bh, 1
	mov bl, 1
	int 10h

	call draw_pattern
	call read_char

	jmp entry

draw_pattern:
	mov ax, 0xb800
	mov es, ax

	cld

	sub al, al
	sub di, di
.next1:
	mov cx, 480
	rep stosb

	add al, 0x11
	jnc .next1

	sub al, al
	mov di, 0x2000
.next2:
	mov cx, 480
	rep stosb

	add al, 0x11
	jnc .next2
	ret

	; Char in AL
read_char:
	push bx
	push cx
	push dx
	push si
	push di
	mov ah, 0x00
	int 0x16
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	ret
