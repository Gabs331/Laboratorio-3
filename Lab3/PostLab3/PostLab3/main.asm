;
;Post Laboratorio3.asm
;
; Author : Gabriela
;; ***************************************************************************************
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Prelab3.asm

; Autor: Paola Gabriela Yoc Moreira
; Proyecto:Postlab 3
; Hardware: ATMega328P
; Creado: 17/02/2025
; Descripción: 
; ********************************************************************************************

; MCU: ATmega328P
; Botón PC0 -> Incrementar
; Botón PC1 -> Decrementar
; Salida en PORTB (PB0-PB3) 
;************************************************************************************+
;ENCABEZADO
;************************************************************************************
.include "M328PDEF.inc"

.cseg
.def contador1 = R20
.def display1 = R22
.def display2 = R23
.org 0x0000
    rjmp SETUP            ; Salto a la configuración
.org PCI1addr
    rjmp ISR_PCINT        ; Vector de interrupción para PCINT8 y PCINT9
.org 0x0020
	rjmp ISR_TIMER0_OVER

;**************************************************
; CONFIGURACIÓN INICIAL
;**************************************************
MT: .DB 0x03F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

SETUP:
    ; Configuración de la pila
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
	LDI R22, 0x00
	STS UCSR0B, R22         ; Deshabilita completamente USART

	; ******************************************************************************
    ; Configuración de puertos
	; ******************************************************************************
    LDI R16, 0x0C
    OUT DDRC, R16        ; PC0 y PC1 como entrada, PC2 y PC3 como salida
    LDI R16, 0x03
    OUT PORTC, R16       ; Activar pull-ups en PC0 y PC1
	CBI PORTC, PC3
	CBI PORTC, PC2

    LDI R16, 0x0F
    OUT DDRB, R16        ; PB0-PB3 como salida
    LDI R17, 0x00        ; Inicializar contador en 0
    OUT PORTB, R17       ; Mostrar en LEDs

	LDI R16, 0xFF
    OUT DDRD, R16          ; Configurar PORTD como salida (contador)

	LDI R24, 0
	LDI R25, 0
	LDI display1, 0
	LDI display2, 0
	LDI R26, 9
	LDI R27, 5
	LDI ZL, LOW(MT<<1)
	LDI ZH, HIGH(MT<<1)
	ADD ZL, R24
	LPM R24, Z


	CALL INIT_TMR0           ; Inicializar Timer0   
	SEI 

	ldi contador1, 0
	; ******************************************************************************
    ; Configuración de interrupcion 
	; ******************************************************************************
    LDI R16, (1<<PCIE1)  ; Habilitar interrupciones en PCINT[14:8]
    STS PCICR, R16
    LDI R16, (1<<PCINT8) | (1<<PCINT9) ; Habilitar interrupciones para PCINT8 y PCINT9
    STS PCMSK1, R16
    SEI                   ; Habilitar interrupciones globales
	; ******************************************************************************
	;LOOP INFINITO
	; ******************************************************************************
MAIN_LOOP:

	CALL DISPLAY_SEG
	CALL DISPLAY_MIN

	CPI contador1, 100    ;para que sea cada segundo
	BRNE MAIN_LOOP
	CLR contador1

	CPSE display1, R26
	CALL AUMENTAR1
	LDI display1, 0
	CPSE display2, R27
	CALL AUMENTAR2
	LDI display2, 0

	RJMP MAIN_LOOP

	; ******************************************************************************
	; DISPLAY SEGUNDOS 
	; ******************************************************************************
DISPLAY_SEG:
	CBI PORTC, PC3
	MOV R24, display1
	LDI ZL, LOW(MT<<1)
	LDI ZH, HIGh(MT<<1)
	ADD ZL, R24
	LPM R24, Z

	CBI PORTC, PC3

	OUT PORTD, R24
	CBI PORTC, PC3
	SBI PORTC, PC2

	RET

	; ******************************************************************************
	; DISPLAY MINUTOS 
	; ******************************************************************************
DISPLAY_MIN:
	CBI PORTC, PC2
	MOV R25, display2
	LDI ZL, LOW(MT<<1)
	LDI ZH, HIGh(MT<<1)
	ADD ZL, R25
	LPM R25, Z

	CBI PORTC, PC2

	OUT PORTD, R25
	CBI PORTC, PC2
	SBI PORTC, PC3

	RET

	; ******************************************************************************
	;  AUMENTAR DISPLAY SEGUNDOS 
	; ******************************************************************************
AUMENTAR1:
	INC display1
	RJMP MAIN_LOOP

	; ******************************************************************************
	;  AUMENTAR DISPLAY MINUTOS 
	; ******************************************************************************
