;*----------------------------------------------------------------------------
;* Name:    Lab_2_program.s 
;* Purpose: This code template is for Lab 2
;* Author: JOSEPH CHOI, PAPA KOBINA
;*----------------------------------------------------------------------------*/
		THUMB 		; Declare THUMB instruction set 
                AREA 		My_code, CODE, READONLY 	; 
                EXPORT 		__MAIN 		; Label __MAIN is used externally q
		ENTRY 
__MAIN
; The following lines are similar to Lab-1 but use an address, in r4, to make it easier.
; Note that one still needs to use the offsets of 0x20 and 0x40 to access the ports
;
; Turn off all LEDs 
		MOV 		R2, #0xC000
		MOV 		R3, #0xB0000000	
		MOV 		R4, #0x0
		MOVT 		R4, #0x2009
		ADD 		R4, R4, R2 		; 0x2009C000 - the base address for dealing with the ports
		STR 		R3, [r4, #0x20]		; Turn off the three LEDs on port 1
		MOV 		R3, #0x0000007C
		STR 		R3, [R4, #0x40] 	; Turn off five LEDs on port 2 

; ---- only focus below this -------------------------------------------------------- 

; don't touch
; R5 -- used for word
; R0 -- used first for letter then delay countdown
; R1 -- used to store morse code

; using

ResetLUT
		LDR         R5, =InputLUT            ; assign R5 to the address at label LUT

; Start processing the characters, we are going to repeat the same word over and over again

NextChar
        LDRB        R0, [R5]		; Read a character to convert to Morse Code
        ADD         R5, #1              ; point to next value for number of delays, jump by 1 byte, setup for when we return to this branch
		TEQ         R0, #0              ; If we hit 0 (null at end of the string) then reset to the start of lookup table
		BNE			ProcessChar	; If we have a character process it

		; ProcessChar is not a subroutine, so this is an if else case
		; R0 above was for stored character, R0 below is for delay

		MOV			R0, #4		; delay 4 extra spaces (7 total) between words
		BL			DELAY
		BEQ         ResetLUT

ProcessChar	
		BL		CHAR2MORSE	; convert ASCII to Morse pattern in R1	; will return from CHAR2MORSE WITH ASCII VALUE IN R1

		MOV 	R1, R0			; give R1 the hex value of ascii

		CLZ		R6, R1			; now we have the ammount of leading zeros in r1 

		LSL 	R1, R1, R6

keepshifting

		LSLS	R1, R1, #1			; shift msb to Carry
		
		BCS 	on_led
		BCC		off_led
		
on_led
		BL		LED_ON
		B 		cont
off_led
		BL 		LED_OFF

cont
		; delay for 1 count
		MOV 	R0, #1
		BL 		DELAY

		CMP 	R1, #0
		BNE 	keepshifting

		MOV 	R0, #3 				; if done processing delay for a count of 3
		BL 		DELAY

		B 		NextChar			; find the next char to process




;*************************************************************************************************************************************************
;*****************  These are alternate methods to read the bits in the Morse code LUT. You can use them or not **********************************
;************************************************************************************************************************************************* 
;	Alternate Method #3
; All of the above methods do not use the shift operation properly.
; In the shift operation the bit which is being lost, or pushed off of the register,
; "falls" into the C flag - then one can BCC (Branch Carry Clear) or BCS (Branch Carry Set)
; This method works very well when coupled with an instruction which counts the number 
;  of leading zeros (CLZ) and a shift left operation to remove those leading zeros.

;*************************************************************************************************************************************************


; Subroutines
;
;			convert ASCII character to Morse pattern
;			pass ASCII character in R0, output in R1
;			index into MorseLuT must be by steps of 2 bytes

CHAR2MORSE	
		STMFD		R13!,{R14, R0}	; push Link Register (return address) on stack
		;		;

		SUB			R0, R0, #0x41			; shifted input to suitable index, register0 will hold the index

		MOV 		R2, #2				; storing 2 into register to double a value later

		MUL			R0, R0, R2 			; setting the step size to 2*index

		; fetching morse code using index
		LDR			R7, =MorseLUT
		
		LDRH		R0, [R7, R0]	; R1 holds the morse code value from table 

		LDMFD		R13!,{R15, R1}			; restore LR to R15 the Program Counter to return


; Turn the LED on, but deal with the stack in a simpler way
; NOTE: This method of returning from subroutine (BX  LR) does NOT work if subroutines are nested!!
;
LED_ON 	   	
		push 		{r3-r4}		; preserve R3 and R4 on the R13 stack
		
		MOV 		R3, #0xA0000000

		STR			R3, [R4, #0x20]

		pop 		{r3-r4}
		BX 			LR		; branch to the address in the Link Register.  Ie return to the caller

; Turn the LED off, but deal with the stack in the proper way
; the Link register gets pushed onto the stack so that subroutines can be nested
;
LED_OFF	   	
		STMFD		R13!,{R3, R14}	; push R3 and Link Register (return address) on stack
		
		MOV 		R3, #0xB0000000

		STR			R3, [R4, #0x20]

		LDMFD		R13!,{R3, R15}	; restore R3 and LR to R15 the Program Counter to return

;	Delay 500ms * R0 times
;	Use the delay loop from Lab-1 but loop R0 times around
;
;	one stack for subroutine but multiple branches within subroutine
;   no need for R0 to be on stack because only reading it

DELAY	
		STMFD		R13!,{R2,R14}
initialize		
		MOV			R2, #0x2C2B
		MOVT		R2, #0x000A
countdown
		SUBS 		R2, #1
		BNE 		countdown
MultipleDelay		
		SUB			R0, #1
		TEQ			R0, #0		; test R0 to see if it's 0 - set Zero flag so you can use BEQ, BNE
		BNE 		initialize
exitDelay		
		LDMFD		R13!,{R2, R15}

;
; Data used in the program
; DCB is Define Constant Byte size
; DCW is Define Constant Word (16-bit) size
; EQU is EQUate or assign a value.  This takes no memory but instead of typing the same address in many places one can just use an EQU
;
		ALIGN				; make sure things fall on word addresses

; One way to provide a data to convert to Morse code is to use a string in memory.
; Simply read bytes of the string until the NULL or "0" is hit.  This makes it very easy to loop until done.
;
InputLUT	
		DCB		"JCKAN", 0	; strings must be stored, and read, as BYTES

		ALIGN				; make sure things fall on word addresses
MorseLUT 
		DCW 	0x17, 0x1D5, 0x75D, 0x75 	; A, B, C, D
		DCW 	0x1, 0x15D, 0x1DD, 0x55 	; E, F, G, H
		DCW 	0x5, 0x1777, 0x1D7, 0x175 	; I, J, K, L
		DCW 	0x77, 0x1D, 0x777, 0x5DD 	; M, N, O, P
		DCW 	0x1DD7, 0x5D, 0x15, 0x7 	; Q, R, S, T
		DCW 	0x57, 0x157, 0x177, 0x757 	; U, V, W, X
		DCW 	0x1D77, 0x775 				; Y, Z

; One can also define an address using the EQUate directive
;
LED_PORT_ADR	EQU	0x2009c000	; Base address of the memory that controls I/O like LEDs

		END 