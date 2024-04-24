; Top of stack on entry to swi handler
;
; 6809:
swiCC		equ	0
swiAreg		equ	1
swiBreg		equ	2
swiDPreg	equ	3
swiXreg		equ	4
swiYreg		equ	6
swiUreg		equ	8
swiPC		equ	10

handle_swi	ldu	10,s			; U points at the return address
	
		lda     ,u			; ld fn code
		
		leau	1,u			; Modify the return address to skip over
						; the fn byte following SWI instruction
		stu	10,s			; Put the modified return address back on the stack
            
		cmpa    #0
		blt     SWIDone
		cmpa    #SWIMax
		bge     SWIDone
            
		asla				; Calculate offset into jump table
		leau    SWITable,pcr
		ldd     a,u
		jmp     d,u

	
SWITable	fdb     sysGetChar-SWITable
		fdb     sysPutChar-SWITable
		fdb	sysPutStr-SWITable
		fdb	sysPutNLStr-SWITable
		fdb	sysPut2Hex-SWITable
		fdb	sysPut4Hex-SWITable
SWIend		equ	*
SWIMax		equ	(SWIend-SWITable)/2
SWIDone		rti				; Function code was out of bounds - just return

sysGetChar	lbsr	getChar
		anda	#$7f			; Strip parity
		cmpa	#CR
		bne	1F
		lda	#LF
1		sta	swiAreg,S
		rti

sysPutChar	lbsr    putChar
		rti

sysPutStr	lbsr	sysPutStr
		rti

sysPutNLStr	lbsr	putNL
		ldx	swiXreg,S
		lbsr	putStr
		rti

sysPut2Hex	lbsr	putHexByte
		lda	#SPACE
		lbsr	putChar
		rti

sysPut4Hex	lbsr	putHexWord
		lda	#SPACE
		lbsr	putChar
		rti

SWI1		lda     #'Z
		rti
