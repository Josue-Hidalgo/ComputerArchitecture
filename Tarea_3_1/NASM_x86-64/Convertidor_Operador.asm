section .data
    ; Mensajes para la entrada y salida

    msg_inicial db "Escriba 2 numeros que se puedan representar en 64 bits", 10
    len_msg_inicial equ $ - msg_inicial                                            

    msg_suma db "El resultado de la suma es: "         
    len_msg_suma equ $ - msg_suma                          

    msg_resta db "El resultado de la resta es: " 
    len_msg_resta equ $ - msg_resta                       

    msg_base db "Base "
    len_msg_base equ $ - msg_base                             

    msg_error db "Error: Entrada invalida.", 10 
    len_msg_error equ $ - msg_error

    msg_continuar db "Quiere ingresar los numeros nuevamente? (S/N)", 10 
    len_msg_continuar equ $ - msg_continuar
    
    newline db 10
    len_newline equ $ - newline

section .bss
    strNum1 resq 1          
    strNum2 resq 1  
    buffer resb 22
    intBuffer resb 22
    opcion resb 1       

section .text
    global _start

_start:
    ; Imprimir el mensaje inicial
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, msg_inicial    ; Dirección del mensaje
    mov rdx, len_msg_inicial; Longitud del mensaje
    syscall

    ; Obtener el primer número
    call _getNumber
    call _atoi              ; Convertir el string a entero
    mov [strNum1], rax      ; Guardar el resultado en strNum1

    ; Obtener el segundo número
    call _getNumber
    call _atoi              ; Convertir el string a entero
    mov [strNum2], rax      ; Guardar el resultado en strNum2

    mov r15, 2              ; r15 es la base actual, empieza en 2

.base_loop:
    call _clear_buffer      ; limpia el buffer para evitar problemas
    call _print_base        ; imprime "Base (número de base actual)"

    ; imprime "El resultado de la resta es: "
    mov rax, 1            
    mov rdi, 1              
    mov rsi, msg_resta   
    mov rdx, len_msg_resta
    syscall

    ; Realiza la resta
    mov rax, [strNum1]      ; Cargar el primer número
    sub rax, [strNum2]      ; Restar el segundo número
    call _clear_buffer
    call _convertidor
    call _printResult       ; Imprimir el resultado
    
    ; imprime "El resultado de la suma es: "
    mov rax, 1              
    mov rdi, 1              
    mov rsi, msg_suma    
    mov rdx, len_msg_suma
    syscall

    ; Realiza la suma
    mov rax, [strNum1]      ; Cargar el primer número
    add rax, [strNum2]      ; Sumar el segundo número
    call _clear_buffer
    call _convertidor
    call _printResult       ; Imprimir el resultado
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    inc r15                 ; se incrementa en 1 la base
    cmp r15, 16             ; si es menor o igual a 16, continúa
    jle .base_loop

    call _exit


_getNumber:
    ; Funcion que obtiene un número del usuario
    ; Entradas: rax - string a convertir
    ; Salidas: rax - número convertido

    ; Write
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin
    mov rsi, buffer         ; Buffer para almacenar la entrada
    mov rdx, 22             ; Longitud máxima de la entrada
    syscall

    mov al, [buffer]

    cmp al, '0'
    jl _print_error

    cmp al, '9'
    jg _print_error

    ; Retorna el numero en rax
    ret

_convertidor:
    ; Funcion que convierte un número en RAX a su representación en string
    ; en la base contenida en R15.
    ; Entrada: RAX - número a convertir, R15 - base destino
    ; Salida: intBuffer - string con el número en la base correspondiente

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
    mov rbx, r15            

