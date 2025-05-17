.data
    msg_inicial:
        .asciz "Escriba 2 numeros que se puedan representar en 32 bits\n"
    len_msg_inicial = . - msg_inicial

    msg_suma:
        .asciz "El resultado de la suma es: "
    len_msg_suma = . - msg_suma

    msg_resta:
        .asciz "El resultado de la resta es: "
    len_msg_resta = . - msg_resta

    msg_base:
        .asciz "Base "
    len_msg_base = . - msg_base

    msg_error:
        .asciz "Error: Entrada invalida.\n"
    len_msg_error = . - msg_error

    msg_continuar:
        .asciz "Quiere ingresar los numeros nuevamente? (S/N)\n"
    len_msg_continuar = . - msg_continuar

    newline:
        .asciz "\n"
    len_newline = . - newline

.section .bss
    .lcomm strNum1, 4        @ 32-bit int
    .lcomm strNum2, 4        @ 32-bit int
    .lcomm buffer, 34        @ Para strings (entrada/salida)
    .lcomm intBuffer, 34     @ Para int a string o viceversa
    .lcomm opcion, 1         @ Para leer una opción (1 byte)

.section .text
.global _start

_start:
    mov r0, #1              
    ldr r1, =msg_inicial    
    ldr r2, =len_msg_inicial
    mov r7, #4              
    swi #0

    @ Leer primer número
    mov r0, #0
    ldr r1, =buffer
    mov r2, #22
    mov r7, #3
    svc #0
    bl atoi
    ldr r1, =strNum1
    str r0, [r1]

    @ Leer segundo número
    mov r0, #0
    ldr r1, =buffer
    mov r2, #22
    mov r7, #3
    svc #0
    bl atoi
    ldr r1, =strNum2
    str r0, [r1]

    @ Empezar en base 2
    mov r9, #2

@ TENGO MIEDO

.base_loop:
    bl _clear_buffer
    bl _print_base

    mov r0, #1
    ldr r1, =msg_resta
    ldr r2, =len_msg_resta
    mov r7, #4
    swi #0

    ldr r0, =strNum1
    ldr r0, [r0]
    ldr r1, =strNum2
    ldr r1, [r1]
    sub r0, r0, r1
    bl _clear_buffer
    bl _convertidor
    bl _printResult

    mov r0, #1
    ldr r1, =msg_suma
    ldr r2, =len_msg_suma
    mov r7, #4
    swi #0

    ldr r0, =strNum1
    ldr r0, [r0]
    ldr r1, =strNum2
    ldr r1, [r1]
    add r0, r0, r1
    bl _clear_buffer
    bl _convertidor
    bl _printResult

    mov r0, #1
    ldr r1, =newline
    mov r2, #1
    mov r7, #4
    swi #0

    add r9, r9, #1
    cmp r9, #16
    ble .base_loop

    bl _exit

_convertidor:
    cmp r0, #0
    bge .positivo
    mov r12, #1             
    rsb r0, r0, #0          
    b .iniciar_conversion

.positivo:
    mov r12, #0             

.iniciar_conversion:
    ldr r7, =intBuffer
    add r7, r7, #34
    mov r2, #0
    strb r2, [r7]          
    mov r3, r9             

.conversion_loop:
    sub r7, r7, #1        
    mov r2, #0              
    udiv r4, r0, r3         
    mul r5, r4, r3          
    sub r2, r0, r5          

    cmp r2, #9
    ble .digit
    add r2, r2, #'A' - 10
    b .store

.digit:
    add r2, r2, #'0'

.store:
    strb r2, [r7]          
    mov r0, r4              
    cmp r0, #0
    bne .conversion_loop

    cmp r12, #0
    beq .finish
    sub r7, r7, #1
    mov r2, #'-'
    strb r2, [r7]

.finish:
    ldr r1, =intBuffer
    mov r2, r7

.copy_loop:
    ldrb r3, [r2], #1
    strb r3, [r1], #1
    cmp r3, #0
    bne .copy_loop

    bx lr

_printResult:
    ldr r1, =intBuffer     
    mov r2, #0             

