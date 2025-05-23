; ------------------------------------------------------
; Programa en NASM: Lee un nombre de archivo, cuenta palabras,
; las ordena alfabéticamente y las muestra
; ------------------------------------------------------

section .data
    ; Mensajes para el usuario
    msg_1           db 'Introduzca el nombre al archivo de texto (max 2048 chars): ', 10
    msg_1_len       equ $ - msg_1
    msg_2           db 'El número de palabras encontradas es: ', 10
    msg_2_len       equ $ - msg_2
    msg_3           db 'Palabras ordenadas alfabéticamente (a-z):  ', 10
    msg_3_len       equ $ - msg_3
    msg_error_1     db 'ERROR: No se pudo abrir el archivo.', 10
    msg_error_1_len equ $-msg_error_1
    msg_error_2     db 'ERROR: Número de caracteres inválido.', 10
    msg_error_2_len equ $-msg_error_2
    msg_error_3     db 'ERROR: No se pudo leer el archivo.', 10
    msg_error_3_len equ $-msg_error_3
    msg_error_4     db 'ERROR: Nombre de archivo inválido.', 10
    msg_error_4_len equ $-msg_error_4
    newline         db 10

section .bss
    filename    resb 256        ; Buffer para el nombre del archivo
    filecontent resb 2048       ; Buffer para el contenido del archivo
    fd          resq 1          ; Descriptor de archivo
    temp_buffer resb 1          ; Buffer temporal para lectura adicional
    buf_len     resq 1          ; Cantidad de bytes leídos del archivo
    word_ptrs   resq 512        ; Punteros a palabras encontradas
    word_count  resq 1          ; Número de palabras
    num_buffer  resb 20         ; Buffer para número convertido a texto

section .text
    global _start

; ======================================================
;                PROGRAMA PRINCIPAL
; ======================================================
_start:
    ; --- Paso 1: Leer nombre del archivo ---
    call print_initial_msg
    call read_filename

    ; --- Paso 2: Abrir archivo ---
    call open_file

    ; --- Paso 3: Leer contenido del archivo ---
    call read_file_content

    ; --- Paso 4: Contar palabras ---
    call count_words
    call print_word_count

    ; --- Paso 5: Analizar, ordenar e imprimir palabras ---
    call parse_words
    call bubble_sort_words
    call print_sorted_words

    ; --- Paso 6: Cerrar archivo y terminar programa ---
    call close_file
    call exit

; ======================================================
;      LECTURA Y MANEJO DE ARCHIVO (Entrada/Salida)
; ======================================================

; ------------------------------------------------------
; read_filename: Lee el nombre del archivo desde stdin.
; Si hay error, imprime mensaje y termina.
; ------------------------------------------------------
read_filename:
    mov   rax, 0         ; syscall: read
    mov   rdi, 0         ; fd: stdin
    mov   rsi, filename  ; buffer destino
    mov   rdx, 256       ; tamaño máximo
    syscall
    cmp   rax, 1         ; Debe ser al menos 2 (nombre + \n), 1 es solo \n
    jle   error_filename
    dec   rax            ; Eliminar el salto de línea
    mov   byte [filename + rax], 0
    ret

; Manejo de error: nombre de archivo inválido
error_filename:
    mov   rax, 1
    mov   rdi, 1
    mov   rsi, msg_error_4
    mov   rdx, msg_error_4_len
    syscall
    call exit_fail

; ------------------------------------------------------
; open_file: Abre el archivo cuyo nombre está en [filename].
; Deja el descriptor en [fd]. Si hay error, termina.
; ------------------------------------------------------
open_file:
    mov   rax, 2           ; syscall: open (O_RDONLY)
    mov   rdi, filename
    mov   rsi, 0
    syscall
    cmp   rax, 0
    jl    exit_error
    mov   [fd], rax
    ret

; ------------------------------------------------------
; read_file_content: Lee hasta 1024 bytes del archivo abierto en [fd].
; Si hay más datos, lee un byte extra para checar límite.
; Si hay error, imprime mensaje y termina.
; ------------------------------------------------------
read_file_content:
    mov rax, 0             ; syscall: read
    mov rdi, [fd]          ; fd del archivo abierto
    mov rsi, filecontent   ; buffer de destino
    mov rdx, 1024          ; leer hasta 1024 bytes
    syscall

    cmp rax, 0
    jle error_read         ; Si no se pudo leer, error

    mov r12, rax
    mov [buf_len], r12
    cmp r12, 1024
    jl .ok_len             ; Si lee menos de 1024, está bien

    ; Verificar si hay contenido adicional (overflow)
    mov rax, 0
    mov rdi, [fd]
    mov rsi, temp_buffer
    mov rdx, 1
    syscall
    cmp rax, 0
    jle error_len
    jmp error_len

.ok_len:
    ret

; Manejo de error: No se pudo leer el archivo
error_read:
    call close_file_if_open
    mov   rax, 1
    mov   rdi, 1
    mov   rsi, msg_error_3
    mov   rdx, msg_error_3_len
    syscall
    call exit_fail

; ======================================================
;           PROCESAMIENTO DE PALABRAS
; ======================================================

