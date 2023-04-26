; BAsic Boot Sector 
;	Loads and change control to a kernel image located in sequential blocks of the boot disk
;
;
;	References:
;	  EDD:
;	    https://archive.org/details/specs-edd30/
;	  i32/x86_64:
;	    https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html
;	    https://css.csail.mit.edu/6.858/2014/readings/i386/toc.htm
;	  Bios Services:
;	    https://www.ctyme.com/rbrown.htm
;	    https://www.ctyme.com/intr/int-13.htm
;	  Nasm:
;	    https://www.nasm.us/doc/
;	  Bootsec tutor:
;	    https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf

;
; Kernel Protocol fields
;	From: https://www.kernel.org/doc/html/latest/x86/boot.html
;
%include "kprot.inc"

;
; ASCII CHARS
;
CR		equ 13		; Carriage Return
LF		equ 10		; Line Feed
FF		equ 12		; Form Feed
BS		equ  8		; Backspace

; 
; General Parameters
;
disk_retries	equ	4


; Not sure, but looks like jmp is part of boot sector "magic id"
; for some old BIOS
		org	7C00h
begin:
                jmp	short .start
                nop
.start:
		cli
		xor	ax, ax
		mov	ds, ax
		mov	es, ax
		mov	ss, ax
		mov	[BootDrive], dl		; Saves Bios boot drive number
		sti

		mov	si, msg_starting
		call	biosWriteStr

; checkEdd
;	Checks by Extended Disk Drive Specification BIOS
;	Exit from int 13h 41h
;	carry clear
;	AH - Version of extensions = 30h
;	AL - Internal use only
;	BX - AA55h
;	CX - Interface support bit map (seeTable 2 )
;	carry set
;	AH - error code (01h, Invalid Command)
checkEdd:
		mov	si, msg_edd_bios
		call	biosWriteStr
		mov	ah, 0x41
		mov	bx, 0x55aa
		mov	dl, [BootDrive]
		int	0x13
		jnc	.ok
.fail:
		mov	si, msg_failed
		jmp	bootFailMsg
.ok:
		cmp	bx, 0xaa55
		jne	.fail
		test	cx, 1
		jz	.fail

		mov	si, msg_ok
		call	biosWriteStr
		call	biosWriteCRLF

ReadStage2:
		mov	ax, 0x1
		mov	bx, 0x7e00
		mov	edx, 0x1	
		call	readSec

Stage2Check:
		mov	dx, [stage2_magic]
		cmp	dx, stage2_signature
		je	.ok
		mov	si, msg_stage2_fail
		jmp	bootFailMsg

.ok:
		mov	si, msg_stage2_ok
		call	biosWriteStr

JumpToStage2:
		jmp	0:stage2

;
; Abort message
;

bootFailMsg:
		call	biosWriteStr
bootFail:
		mov	si, msg_bootfail
		call	biosWriteStr
		jmp	$

; readSec: 
; 	Reads N sector using bios int 13h 42h
; 	AX:    Block count to read
; 	ES:BX: Destination address
; 	EDX:   LBA address
;
; readOneSec:
;	Same but reads just one sector


readOneSec:	
		mov	ax, 1
readSec:
		push	ax
		mov	[DataPacket.buffer], bx
		mov	[DataPacket.segment], es
		mov	[DataPacket.lba], edx
		mov	cx, disk_retries
.retry:
		mov	[DataPacket.blocks], ax
		mov	si, DataPacket
		mov	ah, 0x42
		mov	dl, [BootDrive]
		int	0x13
		jnc	short .ok
		mov	ax, [esp]
		loop	.retry

		pop	ax
		jmp	bootFail
.ok:
		pop	ax
		ret

showRegisters:
		pushad
		mov	di, msg_register
		mov	bp, sp
.loop:
		mov	edx, [di]
		mov	eax, [bp]
		call	showHexWithLabel
		add	bp, 4
		add	di, 4
		cmp	di, msg_register + 32
		jne	.loop
		popad
		ret

; showHexWithLabel:
;	Shows a Hex value with a label, in the form 'LLL:<value>'
;	maily used by showRegisters:
; 	EDX: Label
; 	EAX: Hex
; 	
showHexWithLabel:
		push	eax
		call	biosWriteEdx
		pop	edx
		call	biosWriteHex
		call	biosWriteCRLF
		ret

%include "conio.inc"

BootDrive	db	0
;
; From: https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h)
;
DataPacket:
		db	0x10		; Frame size: 16 bytes
		db	0		; Must be zero (convention)
.blocks:	dw	0		; number of blocks
.buffer:	dw	0x7e00		; Buffer address
.segment	dw	0		; Buffer Segment
.lba:		dd	1		; LBA block address
.notused	dd	0		; Linear memory address (not used)
 
;
; Messages
;

msg_bootfail	db	CR, LF, 'Boot Aborted!', CR, LF, 0
msg_starting	db	'ABDL Starting', CR, LF, 0
msg_stage2_fail	db	'Failed second stage load', CR, LF, 0
msg_stage2_ok	db	'S2 Check', CR, LF, 0
msg_edd_bios	db	'EDD BIOS: ', 0
msg_failed	db	'Failed', 0
msg_ok		db	'OK', 0
msg_register	dw	'EDI:ESI:EBP:ESP:EBX:EDX:ECX:EAX:'

		times 0x1be-($-$$) db 0		; Pad up to MBR partition position and places a 'fake' partitions
						; Looks like satisfy some BIOS that want a MBR partition in place
		;db	80h, 01h, 01h, 00h, 83h, 0FEh, 3Fh, 00h, 3Fh, 00h, 00h, 00h
		db	80h, 01h, 01h, 00h, 83h, 0FEh, 3Fh, 00h, 3Fh, 00h, 00h, 00h, 82h, 3Eh, 00h, 00h, 00h, 00h
	
		times (0x200-2) - ($-$$) db 0	; Pad up to end of bootsector - 2
		dw 0xaa55			; Magic bootsector number

