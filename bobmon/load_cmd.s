;
; doLoad - load Intel hex records
;

		globals

; Used by both ihex and srec loading
g.loadLength	rmb	1
g.loadAddress	rmb	2
g.loadType	rmb	1
g.loadXsum	rmb	1


		code

loadMinArgs	equ	0
loadMaxArgs	equ	0
loadCommand	fcn	"load"
loadHelp	fcn	TAB,"load intel hex records (types 0 and 1 only) or Motorola",CR,LF,TAB,"S-records from the terminal"

doLoad		leax	loading_msg,pcr
		lbsr	putStr

dlNextLine	lbsr	getChar
		cmpa	#CTRLC
		lbeq	dlAbort

		cmpa	#':'
		beq	loadiHex
		cmpa	#'S'
		lbeq	loadMoto
dlSkipLine	lbsr	getChar
		cmpa	#CR
		bne	dlNextLine
		bra	dlSkipLine


loadiHex	leax	ihex_msg,pcr
		lbsr	putStr
lihNext		lbsr	loadiHexRecord
		tsta
		beq	dlError
		cmpa	#2
		beq	dlDone
		lbsr	getChar
		cmpa	#CTRLC
		beq	dlAbort
		cmpa	#':'
		beq	lihNext
		bra	dlError


loadMoto	leax	moto_msg,pcr
		lbsr	putStr
lmNext		lbsr	loadMotoRecord
		tsta
		beq	dlError
		cmpa	#2
		beq	dlDone
		lbsr	getChar
		cmpa	#CTRLC
		beq	dlAbort
		cmpa	#'S'
		beq	lmNext

dlError		leax	bad_fmt_msg,pcr
		lbsr	putStr
		bra	dlDone

