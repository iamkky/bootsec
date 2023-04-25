




		struc kernel_header
			resb 0x1F1	; padding
kh_setup_sects		resb 1		; 01F1/1 - ALL(1) setup_sects The size of the setup in sectors
kh_root_flags		resw 1		; 01F2/2 - ALL root_flags If set, the root is mounted readonly
kh_syssize		resw 2		; 01F4/4 - 2.04+(2) syssize The size of the 32-bit code in 16-byte paras
kh_ram_size		resw 1		; 01F8/2		ALL ram_size DO NOT USE - for bootsect.S use only
kh_vid_mode		resw 1		; 01FA/2		ALL vid_mode Video mode control
kh_root_dev		resw 1		; 01FC/2		ALL root_dev Default root device number
kh_boot_flag		resw 1		; 01FE/2		ALL boot_flag 0xAA55 magic number
kh_jump			resw 1		; 0200/2		2.00+ jump Jump instruction
kh_header		resw 2		; 0202/4		2.00+ header Magic signature "HdrS"
kh_version		resw 1		; 0206/2		2.00+ version Boot protocol version supported
kh_realmode_swtch	resw 2		; 0208/4		2.00+ realmode_swtch Boot loader hook (see below)
kh_start_sys_seg	resw 1		; 020C/2		2.00+ start_sys_seg The load-low segment (0x1000) (obsolete)
kh_kernel_version	resw 1		; 020E/2		2.00+ kernel_version Pointer to kernel version string
kh_type_of_loader	resb 1		; 0210/1		2.00+ type_of_loader Boot loader identifier
kh_loadflags		resb 1		; 0211/1		2.00+ loadflags Boot protocol option flags
kh_setup_move_size	resw 1		; 0212/2		2.00+ setup_move_size Move to high memory size (used with hooks)
kh_code32_start		resw 2		; 0214/4		2.00+ code32_start Boot loader hook (see below)
kh_ramdisk_image	resw 2		; 0218/4		2.00+ ramdisk_image initrd load address (set by boot loader)
kh_ramdisk_size		resw 2		; 021C/4		2.00+ ramdisk_size initrd size (set by boot loader)
kh_bootsect_kludge	resw 2		; 0220/4		2.00+ bootsect_kludge DO NOT USE - for bootsect.S use only
kh_heap_end_ptr		resw 1		; 0224/2		2.01+ heap_end_ptr Free memory after setup end
kh_ext_loader_ver	resb 1		; 0226/1		2.02+(3) ext_loader_ver Extended boot loader version
kh_ext_loader_type	resb 1		; 0227/1		2.02+(3) ext_loader_type Extended boot loader ID
kh_cmd_line_ptr		resw 2		; 0228/4		2.02+ cmd_line_ptr 32-bit pointer to the kernel command line
;kh_			022C/4		2.03+ initrd_addr_max Highest legal initrd address
;kh_			0230/4		2.05+ kernel_alignment Physical addr alignment required for kernel
;kh_			0234/1		2.05+ relocatable_kernel Whether kernel is relocatable or not
;kh_			0235/1		2.10+ min_alignment Minimum alignment, as a power of two
;kh_			0236/2		2.12+ xloadflags Boot protocol option flags
;kh_			0238/4		2.06+ cmdline_size Maximum size of the kernel command line
;kh_			023C/4		2.07+ hardware_subarch Hardware subarchitecture
;kh_			0240/8		2.07+ hardware_subarch_data Subarchitecture-specific data
;kh_			0248/4		2.08+ payload_offset Offset of kernel payload
;kh_			024C/4		2.08+ payload_length Length of kernel payload
;kh_			0250/8		2.09+ setup_data 64-bit physical pointer to linked list of struct setup_data
;kh_			0258/8		2.10+ pref_address Preferred loading address
;kh_			0260/4		2.10+ init_size Linear memory required during initialization
;kh_			0264/4		2.11+ handover_offset Offset of handover entry point
;kh_			0268/4		2.15+ kernel_info_offset Offset of the kernel_info
		endstruc
