* 6809 assembly program generated by cmoc 0.1.86


	SECTION	code


_divmod8	EXPORT


*******************************************************************************

* FUNCTION divmod8(): defined at divmod8.c:2
_divmod8	EQU	*
* Assembly-only function.
* Line divmod8.c:6: inline assembly
* Inline assembly:


DIV8 IMPORT
        lda 3,s ; dividend
        ldb 5,s ; divisor
        lbsr DIV8
        stb [6,s] ; quotient
        sta [8,s] ; remainer
    

* End of inline assembly.
* Useless label L00001 removed
	RTS
* END FUNCTION divmod8(): defined at divmod8.c:2
funcend_divmod8	EQU *
funcsize_divmod8	EQU	funcend_divmod8-_divmod8


	ENDSECTION




	SECTION	initgl




*******************************************************************************

* Initialize global variables.


	ENDSECTION




	SECTION	rodata


string_literals_start	EQU	*
string_literals_end	EQU	*


*******************************************************************************

* READ-ONLY GLOBAL VARIABLES


	ENDSECTION




	SECTION	rwdata


* Statically-initialized global variables
* Statically-initialized local static variables


	ENDSECTION




	SECTION	bss


bss_start	EQU	*
* Uninitialized global variables
* Uninitialized local static variables
bss_end	EQU	*


	ENDSECTION




*******************************************************************************

* Importing 0 utility routine(s).


*******************************************************************************

	END