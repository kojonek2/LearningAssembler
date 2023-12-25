EXTERN ExitProcess : PROC
EXTERN GetStdHandle : PROC
EXTERN WriteConsoleA : PROC

.data
STD_OUTPUT_HANDLE DWORD -11
helloWorld BYTE "Hello World!",0

.code

main PROC
	
	SUB RSP, 28h ; 4 bytes homing + align

	LEA RCX, helloWorld
	CALL WriteConsoleNullTerminated

	XOR RCX, RCX ; set return code and exit
	CALL ExitProcess

	ADD RSP, 28h ;
	RET
main ENDP

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

	; get handle to output
	MOV ECX, STD_OUTPUT_HANDLE ; specify device
	CALL GetStdHandle ; get STD_OUTPUT into RAX

	;print value
	MOV RCX, RAX ; set handle
	MOV RDX, R12 ; set pointer to text
	MOV R8, R13 ; set length of text
	MOV R9, 0 ; set address to DWORD to 0. We do not want to know written character count
	MOV [RSP+20h], R9 ; fifth argument has to be null
	CALL WriteConsoleA

	ADD RSP, 28h
	RET
WriteConsoleNullTerminated ENDP
END