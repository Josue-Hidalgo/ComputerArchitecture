; ------------------------------------------------------
; Programa en NASM: Lee un nombre de archivo, cuenta palabras,
; las ordena alfabéticamente y las muestra
; ------------------------------------------------------

section .data
    ; --- Mensajes para el usuario ---
    msg_1      db 'Introduzca el nombre al archivo de texto (max 2048 chars): ', 10
    msg_1_len  equ $ - msg_1

    msg_2      db 'El número de palabras encontradas es: ', 10
    msg_2_len  equ $ - msg_2

    msg_3      db 'Palabras ordenadas alfabéticamente (a-z):  ', 10
    msg_3_len  equ $ - msg_3
    
    msg_error_1     db 'ERROR: No se pudo abrir el archivo.', 10
    msg_error_1_len equ $-msg_error_1
    
    msg_error_2     db 'ERROR: Número de caracteres inválido.', 10
    msg_error_2_len equ $-msg_error_2
    
    newline         db 10

section .bss
    ; --- Buffers y variables ---
    filename   resb 256           ; Nombre del archivo
    filecontent resb 2048         ; Contenido del archivo
    fd         resq 1            ; Descriptor del archivo
    buffer      resb 2048           ; Input del usuario
    buf_len     resq 1              ; Bytes leídos del input
    word_ptrs   resq 512            ; Punteros a cada palabra encontrada
    word_count  resq 1              ; Número de palabras encontradas

section .text
    global _start

; ======================================================
;                PROGRAMA PRINCIPAL
; ======================================================
_start:

    call print_initial_msg

    ; Leer nombre del archivo
    mov   rax, 0                   ; syscall: read
    mov   rdi, 0                   ; fd: stdin
    mov   rsi, filename            ; buffer destino
    mov   rdx, 256                 ; tamaño máximo
    syscall

    ; Procesar nombre del archivo
    cmp rax, 0                      ; ¿Se leyó algo?
    jle exit_error                 ; Si no, salir con error

    dec rax                         ; Ajustar la longitud para eliminar el salto de línea
    mov byte [filename + rax], 0    ; Añadir terminador nulo al final del nombre del archivo

    ; Abrir el archivo
    mov   rax, 2                   ; syscall: open
    mov   rdi, filename            ; nombre del archivo
    mov   rsi, 0                   ; flags: O_RDONLY
    syscall

    cmp   rax, 0                   ; ¿Se pudo abrir el archivo?
    jl    exit_error               ; Si no, salir con error

    mov   [fd], rax          ; Guardar el descriptor del archivo

    ; Leer contenido del archivo
    mov rax, 0                      ; syscall: sys_read
    mov rdi, [fd]                   ; Descriptor del archivo
    mov rsi, filecontent            ; Buffer donde se almacenará el contenido
    mov rdx, 1024                   ; Tamaño máximo del buffer
    syscall                         ; Llamar al sistema para leer

    ; Verificar longitud máxima
    mov r12, rax                    ; Guardar la cantidad de bytes leídos
    cmp r12, 1024                   ; ¿El contenido cabe en el buffer?
    jl valid_length                 ; Si es menor, continuar

    ; Verificar si hay contenido adicional
    mov rax, 0                      ; syscall: sys_read
    mov rdi, [fd]                   ; Descriptor del archivo
    mov rsi, temp_buffer            ; Buffer temporal
    mov rdx, 1                      ; Leer 1 byte adicional
    syscall

    cmp rax, 0                      ; ¿Se leyó algo?
    jle error_len                  ; Si no, salir con error

valid_length:
    ; Contar palabras
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

error_len:
    ; ===== IMPRIMIR ERROR DE LONGITUD =====
    mov rax, 1                      ; syscall: sys_write
    mov rdi, 1                      ; ID de stdout
    mov rsi, msg_error_2            ; Mensaje de error
    mov rdx, msg_error_2_len        ; Longitud del mensaje
    syscall                         ; Llamar al sistema para escribir

    ; Cerrar archivo y salir con error
    mov rax, 3                      ; syscall: sys_close
    mov rdi, [fd]                   ; Descriptor del archivo
    syscall                         ; Llamar al sistema para cerrar el archivo

    mov rax, 60                     ; syscall: sys_exit
    mov rdi, 1                      ; Código de salida 1 (error)
    syscall                         ; Salir del programa

