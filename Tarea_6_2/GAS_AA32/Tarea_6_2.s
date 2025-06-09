.data 
    
    msg_1:               .asciz "Introduzca el nombre al archivo de texto (max 2048 chars): "
    msg_1_len           = .- msg_1
    msg_2:               .asciz "El número de palabras encontradas es: "
    msg_2_len           = .- msg_2
    msg_3:               .asciz "Palabras ordenadas alfabéticamente (a-z): "
    msg_3_len           = .- msg_3
    
    msg_error_1:         .asciz "ERROR: No se pudo abrir el archivo."
    msg_error_1_len     = .- msg_error_1
    msg_error_2:         .asciz "ERROR: Número de caracteres inválido."
    msg_error_2_len     = .- msg_error_2
    msg_error_3:         .asciz "ERROR: No se pudo leer el archivo."
    msg_error_3_len     = .- msg_error_3
    msg_error_4:         .asciz "ERROR: Nombre de archivo inválido."
    msg_error_4_len     = .- msg_error_4
    
    newline:             .asciz "\n"

.bss
    .lcomm filename, 2048       @ Espacio para el nombre del archivo (2048 bytes)
    .lcomm filecontent, 4096    @ Buffer para el contenido del archivo (4096 bytes)
    .lcomm fd, 4                @ Descriptor de archivo
    .lcomm temp_buffer, 4       @ Buffer temporal para lectura adicional
    .lcomm buf_len, 4           @ Cantidad de bytes leídos del archivo
    .lcomm word_ptrs, 4096      @ Punteros a palabras encontradas
    .lcomm word_count, 4        @ Contador de palabras
    .lcomm num_buffer, 20       @ Buffer para almacenar el número convertido a texto

.text
.global _start

    @ ======================================================
    @                PROGRAMA PRINCIPAL
    @ ======================================================
_start:
        @ Paso 1: Imprimir mensaje inicial
        BL      print_initial_msg
        BL      print_newline
        BL      read_filename
        @ Paso 2: Abrir el archivo
        BL      open_file
        @ Paso 3: Leer el contenido del archivo
        BL      read_file_content
        @ Paso 4: Contar palabras
        BL      count_words
        BL      print_word_count
        @ Paso 5: Procesar palabras
        BL      parse_words
        BL      bubble_sort_words
        BL      print_sorted_words
        @ Paso 6: Cerrar el archivo
        BL      close_file
        BL      exit

    @ ======================================================
    @      LECTURA Y MANEJO DE ARCHIVO (Entrada/Salida)
    @ ======================================================

    @ ------------------------------------------------------
    @ read_filename: Lee el nombre del archivo desde stdin.
    @ Si hay error, imprime mensaje y termina.
    @ ------------------------------------------------------
read_filename:
        MOV     R7, #3                          @ syscall: read
        MOV     R0, #0                          @ fd: stdin
        LDR     R1, =filename                   @ buffer destino
        MOV     R2, #2048                       @ tamaño máximo
        SWI     0
        CMP     R0, #1                          @ Debe ser al menos 2 (nombre + \n)
        BLE     error_filename
        SUB     R0, R0, #1
        LDR     R1, =filename
        ADD     R1, R1, R0
        MOV     R2, #0
        STRB    R2, [R1]
        BX      LR

error_filename:
        MOV     R7, #4                        @ syscall: write
        MOV     R0, #1                        @ fd: stdout
        LDR     R1, =msg_error_4              @ puntero al mensaje
        LDR     R2, =msg_error_4_len          @ longitud del mensaje
        SWI     0
        BL      print_newline
        BL      exit_fail                     @ termina el programa con error

    @ ------------------------------------------------------
    @ open_file: Abre el archivo cuyo nombre está en [filename].
    @ Deja el descriptor en [fd]. Si hay error, termina.
    @ ------------------------------------------------------