.conversion_loop:
    dec r13                 ; Mover hacia atrás en el buffer
    xor rdx, rdx              ; Limpiar RDX para la división
    div rbx                 ; r15 es la base
                            ; RAX = cociente, RDX = residuo
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
    rep movsb               ; instrucción que hace un ciclo, es más eficiente y necesita muchas menos líneas

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
    jl _print_error
    cmp rbx, '9'
    jg _print_error

    ; Convertir a número
    sub rbx, '0'
    
    ; Verificar overflow (RAX * 10 + RBX > 2⁶⁴-1?)
    mov r11, rax
    imul r11, r10               ; RAX * 10
    jo _print_error             ; Salta si overflow
    add r11, rbx
    jo _print_error             ; Salta si overflow
    
    mov rax, r11
    inc rcx
    jmp atoi_loop

atoi_done:
    ret                     ; Retornar con el resultado en rax

_itoa:
    ; Funcion que convierte un número en RDI a string decimal
    ; Entrada: RDI - número a convertir
    ; Salida: intBuffer contiene el string resultante

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

_printResult:
    ; Funcion que imprime un número contenido en RAX
    ; Entrada: RAX - número a imprimir
    ; Salida: imprime el número por pantalla seguido de newline

    mov rdi, rax            ; Cargar el número a imprimir
    call _itoa              ; Convertir el número a string
    
    ; Calcular longitud del string (hasta el primer null byte)
    mov rsi, intBuffer
    mov rdx, 0

; calcula la longitud del resultado
.calc_length:
    cmp byte [rsi + rdx], 0 ; si la suma da 0
    je .print               ; imprime el resultado
    inc rdx
    jmp .calc_length

.print:
    mov rax, 1              
    mov rdi, 1              
    mov rsi, intBuffer      ; Buffer con el string resultante
    syscall                 ; RDX ya tiene la longitud correcta

    ; newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

_print_base:
    ; Funcion que imprime el texto "Base " seguido del valor actual de R15
    ; Entrada: R15 - base actual
    ; Salida: imprime "Base X" por pantalla

    ; 1. Imprimir "Base "
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    mov rsi, msg_base
    mov rdx, len_msg_base                  
    syscall

    ; 2. Convertir e imprimir el número de base (R15) directamente
    ; Para bases 2-16 (nunca más de 2 dígitos)
    mov rbx, intBuffer          ; Usar el buffer existente
    
    ; Convertir decenas (si base ≥ 10)
    mov rax, r15
    xor rdx, rdx
    mov rcx, 10
    div rcx                     ; RAX = decenas, RDX = unidades
    
    test rax, rax
    jz .unidades                ; Si no hay decenas
    
    ; Almacenar decenas (sólo ocurre para bases 10-16)
    add al, '0'
    mov [rbx], al
    inc rbx
    
.unidades:
    ; Almacenar unidades
    add dl, '0'         ; convierte la unidad a ASCII
    mov [rbx], dl       ; Guarda dl en el buffer
    inc rbx             ; avanza el puntero
    
    ; Terminar el string
    mov byte [rbx], 0
    
    ; Calcular longitud (RBX - intBuffer)
    mov rdx, rbx        ; Puntero actual
    sub rdx, intBuffer  ; Restar inicio = longitud
    
    ; Imprimir el número
    mov rax, 1
    mov rdi, 1
    mov rsi, intBuffer
    syscall
    
    ; 3. Imprimir newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ret

_print_error:
    ; imprime el mensaje de error
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_error
    mov rdx, len_msg_error
    syscall

    ; imprime el mensaje de continuar
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_continuar
    mov rdx, len_msg_continuar
    syscall

    ; extrae la respuesta
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin
    mov rsi, opcion         ; opción s o n
    mov rdx, 2              ; 2 bytes para evitar problemas con el enter
    syscall

    mov al, [opcion]
    ; si es s, vuelve al inicio
    cmp al, 's'
    je _start

    ; si es n, se sale del programa
    cmp al, 'n'
    je _exit

    ; si es s, vuelve al inicio
    cmp al, 'S'
    je _start

    ; si es n, se sale del programa
    cmp al, 'N'
    je _exit

    ; si no es ninguna, vuelve a lanzar error
    jmp _print_error

_exit:
    ; Salir del programa
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; Código de salida 0
    syscall