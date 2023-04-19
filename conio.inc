	section .text

; Writes a char in AL to screen
; input: al pointer to strings
; Uses eax, ebx

biosWriteChar:
	mov	ah, 0x0e
	mov	bx, 0x0007
	int	0x10
	ret

; Writes a char in AL to screen
; input: al pointer to strings
; Uses eax, ebx

biosWriteCRLF:
	mov	al, CR
	call	biosWriteChar
	mov	al, LF
	call	biosWriteChar
	ret
	
; Writes out a null terminated string pointed by SI
; input: si pointer to strings
; Uses eax, ebx, si

biosWriteStr:
	jmp	.L4
.L3:
	call	biosWriteChar
.L4:
	movzx	eax, byte [si]
	add	si, 1
	test	al, al
	jne	.L3
.L10:
	rep ret

; Writes out content of DX as a hex number
; input: EDX holds the number to be printed
; Uses eax, ebx, ecx, edx

biosWriteHex:
	mov	cx, 8
.L4:
	rol	edx, 4
	mov	ax, dx
	and	al, 0x0f
	add	al, 48
	cmp	al, 57
	jle	.L5
	add	al, 7
.L5:	
	call	biosWriteChar
	loop	.L4
	;dec	cx
	;jne	.L4

	rep ret

; Writes out a null terminated string contained into EDX
; input: EDX contains a string
; Uses eax, ebx, ecx, edx

biosWriteEdx:
	mov	cx, 4
.L4:
	mov	ax, dx
	and	al, 0xff
	jz	.L5
	shr	edx, 8
	call	biosWriteChar
	loop	.L4
	;dec	cl
	;jne	.L4
.L5:
	rep ret