; ------------------------------------------------------
; count_words: Cuenta el número de palabras en [filecontent]
; Resultado en [word_count]
; ------------------------------------------------------
count_words:
    mov qword [word_count], 0   ; Inicializar contador
    mov rcx, 0                  ; Índice de recorrido
    mov r13b, 1                 ; Flag: último caracter fue separador

.count_loop:
    cmp rcx, r12
    jge .count_done
    mov al, [filecontent + rcx]

    ; Verificar si es letra (A-Z, a-z)
    cmp al, 'A'
    jl .non_letter
    cmp al, 'Z'
    jle .letter
    cmp al, 'a'
    jl .non_letter
    cmp al, 'z'
    jg .non_letter

.letter:
    mov r13b, 0
    jmp .next_char

.non_letter:
    cmp r13b, 0
    jne .skip_count
    inc qword [word_count]
.skip_count:
    mov r13b, 1
.next_char:
    inc rcx
    jmp .count_loop

.count_done:
    cmp r13b, 0
    jne .skip_last
    inc qword [word_count]
.skip_last:
    ret

; ------------------------------------------------------
; print_word_count: Imprime el número de palabras encontradas
; ------------------------------------------------------
print_word_count:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_2
    mov rdx, msg_2_len
    syscall

    ; Convertir número a texto
    mov rax, [word_count]
    lea rdi, [num_buffer + 19]
    mov byte [rdi], 0
    mov rbx, 10
.convert_loop:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    test rax, rax
    jnz .convert_loop

    ; Calcular longitud del número convertido
    mov r8, rdi
    mov r9, num_buffer + 19
    sub r9, r8
    mov rdx, r9

    ; Imprimir número
    mov rax, 1
    mov rdi, 1
    mov rsi, r8
    syscall

    ; Imprimir salto de línea
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

; ------------------------------------------------------
; parse_words: Separa el buffer en palabras y guarda punteros
; ------------------------------------------------------
parse_words:
    xor   rcx, rcx          ; Índice buffer
    xor   rbx, rbx          ; Contador palabras
    mov   r8, filecontent   ; Puntero actual

.parse_loop:
    cmp   rcx, [buf_len]
    jge   .parse_done
    mov   al, [filecontent + rcx]
    ; ¿Es separador? (espacio, tab, salto de línea)
    cmp   al, ' '
    je    .set_null
    cmp   al, 9
    je    .set_null
    cmp   al, 10
    je    .set_null

    ; Si es inicio de palabra, guardar puntero
    cmp   r8, filecontent
    je    .save_ptr
    cmp   byte [r8 - 1], 0
    jne   .continue
.save_ptr:
    mov   [word_ptrs + rbx*8], r8
    inc   rbx
    jmp   .continue
.set_null:
    mov   byte [filecontent + rcx], 0
.continue:
    inc   rcx
    inc   r8
    jmp   .parse_loop

.parse_done:
    mov   [word_count], rbx
    ret

; ------------------------------------------------------
; bubble_sort_words: Ordena alfabéticamente los punteros de las palabras
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
; print_sorted_words: Imprime las palabras ordenadas una por línea
; ------------------------------------------------------
print_sorted_words:
    ; Imprimir encabezado
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_3
    mov rdx, msg_3_len
    syscall

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
; strcmp: Compara dos cadenas terminadas en null
; rdi=string1, rdx=string2. rax<0 si str1<str2, >0 si str1>str2, 0 si iguales
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
; print_string: Imprime en pantalla una cadena terminada en null
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
; print_initial_msg: Imprime el mensaje inicial
; ------------------------------------------------------
print_initial_msg:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_1
    mov rdx, msg_1_len
    syscall
    ret

; ------------------------------------------------------
; print_newline: Imprime un salto de línea
; ------------------------------------------------------
print_newline:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

; ------------------------------------------------------
; close_file_if_open: Cierra el archivo solo si el descriptor es válido (>0)
; ------------------------------------------------------
close_file_if_open:
    mov rax, [fd]
    cmp rax, 0
    jle .done
    mov rdi, rax
    mov rax, 3
    syscall
    mov qword [fd], 0
.done:
    ret

; ------------------------------------------------------
; close_file: Cierra el archivo si está abierto
; ------------------------------------------------------
close_file:
    mov rax, [fd]
    cmp rax, 0
    jle .done
    mov rdi, rax
    mov rax, 3
    syscall
    mov qword [fd], 0
.done:
    ret

; ------------------------------------------------------
; exit_error: Imprime mensaje y termina si no se pudo abrir el archivo
; ------------------------------------------------------
exit_error:
    call close_file_if_open
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_error_1
    mov rdx, msg_error_1_len
    syscall
    call exit_fail

; ------------------------------------------------------
; error_len: Imprime mensaje y termina si longitud excede el máximo
; ------------------------------------------------------
error_len:
    call close_file_if_open
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_error_2
    mov rdx, msg_error_2_len
    syscall
    call exit_fail

; ------------------------------------------------------
; exit: Termina el programa exitosamente (código 0)
; exit_fail: Termina el programa con error (código 1)
; ------------------------------------------------------
exit:
    mov   rax, 60
    xor   rdi, rdi
    syscall

exit_fail:
    mov   rax, 60
    mov   rdi, 1
    syscall