AUMENTAR2:
	INC display2
	RJMP MAIN_LOOP

	; ******************************************************************************
	; TIMER 0 OVERFLOW
	; ******************************************************************************
ISR_TIMER0_OVER:
	PUSH R16              ; Guardar registros
    IN R16, SREG
    PUSH R16			  ; Guardar SREG en pila	

	LDI R16, 99			  ; cargar valor de desbordamiento 
	OUT TCNT0, R16		  ; cargar valor in
	SBI TIFR0, TOV0		  ; borrar bandera TOV0
	INC contador1		  ; incrementar contador 10ms

	POP R16
	OUT SREG, R16
	POP R16
	RETI
	; ******************************************************************************
	; TIMER0
	; ******************************************************************************

INIT_TMR0:
    LDI R21, (1<<CS02) | (1<<CS00) ; Prescaler de 64
    OUT TCCR0B, R21
    LDI R21, 99                  ; Cargar valor inicial en TCNT0
    OUT TCNT0, R21
	LDI R21, (1 << TOIE0)
	STS TIMSK0, R16
    RET

;**************************************************
; RUTINA DE INTERRUPCIÓN (PCINT8 y PCINT9)
;**************************************************
ISR_PCINT:
    PUSH R16              ; Guardar registros
    IN R16, SREG
    PUSH R16
    IN R16, PINC          ; Leer estado de los botones

    ; Deshabilitar interrupciones momentáneamente para evitar rebote
    ; Verificar si el pin PC0 (incremento) está presionado
    SBIS PINC, 0          ; Si PC0 está presionado (flanco bajo)
    RJMP INCREMENTO       ; Saltar a INCREMENTO

    ; Verificar si el pin PC1 (decremento) está presionado
    SBIS PINC, 1          ; Si PC1 está presionado (flanco bajo)
    RJMP DECREMENTO       ; Saltar a DECREMENTO

ISR_END:
    NOP                   ; Añadir una pequeña espera
    POP R16               ; Restaurar registros
    OUT SREG, R16
    POP R16
    RETI                  ; Retorno de la interrupción

INCREMENTO:
    ; Añadir un pequeño ciclo de espera para evitar rebotes (debouncing)
    LDI R18, 100          ; Establecer el número de ciclos de espera
DEBOUNCE_INC:
    NOP                   ; No hace nada, solo espera
    DEC R18               ; Decrementar el contador
    BRNE DEBOUNCE_INC     ; Si no ha llegado a cero, sigue esperando

    ; Verificar que el botón sigue presionado antes de incrementar
    SBIS PINC, 0          ; Verificar si el pin sigue bajo (botón sigue presionado)
    RJMP INCREMENTO       ; Si no es presionado, no hacer nada y esperar

    ; Asegurarse que el contador se incremente solo una vez
    INC R17               ; Incrementar contador
    CPI R17, 15           ; Si llega a 16, reiniciar a 0
    BRGE RESET_INC
    OUT PORTB, R17        ; Mostrar el contador incrementado
    RJMP ISR_END          ; Terminar rutina de interrupción

RESET_INC:
    LDI R17, 0x00         ; Reiniciar contador a 0
    OUT PORTB, R17        ; Mostrar el contador reiniciado
    RJMP ISR_END

DECREMENTO:
    ; Añadir un pequeño ciclo de espera para evitar rebotes (debouncing)
    LDI R18, 100          ; Establecer el número de ciclos de espera
DEBOUNCE_DEC:
    NOP                   ; No hace nada, solo espera
    DEC R18               ; Decrementar el contador
    BRNE DEBOUNCE_DEC     ; Si no ha llegado a cero, sigue esperando

    ; Verificar que el botón sigue presionado antes de decrementar
    SBIS PINC, 1          ; Verificar si el pin sigue bajo (botón sigue presionado)
    RJMP DECREMENTO       ; Si no es presionado, no hacer nada y esperar

    ; Asegurarse que el contador se decremente solo una vez
    DEC R17               ; Decrementar contador
    CPI R17, 0            ; Si es 0, reiniciar a 0x0F
    BRMI RESET_D          ; Si es menor que 0 (ya ha pasado a negativo), reiniciar
    OUT PORTB, R17        ; Mostrar el contador decrementado
    RJMP ISR_END          ; Terminar rutina de interrupción
RESET_D:
    LDI R17, 0x0F         ; Reiniciar contador a 0x0F
    OUT PORTB, R17        ; Mostrar el contador reiniciado
    RJMP ISR_END
	