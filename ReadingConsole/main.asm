EXTERN ExitProcess : PROC
EXTERN GetStdHandle : PROC
EXTERN WriteConsoleA : PROC
EXTERN ReadConsoleA : PROC

.data
STD_INPUT_HANDLE DWORD -10
STD_OUTPUT_HANDLE DWORD -11
stdInput DWORD ?
stdOutput DWORD ?
howTall BYTE "How tall christmass tree should be?:",0
readToManyCharacters BYTE "Too many characters supplied!",0
detectedNonDigit BYTE "Non digit character detected!",0
printingTree BYTE "Printing tree with size: ",0

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
	ADD RAX, R8

	; increase address of the letter
	INC RCX 

	; if number of words is positive then loop around
	CMP R9D, 0
	JG parseLoop

epilog:
	ADD RSP, 28h
	RET

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
	RET
WriteConsoleNullTerminated ENDP
END