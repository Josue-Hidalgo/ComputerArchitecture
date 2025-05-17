section .data
    ; Definición de datos constantes
    msg_prompt          db  'Cual es el archivo que desea abrir: ', 10 ; Mensaje inicial con salto de línea
    msg_prompt_len      equ $ - msg_prompt                              ; Longitud del mensaje inicial
    msg_count           db  'Numero de palabras: ', 0                  ; Mensaje para mostrar el conteo de palabras
    msg_count_len       equ $ - msg_count - 1                          ; Longitud del mensaje de conteo
    msg_length_error    db  'Longitud de caracteres supera el limite', 10 ; Mensaje de error de longitud con salto de línea
    msg_length_error_len equ $ - msg_length_error                      ; Longitud del mensaje de error
    newline             db 10                                          ; Carácter de nueva línea

section .bss
    ; Definición de variables y buffers
    filename     resb 256           ; Buffer para almacenar el nombre del archivo
    filecontent  resb 1024          ; Buffer para almacenar el contenido del archivo
    fd           resq 1             ; Descriptor de archivo
    word_count   resq 1             ; Contador de palabras
    num_buffer   resb 20            ; Buffer para almacenar el número convertido a texto
    temp_buffer  resb 1             ; Buffer temporal para verificar longitud adicional

section .text
    global _start

_start:
    ; ===== IMPRIMIR MENSAJE INICIAL =====
    mov rax, 1                      ; syscall: sys_write
    mov rdi, 1                      ; ID de stdout
    mov rsi, msg_prompt             ; Dirección del mensaje inicial
    mov rdx, msg_prompt_len         ; Longitud del mensaje
    syscall                         ; Llamar al sistema para escribir

    ; ===== LEER NOMBRE DEL ARCHIVO =====
    mov rax, 0                      ; syscall: sys_read
    mov rdi, 0                      ; ID de stdin
    mov rsi, filename               ; Dirección del buffer donde se almacenará el nombre
    mov rdx, 256                    ; Tamaño máximo del buffer
    syscall                         ; Llamar al sistema para leer

    ; ===== PROCESAR NOMBRE DEL ARCHIVO =====
    cmp rax, 0                      ; ¿Se leyó algo?
    jle _exit_error                 ; Si no, salir con error

    dec rax                         ; Ajustar la longitud para eliminar el salto de línea
    mov byte [filename + rax], 0    ; Añadir terminador nulo al final del nombre del archivo

    ; ===== ABRIR EL ARCHIVO =====
    mov rax, 2                      ; syscall: sys_open
    mov rdi, filename               ; Dirección del nombre del archivo
    mov rsi, 0                      ; Modo de apertura: lectura (O_RDONLY)
    syscall                         ; Llamar al sistema para abrir el archivo

    cmp rax, 0                      ; ¿Se pudo abrir el archivo?
    jl _exit_error                  ; Si no, salir con error

    mov [fd], rax                   ; Almacenar el descriptor del archivo

    ; ===== LEER CONTENIDO DEL ARCHIVO =====
    mov rax, 0                      ; syscall: sys_read
    mov rdi, [fd]                   ; Descriptor del archivo
    mov rsi, filecontent            ; Buffer donde se almacenará el contenido
    mov rdx, 1024                   ; Tamaño máximo del buffer
    syscall                         ; Llamar al sistema para leer

    ; ===== VERIFICAR LONGITUD MÁXIMA =====
    mov r12, rax                    ; Guardar la cantidad de bytes leídos
    cmp r12, 1024                   ; ¿El contenido cabe en el buffer?
    jl valid_length                 ; Si es menor, continuar

    ; Verificar si hay contenido adicional
    mov rax, 0                      ; syscall: sys_read
    mov rdi, [fd]                   ; Descriptor del archivo
    mov rsi, temp_buffer            ; Buffer temporal
    mov rdx, 1                      ; Leer 1 byte adicional
    syscall                         ; Llamar al sistema para leer

    cmp rax, 0                      ; ¿Hay más contenido?
    jg _length_error                ; Si hay más, mostrar error de longitud

valid_length:
    ; ===== IMPRIMIR EL CONTENIDO DEL ARCHIVO =====
    mov rdx, r12                    ; Número de bytes leídos
    mov rax, 1                      ; syscall: sys_write
    mov rdi, 1                      ; ID de stdout
    mov rsi, filecontent            ; Dirección del contenido del archivo
    syscall                         ; Llamar al sistema para escribir

    ; ===== CONTAR PALABRAS =====
    mov qword [word_count], 0       ; Inicializar el contador de palabras en 0
    mov rcx, 0                      ; Índice para recorrer el contenido
    mov r13b, 1                     ; Flag: 1 si el último carácter era un no-letra o separador