open_file:
        MOV     R7, #5                          @ syscall: open (O_RDONLY)
        LDR     R0, =filename
        MOV     R1, #0
        SWI     0
        CMP     R0, #0
        BLT     exit_error
        LDR     R1, =fd
        STR     R0, [R1]
        BX      LR

    @ ------------------------------------------------------
    @ read_file_content: Lee hasta 4096 bytes del archivo abierto en [fd].
    @ Si hay más datos, lee un byte extra para checar límite.
    @ Si hay error, imprime mensaje y termina.
    @ ------------------------------------------------------
read_file_content:
        LDR     R1, =fd
        LDR     R0, [R1]                        @ fd del archivo abierto
        MOV     R7, #3                          @ syscall: read
        LDR     R1, =filecontent                @ buffer de destino
        MOV     R2, #4096                       @ leer hasta 4096 bytes
        SWI     0

        CMP     R0, #0
        BLE     error_read

        LDR     R2, =buf_len
        STR     R0, [R2]
        CMP     R0, #4096
        BLT     read_file_ok_len

        @ Verificar si hay contenido adicional (overflow)
        LDR     R1, =fd
        LDR     R0, [R1]
        MOV     R7, #3
        LDR     R1, =temp_buffer
        MOV     R2, #1
        SWI     0
        CMP     R0, #0
        BLE     error_len
        B       error_len

read_file_ok_len:
        BX      LR

    @ Manejo de error: No se pudo leer el archivo
error_read:
        BL      close_file_if_open                @ Cierra archivo si está abierto
        LDR     R0, =msg_error_3                  @ puntero al mensaje de error
        LDR     R1, =msg_error_3_len              @ longitud del mensaje
        BL      error_len                         @ imprime el mensaje de error
        BL      exit_fail                         @ termina el programa con error

    @ ======================================================
    @           PROCESAMIENTO DE PALABRAS
    @ ======================================================

    @ ------------------------------------------------------
    @ count_words: Cuenta el número de palabras en [filecontent]
    @ Resultado en [word_count]
    @ ------------------------------------------------------

count_words:
        LDR     R4, =word_count                 @ R4 = dirección de word_count
        MOV     R5, #0                          @ R5 = índice de recorrido (i = 0)
        MOV     R6, #1                          @ R6 = flag: último caracter fue separador (1 = sí)
        LDR     R7, =filecontent                @ R7 = dirección del buffer de archivo
        LDR     R8, =buf_len                    @ R8 = dirección de buf_len
        LDR     R9, [R8]                        @ R9 = cantidad de bytes leídos

        MOV     R10, #0                         @ R10 = contador de palabras (local, luego se guarda en word_count)

count_loop:
        CMP     R5, R9                          @ ¿Hemos llegado al final del buffer?
        BGE     count_done

        LDRB    R0, [R7, R5]                    @ R0 = filecontent[R5] (caracter actual)

        @ Verificar si es letra (A-Z, a-z)
        CMP     R0, #'A'
        BLT     non_letter
        CMP     R0, #'Z'
        BLE     is_letter
        CMP     R0, #'a'
        BLT     non_letter
        CMP     R0, #'z'
        BGT     non_letter

is_letter:
        MOV     R6, #0                          @ Último caracter ya no es separador
        B       next_char

non_letter:
        CMP     R6, #0
        BNE     skip_count
        ADD     R10, R10, #1                    @ Contador de palabras++
skip_count:
        MOV     R6, #1                          @ Ahora último caracter es separador
next_char:
        ADD     R5, R5, #1                      @ i++
        B       count_loop

count_done:
        CMP     R6, #0
        BNE     skip_last
        ADD     R10, R10, #1                    @ Si terminó en letra, cuenta palabra final
skip_last:
        STR     R10, [R4]                       @ Guarda resultado en word_count
        BX      LR

    @ ------------------------------------------------------
    @ print_word_count: Imprime el número de palabras encontradas
    @ ------------------------------------------------------
