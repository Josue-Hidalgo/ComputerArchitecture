    .data
msj_0:      .asciz "Seleccione una Opción: \n"
msj_1:      .asciz "a. Hola Mundo!!!\n"
msj_1_1:    .asciz "Hola Mundo!!!\n"
msj_2:      .asciz "b. Feliz Día del Amor y la Amistad!!!\n"
msj_2_1:    .asciz "Feliz Día del Amor y la Amistad!!!\n"
msj_3:      .asciz "c. Feliz Navidad!!!\n"
msj_3_1:    .asciz "Feliz Navidad!!!\n"
msj_4:      .asciz "d. Feliz Día de la Independencia!!!\n"
msj_4_1:    .asciz "Feliz Día de la Independencia!!!\n"
msj_5:      .asciz "e. Otro (ingrese su propio mensaje).\n"
msj_5_1:    .asciz "Otro (ingrese su propio mensaje).\n"
msj_6:      .asciz "f. Finalizar el Programa.\n"
msj_7:      .asciz "Opción no válida. Intente de nuevo.\n"
salto_linea:.asciz "\n"

    .bss
    .align 4
buffer: .skip 100

    .text
    .global _start

_start:
    bl getOptionAndExecute
    bl exit

printMenu:
    push {lr}
    ldr r0, =msj_0
    bl print_str
    ldr r0, =msj_1
    bl print_str
    ldr r0, =msj_2
    bl print_str
    ldr r0, =msj_3
    bl print_str
    ldr r0, =msj_4
    bl print_str
    ldr r0, =msj_5
    bl print_str
    ldr r0, =msj_6
    bl print_str
    pop {pc}

printEnter:
    push {lr}
    ldr r0, =salto_linea
    bl print_str
    pop {pc}

printError:
    push {lr}
    ldr r0, =msj_7
    bl print_str
    pop {pc}

option_a:
    ldr r0, =msj_1_1
    bl print_str
    b getOptionAndExecute

option_b:
    ldr r0, =msj_2_1
    bl print_str
    b getOptionAndExecute

option_c:
    ldr r0, =msj_3_1
    bl print_str
    b getOptionAndExecute

option_d:
    ldr r0, =msj_4_1
    bl print_str
    b getOptionAndExecute

option_e:
    ldr r0, =msj_5_1
    bl print_str

    /* Leer mensaje personalizado */
    ldr r0, =buffer     /* buffer destino */
    mov r1, #100        /* máximo a leer */
    bl read_line        /* retorna en r1: longitud real */

    /* Quitar salto de línea si lo hay */
    cmp r1, #0
    beq print_user_msg
    ldr r2, =buffer
    add r2, r2, r1
    sub r2, r2, #1
    ldrb r3, [r2]
    cmp r3, #10         /* 10 = '\n' */
    bne print_user_msg
    mov r3, #0
    strb r3, [r2]
    sub r1, r1, #1      /* longitud-- */

print_user_msg:
    ldr r0, =buffer
    mov r2, r1
    bl write_stdout

    bl printEnter
    b getOptionAndExecute

option_f:
    b exit

getOptionAndExecute:
    bl printEnter
    bl printMenu

    /* Leer opción del usuario (hasta 10 bytes) */
    ldr r0, =buffer
    mov r1, #10
    bl read_line        /* longitud en r1 */

    /* Buscar primer caracter útil */
    ldr r2, =buffer
    mov r3, r1

find_option_loop:
    cmp r3, #0
    beq invalid_option
    ldrb r4, [r2]
    cmp r4, #10         /* '\n' */
    beq skip_invalid
    cmp r4, #13         /* '\r' */
    beq skip_invalid
    cmp r4, #' '
    beq skip_invalid

    /* Procesar */
    cmp r4, #'a'
    beq option_a
    cmp r4, #'b'
    beq option_b
    cmp r4, #'c'
    beq option_c
    cmp r4, #'d'
    beq option_d
    cmp r4, #'e'
    beq option_e
    cmp r4, #'f'
    beq option_f

invalid_option:
    bl printError
    b getOptionAndExecute

skip_invalid:
    add r2, r2, #1
    sub r3, r3, #1
    b find_option_loop

/* --- Utilidades para IO --- */

/* Imprime string cero-terminado en r0 */
print_str:
    push {r1, r2, lr}
    mov r1, r0
    mov r2, #0
count_strlen:
    ldrb r3, [r1, r2]
    cmp r3, #0
    beq print_str_len
    add r2, r2, #1
    b count_strlen
print_str_len:
    mov r1, r0
    mov r0, #1      /* stdout */
    mov r7, #4      /* sys_write */
    svc 0
    pop {r1, r2, pc}

/* Escribe r2 bytes desde r0 a stdout */
write_stdout:
    push {lr}
    mov r1, r0
    mov r0, #1      /* stdout */
    mov r7, #4      /* sys_write */
    svc 0
    pop {pc}

/* Lee hasta r1 bytes a buffer en r0, retorna longitud en r1 */
read_line:
    push {r2, r3, lr}
    mov r2, r1
    mov r1, r0
    mov r0, #0      /* stdin */
    mov r7, #3      /* sys_read */
    svc 0
    mov r1, r0      /* devuelve longitud en r1 */
    pop {r2, r3, pc}

/* Sale del programa */
exit:
    mov r7, #1      /* sys_exit */
    mov r0, #0
    svc 0