dlAbort		leax	load_aborted_msg,pcr
		lbsr	putStr
		bra	dlEnd`

dlDone		leax	load_ok_msg,pcr
		lbsr	putStr

dlEnd		rts

loading_msg	fcn	"Waiting for data - press Ctrl-C to abort.",CR,LF
ihex_msg	fcn	"Detected intel hex - loading...",CR,LF
moto_msg	fcn	"Detected Motorola S-Records - loading...",CR,LF
bad_fmt_msg	fcn	"Badly formatted record - aborted",CR,LF
load_aborted_msg
		fcn	CR,LF,"Aborted.",CR,LF
load_ok_msg	fcn	CR,LF,"Loaded ok.",CR,LF


*******************************************************************
* loadiHexRecord - read a single record (the first character of the
*	record has already been read and checked)
*
* on entry: none
*
*  trashes: nothing
*
*  returns:
*	A: 0=Error, 1=OK, 2=End record read
*
loadiHexRecord	pshs	a,b
		lbsr	getHexByte
		sta	g.loadLength
		sta	g.loadXsum

		lbsr	getHexWord
		std	g.loadAddress
		adda	g.loadXsum
		sta	g.loadXsum
		addb	g.loadXsum
		stb	g.loadXsum

		lbsr	getHexByte
		sta	g.loadType
		adda	g.loadXsum
		sta	g.loadXsum

; we only need type 00 and 01 records - ignore anything else
		lda	g.loadType
		cmpa	#0	; data record
		beq	lihData
		cmpa	#1
		beq	lihEOF
		
; Record type not supported. Whine and then abort.
		leax	load_not_supported_msg,pcr
		lbsr	putStr
		bsr	gobbleRestOfLine
		lda	#1
		bra	lihEnd

lihData		ldx	g.loadAddress

		tfr	x,d
		lbsr	putHexWord
		lda	#CR
		lbsr	putChar

		ldb	g.loadLength
		beq	2F		; This would be unusual - a data record of 0 items

1		lbsr	getHexByte
		
		sta	,x+

		adda	g.loadXsum
		sta	g.loadXsum

		decb
		bne	1B

2		bsr	getLoadChecksum
		bne	lihBadXsum
		bsr	gobbleRestOfLine

		lda	#1		; All good
		bra	lihEnd

lihEOF		bsr	getLoadChecksum
		bne	lihBadXsum
		leax	load_ok_msg,pcr
		lbsr	putStr
		lda	#2		; End record found
		bra	lihEnd

lihBadEOF	leax	load_eof_err_msg,pcr
		lbsr	putStr
		bsr	gobbleRestOfLine
		clra			; Error
		bra	lihEnd

lihBadXsum	leax	load_xsum_err_msg,pcr
		lbsr	putStr
		
lihEnd		rts


gobbleRestOfLine lbsr	getChar
		cmpa	#CR
		bne	gobbleRestOfLine
		rts

getLoadChecksum	pshs	b
		lbsr	getHexByte
		tfr	a,b
		lda	g.loadXsum
		coma
		adda	#1
		sta	g.loadXsum
		cmpb	g.loadXsum
		puls	b,pc

load_eof_err_msg
		fcn	CR,LF,"Badly formatted End of File record.",CR,LF
load_xsum_err_msg
		fcn	CR,LF,"Calculated checksum does not match expected checksum.",CR,LF
load_not_supported_msg
		fcn	CR,LF,"Unsupported record type found. We only support types 0 and 1.",CR,LF



*******************************************************************
* loadMotoRecord - read a single record (the first character of the
*	record has already been read and checked)
*
* on entry: none
*
*  trashes: nothing
*
*  returns:
*	A: 0=Error, 1=OK, 2=End record read
*
loadMotoRecord	pshs	b,x,y

* Nrxt byte is record type
       	        lbsr     getChar

		cmpa    #'0'
		lblt     lmrBadChar
		cmpa    #'9'
		lbgt     lmrBadChar
		sta	g.loadType

* Next two bytes are count
       	        lbsr    getHexByte
		lbcs	lmrBadChar
		sta	g.loadLength
		sta	g.loadXsum		; Initialise checksum

* What comes next is record type specific

* ...Some records, we silently ignore
       		lda	g.loadType
		cmpa	#'0'
		lbeq	lmrIgnore
		cmpa	#'5'
		lbeq	lmrIgnore
		cmpa	#'9'
		beq	lmrNine
		cmpa	#'1'
		lbeq	lmrOne
		lbra	lmrNotSupported


* S9 record - sets start address and terminates
* next 4 bytes are the start address
lmrNine		lbsr	putNL
		lbsr	putNL

		lbsr	getHexWord
		lbcs	lmrBadChar
		std	g.loadAddress

		adda	g.loadXsum
		sta	g.loadXsum
		addb	g.loadXsum
		stb	g.loadXsum

* Next byte will be the checksum
       	    	lbsr    getHexByte
		lbcs	lmrBadChar
		tfr	a,b

		lda	g.loadXsum
		coma
		sta	g.loadXsum

		cmpb	g.loadXsum
		beq	lmrS9OK

		leax	lmr_bad_xsum_msg,pcr
		lbsr	putStr
		lbsr	skipLine
		lbra	lmrDone

lmrS9OK		leax	lmr_loaded_ok_msg,pcr
		lbsr	putStr

		ldd	g.loadAddress
		lbsr	putHexWord
		lbsr	putNL
		lda	#2		; End record success
		lbra	lmrDone		; S9 record is always the last one, so quit loading

* S1 record - next 4 bytes are the load address
lmrOne		
		lbsr	getHexWord
		lbcs	lmrBadChar
		std	g.loadAddress

		adda	g.loadXsum
		sta	g.loadXsum
		addb	g.loadXsum
		stb	g.loadXsum

		ldd	g.loadAddress
		lbsr	putHexWord
		lda	#CR
		lbsr	putChar

* prepare to read the data bytes		
		ldy	g.loadAddress
		ldb	g.loadLength
		clra
		subd	#3		; count included address and xsum
		tfr	d,x

* Read loop starts here
lmrS1Next	lbsr	getHexByte
		bcs	lmrBadChar

		tfr	a,b
		addb	g.loadXsum
		stb	g.loadXsum

		sta	,y+		; Deposit byte at correct address

		leax	-1,x		; Count--
		beq	lmrS1DataDone

		bra	lmrS1Next		


* Next byte will be the checksum
lmrS1DataDone  	lbsr    getHexByte
		bcs	lmrBadChar
		tfr	a,b

		lda	g.loadXsum
		coma
		sta	g.loadXsum

		cmpb	g.loadXsum
		beq	lmrS1OK

		leax	lmr_bad_xsum_msg,pcr
		lbsr	putStr
		lbsr	skipLine
		bra	lmrDone

lmrS1OK		lbsr	skipLine
		lda	#1		; Success
		bra	lmrDone


* User wants to quit
srQuit		lbsr	skipLine
		clra			; Error
		bra	lmrDone


* Ignore this record - it's harmless
lmrIgnore       lbsr    skipLine
		lda	#1		; Success
		bra	lmrDone


* We don't support all S records, in particular the ones that deal with
* a memory space bigger than 64K
lmrNotSupported	leax	lmr_record_not_supported,pcr
		lbsr	putStr
		lda	g.loadType
		lbsr	putChar
		lbsr	putNL
		lbsr	skipLine
		lda	#0		; Error
		bra	lmrDone

lmrBadChar	leax	lmr_bad_format_msg,pcr
		lbsr	putStr

lmrDone		puls	b,x,y,pc

	
	
lmr_bad_format_msg fcn	CR,LF,"Unexpected character while reading S record.",CR,LF
lmr_record_not_supported
		fcn	CR,LF,"Unsupported S record type: "
lmr_bad_xsum_msg 
		fcn	CR,LF,"Calculated checksum does not match transmitted checksum!",CR,LF
lmr_loaded_ok_msg 
		fcn	CR,LF,"Loaded OK. Start address: "