print_word_count:
        @ Imprimir mensaje inicial
        MOV     R7, #4                             @ syscall: write
        MOV     R0, #1                             @ fd: stdout
        LDR     R1, =msg_2                         @ puntero al mensaje
        LDR     R2, =msg_2_len                     @ longitud del mensaje
        SWI     0

        BL      print_newline

        @ Convertir el número a texto (decimal, termina en null)
        LDR     R3, =word_count                    @ R3 = dirección de word_count
        LDR     R4, [R3]                           @ R4 = número de palabras
        LDR     R5, =num_buffer                    @ R5 = buffer para número
        ADD     R6, R5, #19                        @ R6 = puntero al final del buffer
        MOV     R7, #0
        STRB    R7, [R6]                           @ null terminator

        MOV     R7, #10                            @ divisor (decimal)
        MOV     R8, R4                             @ copia del número a convertir
        MOV     R9, R6                             @ puntero de escritura

convert_loop:
        SUB     R9, R9, #1                         @ avanzar hacia atrás en el buffer
        MOV     R1, #0
        UDIV    R2, R8, R7                         @ R2 = R8 / 10
        MLS     R1, R2, R7, R8                     @ R1 = R8 - (R2 * 10) (resto)
        ADD     R1, R1, #'0'                       @ convertir a carácter ASCII
        STRB    R1, [R9]
        MOV     R8, R2                             @ actualizar número a dividir
        CMP     R8, #0
        BNE     convert_loop

        @ Calcular longitud del número convertido
        ADD     R10, R5, #19                       @ puntero final del buffer
        SUB     R2, R10, R9                        @ longitud = fin - inicio

        @ Imprimir el número convertido
        MOV     R7, #4                             @ syscall: write
        MOV     R0, #1                             @ fd: stdout
        MOV     R1, R9                             @ puntero al inicio del número
        SWI     0

        BL      print_newline

        BX      LR
    


@ ------------------------------------------------------
@ Agregar Abajo lógica para procesar palabras e imprimir en orden alfabético
@ ------------------------------------------------------


@ ------------------------------------------------------
@ parse_words: Separa el buffer en palabras y guarda punteros
@ ------------------------------------------------------
parse_words:
        MOV     R4, #0                  @ Índice buffer
        MOV     R5, #0                  @ Contador palabras
        LDR     R9, =filecontent        @ Base de filecontent
        ADD     R6, R9, #0              @ Puntero actual = inicio de filecontent
        LDR     R7, =buf_len
        LDR     R7, [R7]                @ buf_len

