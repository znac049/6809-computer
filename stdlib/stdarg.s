* 6809 assembly program generated by cmoc 0.1.86


	SECTION	code


___va_arg	EXPORT


*******************************************************************************

* FUNCTION __va_arg(): defined at stdarg.c:10
___va_arg	EQU	*
* Assembly-only function.
* Line stdarg.c:20: inline assembly
* Inline assembly:


        ldx [2,s] ; 2,s is 'app', so get *app in X
        ldd 4,s ; sizeInBytes
        cmpd #1
        bne @notSingleByte
        leax 1,x ; ++origAddr
@notSingleByte
        pshs x ; app is now at 4,s
        leax d,x
        stx [4,s] ; store in *app
        puls a,b ; return origAddr in D
    

* End of inline assembly.
* Useless label L00002 removed
	RTS
* END FUNCTION __va_arg(): defined at stdarg.c:10
funcend___va_arg	EQU *
funcsize___va_arg	EQU	funcend___va_arg-___va_arg


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
