section .data

    ; Output 1
    msg_output_1_1 db "Bienvenido! Introduzca 2 operandos: ", 10
    len_msg_output_1_1 equ $ - msg_output_1_1

    ; Output 2
    msg_output_2_1 db "Seleccione la operacion a realizar", 10
    len_msg_output_2_1 equ $ - msg_output_2_1

    msg_output_2_2 db "1. Sumar", 10
    len_msg_output_2_2 equ $ - msg_output_2_2

    msg_output_2_3 db "2. Restar", 10
    len_msg_output_2_3 equ $ - msg_output_2_3

    msg_output_2_4 db "3. Multiplicar", 10
    len_msg_output_2_4 equ $ - msg_output_2_4

    msg_output_2_5 db "4. Dividir", 10
    len_msg_output_2_5 equ $ - msg_output_2_5

    ; Output 3
    msg_output_3_1 db "Resultados: ", 10
    len_msg_output_3_1 equ $ - msg_output_3_1

    ; Output 4

    newline db 10
    len_newline equ $ - newline

    ; Output 5 

    msg_base_2 db "Binario (2): ", 0
    len_msg_base_2 equ $ - msg_base_2
    
    msg_base_8 db "Octal (8): ", 0
    len_msg_base_8 equ $ - msg_base_8

    msg_base_10 db "Decimal (10): ", 0
    len_msg_base_10 equ $ - msg_base_10
    
    msg_base_16 db "Hexadecimal (16): ", 0
    len_msg_base_16 equ $ - msg_base_16

    ; Output Errors
    msg_error_1 db "Error: Entrada Inválida.", 10
    len_msg_error_1 equ $ - msg_error_1

    msg_error_2 db "Error: Entrada supera los 64bits.", 10
    len_msg_error_2 equ $ - msg_error_2

    msg_error_3 db "Error: Division entre 0.", 10
    len_msg_error_3 equ $ - msg_error_3

    msg_error_4 db "Error: Opcion no valida.", 10
    len_msg_error_4 equ $ - msg_error_4

section .bss
    num1 resq 1          ; Espacio para el primer número
    num2 resq 1          ; Espacio para el segundo número
    buffer resb 22          ; Buffer para la entrada del usuario
    intBuffer resb 65       ; Buffer extra para evitar errores de números duplicados
    opcion resb 2           ; Variable para almacenar la opción del usuario
    result resq 1

section .text
    global _start

_start:
    ; Imprimir "Introduzca 2 operandos: "
    call _printMsg1

    ; Obtener el primer número
    call _getNumber
    mov [num1], rax

    ; Obtener el segundo número
    call _getNumber
    mov [num2], rax

    ; Imprimir el mensaje inicial
    call _printMsg2

    ; Leer la opción del usuario
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin
    mov rsi, opcion         ; Buffer para almacenar la opción
    mov rdx, 2              ; Longitud máxima de la entrada
    syscall

    ; Convertir el la opcion a entero
    movzx rcx, byte [opcion]
    sub rcx, '0'

    cmp rcx, 1
    je _suma

    cmp rcx, 2
    je _resta

    cmp rcx, 3
    je _multiplicacion

    cmp rcx, 4
    je _division

    call _exit

; ********************************
;           OPERACIONES
; ********************************

_suma:
    call _printMsg3
    mov rax, [num1]
    add rax, [num2]
    call _printResult
    jmp _exit

_resta:
    call _printMsg3
    mov rax, [num1]
    sub rax, [num2]
    call _printResult
    jmp _exit

_multiplicacion:
    call    _printMsg3
    mov     rax, [num1]
    imul    rax, [num2]
    cmp     rdx, 0              ; Compara si RDX tiene algún valor (overflow)
    jne     _conversorMul       ; Si RDX ≠ 0, llama a _conversorMul
    call    _printResult
    jmp     _exit

_division:
    call _printMsg3
    mov rax, [num1]
    mov rbx, [num2]
    test rbx, rbx
    jz _print_error_division
    cmp rax, rbx
    jl .swapDiv
    cqo                     ; Extender rax a rdx:rax
    idiv rbx
    call _printResult
    jmp _exit

.swapDiv:
    mov rdx, rax
    mov rax, rbx
    mov rbx, rdx
    cqo                     ; Extender rax a rdx:rax
    idiv rbx
    call _printResult
    jmp _exit

; ********************************
;           READ NUMBER
; ********************************