parse_loop:
        CMP     R4, R7                  @ ¿fin del buffer?
        BGE     parse_done

        LDRB    R0, [R9, R4]            @ al = filecontent[rcx]

        @ Es separador (espacio, tab, salto de línea)?
        CMP     R0, #' '
        BEQ     set_null
        CMP     R0, #9
        BEQ     set_null
        CMP     R0, #10
        BEQ     set_null

        @ Si es inicio de palabra, guardar puntero
        CMP     R6, R9                  @ ¿Es el inicio absoluto del buffer?
        BEQ     save_ptr_check
        LDRB    R1, [R6, #-1]           @ ¿El anterior era 0?
        CMP     R1, #0
        BNE     not_word_start
save_ptr_check:
        LDR     R2, =word_ptrs
        ADD     R2, R2, R5, LSL #2      @ word_ptrs + rbx*4
        STR     R6, [R2]                @ Guardar puntero a palabra
        ADD     R5, R5, #1              @ contador palabras++
not_word_start:
        ADD     R4, R4, #1              @ rcx++
        ADD     R6, R6, #1              @ puntero++
        B       parse_loop

set_null:
        STRB    R1, [R9, R4]            @ poner 0 en filecontent[rcx]
        MOV     R1, #0
        ADD     R4, R4, #1
        ADD     R6, R6, #1
        B       parse_loop

parse_done:
        LDR     R2, =word_count
        STR     R5, [R2]                @ Guardar número de palabras encontradas
        BX      LR

@ ------------------------------------------------------
@ bubble_sort_words: Ordena alfabéticamente los punteros de las palabras
@ ------------------------------------------------------
bubble_sort_words:
        LDR     R0, =word_count
        LDR     R1, [R0]
        SUBS    R1, R1, #1              @ rcx = word_count - 1
        BLT     bubble_done

bubble_outer:
        MOV     R2, #0                  @ rsi = 0
bubble_inner:
        CMP     R2, R1
        BGE     bubble_end_inner
        LDR     R3, =word_ptrs
        ADD     R4, R3, R2, LSL #2      @ word_ptrs + rsi*4
        LDR     R5, [R4]                @ rdi = word_ptrs[rsi]
        ADD     R6, R4, #4              @ word_ptrs + (rsi+1)*4
        LDR     R7, [R6]                @ rdx = word_ptrs[rsi+1]
        MOV     R0, R5
        MOV     R1, R7
        BL      strcmp_arm              @ strcmp(rdi, rdx)
        CMP     R0, #0
        BLE     bubble_no_swap
        @ Intercambiar punteros
        LDR     R8, [R4]
        LDR     R9, [R6]
        STR     R9, [R4]
        STR     R8, [R6]
bubble_no_swap:
        ADD     R2, R2, #1
        B       bubble_inner
bubble_end_inner:
        SUBS    R1, R1, #1
        BPL     bubble_outer
bubble_done:
        BX      LR

@ ------------------------------------------------------
@ print_sorted_words: Imprime las palabras ordenadas una por línea
@ ------------------------------------------------------
print_sorted_words:
        @ Imprimir encabezado
        MOV     R7, #4
        MOV     R0, #1
        LDR     R1, =msg_3
        LDR     R2, =msg_3_len
        SWI     0

        BL      print_newline

        MOV     R4, #0                      @ rsi = 0
        LDR     R5, =word_count
        LDR     R5, [R5]
print_words_loop:
        CMP     R4, R5
        BGE     print_words_done
        LDR     R6, =word_ptrs
        ADD     R6, R6, R4, LSL #2          @ word_ptrs + rsi*4
        LDR     R7, [R6]                    @ rdi = word_ptrs[rsi]
        MOV     R0, R7
        BL      print_string_arm            @ print_string(rdi)
        BL      print_newline
        ADD     R4, R4, #1
        B       print_words_loop
print_words_done:
        BX      LR

@ ======================================================
@           SUBRUTINAS DE UTILIDAD
@ ======================================================

@ ------------------------------------------------------
@ strcmp_arm: Compara dos cadenas terminadas en null
@ Entradas: R0=puntero1, R1=puntero2
@ Salida:   R0 < 0 si str1<str2, >0 si str1>str2, 0 si iguales
@ ------------------------------------------------------
strcmp_arm:
        PUSH    {R2, R3}
strcmp_loop:
        LDRB    R2, [R0], #1
        LDRB    R3, [R1], #1
        CMP     R2, R3
        BNE     strcmp_diff
        CMP     R2, #0
        BEQ     strcmp_equal
        B       strcmp_loop
strcmp_diff:
        SUB     R0, R2, R3
        POP     {R2, R3}
        BX      LR
strcmp_equal:
        MOV     R0, #0
        POP     {R2, R3}
        BX      LR

@ ------------------------------------------------------
@ print_string_arm: Imprime en pantalla una cadena terminada en null
@ Entrada: R0 = puntero a string
@ ------------------------------------------------------

print_string_arm:
        PUSH    {R1, R2, R3, LR}
        MOV     R1, R0                @ R1 = inicio del string
        MOV     R2, #0                @ R2 = contador de longitud
print_strlen_loop:
        LDRB    R3, [R1, R2]
        CMP     R3, #0
        BEQ     print_strlen_done
        ADD     R2, R2, #1
        B       print_strlen_loop
print_strlen_done:
        MOV     R7, #4
        MOV     R0, #1                @ fd=stdout
        MOV     R1, R1                @ puntero string
        MOV     R2, R2                @ longitud string
        SWI     0
        POP     {R1, R2, R3, PC}

@ ------------------------------------------------------
@ Agregar Arriba para procesar palabras e imprimir en orden alfabético
@ ------------------------------------------------------



    @ ------------------------------------------------------
    @ print_initial_msg: Imprime el mensaje inicial
    @ ------------------------------------------------------
print_initial_msg:
        MOV     R7, #4                        @ syscall: write
        MOV     R0, #1                        @ fd: stdout
        LDR     R1, =msg_1                    @ puntero al mensaje
        LDR     R2, =msg_1_len                @ longitud del mensaje
        SWI     0
        BX      LR

    @ ------------------------------------------------------
    @ print_newline: Imprime un salto de línea
    @ ------------------------------------------------------
print_newline:
        MOV     R7, #4                        @ syscall: write
        MOV     R0, #1                        @ fd: stdout
        LDR     R1, =newline                  @ puntero al salto de línea
        MOV     R2, #1                        @ longitud 1
        SWI     0
        BX      LR

    @ ------------------------------------------------------
    @ close_file_if_open: Cierra el archivo solo si el descriptor es válido (>0)
    @ ------------------------------------------------------
close_file_if_open:
        LDR     R1, =fd                       @ R1 = dirección de fd
        LDR     R0, [R1]                      @ R0 = valor de fd
        CMP     R0, #0
        BLT     close_file_if_open_done       @ Si fd <= 0, salir
        MOV     R7, #6                        @ syscall: close
        SWI     0
        MOV     R0, #0
        STR     R0, [R1]                      @ fd = 0
close_file_if_open_done:
        BX      LR

            @ ------------------------------------------------------
    @ close_file: Cierra el archivo si está abierto
    @ ------------------------------------------------------
close_file:
        LDR     R1, =fd                       @ R1 = dirección de fd
        LDR     R0, [R1]                      @ R0 = fd
        CMP     R0, #0
        BLE     close_file_done               @ Si fd <= 0, salir
        MOV     R7, #6                        @ syscall: close (ARM32)
        SWI     0
        MOV     R0, #0
        STR     R0, [R1]                      @ fd = 0
close_file_done:
        BX      LR

    @ ------------------------------------------------------
    @ exit_error: Imprime mensaje y termina si no se pudo abrir el archivo
    @ ------------------------------------------------------
exit_error:
        BL      close_file_if_open
        MOV     R7, #4                        @ syscall: write
        MOV     R0, #1                        @ fd: stdout
        LDR     R1, =msg_error_1              @ puntero al mensaje
        LDR     R2, =msg_error_1_len          @ longitud
        SWI     0
        BL      exit_fail

    @ ------------------------------------------------------
    @ error_len: Imprime mensaje y termina si longitud excede el máximo
    @ ------------------------------------------------------
error_len:
        BL      close_file_if_open
        MOV     R7, #4                        @ syscall: write
        MOV     R0, #1                        @ fd: stdout
        LDR     R1, =msg_error_2              @ puntero al mensaje
        LDR     R2, =msg_error_2_len          @ longitud
        SWI     0
        BL      exit_fail

    @ ------------------------------------------------------
    @ exit: Termina el programa exitosamente (código 0)
    @ exit_fail: Termina el programa con error (código 1)
    @ ------------------------------------------------------

exit:
        MOV     R7, #1                        @ syscall: exit (ARM32 ABI)
        MOV     R0, #0                        @ código de salida 0
        SWI     0

exit_fail:
        MOV     R7, #1                        @ syscall: exit (ARM32 ABI)
        MOV     R0, #1                        @ código de salida 1
        SWI     0