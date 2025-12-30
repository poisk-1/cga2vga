cpu 8086
org 0

section .text

	db 0x55, 0xaa ; BIOS marker
	db 0 ; BIOS size / 512 bytes

entry:
	mov al, 16
	mov bl, 0

	push ax
	push bx
	push cx

.mode6:
	mov ah, 0
	mov al, 6
	int 10h

	jmp .draw_pattern

.mode4_pal0:
	mov ah, 0
	mov al, 4
	int 10h

	mov ah, 0xb
	mov bh, 1
	mov bl, 0
	int 10h

	jmp .draw_pattern

.mode4_pal1:
	mov ah, 0
	mov al, 4
	int 10h

	mov ah, 0xb
	mov bh, 1
	mov bl, 1
	int 10h

	jmp .draw_pattern

.alt_pattern:
	pop cx
	pop bx
	pop ax

	not bx

	push ax
	push bx
	push cx

	jmp .draw_pattern

.inc_patterns:
	pop cx
	pop bx
	pop ax

	cmp al, 64
	je .skip_inc_patterns
	shl al, 1
.skip_inc_patterns:

	push ax
	push bx
	push cx

	jmp .draw_pattern

.reset_patterns:
	pop cx
	pop bx
	pop ax

	mov al, 16

	push ax
	push bx
	push cx

	jmp .draw_pattern

.dec_patterns:
	pop cx
	pop bx
	pop ax

	cmp al, 1
	je .skip_dec_patterns
	shr al, 1
.skip_dec_patterns:

	push ax
	push bx
	push cx

.draw_pattern:
	pop cx
	pop bx
	pop ax

	call draw_pattern

	push ax
	push bx
	push cx

	call read_char

	cmp al, 0x30 ; '0'
	je .mode6

	cmp al, 0x31 ; '1'
	je .mode4_pal0

	cmp al, 0x32 ; '2'
	je .mode4_pal1

	cmp al, 0x20 ; Space
	je .alt_pattern

	cmp al, 0x3C ; '<'
	je .dec_patterns

	cmp al, 0x3D ; '='
	je .reset_patterns

	cmp al, 0x3E ; '>'
	je .inc_patterns

	jmp .draw_pattern

draw_pattern:
	push ax
	mov ax, 0xb800
	mov es, ax
	pop ax

	; fill even lines
	sub di, di
	call fill_zeroes
	call fill_pattern

	; fill odd lines
	mov di, 0x2000
	call fill_zeroes
	call fill_pattern

	ret

; al: number of patterns
; bl: 0 natural bits, 1 inverted bits
fill_pattern:
	pushf
	push ax
	push cx
	push di

	; al: number of patterns
	; cx = (100 / al) * 80
	; cx: bytes to fill
	push ax
	push bx

	mov bl, al
	mov ax, 100
	div bl
	mov bl, 80
	mul bl
	mov cx, ax

	pop bx
	pop ax

	cld

.next:
	dec al

	push ax
	push cx

	; al: pattern index (number of patterns, 0]
	; al = ((al & 0xf) << 4) + (al & 0xf)
	; al: pattern
	and ax, 0x000f
	mov ah, al
	mov cl, 4
	shl al, cl
	add al, ah

	cmp bl, 0
	je .skip_invert
	not al
.skip_invert:

	pop cx
	push cx

	rep stosb

	pop cx
	pop ax

	cmp al, 0
	jne .next

.done:
	pop di
	pop cx
	pop ax
	popf
	ret

fill_zeroes:
	pushf
	push ax
	push cx
	push di

	mov cx, 8000
	sub al, al

	rep stosb

	pop di
	pop cx
	pop ax
	popf
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
