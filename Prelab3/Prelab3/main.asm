;
; Prelab3.asm
;
; Created: 17/02/2025 
; Author : Gabriela
; ***************************************************************************************
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Prelab3.asm

; Autor: Paola Gabriela Yoc Moreira
; Proyecto: Prelab 3
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
.org 0x0000
    rjmp SETUP            ; Salto a la configuración
.org PCI1addr
    rjmp ISR_PCINT        ; Vector de interrupción para PCINT8 y PCINT9

;**************************************************
; CONFIGURACIÓN INICIAL
;**************************************************
SETUP:
    ; Configuración de la pila
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16

    ; Configuración de puertos
    LDI R16, 0x00
    OUT DDRC, R16        ; PC0 y PC1 como entrada
    LDI R16, 0x03
    OUT PORTC, R16       ; Activar pull-ups en PC0 y PC1

    LDI R16, 0x0F
    OUT DDRB, R16        ; PB0-PB3 como salida
    LDI R17, 0x00        ; Inicializar contador en 0
    OUT PORTB, R17       ; Mostrar en LEDs

    ; Configuración de interrupciones
    LDI R16, (1<<PCIE1)  ; Habilitar interrupciones en PCINT[14:8]
    STS PCICR, R16
    LDI R16, (1<<PCINT8) | (1<<PCINT9) ; Habilitar interrupciones para PCINT8 y PCINT9
    STS PCMSK1, R16
    SEI                   ; Habilitar interrupciones globales

MAIN_LOOP:
    RJMP MAIN_LOOP        ; Bucle infinito

;**************************************************
; RUTINA DE INTERRUPCIÓN (PCINT8 y PCINT9)
;**************************************************
ISR_PCINT:
    PUSH R16              ; Guardar registros
    IN R16, SREG
    PUSH R16
    IN R16, PINC          ; Leer estado de los botones

    ; Deshabilitar interrupciones momentáneamente para evitar rebotes
    CLI                   ; Deshabilitar interrupciones globales

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
    SEI                   ; Habilitar interrupciones
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
