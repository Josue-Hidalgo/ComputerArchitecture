.data
    msg_prompt: .asciz "Cual es el archivo que desea abrir: "
    msg_promt_len = . - msg_prompt  @ Longitud del mensaje de prompt
    msg_count: .asciz "Numero de palabras: "
    msg_count_len = . - msg_count   @ Longitud del mensaje para el conteo de palabras
    msg_lenght_error: .asciz "La longitud de caracteres supera el limite."
    msg_lenght_error_len = . - msg_lenght_error  @ Longitud del mensaje de error
    newline: .asciz "\n"  @ Nueva línea para separar salidas

.bss
    .lcomm filename, 256       @ Espacio para el nombre del archivo (256 bytes)
    .lcomm filecontent, 1024   @ Buffer para el contenido del archivo (1024 bytes)
    .lcomm fd, 4               @ Descriptor de archivo
    .lcomm word_count, 4       @ Contador de palabras
    .lcomm num_buffer, 20      @ Buffer para almacenar el número convertido a texto
    .lcomm temp_buffer, 1      @ Buffer temporal para verificar longitud

.text
.global _start

_start:
    @ ===== IMPRIMIR EL PROMPT =====
    mov r0, #1              @ stdout
    ldr r1, =msg_prompt     @ Dirección del mensaje
    ldr r2, =msg_promt_len  @ Longitud del mensaje
    mov r7, #4              @ syscall: sys_write
    swi #0

    @ ===== LEER EL NOMBRE DEL ARCHIVO =====
    mov r0, #0          @ stdin
    ldr r1, =filename   @ Dirección donde se almacenará el nombre del archivo
    mov r2, #256        @ Máxima longitud permitida
    mov r7, #3          @ syscall: sys_read
    swi #0

    @ ===== PROCESAR EL NOMBRE DEL ARCHIVO =====
    cmp r0, #0          @ ¿Se leyó algo?
    ble _exit_error     @ Si no, salir con error

    sub r0, r0, #1      @ Ajustar longitud para eliminar el salto de línea
    ldr r1, =filename   @ Dirección del buffer
    mov r2, #0
    strb r2, [r1, r0]   @ Reemplazar el salto de línea con un terminador nulo

    @ ===== ABRIR EL ARCHIVO =====
    ldr r0, =filename   @ Nombre del archivo
    mov r1, #0          @ Modo de apertura: lectura (0_RDONLY)
    mov r7, #5          @ syscall: sys_open
    swi #0

    cmp r0, #0          @ ¿Se pudo abrir el archivo?
    blt _exit_error     @ Si no, salir con error

    ldr r1, =fd         @ Guardar el descriptor del archivo
    str r0, [r1]

    @ ===== LEER EL CONTENIDO DEL ARCHIVO =====
    ldr r0, [r1]            @ Descriptor del archivo
    ldr r1, =filecontent    @ Buffer donde se almacenará el contenido
    mov r2, #1024           @ Tamaño máximo de lectura
    mov r7, #3              @ syscall: sys_read
    swi #0

    @ ===== VERIFICAR LA LONGITUD DEL CONTENIDO =====
    mov r4, r0          @ Guardar la cantidad de bytes leídos
    cmp r4, #1024       @ ¿El contenido cabe en el buffer?
    blt valid_length    @ Si es menor, continuar

    @ Leer un byte extra para verificar si hay más contenido
    ldr r0, =fd             @ Descriptor del archivo
    ldr r0, [r0]
    ldr r1, =temp_buffer    @ Buffer temporal
    mov r2, #1              @ Leer 1 byte
    mov r7, #3              @ syscall: sys_read
    swi #0

    cmp r0, #0          @ ¿Hay más bytes?
    bgt _length_error   @ Si hay más, error de longitud

valid_length:
    @ ===== IMPRIMIR EL CONTENIDO DEL ARCHIVO =====
    mov r2, r4              @ Número de bytes leídos
    mov r0, #1              @ stdout
    ldr r1, =filecontent    @ Dirección del contenido
    mov r7, #4              @ syscall: sys_write
    swi #0

    @ ===== CONTAR PALABRAS =====
    ldr r0, =word_count @ Dirección del contador de palabras
    mov r1, #0          @ Inicializar contador en 0
    str r1, [r0]

    mov r5, #0          @ Índice para recorrer el contenido
    mov r6, #1          @ Flag: 1 si el último carácter era un espacio o puntuación

count_loop:
    cmp r5, r4          @ ¿Hemos procesado todos los bytes?
    bge print_count     @ Si sí, imprimir el resultado

    ldr r0, =filecontent
    ldrb r0, [r0, r5]   @ Leer un byte del contenido

    @ ===== IGNORAR CARACTERES NO VÁLIDOS =====
    cmp r0, #'a'        @ ¿Es una letra minúscula?
    bge valid_char      @ Si es mayor o igual a 'a', puede ser válido
    cmp r0, #'A'        @ ¿Es una letra mayúscula?
    bge valid_char      @ Si es mayor o igual a 'A', puede ser válido
    cmp r0, #'0'        @ ¿Es un número?
    bge valid_char      @ Si es mayor o igual a '0', puede ser válido

    @ Verificar signos de puntuación permitidos
    cmp r0, #32         @ Espacio (ASCII 32)
    beq valid_char
    cmp r0, #46         @ Punto (.)
    beq valid_char
    cmp r0, #44         @ Coma (,)
    beq valid_char
    cmp r0, #59         @ Punto y coma (;)
    beq valid_char
    cmp r0, #58         @ Dos puntos (:)
    beq valid_char
    cmp r0, #33         @ Signo de exclamación (!)
    beq valid_char
    cmp r0, #63         @ Signo de interrogación (?)
    beq valid_char
    cmp r0, #40         @ Paréntesis abierto (()
    beq valid_char
    cmp r0, #41         @ Paréntesis cerrado ())
    beq valid_char
    cmp r0, #91         @ Corchete abierto ([)
    beq valid_char
    cmp r0, #93         @ Corchete cerrado (])
    beq valid_char
    cmp r0, #123        @ Llave abierta ({)
    beq valid_char
    cmp r0, #125        @ Llave cerrada (})
    beq valid_char
    cmp r0, #34         @ Comillas dobles (")
    beq valid_char
    cmp r0, #39         @ Comillas simples (')
    beq valid_char
    cmp r0, #45         @ Guion (-)
    beq valid_char

    @ Si no es válido, saltar al siguiente carácter
    b next_char