_Monsalve:
    ; Leer input del usuario
    mov   rax, 0                   ; syscall: read
    mov   rdi, 0                   ; fd: stdin
    mov   rsi, buffer              ; buffer destino
    mov   rdx, 2048                ; tamaño máximo
    syscall
    cmp   rax, 0                   ; ¿Error o EOF?
    jle   exit_error
    mov   [buf_len], rax

    ; Parsear palabras
    call parse_words

    ; Ordenar palabras
    call bubble_sort_words

    ; Imprimir palabras ordenadas
    call print_sorted_words

    ; Salir exitosamente
    mov   rax, 60
    xor   rdi, rdi
    syscall

; ======================================================
;           SUBRUTINAS DE PROCESAMIENTO
; ======================================================

; ------------------------------------------------------
; parse_words: Separa el buffer en palabras y guarda punteros
; ------------------------------------------------------
parse_words:
    xor   rcx, rcx                ; Índice buffer
    xor   rbx, rbx                ; Contador palabras
    mov   r8, buffer              ; Puntero actual

.parse_loop:
    cmp   rcx, [buf_len]
    jge   .parse_done
    mov   al, [buffer + rcx]
    ; ¿Es separador?
    cmp   al, ' '
    je    .set_null
    cmp   al, 9
    je    .set_null
    cmp   al, 10
    je    .set_null

    ; Si es inicio de palabra, guardar puntero
    cmp   r8, buffer
    je    .save_ptr
    cmp   byte [r8 - 1], 0
    jne   .continue

.save_ptr:
    mov   [word_ptrs + rbx*8], r8
    inc   rbx
    jmp   .continue

.set_null:
    mov   byte [buffer + rcx], 0

.continue:
    inc   rcx
    inc   r8
    jmp   .parse_loop

.parse_done:
    mov   [word_count], rbx
    ret

; ------------------------------------------------------
; bubble_sort_words: Ordena alfabéticamente los punteros
; ------------------------------------------------------
bubble_sort_words:
    mov   rcx, [word_count]
    dec   rcx
    jle   .done

.outer:
    xor   rsi, rsi

.inner:
    cmp   rsi, rcx
    jge   .end_inner
    mov   rdi, [word_ptrs + rsi*8]
    mov   rdx, [word_ptrs + rsi*8 + 8]
    call  strcmp
    test  rax, rax
    jle   .no_swap
    ; Intercambiar punteros
    mov   rax, [word_ptrs + rsi*8]
    xchg  rax, [word_ptrs + rsi*8 + 8]
    mov   [word_ptrs + rsi*8], rax

.no_swap:
    inc   rsi
    jmp   .inner

.end_inner:
    dec   rcx
    jnz   .outer
.done:
    ret

; ------------------------------------------------------
; print_sorted_words: Imprime las palabras ordenadas
; ------------------------------------------------------
print_sorted_words:
    xor   rsi, rsi
.print_next:
    cmp   rsi, [word_count]
    jge   .done
    mov   rdi, [word_ptrs + rsi*8]
    push  rsi
    call  print_string
    call  print_newline
    pop   rsi
    inc   rsi
    jmp   .print_next
.done:
    ret

; ======================================================
;           SUBRUTINAS DE UTILIDAD
; ======================================================

; ------------------------------------------------------
; strcmp: compara dos cadenas terminadas en null
; Entradas: rdi=string1, rdx=string2
; Salida:   rax <0 si str1 < str2, >0 si str1 > str2, 0 si iguales
; ------------------------------------------------------
strcmp:
    xor rax, rax
.loop:
    mov al, [rdi]
    mov bl, [rdx]
    cmp al, bl
    jne .diff
    test al, al
    jz .equal
    inc rdi
    inc rdx
    jmp .loop
.diff:
    sub al, bl
    movsx rax, al
    ret
.equal:
    xor rax, rax
    ret

; ------------------------------------------------------
; print_string: imprime en pantalla una cadena terminada en null
; Entrada: rdi = puntero a string
; ------------------------------------------------------
print_string:
    push r12
    push r13
    mov r12, rdi
    xor r13, r13
.calc_len:
    cmp byte [r12 + r13], 0
    je .write
    inc r13
    jmp .calc_len
.write:
    mov rax, 1
    mov rdi, 1
    mov rsi, r12
    mov rdx, r13
    syscall
    pop r13
    pop r12
    ret

; ------------------------------------------------------
; print_initial_msg: imprime el mensaje inicial
; ------------------------------------------------------
print_initial_msg:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_1
    mov rdx, msg_1_len
    syscall
    ret

; ------------------------------------------------------
; print_newline: imprime un salto de línea
; ------------------------------------------------------
print_newline:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

; ------------------------------------------------------
; exit_error: imprime mensaje de error y sale
; ------------------------------------------------------
exit_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_error_1
    mov rdx, msg_error_1_len
    syscall
    mov rax, 60
    mov rdi, 1
    syscall