.calc_length:
    ldrb r3, [r1, r2]
    cmp r3, #0
    beq .print
    add r2, r2, #1
    b .calc_length

.print:
    mov r0, #1
    ldr r1, =intBuffer     
    mov r7, #4
    swi #0

    mov r0, #1
    ldr r1, =newline
    mov r2, #1
    mov r7, #4
    swi #0

    bx lr

_print_error:
    mov r0, #1
    ldr r1, =msg_error
    ldr r2, =len_msg_error
    mov r7, #4
    swi #0

    mov r0, #1
    ldr r1, =msg_continuar
    ldr r2, =len_msg_continuar
    mov r7, #4
    swi #0

    mov r0, #0
    ldr r1, =opcion
    mov r2, #2
    mov r7, #3
    swi #0

    ldr r1, =opcion
    ldrb r0, [r1]
    cmp r0, #'s'
    beq _start
    cmp r0, #'n'
    beq _exit
    cmp r0, #'S'
    beq _start
    cmp r0, #'N'
    beq _exit
    b _print_error

atoi:
    mov r0, #0              @ Initialize result to 0
    mov r2, #0              @ Initialize index to 0
    mov r4, #10             @ Base 10 multiplier

atoi_loop:
    ldr r1, =buffer         @ Load buffer address
    ldrb r3, [r1, r2]       @ Load next character
    cmp r3, #0              @ Check for null terminator
    beq atoi_done
    cmp r3, #10             @ Check for newline
    beq atoi_done
    cmp r3, #'0'            @ Check if character is a digit
    blt _print_error
    cmp r3, #'9'
    bgt _print_error
    sub r3, r3, #'0'        @ Convert ASCII to digit

    @ Multiply current result by 10 (using r5 as temporary)
    mov r5, r0              @ Copy current result to r5
    mul r0, r5, r4          @ Multiply by 10 (r0 = r5 * r4)
    
    add r0, r0, r3          @ Add new digit
    add r2, r2, #1          @ Increment index
    b atoi_loop             @ Repeat

atoi_done:
    cmp r0, #0x7FFFFFFF      @ Verificar si el número excede 32 bits con signo
    bhi _print_error         @ Si es mayor, mostrar error

    bx lr

_itoa:
    ldr r1, =intBuffer
    add r1, r1, #10         
    mov r2, #0              
    strb r2, [r1]           
    mov r3, #10             
    b itoa_loop             

itoa_loop:
    sub r1, r1, #1          
    mov r2, #0              
    udiv r4, r0, r3         
    mul r5, r4, r3          
    sub r2, r0, r5          
    add r2, r2, #'0'        
    strb r2, [r1]           
    mov r0, r4              
    cmp r0, #0              
    bne itoa_loop           
    bx lr

_print_base:
    mov r0, #1                  
    ldr r1, =msg_base
    ldr r2, =len_msg_base                  
    mov r7, #4
    swi #0

    ldr r3, =intBuffer          

    mov r0, r9
    mov r1, #10
    udiv r4, r0, r1             
    mul r5, r4, r1              
    sub r6, r0, r5              

    cmp r4, #0
    beq .unidades

    add r4, r4, #'0'
    strb r4, [r3]
    add r3, r3, #1

.unidades:
    add r6, r6, #'0'
    strb r6, [r3]
    add r3, r3, #1

    mov r0, #0
    strb r0, [r3]

    ldr r1, =intBuffer
    sub r2, r3, r1

    mov r0, #1
    mov r7, #4
    swi #0

    mov r0, #1
    ldr r1, =newline
    mov r2, #1
    mov r7, #4
    swi #0

    bx lr

_clear_buffer:
    push {r0, r1, r2}         
    mov r1, #20               
    ldr r0, =intBuffer        
    mov r2, #0                

.clear_loop:
    strb r2, [r0], #1         
    subs r1, r1, #1           
    bne .clear_loop           

    pop {r0, r1, r2}          
    bx lr


_exit:
    mov r0, #0
    mov r7, #1
    svc #0
