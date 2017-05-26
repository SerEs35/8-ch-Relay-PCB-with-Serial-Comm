;--------------------------------------------------------------------------
;Author:  Sergio E.
;Name:	  Firmware for the 8-relay controller PCB
;Date:	  January, 2009
;Comment:	One-way transmission from Serial Port to Ucontroller.
;--------------------------------------------------------------------------	
	list      p=16F84A            ; list directive to define processor
	#include <p16F84A.inc>        ; processor specific variable definitions    
    
_PWRTE_ON	EQU		H'3FF7'
_XT_OSC		EQU     H'3FFD'
_WDT_OFF	EQU     H'3FFB'
_CP_OFF		EQU     H'3FFF'
;--------------------------------------------------------------------------

tmr0	equ	0x01	; Timer/counter
status	equ	0x03	; Status word reg
portA	equ	0x05	; Port A reg
portB	equ	0x06	; Port B reg
intCon	equ	0x0b	; Interrupt control reg
rcvReg	equ	0x0c	; General purpose reg
count	equ	0x0d	; General purpose reg
temp	equ	0x0e	; General purpose reg
optReg	equ	0x81	; File reg en Bank 1
trisA	equ	0x85	; File reg en Bank 1 
trisB	equ	0x86	; File reg en Bank 1 
;--------------------------------------------------------------------------

rp0	equ	5
;---------------------Start of Program-------------------------------------
	org	0x000

start	clrf	status		; Clear Status				
	bsf 	status, rp0		; To Bank 1 
	movlw	0x01			; A0 input
	movwf	trisA

	movlw	0x00			; Port B: all output
	movwf	trisB

	bcf		status, rp0		; Back to Bank 0
	clrf	portB
	clrf	rcvReg


;-------------------------------------------------------------------------	
doThis	call	rcv4800		; Yes, to serial in subroutine
	movf	rcvReg,  w		; Get byte received
	movwf	portB			; Display byte on the 8 LEDs
	
circle	goto	doThis		; Done
;--------------------------------------------------------------------------


rcv4800	bcf		intCon, 5	; Disable tmr0 interrupts
	bcf		intCon,	7		; Disable global interrupts
	clrf	tmr0			; Clear timer/counter
	;clrwdt					; Clear wdt prep prescaler assign

	bsf		status, rp0		; to Bank 1	
	;movlw	b'11011000'		; set up timer/counter
	movlw	b'11010000'		; set up timer/counter   1 instruccion cada 2 pulsos de cristal

	movwf	optReg
	bcf		status, rp0		; Back to Bank 1
	movlw	0x08			; Init shift counter
	movwf	count

;----------------------------------------------------------------------------
sbit	
	btfsc	portA, 0		; Look for start bit
	goto 	sbit			; For Mark

;---NOTA: F9 = 249 (0 a 255) . Para busqueda de fallas en synch, iterar manualmente.
;---Ver la duracion de cada instruccion, tomando en cuenta la configuracion del tiempo.

	movlw	0xEB			
	movwf	tmr0			; Load and start timer/counter
	bcf		intCon, 2		; Clear tmr0 overflow flag
	nop

time1	btfss	intCon, 2	; Has the timer (bit 2) overflowed?  Skip next line if 1
	goto	time1			; No

	btfsc	portA, 0		; Start bit still low?
	goto 	sbit			; False start, go back

	movlw	0xD2			; real, define N for timer    
	movwf	tmr0			; start timer/counter - bit time
	bcf		intCon, 2		; Clear tmr0 overflow flag
	nop

time2	btfss	intCon, 2	; Timer overflow?
	goto	time2			; No

	movf	portA, w		; Read port A
	movwf	temp			; Store
	rrf		temp, f			; Rotate bit 0 into carry flag
	rrf		rcvReg, f		; Rotate carry into rcvReg bit 7
	nop
	nop
	movlw	0xD2			; Yes, define N for timer
	movwf	tmr0			; Start timer/counter
	bcf		intCon, 2 		; Clear tmr0 overflow flag
	
	decfsz	count, f		; Shifted 8 bits from serial port?
	goto	time2			; No
	
time3	btfss	intCon, 2	; Timer overflow?
	goto	time3			; No
	return					; Yes, byte received
;-----------------------------------------------------------------------
  	end
;-----------------------------------------------------------------------
; At blast time, select:
; 	memory unprotected
; 	watchdog timer disabled
;	standard crystal (4 MHz)
; 	power-up timer on
;=======================================================================
