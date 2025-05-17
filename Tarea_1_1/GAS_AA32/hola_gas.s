.global _start

.section .data
mensaje:
    .asciz "Hola Mundo\n"

.section .text
_start:
    // Escribir el mensaje en la salida estándar
    mov r0, #1              // Descriptor de archivo (1 = stdout)
    ldr r1, =mensaje        // Dirección del mensaje
    mov r2, #13             // Longitud del mensaje (incluyendo el salto de línea)
    mov r7, #4              // Número de la llamada al sistema (4 = write)
    swi 0                   // Llamada al sistema

    // Salir del programa
    mov r0, #0              // Código de salida (0 = éxito)
    mov r7, #1              // Número de la llamada al sistema (1 = exit)
    swi 0                   // Llamada al sistema
