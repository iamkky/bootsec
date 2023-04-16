;
; ASCII CHARS
;
CR		equ 13		; Carriage Return
LF		equ 10		; Line Feed
FF		equ 12		; Form Feed
BS		equ  8		; Backspace

		org	7C00h

; Not sure but looks like jmp is part of boot sector "magic id"
; for some old BIOS

begin:
                jmp short .start
                nop
.start:
		mov	[BootDrive], dl		; Saves Bios boot drive number

		;mov	edx, esp		; check value of SP
		;call	biosWriteHex
		;mov	edx, 0x3430		; biosWriteHex test
		;call	biosWriteHex

		mov	si, msg
		call	biosWriteStr

; Exit from int 13h 41h
; carry clear
; AH - Version of extensions = 30h
; AL - Internal use only
; BX - AA55h
; CX - Interface support bit map (seeTable 2 )
; carry set
; AH - error code (01h, Invalid Command)
checkEdd:
		mov	si, msg_edd_bios
		call	biosWriteStr
		mov	ah, 0x41
		mov	bx, 0x55AA
		mov	dl, [BootDrive]
		int	0x13
		jnc	.ok
		mov	si, msg_failed
		call	biosWriteStr
		jmp	bootFail
.ok:
		mov	si, msg_ok
		call	biosWriteStr



		call	showRegister

ReadStage2:
		mov	si, DataPacket		; address of "disk address packet"
		mov	ah, 0x42		; AL is unused
		mov	dl, [BootDrive]		; drive number 0 (OR the drive # with 0x80)
		int	0x13
		jnc	short .ok
		jmp	bootFail
.ok:

		mov	edx,[magic_stage2]
		call	biosWriteHex
		call	biosWriteCRLF
		
		jmp	stage2

		jmp	$				; Jump to the current address ( i.e. forever ) .
;
; Padding and magic BIOS number.
;

bootFail:
		mov	si, msg_bootfail
		call	biosWriteStr
		jmp	$

; Reads N sector using bios int 13h 42h
; AX: Block count to read
; BX; Destination address
; EDX: LBA address

retries		equ	8

readSec:
		mov	[DataPacket.buffer], bx
		mov	[DataPacket.lba], edx
		push	dx
		mov	dh, retries
.retry
		push	ax
		mov	[DataPacket.blocks], ax
		mov	si, DataPacket		; address of "disk address packet"
		mov	ah, 0x42		; AL is unused
		mov	dl, [BootDrive]		; drive number 0 (OR the drive # with 0x80)
		int	0x13
		jnc	short .ok
		
		pop	ax
		dec	dh
		test	dh, dh
		jnz	.retry

		pop	dx
		jmp	bootFail
.ok:
		pop	ax
		pop	dx
		ret
		

readsector:
		

showRegister:
		call	biosWriteCRLF
		mov	edx, 'ESP:'
		call	biosWriteEdx
		mov	edx, esp
		call	biosWriteHex
		call	biosWriteCRLF
		ret
		

%include "conio.inc"

;
; Strings
;

msg_bootfail	db CR, LF, 'Boot Aborted!', CR, LF, 0
msg		db 'Abud online', CR, LF, 0
msg_edd_bios	db 'EDD BIOS: ', 0
msg_failed	db 'Failed', 0
msg_ok		db 'OK', 0
BootDrive	db  0
;
; From: https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h)
;
DataPacket:
		db	0x10
		db	0
.blocks:	dw	1		; int 13 resets this to # of blocks actually read/written
.buffer:	dw	0x7e00		; memory buffer destination address (0:7c00)
		dw	0		; in memory page zero
.lba:		dd	1		; put the lba to read in this spot
		dd	0		; more storage bytes only for big lba's ( > 4 bytes )
 

		times 510-($-$$) db 0		; Pad the boot sector out with zeros
		dw 0xaa55			; Last two bytes form the magic number ,

magic_stage2:
		
		dw 0xabcd

stage2:
		mov	si,	msg_stage2
		call	biosWriteStr
		jmp	$


msg_stage2	db 'Second Stage loaded', CR, LF, 0

		times 1024-($-$$) db 0		; Pad second sector out with zeros

; so BIOS knows we are a boot sector.

