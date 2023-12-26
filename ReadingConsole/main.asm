EXTERN ExitProcess : PROC
EXTERN GetStdHandle : PROC
EXTERN WriteConsoleA : PROC
EXTERN ReadConsoleA : PROC
EXTERN GetConsoleScreenBufferInfo : PROC

.data
STD_INPUT_HANDLE DWORD -10
STD_OUTPUT_HANDLE DWORD -11
stdInput DWORD ?
stdOutput DWORD ?
howTall BYTE "How tall christmass tree should be?:",0
readToManyCharacters BYTE "Too many characters supplied!",0
detectedNonDigit BYTE "Non digit character detected!",0
zeroHeightText BYTE "Can't print tree with height 0",0
heightTooBigText BYTE "Height of the tree is to big to print it in the current console!",0
int64ExceededText BYTE "Number overflow!",0
printingTree BYTE "Printing tree:",13,10,0

.code

main PROC
	
	SUB RSP, 28h ; 4 bytes homing + 1 argument

	; get handle to output
	MOV ECX, STD_OUTPUT_HANDLE ; specify device
	CALL GetStdHandle ; get STD_OUTPUT into RAX
	MOV stdOutput, EAX

	; get handle to input
	MOV ECX, STD_INPUT_HANDLE
	CALL GetStdHandle ; get STD INPUT HANDLE
	MOV stdInput, EAX

	; write prompt
	LEA RCX, howTall
	CALL WriteConsoleNullTerminated

	; read input
	MOV ECX, stdInput ; firs arugment is input handle
	LEA RDX, [RSP+38h] ; use homing area as read buffer
	MOV R8, 18h ; read 24 chars max (24 bytes)
	LEA R9, [RSP+34h] ; use half of first homing area argument for DWORD
	XOR RAX, RAX
	MOV [RSP+20h], RAX ; fifth argument to null
	CALL ReadConsoleA ;

	; check length of input
	MOV ECX, [RSP+34h] ; get number of read characters
	CMP ECX, 18h
	JGE toManyCharsRead

	; parse number
	LEA RCX, [RSP+38h]
	MOV EDX, [RSP+34h]
	CALL ParseNumber

	; print tree
	MOV RCX, RAX
	CALL PrintTree

	; set return code and exit
	XOR RCX, RCX 
	CALL ExitProcess

toManyCharsRead:
	; write prompt
	LEA RCX, readToManyCharacters
	CALL WriteConsoleNullTerminated

	; set return code and exit
	MOV RCX, 1 
	CALL ExitProcess

main ENDP

; CORD (4 bytes)
; SHORT X +0 (2 bytes)
; SHORT Y +2 (2 bytes)

; SMALL_RECT (8 bytes)
; SHORT Left +0 (2 bytes)
; SHORT Top +2 (2 bytes)
; SHORT Right +4 (2 bytes)
; SHORT Bottom +6 (2 bytes)

; _CONSOLE_SCREEN_BUFFER_INFO (22 bytes)
; CORD dwSize +0 (4 bytes)
; CORD dwCursorPosition +4 (4 bytes)
; WORD wAttributes +8 (2 byte)
; SMALL_RECT srWindow +10 (8 bytes)
; CORD dwMaximumWindowSize +18 (4 bytes)

;Prints christmass tree into console
;First argument is the height
PrintTree PROC
	MOV [RSP+8h], R12 ; save R12 in homing
	MOV [RSP+10h], R13 ; save R13 in homing
	MOV [RSP+18h], R14 ; save R14 in homing
	SUB RSP, 38h ; homing + 18h (24 bytes) for _CONSOLE_SCREEN_BUFFER_INFO and align

	CMP RCX, 0
	JE zeroHeight

	; save print height in non volatile register
	MOV R12, RCX

	; get console info pointer
	MOV ECX, stdOutput
	LEA RDX, [RSP+20h] ; store it right after homing
	CALL GetConsoleScreenBufferInfo

	; calculate required width
	MOV RAX, R12
	MOV RCX, 2
	MUL RCX
	JC heightTooBig
	SUB RAX, 1

	;check if width is enough
	XOR RCX, RCX 
	MOV CX, [RSP+20h] ; load width of console to CX
	CMP RCX, RAX
	JL heightTooBig
	
	;save length of buffer to R13
	ADD RAX, 3 ; CL RF \0
	MOV R13, RAX

	LEA RCX, printingTree
	CALL WriteConsoleNullTerminated

	;crete space for buffer on stack
	SUB RSP, R13

	; RAX current addres, RCX target address
	LEA RAX, [RSP + 20h]
	LEA RCX, [RSP + R13 + 20h]

	;set all buffer to zero
