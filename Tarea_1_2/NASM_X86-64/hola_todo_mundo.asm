section .data
    ; Mensaje principal del menú
    msj_0     db "Seleccione una Opción: ", 0xA
    len_0    equ  $  -  msj_0

    ; Opción a
    msj_1     db "a. Hola Mundo!!!", 0xA
    len_1    equ  $  -  msj_1

    msj_1_1     db "Hola Mundo!!!", 0xA
    len_1_1    equ  $  -  msj_1_1

    ; Opción b
    msj_2     db "b. Feliz Día del Amor y la Amistad!!!", 0xA
    len_2    equ  $  -  msj_2

    msj_2_1     db "Feliz Día del Amor y la Amistad!!!", 0xA
    len_2_1    equ  $  -  msj_2_1

    ; Opción c
    msj_3     db "c. Feliz Navidad!!!", 0xA
    len_3    equ  $  -  msj_3

    msj_3_1     db "Feliz Navidad!!!", 0xA
    len_3_1    equ  $  -  msj_3_1

    ; Opción d
    msj_4     db "d. Feliz Día de la Independencia!!!", 0xA
    len_4    equ  $  -  msj_4

    msj_4_1     db "Feliz Día de la Independencia!!!", 0xA
    len_4_1    equ  $  -  msj_4_1

    ; Opción e
    msj_5     db "e. Otro (ingrese su propio mensaje).", 0xA
    len_5    equ  $  -  msj_5

    msj_5_1     db "Otro (ingrese su propio mensaje).", 0xA
    len_5_1    equ  $  -  msj_5_1

    ; Opción f
    msj_6     db "f. Finalizar el Programa.", 0xA
    len_6    equ  $  -  msj_6

    ; Mensaje de error para opción no válida
    msj_7     db "Opción no válida. Intente de nuevo.", 0xA
    len_7    equ  $  -  msj_7

    ; Salto de línea para imprimir ENTER
    salto_linea db 0xA

section .bss
    buffer resb 100            ; Buffer para almacenar la entrada del usuario

section .text
    global _start

; Punto de entrada principal
_start:
    call _getOptionAndExecute  ; Empieza el ciclo del menú
    call _exit                 ; Sale del programa

; Rutina para opción 'a'
_option_a:
    mov rax, 1                 ; syscall: write
    mov rdi, 1                 ; file descriptor: stdout
    mov rsi, msj_1_1           ; mensaje a imprimir
    mov rdx, len_1_1           ; longitud del mensaje
    syscall
    jmp _getOptionAndExecute   ; Regresar al menú

; Rutina para opción 'b'
_option_b:
    mov rax, 1
    mov rdi, 1
    mov rsi, msj_2_1
    mov rdx, len_2_1
    syscall
    jmp _getOptionAndExecute

; Rutina para opción 'c'
_option_c:
    mov rax, 1
    mov rdi, 1
    mov rsi, msj_3_1
    mov rdx, len_3_1
    syscall
    jmp _getOptionAndExecute

; Rutina para opción 'd'
_option_d:
    mov rax, 1
    mov rdi, 1
    mov rsi, msj_4_1
    mov rdx, len_4_1
    syscall
    jmp _getOptionAndExecute

; Rutina para opción 'e'
_option_e:
    mov rax, 1
    mov rdi, 1
    mov rsi, msj_5_1
    mov rdx, len_5_1
    syscall

    ; Leer el mensaje del usuario por stdin
    mov rax, 0                ; syscall: read
    mov rdi, 0                ; file descriptor: stdin
    mov rsi, buffer           ; buffer donde guardar
    mov rdx, 100              ; máximo a leer
    syscall
    mov rcx, rax              ; rcx = bytes realmente leídos

    ; Quitar salto de línea si fue ingresado (reemplaza '\n' por NULL)
    cmp rcx, 0
    je .imprime_msg
    mov rbx, buffer
    add rbx, rcx
    dec rbx
    cmp byte [rbx], 10        ; ¿último caracter == '\n'?
    jne .imprime_msg
    mov byte [rbx], 0         ; lo reemplaza por 0
    dec rcx                   ; reduce longitud a imprimir

.imprime_msg:
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, rcx
    syscall

    call _printEnter          ; Imprime un salto de línea

    jmp _getOptionAndExecute

; Rutina para opción 'f': salir
_opcion_f:
    jmp _exit

; Rutina principal de ciclo de menú y lectura de opción
_getOptionAndExecute:
    
    call _printEnter          ; Imprime salto de línea (para separar ciclos del menú)
    call _printMenu           ; Imprime el menú
    call _printEnter
    
    ; Leer la opción del usuario: lee hasta 10 bytes
    mov rax, 0                ; syscall: read
    mov rdi, 0                ; stdin
    mov rsi, buffer
    mov rdx, 10
    syscall
    mov rcx, rax              ; rcx = bytes leídos

    ; Buscar primer caracter válido (ignora saltos de línea, retorno de carro y espacios)
    mov rbx, buffer
.buscar_opcion:
    cmp rcx, 0
    je _printError            ; Si no se leyó nada útil, error
    mov al, [rbx]
    cmp al, 10                ; ¿\n?
    je .siguiente
    cmp al, 13                ; ¿\r?
    je .siguiente
    cmp al, ' '               ; ¿espacio?
    je .siguiente

    ; Procesar la opción seleccionada
    cmp al, 'a'
    je _option_a
    cmp al, 'b'
    je _option_b
    cmp al, 'c'
    je _option_c
    cmp al, 'd'
    je _option_d
    cmp al, 'e'
    je _option_e
    cmp al, 'f'
    je _opcion_f

    call _printEnter
    jmp _printError           ; Si no es ninguna opción válida

.siguiente:
    inc rbx
    dec rcx
    jmp .buscar_opcion

; Imprime mensaje de error por opción no válida
_printError:
    mov rax, 1
    mov rdi, 1
    mov rsi, msj_7
    mov rdx, len_7
    syscall
    jmp _getOptionAndExecute

; Imprime el menú completo
_printMenu:
    mov rax, 1
    mov rdi, 1
    mov rsi, msj_0
    mov rdx, len_0
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msj_1
    mov rdx, len_1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msj_2
    mov rdx, len_2
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msj_3
    mov rdx, len_3
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msj_4
    mov rdx, len_4
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msj_5
    mov rdx, len_5
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msj_6
    mov rdx, len_6
    syscall

    ret

; Imprime solo un salto de línea (ENTER)
_printEnter:
    mov rax, 1
    mov rdi, 1
    mov rsi, salto_linea
    mov rdx, 1
    syscall
    ret

; Sale del programa
_exit:
    mov rax, 60
    xor rdi, rdi
    syscall