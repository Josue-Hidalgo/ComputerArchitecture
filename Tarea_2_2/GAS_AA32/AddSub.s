.section .data
    msg:    .asciz "Escriba 2 numeros de maximo 10 digitos. El resultado sera sumado y restado\n"
    msg_len = . - msg
    newline: .asciz "\n"

.section .bss
    .lcomm buffer, 12      @ 10 dígitos + newline + null
    .lcomm num1, 4
    .lcomm num2, 4
    .lcomm intBuffer, 12

.section .text
    .global _start

_start:
    @ Imprimir mensaje
    mov r0, #1
    ldr r1, =msg
    ldr r2, =msg_len
    mov r7, #4
    svc #0

    @ Leer primer número
    mov r0, #0
    ldr r1, =buffer
    mov r2, #12
    mov r7, #3
    svc #0
    bl atoi
    ldr r1, =num1
    str r0, [r1]

    @ Leer segundo número
    mov r0, #0
    ldr r1, =buffer
    mov r2, #12
    mov r7, #3
    svc #0
    bl atoi
    ldr r1, =num2
    str r0, [r1]

    @ Calcular y mostrar RESTA (num1 - num2)
    ldr r0, =num1
    ldr r0, [r0]
    ldr r1, =num2
    ldr r1, [r1]
    sub r0, r0, r1        @ Solo resta, sin actualizar flags
    bl printResult

    @ Calcular y mostrar SUMA (num1 + num2)
    ldr r0, =num1
    ldr r0, [r0]
    ldr r1, =num2
    ldr r1, [r1]
    add r0, r0, r1
    bl printResult

    @ Salir
    mov r0, #0
    mov r7, #1
    svc #0

atoi:
    ldr r1, =buffer
    mov r0, #0
    mov r2, #0
    mov r4, #10

atoi_loop:
    ldrb r3, [r1, r2]
    cmp r3, #0
    beq atoi_done
    cmp r3, #10
    beq atoi_done
    
    cmp r3, #'0'
    blt atoi_error
    cmp r3, #'9'
    bgt atoi_error
    
    sub r3, r3, #'0'
    mul r0, r4, r0
    add r0, r0, r3
    add r2, r2, #1
    b atoi_loop

atoi_error:
    mov r0, #0
atoi_done:
    bx lr

itoa:
    push {r4-r8}          @ Preservar registros
    ldr r1, =intBuffer
    add r1, r1, #11
    mov r2, #0
    strb r2, [r1]
    sub r1, r1, #1
    
    mov r3, r0
    mov r4, #10
    mov r5, #0

itoa_loop:
    cmp r3, #0
    beq itoa_done
    
    udiv r6, r3, r4
    mul r7, r6, r4
    sub r8, r3, r7
    
    add r8, r8, #'0'
    strb r8, [r1]
    sub r1, r1, #1
    add r5, r5, #1
    
    mov r3, r6
    b itoa_loop

itoa_done:
    add r1, r1, #1
    ldr r2, =intBuffer
    mov r3, #0

copy_loop:
    cmp r3, r5
    bge copy_done
    ldrb r4, [r1], #1
    strb r4, [r2], #1
    add r3, r3, #1
    b copy_loop

copy_done:
    mov r4, #0
    strb r4, [r2]
    pop {r4-r8}           @ Restaurar registros
    bx lr

printResult:
    push {lr}
    bl itoa
    
    @ Calcular longitud real del string
    ldr r1, =intBuffer
    mov r2, #0
length_loop:
    ldrb r0, [r1, r2]
    cmp r0, #0
    beq length_done
    add r2, r2, #1
    b length_loop
length_done:

    mov r0, #1
    ldr r1, =intBuffer
    mov r7, #4
    svc #0

    mov r0, #1
    ldr r1, =newline
    mov r2, #1
    mov r7, #4
    svc #0

    pop {pc}