zeroOut:
	MOV BYTE PTR [RAX], 20h ; space
	INC RAX
	CMP RAX, RCX
	JL zeroOut

	;set CR LR \0
	MOV BYTE PTR [RCX - 1h], 0 ; \0
	MOV BYTE PTR [RCX - 2h], 13 ; CR
	MOV BYTE PTR [RCX - 3h], 10 ; LR

	; R14 iteration
	MOV R14, 0
printLoop:
	LEA RAX, [RSP + 20h + R12 - 1] ; calculate center
	MOV BYTE PTR [RAX + R14], 2Ah ; *
	SUB RAX, R14
	MOV BYTE PTR [RAX], 2Ah ; *

	LEA RCX, [RSP + 20h]
	CALL WriteConsoleNullTerminated

	INC R14
	CMP R14, R12
	JL printLoop

	ADD RSP, R13

	;epilog
	ADD RSP, 38h
	MOV R12, [RSP+8h] ; restore R12 in homing
	MOV R13, [RSP+10h] ; restore R13 in homing
	MOV R14, [RSP+18h] ; restore R14 in homing
	RET

heightTooBig:
	; print error
	LEA RCX, heightTooBigText
	CALL WriteConsoleNullTerminated

	; set return code and exit
	MOV RCX, 1 
	CALL ExitProcess

zeroHeight:
	; print error
	LEA RCX, zeroHeightText
	CALL WriteConsoleNullTerminated

	; set return code and exit
	MOV RCX, 1 
	CALL ExitProcess
PrintTree ENDP

; Parses number from the string
; First argument is pointer to the data buffer
; Second argument is number of the characters DWORD
; Return value is number
ParseNumber PROC
	MOV [RSP+8h], RCX ; home RCX
	MOV [RSP+10h], EDX ; home RDX
	SUB RSP, 28h ; homing and align

	XOR RAX, RAX ; zero out result
	MOV R10, 10 ; used for multiplication

	MOV R9D, EDX 

parseLoop:
	DEC R9D ; decrease number of left characters

	XOR R8, R8
	MOV R8B, [RCX];
	SUB R8, 48 ; get numeric value of char

	; if negative then it was not a number
	JS nonLiteral
	
	; if larger than 9 than it was not a number
	CMP R8, 9
	JG nonLiteral	

	; add digit to number
	MUL R10
	JC int64Exceeded
	ADD RAX, R8

	; increase address of the letter
	INC RCX 

	; if number of words is positive then loop around
	CMP R9D, 0
	JG parseLoop

epilog:
	ADD RSP, 28h
	RET

int64Exceeded:
	; print error
	LEA RCX, int64ExceededText
	CALL WriteConsoleNullTerminated

	; set return code and exit
	MOV RCX, 1 
	CALL ExitProcess

nonLiteral:
	CMP R8, -35 ; 13 (CR) - 48
	JE epilog ; allowed ending

	; print error
	LEA RCX, detectedNonDigit
	CALL WriteConsoleNullTerminated

	; set return code and exit
	MOV RCX, 1 
	CALL ExitProcess

ParseNumber ENDP

; Writes null terminated string to console
; first argument is pointer to the text
WriteConsoleNullTerminated PROC
	MOV [RSP+8h], RCX ; home RCX
	MOV [RSP+10h], R12 ; save R12
	MOV [RSP+18h], R13 ; save R13
	SUB RSP, 28h ; 4 bytes homing + align

	MOV R12, RCX ; move text pointer to non volatile register

	; get length of string
checkNullTermination:
	MOV AL, [RCX] ; load value at adrress
	CMP AL, 0 ; compare only 1 byte !
	JE nullTerminationFound
	INC RCX
	JMP checkNullTermination

nullTerminationFound:
	SUB RCX, R12 ; get length
	MOV R13, RCX ; move to non volatile register

	;print value
	MOV ECX, stdOutput ; set handle
	MOV RDX, R12 ; set pointer to text
	MOV R8, R13 ; set length of text
	MOV R9, 0 ; set address to DWORD to 0. We do not want to know written character count
	MOV [RSP+20h], R9 ; fifth argument has to be null
	CALL WriteConsoleA

	ADD RSP, 28h
	MOV R12, [RSP+10h] ; restore R12
	MOV R13, [RSP+18h] ; restore R13
	RET
WriteConsoleNullTerminated ENDP
END