_getNumber:
    ; Leer entrada del usuario
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin
    mov rsi, buffer         ; Buffer para la entrada
    mov rdx, 22             ; Longitud máxima
    syscall

    ; Convertir a número
    mov rsi, buffer         ; Puntero al buffer
    xor rax, rax            ; Limpiar rax (acumulador)
    xor rcx, rcx            ; Limpiar rcx (contador)
    mov r10, 10             ; Base 10

.conversion_loop:
    movzx rbx, byte [rsi + rcx]
    cmp rbx, 10             ; Newline
    je .done
    cmp rbx, 0              ; Null terminator
    je .done

    ; Validar dígito
    cmp rbx, '0'
    jl _print_error_invalid
    cmp rbx, '9'
    jg _print_error_invalid

    ; Convertir a número y acumular
    sub rbx, '0'
    imul rax, r10
    jo _print_error_overflow
    add rax, rbx
    jo _print_error_overflow

    inc rcx
    jmp .conversion_loop

.done:
    ret

_clear_buffer:
    ; Funcion que limpia el buffer intBuffer llenándolo con ceros
    ; Entrada: ninguna
    ; Salida: intBuffer lleno de ceros

    push rax                ; Preservar RAX
    mov rcx, 20             ; Contador de bytes (20 iteraciones)
    mov rdi, intBuffer      ; Puntero al buffer
    xor al, al              ; AL = 0 (valor para limpiar)

.clear_loop:
    mov [rdi], al           ; Escribir 0 en la posición actual
    inc rdi                 ; Mover al siguiente byte
    dec rcx                 ; Decrementar contador
    jnz .clear_loop         ; Repetir si RCX no es cero

    pop rax                 ; Restaurar RAX
    ret

; ********************************
;           ITOA Y ATOI
; ********************************

; Convertir el string a entero
_atoi:
    ; Funcion que convierte un string decimal a entero
    ; Entrada: RSI - puntero al string
    ; Salida: RAX - número convertido

    xor rax, rax
    xor rcx, rcx
    mov r10, 10              ; Limpiar rcx (índice)

atoi_loop:
    movzx rbx, byte [rsi + rcx]
    cmp rbx, 10             ; Newline
    je atoi_done
    cmp rbx, 0              ; Null terminator
    je atoi_done

    ; Verificar dígito válido
    cmp rbx, '0'
    jl _print_error_invalid
    cmp rbx, '9'
    jg _print_error_invalid

    ; Convertir a número
    sub rbx, '0'
    
    ; Verificar overflow (RAX * 10 + RBX > 2⁶⁴-1?)
    mov r11, rax
    imul r11, r10               ; RAX * 10
    jo _print_error_overflow         ; Salta si overflow
    add r11, rbx
    jo _print_error_overflow            ; Salta si overflow
    
    mov rax, r11
    inc rcx
    jmp atoi_loop

atoi_done:
    ret                     ; Retornar con el resultado en rax

_itoa:
    ; Convertir número en RDI a string decimal
    ; Resultado en intBuffer
    mov rax, rdi        ; Número a convertir
    mov rdi, intBuffer  ; Buffer de destino
    add rdi, 21         ; Empezar desde el final del buffer
    mov byte [rdi], 0   ; Carácter nulo terminador
    mov rbx, 10         ; Base 10

.itoa_loop:
    dec rdi             ; Mover hacia atrás en el buffer
    xor rdx, rdx        ; Limpiar RDX para la división
    div rbx             ; RAX = cociente, RDX = residuo
    add dl, '0'         ; Convertir dígito a ASCII
    mov [rdi], dl       ; Almacenar dígito
    test rax, rax       ; ¿Cociente cero?
    jnz .itoa_loop   ; Si no, continuar
    
    ; Mover el resultado al inicio del buffer
    mov rsi, rdi       ; RSI = inicio del string
    mov rdi, intBuffer ; RDI = destino
    mov rcx, 22        ; Longitud máxima
    sub rcx, rdi
    add rcx, rsi       ; Calcular longitud real
    rep movsb          ; Copiar string al inicio
    
    ret

; ********************************
;           CONVERTIDORES
; ********************************


_conversorMul:
    ; Guardar el resultado original (128 bits en RDX:RAX)
    push rdx
    push rax
    
    ; Imprimir mensaje de resultado
    call _printMsg3
    
    ; Convertir e imprimir en base 2
    mov rsi, msg_base_2
    mov rdx, len_msg_base_2
    call _printBaseMsg
    pop rax
    pop rdx
    push rdx
    push rax
    mov rbx, 1      ; Indicador para base 2 (1 bit por dígito)
    call _convertExtended
    
    ; Convertir e imprimir en base 8
    mov rsi, msg_base_8
    mov rdx, len_msg_base_8
    call _printBaseMsg
    pop rax
    pop rdx
    push rdx
    push rax
    mov rbx, 3      ; Indicador para base 8 (3 bits por dígito)
    call _convertExtended
    
    ; Convertir e imprimir en base 16
    mov rsi, msg_base_16
    mov rdx, len_msg_base_16
    call _printBaseMsg
    pop rax
    pop rdx
    mov rbx, 4      ; Indicador para base 16 (4 bits por dígito)
    call _convertExtended
    
    jmp _exit

