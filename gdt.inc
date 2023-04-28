; GDT

;		dw	0xffff		limit
;		dw	0x0000		base ( 0-15 bits)
;		db	0x00		base (16-23 bits)
;		db	0x00		flags (P, DPL, S, E, DC, RW, A)
;		db	0x00		flags (G, DB, L, reserved) + limit (16-19 bits)
;		db	0x00		base (24-31 bits)
;
; flags:
;		P   - Present					must be 1
;		DPL - Descriptor Privilege Level		00 - Highest, 11-lowest
;		S   - type					0-system, 1-code/data
;		E   - Executable bit				0-data, 1-code
;		DC  - Direction bit/Conforming bit.		Complex, usually 0
;		RW  - Readable bit/Writable bit.		For code seg: 0-read not allowed, 1-read allowed, data seg: 0-write not allowed, 1-write allowed
;		A   - Accessed bit.				left clear, used by CPU to indicate access
;
;		G   - Granularity flag				0-1 byte, 1-4kb blocks
;		DB  - Size flag					0-16 bits, 1-32 bits 
;		L   - Long-mode code flag			1-64 bits code seg (for non code seg and 32 bits code seg should be 0)
;		R   - Reserved					not used

		align 8
gdt_start:
gdt_null:
		dd	0x0 
		dd	0x0

gdt_code:
		; base =0x0 , limit =0xfffff ,
		; 1 st flags : ( present )1 ( privilege )00 ( descriptor type )1 -> 1001 b
		; type flags : ( code )1 ( conforming )0 ( readable )1 ( accessed )0 -> 1010 b
		; 2 nd flags : ( granularity )1 (32 - bit default )1 (64 - bit seg )0 ( AVL )0 -> 1100 b
		dw	0xffff		; Limit ( bits 0 -15)
		dw	0x0		; Base ( bits 0 -15)
		db	0x0		; Base ( bits 16 -23)
		db	10011010b	; 1 st flags , type flags
		db	11001111b	; 2 nd flags , Limit ( bits 16 -19)
		;db	10001111b	; 2 nd flags , Limit ( bits 16 -19)
		db	0x0		; Base ( bits 24 -31)

gdt_data:
		; Same as code segment except for the type flags :
		; type flags : ( code )0 ( expand down )0 ( writable )1 ( accessed )0 -> 0010 b
		dw	0xffff		; Limit ( bits 0 -15)
		dw	0x0		; Base ( bits 0 -15)
		db	0x0		; Base ( bits 16 -23)
		db	10010010b	; 1 st flags , type flags
		db	11001111b	; 2 nd flags , Limit ( bits 16 -19)
		db	0x0		; Base ( bits 24 -31)

back_to_real_code:
		; base = 0x00000000, limit = 0xffff
		dw	0xffff		; limit
		dw	0x0000		; Base 00-15
		db	0x00		; Base 16-23
		db	10011010b	; P=1, DPL=0, S=1, E=1, DC=0, RW=1, A=0
		db	00000000b	; G=0, DB=0, L=0, R=0, limit 16-19=0000
		db	0x00		; Base 24-31

back_to_real_data:
		; base = 0x00000000, limit = 0xffff
		dw	0xffff		; limit
		dw	0x0000		; Base 00-15
		db	0x00		; Base 16-23
		db	10010010b	; P=1, DPL=0, S=1, E=0, DC=0, RW=1, A=0
		db	00000000b	; G=0, DB=0, L=0, R=0, limit 16-19=0000
		db	0x00		; Base 24-31
gdt_end:

gdt_descriptor :
		dw	gdt_end - gdt_start - 1
		dd	gdt_start

CODE_SEG	equ	gdt_code - gdt_start
DATA_SEG	equ	gdt_data - gdt_start
CODE_BACK_TO_16	equ	back_to_real_code - gdt_start
DATA_BACK_TO_16	equ	back_to_real_data - gdt_start