count_loop:
    cmp rcx, r12                    ; ¿Se han procesado todos los bytes?
    jge print_count                 ; Si sí, imprimir el resultado

    mov al, [filecontent + rcx]     ; Leer un byte del contenido

    ; ===== VERIFICAR SI ES LETRA =====
    cmp al, 'A'                     ; ¿Es mayor o igual a 'A'?
    jl non_letter                   ; Si no, no es letra
    cmp al, 'Z'                     ; ¿Es menor o igual a 'Z'?
    jle letter                      ; Si sí, es letra
    cmp al, 'a'                     ; ¿Es mayor o igual a 'a'?
    jl non_letter                   ; Si no, no es letra
    cmp al, 'z'                     ; ¿Es menor o igual a 'z'?
    jg non_letter                   ; Si no, no es letra

letter:
    ; Caracter válido (letra)
    mov r13b, 0                     ; Flag: estamos en una palabra
    jmp next_char

non_letter:
    ; Caracter inválido (no-letra)
    cmp r13b, 0                     ; ¿El carácter anterior era parte de una palabra?
    jne skip_count                  ; Si no, no contar palabra

    inc qword [word_count]          ; Incrementar el contador de palabras

skip_count:
    mov r13b, 1                     ; Flag: estamos en un no-letra o separador
    jmp next_char

next_char:
    inc rcx                         ; Avanzar al siguiente carácter
    jmp count_loop                  ; Repetir el bucle

print_count:
    ; ===== IMPRIMIR NÚMERO DE PALABRAS =====
    cmp r13b, 0                     ; ¿El último carácter era parte de una palabra?
    jne skip_last                   ; Si no, no ajustar el contador

    inc qword [word_count]          ; Incrementar el contador por la última palabra

skip_last:
    ; Imprimir mensaje de conteo
    mov rax, 1                      ; syscall: sys_write
    mov rdi, 1                      ; ID de stdout
    mov rsi, msg_count              ; Mensaje de conteo
    mov rdx, msg_count_len          ; Longitud del mensaje
    syscall                         ; Llamar al sistema para escribir

    ; ===== CONVERTIR NÚMERO A TEXTO =====
    mov rax, [word_count]           ; Obtener el número de palabras
    lea rdi, [num_buffer + 19]      ; Posicionar al final del buffer
    mov byte [rdi], 0               ; Añadir terminador nulo
    mov rbx, 10                     ; Base decimal

convert_loop:
    dec rdi                         ; Mover el puntero hacia atrás
    xor rdx, rdx                    ; Limpiar rdx
    div rbx                         ; Dividir rax entre 10
    add dl, '0'                     ; Convertir el residuo a carácter ASCII
    mov [rdi], dl                   ; Almacenar el carácter en el buffer
    test rax, rax                   ; ¿Quedan más dígitos?
    jnz convert_loop                ; Si sí, repetir

    ; Calcular longitud del número
    mov r8, rdi                     ; Inicio del número convertido
    mov r9, num_buffer + 19         ; Final del buffer
    sub r9, r8                      ; Calcular la longitud
    mov rdx, r9

    ; Imprimir número
    mov rax, 1                      ; syscall: sys_write
    mov rdi, 1                      ; ID de stdout
    mov rsi, r8                     ; Dirección del número convertido
    syscall                         ; Llamar al sistema para escribir

    ; Imprimir nueva línea
    mov rax, 1                      ; syscall: sys_write
    mov rdi, 1                      ; ID de stdout
    mov rsi, newline                ; Carácter de nueva línea
    mov rdx, 1                      ; Longitud del carácter
    syscall                         ; Llamar al sistema para escribir

    ; ===== CERRAR ARCHIVO Y SALIR =====
    mov rax, 3                      ; syscall: sys_close
    mov rdi, [fd]                   ; Descriptor del archivo
    syscall                         ; Llamar al sistema para cerrar el archivo

    mov rax, 60                     ; syscall: sys_exit
    xor rdi, rdi                    ; Código de salida 0 (éxito)
    syscall                         ; Salir del programa

_length_error:
    ; ===== IMPRIMIR ERROR DE LONGITUD =====
    mov rax, 1                      ; syscall: sys_write
    mov rdi, 1                      ; ID de stdout
    mov rsi, msg_length_error       ; Mensaje de error
    mov rdx, msg_length_error_len   ; Longitud del mensaje
    syscall                         ; Llamar al sistema para escribir

    ; Cerrar archivo y salir con error
    mov rax, 3                      ; syscall: sys_close
    mov rdi, [fd]                   ; Descriptor del archivo
    syscall                         ; Llamar al sistema para cerrar el archivo

    mov rax, 60                     ; syscall: sys_exit
    mov rdi, 1                      ; Código de salida 1 (error)
    syscall                         ; Salir del programa

_exit_error:
    ; ===== SALIR CON ERROR =====
    mov rax, 60                     ; syscall: sys_exit
    mov rdi, 1                      ; Código de salida 1 (error)
    syscall                         ; Salir del programa