_convertExtended:
    ; Función que convierte un número de 128 bits (RDX:RAX) a string en la base especificada
    ; Entrada: RDX:RAX - número de 128 bits
    ;          RBX - bits por dígito (1 para base 2, 3 para base 8, 4 para base 16)
    ; Salida: imprime el número convertido
    
    ; Calcular el número máximo de bits a procesar (128)
    mov r12, 128
    
    ; Calcular el número de dígitos (128 / bits_por_dígito)
    xor rdx, rdx
    mov rax, r12
    div rbx
    mov r13, rax    ; r13 = contador de dígitos
    
    ; Restaurar el número original
    pop rax         ; Obtener RAX del stack
    pop rdx         ; Obtener RDX del stack
    push rdx        ; Volver a guardar para no perderlo
    push rax
    
    ; Inicializar buffer de salida
    mov rdi, intBuffer
    add rdi, 64     ; Empezar desde el final del buffer
    mov byte [rdi], 0 ; Carácter nulo terminador
    
    ; Máscara para extraer los bits necesarios
    mov rcx, rbx
    mov r14, 1
    shl r14, cl
    dec r14         ; r14 = máscara (2^bits_por_dígito - 1)
    
.convertLoop:
    ; Extraer el siguiente grupo de bits
    xor r11, r11    ; r11 almacenará los bits extraídos
    
    ; Verificar si necesitamos bits de RDX
    cmp r12, 64
    jle .extractFromRAX
    
.extractFromRDX:
    ; Extraer bits de RDX primero
    mov r15, r12
    sub r15, 64     ; r15 = posición relativa en RDX
    
    mov r11, rdx
    shr r11, cl     ; Desplazar para alinear los bits que necesitamos
    and r11, r14    ; Aplicar máscara
    
    sub r12, rbx    ; Actualizar contador de bits restantes
    jmp .processDigits
    
.extractFromRAX:
    ; Extraer bits de RAX
    mov r11, rax
    shr r11, cl     ; Desplazar para alinear los bits que necesitamos
    and r11, r14    ; Aplicar máscara
    
    sub r12, rbx    ; Actualizar contador de bits restantes
    
.processDigits:
    ; Convertir el valor a ASCII
    cmp r11, 9
    jle .decimalDigit
    add r11, 'A'-10 ; Para valores 10-15 (A-F)
    jmp .storeDigit
    
.decimalDigit:
    add r11, '0'    ; Para valores 0-9
    
.storeDigit:
    ; Almacenar el dígito en el buffer
    dec rdi
    mov [rdi], r11b
    
    ; Rotar los registros para procesar los siguientes bits
    mov rcx, rbx
    shld rdx, rax, cl
    shl rax, cl
    
    ; Decrementar el contador de dígitos
    dec r13
    jnz .convertLoop
    
    ; Calcular la longitud del string resultante
    mov rsi, intBuffer
    add rsi, 64
    sub rsi, rdi    ; rsi = longitud del string
    
    ; Imprimir el resultado
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    mov rdx, rsi    ; longitud
    mov rsi, rdi    ; buffer
    syscall
    
    ; Imprimir nueva línea
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ret



; ********************************



_convertidor:
    ; Función adaptada de tu código original
    ; Entrada: RAX = número, R15 = base
    ; Salida: intBuffer con el string convertido
    
    push r12
    push r13
    push rbx
    push rdx
    
    test rax, rax
    jns .positivo
    mov r12, 1              ; bandera de negativo
    neg rax                 ; convertir a positivo
    jmp .iniciar_conversion
.positivo:
    mov r12, 0              ; Bandera de positivo

.iniciar_conversion:
    mov r13, intBuffer + 64 ; Apuntar al final del buffer
    mov byte [r13], 0       ; Carácter nulo terminador
    mov rbx, r15            ; Usar la base pasada en R15

.conversion_loop:
    dec r13                 ; Mover hacia atrás en el buffer
    xor rdx, rdx            ; Limpiar RDX para la división
    div rbx                 ; RAX = cociente, RDX = residuo
    
    ; Convertir residuo a ASCII
    cmp dl, 9
    jbe .digit
    add dl, 'A' - 10
    jmp .store
