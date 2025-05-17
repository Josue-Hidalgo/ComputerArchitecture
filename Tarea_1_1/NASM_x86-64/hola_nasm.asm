section .data
    mensaje     db "hola mundo", 0xA
    longitud    equ  $  -  mensaje

section .text
    global _start

_start:
    mov rdx, longitud    ; RDX = longitud de la cadena
    mov rsi, mensaje     ; RSI = dirección de la cadena
    mov rdi, 1           ; RDI = descriptor de archivo (1 = STDOUT)
    mov rax, 1           ; RAX = syscall write
    syscall              ; Llamada al sistema

    mov rdi, 0           ; RDI = código de salida
    mov rax, 60          ; RAX = syscall exit
    syscall              ; Llamada al sistema

