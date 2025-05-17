; Allan Jiménez & Josué Hidalgo

section .data
    msg db "Escriba 2 numeros de maximo 10 digitos. El resultado sera restado y sumado", 10 ; mensaje
    len_msg equ $ - msg ; longitud del mensaje
    newline db 10

section .bss
    buffer resb 11          ; input del usuario
    intBuffer resb 11       ; variable extra para evitar errores de números duplicados
    strNum1 resq 1          ; espacio para el primer número 
    strNum2 resq 1          ; espacio para el segundo número

section .text
    global _start

_start:
    ; Imprimir el mensaje inicial
    call _printMsg

    ; Obtener el primer número
    call _getNumber
    call _atoi              ; Convertir el string a entero
    mov [strNum1], rax      ; Guardar el resultado en strNum1

    ; Obtener el segundo número
    call _getNumber
    call _atoi              ; Convertir el string a entero
    mov [strNum2], rax      ; Guardar el resultado en strNum2

    ; Realizar la resta
    mov rax, [strNum1]      ; Cargar el primer número
    sub rax, [strNum2]      ; Restar el segundo número
    call _printResult       ; Imprimir el resultado

    ; Realizar la suma
    mov rax, [strNum1]      ; Cargar el primer número
    add rax, [strNum2]      ; Sumar el segundo número
    call _printResult       ; Imprimir el resultado

    ; Salir del programa
    call _exit

_printMsg:
    ; Escribir el mensaje inicial
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg            ; Dirección del mensaje
    mov rdx, len_msg        ; Longitud del mensaje
    syscall
    ret

_getNumber:
    ; Leer un número del usuario
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin
    mov rsi, buffer         ; Buffer para almacenar la entrada
    mov rdx, 11             ; Longitud máxima de la entrada
    syscall
    ret

_atoi:
    ; Convertir el string a entero
    xor rax, rax            ; Limpiar rax (acumulador)
    xor rcx, rcx            ; Limpiar rcx (índice)

atoi_loop:
    movzx rbx, byte [rsi + rcx]  ; Cargar el siguiente byte de el string
    cmp rbx, 10             ; Verificar si es un salto de línea
    je atoi_done            ; Si es el final, terminar
    cmp rbx, 0              ; Verificar si es un carácter nulo
    je atoi_done            ; Si es el final, terminar

    sub rbx, '0'            ; Convertir el carácter a número
    imul rax, rax, 10       ; Multiplicar el acumulador por 10
    add rax, rbx            ; Sumar el nuevo dígito
    inc rcx                 ; Incrementar el índice
    jmp atoi_loop           ; Repetir

atoi_done:
    ret                     ; Retornar con el resultado en rax

_printResult:
    ; Convertir el entero en string e imprimirlo
    mov rdi, rax            ; Cargar el número a imprimir
    ;mov rsi, buffer
    call _itoa              ; Convertir el número a string

    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, intBuffer      ; Buffer con el string resultante
    mov rdx, 11             ; Longitud máxima del string
    syscall

    ; newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ret

_itoa:
    ; Convertir un entero a string
    mov rsi, intBuffer + 10     ; Apuntar al final del buffer
    mov byte [rsi], 0           ; Terminar el string con un carácter nulo
    mov rbx, 10                 ; Base 10
    jmp itoa_loop               ; Si no es negativo, continuar


itoa_loop:
    dec rsi                 ; Mover el puntero hacia atrás
    xor rdx, rdx            ; Limpiar rdx para la división
    idiv rbx                ; Dividir rax por 10
    add dl, '0'             ; Convertir el residuo a carácter
    mov [rsi], dl           ; Almacenar el carácter en el buffer
    test rax, rax           ; Verificar si el cociente es cero
    jnz itoa_loop           ; Si no es cero, repetir
    ret

_exit:
    ; Salir del programa
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; Código de salida 0
    syscall