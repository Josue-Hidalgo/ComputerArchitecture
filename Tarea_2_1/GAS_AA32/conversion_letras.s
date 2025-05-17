@ Curso: Arquitectura de Computadores
@ Nombre: Allan José Jimenez Rivera y Josué Santiago Hidalgo Sandoval

.section .data
    mensaje:       .asciz "Escriba una oración (maximo 100 caracteres):\n"
    mensajeError:  .asciz "Error: la oracion contiene caracteres invalidos\n"


.section .bss       
    oracion: 
        .space 100        
    longitud:
        .space 1          


.section .text
.global _start


_start:
    @ Llamadas a procedimientos
    bl _printMensaje   
    bl _getOracion     
    bl _procesarLetras 
    bl _printResultado 

    mov r7, #1         @ Syscall para `exit` en ARM
    mov r0, #0         @ Código de salida 0
    swi 0              @ Invocar syscall


_printMensaje:
    mov r7, #4          @ Syscall write (4) en ARM
    mov r0, #1          @ File descriptor 1 (stdout)
    ldr r1, =mensaje    @ Dirección del mensaje en r1
    mov r2, #47         @ Longitud del mensaje
    swi 0               @ Llamada al sistema (syscall)
    bx lr               @ Retorno de la función


_getOracion:
    mov r7, #3            @ Syscall read (3)
    mov r0, #0            @ File descriptor 0 (stdin)
    ldr r1, =oracion      @ Cargar la dirección del buffer
    mov r2, #100          @ Leer hasta 100 bytes
    swi 0                 @ Llamada al sistema

    ldr r3, =longitud
    strb r0, [r3]         @ Almacena el número de bytes leídos en `longitud`
    bx lr                 @ Retorno de la función


_procesarLetras:
    mov r4, #0          @ Inicializa el contador en 0
    ldr r5, =longitud
    ldrb r5, [r5]       @ Carga la longitud del mensaje en r5
    b _for              @ Salta al bucle

    bx lr               @ Retorno de la función


_for:
    cmp r4, r5               @ Comparar índice con la longitud
    bge _fin                 @ Si r4 >= r5, termina el bucle

    ldrb r6, [r1, r4]        @ Cargar el carácter actual desde la cadena

    cmp r6, #'A'             @ Comparar con 'A'
    blt _verificarInvalido   @ Si es menor, verificar si es inválido

    cmp r6, #'Z'             @ Comparar con 'Z'
    bgt _convertirAMayuscula @ Si es mayor que 'Z', convertir a mayúscula

    b _convertirAMinuscula   @ Si está entre 'A' y 'Z', convertir a minúscula


_convertirAMinuscula:
    add r6, r6, #32          @ Convertir a minúscula (suma 32)
    strb r6, [r1, r4]        @ Guardar el carácter modificado
    b _siguiente             @ Pasar al siguiente carácter


_convertirAMayuscula:
    cmp r6, #'a'             @ Comparar con 'a'
    blt _siguiente           @ Si es menor, saltar (ya es mayúscula o inválido)

    cmp r6, #'z'             @ Comparar con 'z'
    bgt _verificarInvalido   @ Si es mayor, es inválido

    sub r6, r6, #32          @ Convertir a mayúscula (restar 32)
    strb r6, [r1, r4]        @ Guardar el carácter modificado
    b _siguiente             @ Pasar al siguiente carácter


_verificarInvalido:
    cmp r6, #' '        @ Comparar con espacio
    beq _siguiente      @ Si es espacio, es válido, saltar

    cmp r6, #10         @ Comparar con Enter (ASCII 10)
    beq _siguiente      @ Si es Enter, es válido, saltar

    bl _printError      @ Llamar a la función de error

    mov r7, #1         @ Syscall exit (1)
    mov r0, #1         @ Código de salida 1 (error)
    swi 0              @ Llamada al sistema para salir


_siguiente:
    add r4, r4, #1     @ Incrementa el contador (equivalente a inc rcx)
    b _for             @ Salta de vuelta al bucle _for


_fin:
    bx lr   @ Retorna al llamador


_printError:
    mov r7, #4             @ Syscall write (4)
    mov r0, #1             @ File descriptor 1 (stdout)
    ldr r1, =mensajeError  @ Cargar dirección del mensaje de error
    mov r2, #48            @ Longitud del mensaje (48 bytes)
    swi 0                  @ Llamada al sistema

    bx lr               @ Retorno de la función


_printResultado:    
    mov r7, #4           @ Syscall write (4)
    mov r0, #1           @ File descriptor 1 (stdout)
    ldr r1, =oracion     @ Cargar la dirección de la cadena en r1
    ldr r3, =longitud    
    ldrb r2, [r3]        @ Cargar la longitud de la cadena en r2
    swi 0                @ Llamada al sistema

    bx lr                