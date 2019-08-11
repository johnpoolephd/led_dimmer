;**********************************************************************
;                                                                     *
;    Filename:	    led_dimmer.asm                                    *
;    Date:	    11/08/2019                                        *
;    File Version:                                                    *
;                                                                     *
;    Author:        John Poole                                        *
;    Company:                                                         *
;                                                                     * 
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files Required: P16F690.INC                                      *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:	    Dim a LED using a single turn potentiometer       *
;                                                                     *
;**********************************************************************


	list		p=16f690		; list directive to define processor
	#include	<p16f690.inc>		; processor specific variable definitions
	
	__CONFIG    _CP_OFF & _CPD_OFF & _BOR_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _FCMEN_OFF & _IESO_OFF


; '__CONFIG' directive is used to embed configuration data within .asm file.
; The labels following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.


;***** VARIABLE DEFINITIONS
w_temp		EQU	0x7D			; variable used for context saving
status_temp	EQU	0x7E			; variable used for context saving
pclath_temp	EQU	0x7F			; variable used for context saving


	;**********************************************************************
	ORG		0x000			; processor reset vector
  	goto		main			; go to beginning of program


	ORG		0x004			; interrupt vector location
	movwf		w_temp			; save off current W register contents
	movf		STATUS,w		; move status register into W register
	movwf		status_temp		; save off contents of STATUS register
	movf		PCLATH,w		; move pclath register into W register
	movwf		pclath_temp		; save off contents of PCLATH register


; isr code can go here or be located as a call subroutine elsewhere

	movf		pclath_temp,w		; retrieve copy of PCLATH register
	movwf		PCLATH			; restore pre-isr PCLATH register contents	
	movf		status_temp,w		; retrieve copy of STATUS register
	movwf		STATUS			; restore pre-isr STATUS register contents
	swapf		w_temp,f
	swapf		w_temp,w		; restore pre-isr W register contents
	retfie					; return from interrupt
;**********************************************************************
; hardware configuration
;	yellow LED connected to RC6(8) with 330 Ohm resistor to Vss
;	single turn 10K potentiometer between Vdd and Vss with wiper to AN9(9) 
;**********************************************************************
	
wait_acq_time
;**********************************************************************
; wait for ADC input capacitor to charge before conversion
;   input:	none
;   output:	none
;   variable:	
;   assume:	
	
;**********************************************************************

		
main
;**********************************************************************
; program execution starts here
;**********************************************************************	

init
; configure LED output 
	bcf		STATUS, RP0		; select memory bank 2
	bsf		STATUS, RP1
	bcf		ANSELH, 0		; make RC6 digital 
	bsf		STATUS, RP0		; select memory bank 1
	bcf		STATUS, RP1		
	bcf		TRISC, 6		; make RC6 output for LED
	
	bcf		STATUS, RP0		; select memory bank 0

;	bsf		PORTC, 6		; TEST; turn on LED
;	goto		$

; setup ADC module 
						; configure pins as analog input
	bsf		STATUS, RP0		; select memory bank 1
	bcf		STATUS, RP1		;
	bsf		TRISC, 7		; disable output driver on RC7
	bsf		STATUS, RP1		; select memory bank 3
	bsf		ANSELH, 1		; make AN9 analog input
	
						; configure ADC module
	bcf		STATUS, RP0		; select memory bank 0
	bcf		STATUS, RP1	    
	movlw		0b00100001		; result left justified
						; Vref = Vdd
						; select channel AN9
						; enable ADC module
	movwf		ADCON0	
	bsf		STATUS, RP1		; select memory bank 1
	movlw		0b01100000		; set Fosc/64
	movwf		ADCON1			 
	
loop
	call		wait_acq_time		; wait ADC aquisition time 
	
	bcf		STATUS, RP0		; select memory bank 0
	bcf		STATUS, RP1		;
	bsf		ADCON0, 1		; start conversion (set GO bit)
	btfsc		ADCON0, 1		; poll for DONE
	goto		$-1

	bcf		STATUS, RP0		; select memory bank 0
	bcf		STATUS, RP1		;
	movf		ADRESH, W		; get top 8 bits of ADC result
	
	goto		loop
	

;	ORG	0x2100				; data EEPROM location
;	DE	1,2,3,4				; define first four EEPROM locations as 1, 2, 3, and 4




	END                       ; directive 'end of program'