; =========================================================
; === Stage 2
; ========================================================

stage2_signature	equ	0xabcd

stage2_magic:
		dw	stage2_signature

stage2:
		mov	si, msg_s2.stage2
		call	biosWriteStr
		
		call	checkA20
		cmp	ax, 1
		je	.a20_ok
		
		mov	si, msg_s2.a20_disabled
		jmp	bootFailMsg

.a20_ok:
		; Loads a kernel staring at LBA 0x04
		mov	edx, 0x04
		jmp	loadKernel

		jmp	$

;
; Loads a Kernel staring at LBA block pointed by EDX
;

cmdline		equ	0xe000

loadKernel:
		; Reads first 32kb at 0x1000:0000
		mov	ax, 0x1000
		mov	es, ax
		mov	bx, 0x0000
		mov	ax, 64
		call	readSec

		mov	ax, [es:kh_boot_flag]
		cmp	ax, 0xAA55
		je	.sig_ok
.sig_not_ok:
		mov	si, msg_s2.fail_sig1
		jmp	bootFailMsg
.sig_ok:
		mov	eax, [es:kh_header]
		cmp	eax, 'HdrS'
		jne	.sig_not_ok

		movzx	edx, byte [es:kh_setup_sects]
		call	writeHexSpace
		mov	edx, [es:kh_syssize]
		call	writeHexSpace
		movzx	edx, word [es:kh_version]
		call	writeHexSpace
		call	biosWriteCRLF

		xor	eax, eax
		mov	dword [es:kh_ramdisk_image], eax
		mov	dword [es:kh_ramdisk_size], eax
		mov	word [es:kh_heap_end_ptr], 0xde00	
		mov	byte [es:kh_type_of_loader], 0xff
		mov	dword [es:kh_cmd_line_ptr], 0x10000+cmdline
		or	byte [es:kh_loadflags], 0x80

		cld
		mov	si, defcmdline
		mov	cx, defcmdline_size
		mov	di, cmdline
		rep movsb

		;call	showRegisters
.comment1:

runKernel:
		;
		; Breaking Execution for debug with qemu
		;
		break	equ	0x2bb
		;mov	byte [es:break], 0xeb
		;mov	byte [es:break+1], 0xfe

		; Put this here to break signature and see that real mode setup are really running
		mov	byte [es:0x2a5], 0xfe
		cli
		mov	ax, 0x1000
		mov	ds, ax
		mov	es, ax
		mov	fs, ax
		mov	gs, ax
		mov	ss, ax
		mov	sp, 0xe000
.jump1:

		jmp	0x1020:0x0000

writeHexSpace:
		call	biosWriteHex
		mov	edx, ' '
		call	biosWriteEdx
		ret


		

; code from: https://wiki.osdev.org/A20_Line
;	out:
;		ax - state (0 - disabled, 1 - enabled)
checkA20:
		pushf
		push	si
		push	di
		push	ds
		push	es
		cli
 
		mov	ax, 0x0000					;	0x0000:0x0500(0x00000500) -> ds:si
		mov	ds, ax
		mov	si, 0x0500
 
		not	ax						;	0xffff:0x0510(0x00100500) -> es:di
		mov	es, ax
		mov	di, 0x0510
 
		mov	ah, 1
		mov	byte [ds:si], 0
		mov	byte [es:di], 1
		out	0x80, al
		out	0x80, al
		mov	al, [ds:si]
		cmp	al, [es:di]					;	check byte at address 0x0500 != byte at address 0x100500
		jne 	.exit
		dec	ah
.exit:
		shr	ax, 8					;	move result from ah to al register and clear ah
		sti
		pop	es
		pop	ds
		pop	di
		pop	si
		popf
		ret

pm_test:
		cli
		lgdt	[gdt_descriptor]
		mov	eax, cr0
		or	eax, 0x1
		mov	cr0, eax
		jmp	CODE_SEG:.init_pm
		bits 32
.init_pm:
		mov	ax, DATA_SEG
		mov	ds, ax
		mov	es, ax

		; 32 bits pm code
		call	abcd_pm_mode

		; returning to real mode
		mov	ax, DATA_BACK_TO_16
		mov	es, ax
		mov	ds, ax
		mov	es, ax

		jmp	CODE_BACK_TO_16:.back
.back:
		bits 16
		mov	eax, cr0
		and	al, 0xfe 
		mov	cr0, eax
		jmp	0x0:.exit_pm
.exit_pm:
		xor	ax, ax
		mov	ds, ax
		mov	es, ax
		mov	ss, ax
		sti

		ret

		
; 32 bits protected mode code
		bits 32
;
; writes 'ABCD' on left upper corner of screen
; Using direct video access in 32 bits protected mode
; just a test
;
abcd_pm_mode:
		mov	ax, 0x0f41
		mov	[0xb8000], ax
		mov	ax, 0x0f42
		mov	[0xb8002], ax
		mov	ax, 0x0f43
		mov	[0xb8004], ax
		mov	ax, 0x0f44
		mov	[0xb8006], ax
		ret

%include "gdt.inc"

defcmdline	db	'linux auto', 0
defcmdline_size	equ	$-defcmdline

msg_s2:
.stage2		db	'S2 Starting', CR, LF, 0
.a20_disabled	db	'S2 A20 Not Enabled', CR, LF, 0
.fail_sig1	db	'S2 Signature failed', CR, LF, 0

		times	2048-($-$$) db 0