valid_char:
    @ Verificar si es un delimitador
    cmp r0, #32         @ Espacio (ASCII 32)
    beq is_delimiter
    cmp r0, #46         @ Punto (.)
    beq is_delimiter
    cmp r0, #44         @ Coma (,)
    beq is_delimiter
    cmp r0, #59         @ Punto y coma (;)
    beq is_delimiter
    cmp r0, #58         @ Dos puntos (:)
    beq is_delimiter
    cmp r0, #33         @ Signo de exclamación (!)
    beq is_delimiter
    cmp r0, #63         @ Signo de interrogación (?)
    beq is_delimiter
    cmp r0, #40         @ Paréntesis abierto (()
    beq is_delimiter
    cmp r0, #41         @ Paréntesis cerrado ())
    beq is_delimiter
    cmp r0, #91         @ Corchete abierto ([)
    beq is_delimiter
    cmp r0, #93         @ Corchete cerrado (])
    beq is_delimiter
    cmp r0, #123        @ Llave abierta ({)
    beq is_delimiter
    cmp r0, #125        @ Llave cerrada (})
    beq is_delimiter
    cmp r0, #34         @ Comillas dobles (")
    beq is_delimiter
    cmp r0, #39         @ Comillas simples (')
    beq is_delimiter
    cmp r0, #45         @ Guion (-)
    beq is_delimiter

    mov r6, #0          @ No es delimitador, estamos en una palabra
    b next_char

is_delimiter:
    tst r6, r6          @ Verificar si el último carácter era delimitador
    bne next_char       @ Si sí, no contar como nueva palabra

    ldr r0, =word_count @ Incrementar el contador de palabras
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    mov r6, #1          @ Actualizar flag como delimitador

next_char:
    add r5, r5, #1      @ Avanzar al siguiente byte
    
    b count_loop
    
    print_count:
    @ ===== IMPRIMIR EL NÚMERO DE PALABRAS =====
    cmp r6, #0          @ ¿El último carácter era parte de una palabra?
    bne skip_last       @ Si no, no ajustar el contador

    ldr r0, =word_count
    ldr r1, [r0]
    add r1, r1, #1      @ Incrementar una palabra extra al final
    str r1, [r0]

skip_last:
    mov r0, #1          @ stdout
    ldr r1, =msg_count  @ Mensaje de "Número de palabras"
    ldr r2, =msg_count_len
    mov r7, #4          @ syscall: sys_write
    swi #0

    @ Convertir el número de palabras a string
    ldr r0, =word_count
    ldr r0, [r0]        @ Cargar el número de palabras
    ldr r1, =num_buffer
    add r1, r1, #19     @ Posicionar al final del buffer
    mov r2, #0          @ Null terminator
    strb r2, [r1]
    mov r3, #10         @ Base decimal

convert_loop:
    sub r1, r1, #1      @ Mover hacia atrás en el buffer
    mov r2, r0
    udiv r2, r0, r3     @ Cociente
    mls r0, r2, r3, r0  @ Residuo
    add r0, r0, #'0'    @ Convertir número a carácter ASCII
    strb r0, [r1]
    mov r0, r2          @ Actualizar el cociente
    cmp r0, #0
    bne convert_loop    @ Repetir mientras el cociente no sea 0

    @ Calcular longitud del número convertido
    ldr r2, =num_buffer
    add r2, r2, #19
    sub r2, r2, r1
    mov r3, r2

    @ Imprimir el número de palabras
    mov r0, #1
    mov r2, r3
    mov r7, #4
    swi #0

    @ Imprimir nueva línea
    mov r0, #1
    ldr r1, =newline
    mov r2, #1
    mov r7, #4
    swi #0

    @ ===== CERRAR ARCHIVO Y SALIR =====
    ldr r0, =fd
    ldr r0, [r0]
    mov r7, #6          @ syscall: sys_close
    swi #0

    mov r0, #0          @ status 0 (éxito)
    mov r7, #1          @ syscall: sys_exit
    swi #0

_length_error:
    @ ===== IMPRIMIR ERROR DE LONGITUD =====
    mov r0, #1          @ stdout
    ldr r1, =msg_lenght_error
    ldr r2, =msg_lenght_error_len
    mov r7, #4          @ syscall: sys_write
    swi #0

    @ Cierre del archivo y salida con error
    ldr r0, =fd
    ldr r0, [r0]
    mov r7, #6          @ syscall: sys_close
    swi #0

    mov r0, #1          @ status 1 (error)
    mov r7, #1          @ syscall: sys_exit
    swi #0

_exit_error:
    mov r0, #1          @ status 1 (error)
    mov r7, #1          @ syscall: sys_exit
    swi #0