.digit:
    add dl, '0'
.store:
    mov [r13], dl           ; Almacenar el dígito
    
    ; Verificar si hemos terminado
    test rax, rax
    jnz .conversion_loop    ; Continuar si cociente ≠ 0

    test r12, r12
    jz .finish
    dec r13
    mov byte [r13], '-'

.finish:
    ; Mover resultado al inicio del buffer
    mov rsi, r13
    mov rdi, intBuffer
    mov rcx, intBuffer + 64
    sub rcx, r13
    rep movsb
    
    pop rdx
    pop rbx
    pop r13
    pop r12
    ret

; ********************************
;       MENSAJES Y SALIDA
; ********************************

_printBaseMsg:
    ; Función auxiliar para imprimir el mensaje de base
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    syscall
    ret

_printResult:
    ; Guardar el resultado
    mov [result], rax
    
    ; Mostrar en base 10 (decimal)
    mov rsi, msg_base_10
    call _printBaseLabel
    mov rax, [result]
    mov r15, 10
    call _clear_buffer
    call _convertidor
    call _printConvertedNumber
    
    ; Mostrar en base 2 (binario)
    mov rsi, msg_base_2
    call _printBaseLabel
    mov rax, [result]
    mov r15, 2
    call _clear_buffer
    call _convertidor
    call _printConvertedNumber
    
    ; Mostrar en base 8 (octal)
    mov rsi, msg_base_8
    call _printBaseLabel
    mov rax, [result]
    mov r15, 8
    call _clear_buffer
    call _convertidor
    call _printConvertedNumber
    
    ; Mostrar en base 16 (hexadecimal)
    mov rsi, msg_base_16
    call _printBaseLabel
    mov rax, [result]
    mov r15, 16
    call _clear_buffer
    call _convertidor
    call _printConvertedNumber
    
    ret

_printBaseLabel:
    ; Imprime la etiqueta de la base (ej. "Decimal (10): ")
    push rsi
    call _strlen
    mov rdx, rax      ; Longitud del mensaje
    mov rax, 1
    mov rdi, 1
    pop rsi
    syscall
    ret

_printConvertedNumber:
    ; Imprime el número convertido en intBuffer
    mov rsi, intBuffer
    call _strlen      ; Obtener longitud del número
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    
    ; Newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

_strlen:
    ; Calcula longitud de string terminado en null
    xor rax, rax
.count_loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .count_loop
.done:
    ret

_print_error_invalid:
    ; Imprimir el mensaje de error
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_error_1    ; Dirección del mensaje
    mov rdx, len_msg_error_1; Longitud del mensaje 
    syscall

    call _exit
    
_print_error_overflow:
    ; Imprimir el mensaje de error
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_error_2    ; Dirección del mensaje
    mov rdx, len_msg_error_2; Longitud del mensaje 
    syscall

    call _exit

_print_error_division:
    ; Imprimir el mensaje de error
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_error_3    ; Dirección del mensaje
    mov rdx, len_msg_error_3; Longitud del mensaje 
    syscall

    call _exit

_print_error_option:
    ; Imprimir el mensaje de error
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_error_4    ; Dirección del mensaje
    mov rdx, len_msg_error_4; Longitud del mensaje 
    syscall

    call _exit

_printMsg1:
    ; Imprimir el mensaje inicial
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_output_1_1 ; Dirección del mensaje
    mov rdx, len_msg_output_1_1; Longitud del mensaje 
    syscall

    ret

_printMsg2:
    ; Imprimir las opciones
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_output_2_1 ; Dirección del mensaje
    mov rdx, len_msg_output_2_1; Longitud del mensaje
    syscall

    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_output_2_2 ; Dirección del mensaje
    mov rdx, len_msg_output_2_2; Longitud del mensaje
    syscall

    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_output_2_3 ; Dirección del mensaje
    mov rdx, len_msg_output_2_3; Longitud del mensaje
    syscall

    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_output_2_4 ; Dirección del mensaje
    mov rdx, len_msg_output_2_4; Longitud del mensaje
    syscall

    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_output_2_5 ; Dirección del mensaje
    mov rdx, len_msg_output_2_5; Longitud del mensaje
    syscall

    ret

_printMsg3:
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, msg_output_3_1     ; Dirección del mensaje
    mov rdx, len_msg_output_3_1 ; Longitud del mensaje
    syscall
    
    ret

_exit:
    ; Salir del programa
    mov rax, 60             ; syscall: exit
    xor rdi, rdi            ; código de salida: 0
    syscall