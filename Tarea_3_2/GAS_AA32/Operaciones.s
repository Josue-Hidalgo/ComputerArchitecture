.syntax unified
.arch armv7-a
.cpu cortex-a72
.thumb

.data
    msg_output_1_1: .asciz "Bienvenido! Introduzca 2 operandos: \n"
    len_msg_output_1_1 = . - msg_output_1_1

    msg_output_2_1: .asciz "Seleccione la operacion a realizar\n"
    msg_output_2_2: .asciz "1. Sumar\n"
    msg_output_2_3: .asciz "2. Restar\n"
    msg_output_2_4: .asciz "3. Multiplicar\n"
    msg_output_2_5: .asciz "4. Dividir\n"

    msg_output_3_1: .asciz "Resultados: \n"

    msg_base_2:  .asciz "Binario (2): "
    msg_base_8:  .asciz "Octal (8): "
    msg_base_10: .asciz "Decimal (10): "
    msg_base_16: .asciz "Hexadecimal (16): "

    msg_error_1: .asciz "Error: Entrada Inválida.\n"
    msg_error_2: .asciz "Error: Entrada supera los 32bits.\n"
    msg_error_3: .asciz "Error: Division entre 0.\n"
    msg_error_4: .asciz "Error: Opcion no valida.\n"

    newline: .asciz "\n"

.bss
    .lcomm num1, 4
    .lcomm num2, 4
    .lcomm buffer, 22
    .lcomm intBuffer, 65
    .lcomm opcion, 2
    .lcomm result, 4

.text
.global _start
.thumb_func

_start:
    bl _printMsg1

    @ Obtener primer número
    bl _getNumber
    ldr r1, =num1
    str r0, [r1]

    @ Obtener segundo número
    bl _getNumber
    ldr r1, =num2
    str r0, [r1]

    bl _printMsg2

    @ Leer opción
    mov r0, #0              @ STDIN
    ldr r1, =opcion
    mov r2, #2              @ Longitud
    mov r7, #3              @ sys_read
    svc 0

    @ Convertir opción
    ldr r1, =opcion
    ldrb r0, [r1]
    sub r0, r0, #'0'

    @ Comparar opción
    cmp r0, #1
    beq _suma
    cmp r0, #2
    beq _resta
    cmp r0, #3
    beq _multiplicacion
    cmp r0, #4
    beq _division

    bl _print_error_option

_suma:
    bl _printMsg3
    ldr r0, =num1
    ldr r0, [r0]
    ldr r1, =num2
    ldr r1, [r1]
    add r0, r0, r1
    bl _printResult
    b _exit

_resta:
    bl _printMsg3
    ldr r0, =num1
    ldr r0, [r0]
    ldr r1, =num2
    ldr r1, [r1]
    sub r0, r0, r1
    bl _printResult
    b _exit

_multiplicacion:
    bl _printMsg3
    ldr r0, =num1
    ldr r0, [r0]
    ldr r1, =num2
    ldr r1, [r1]
    @ Usamos registro temporal para evitar Rd == Rm
    mov r2, r0
    mul r0, r2, r1
    bl _printResult
    b _exit

_division:
    bl _printMsg3
    ldr r0, =num1
    ldr r0, [r0]
    ldr r1, =num2
    ldr r1, [r1]
    
    cmp r1, #0
    beq _print_error_division
    
    bl _divmod
    bl _printResult
    b _exit

_divmod:
    @ Implementación segura de división
    push {r4-r6, lr}
    mov r2, #0          @ Cociente
    mov r3, #32         @ Contador
    mov r4, r0          @ Dividendo
    mov r5, r1          @ Divisor
    mov r6, #0          @ Resto
    
_divmod_loop:
    lsl r2, r2, #1
    lsls r4, r4, #1
    adc r6, r6, r6
    
    cmp r6, r5
    it ge
    subge r6, r6, r5
    it ge
    addge r2, r2, #1
    
    subs r3, r3, #1
    bne _divmod_loop
    
    mov r0, r2          @ Cociente
    mov r1, r6          @ Resto
    pop {r4-r6, pc}

_getNumber:
    push {r4-r5, lr}
    mov r0, #0          @ STDIN
    ldr r1, =buffer
    mov r2, #22         @ Longitud
    mov r7, #3          @ sys_read
    svc 0

    ldr r1, =buffer
    mov r0, #0          @ Resultado
    mov r2, #0          @ Índice
    mov r3, #10         @ Base 10
    
_gn_loop:
    ldrb r4, [r1, r2]
    cmp r4, #10         @ Newline
    beq _gn_done
    cmp r4, #0          @ Null terminator
    beq _gn_done

    cmp r4, #'0'
    blt _print_error_invalid
    cmp r4, #'9'
    bgt _print_error_invalid

    sub r4, r4, #'0'
    @ Multiplicación segura usando registro temporal
    mov r5, r0
    mul r0, r5, r3
    adds r0, r0, r4
    bvs _print_error_overflow

    add r2, r2, #1
    b _gn_loop
    
_gn_done:
    pop {r4-r5, pc}

_itoa:
    @ r0 = número, r1 = base
    push {r4-r7, lr}
    ldr r2, =intBuffer
    add r2, r2, #64
    mov r3, #0
    strb r3, [r2]
    
    cmp r0, #0
    bge _itoa_loop
    neg r0, r0
    mov r7, #1
    b _itoa_loop

_itoa_loop:
    sub r2, r2, #1
    mov r3, #0
    bl _divmod
    
    cmp r3, #9
    ite le
    addle r3, r3, #'0'
    addgt r3, r3, #'A'-10
    strb r3, [r2]
    
    cmp r0, #0
    bne _itoa_loop
    
    cmp r7, #1
    it eq
    subeq r2, r2, #1
    it eq
    moveq r3, #'-'
    it eq
    strbeq r3, [r2]

_itoa_finish:
    ldr r0, =intBuffer
    mov r1, r2
    mov r3, #64
    sub r3, r3, r2
    bl _memcpy
    
    pop {r4-r7, pc}

_memcpy:
    push {r4}
_memcpy_loop:
    ldrb r4, [r1], #1
    strb r4, [r0], #1
    subs r3, r3, #1
    bne _memcpy_loop
    pop {r4}
    bx lr

_printResult:
    push {lr}
    ldr r4, =result
    str r0, [r4]
    
    @ Base 10
    ldr r1, =msg_base_10
    bl _printStr
    ldr r0, [r4]
    mov r1, #10
    bl _itoa
    bl _printConvertedNumber
    
    @ Base 2
    ldr r1, =msg_base_2
    bl _printStr
    ldr r0, [r4]
    mov r1, #2
    bl _itoa
    bl _printConvertedNumber
    
    @ Base 8
    ldr r1, =msg_base_8
    bl _printStr
    ldr r0, [r4]
    mov r1, #8
    bl _itoa
    bl _printConvertedNumber
    
    @ Base 16
    ldr r1, =msg_base_16
    bl _printStr
    ldr r0, [r4]
    mov r1, #16
    bl _itoa
    bl _printConvertedNumber
    
    pop {pc}

_printConvertedNumber:
    push {lr}
    ldr r1, =intBuffer
    bl _strlen
    mov r2, r0
    ldr r1, =intBuffer
    bl _printMsg
    
    ldr r1, =newline
    mov r2, #1
    bl _printMsg
    pop {pc}

_strlen:
    mov r2, #0
_strlen_loop:
    ldrb r3, [r1, r2]
    cmp r3, #0
    it eq
    moveq r0, r2
    beq _strlen_done
    add r2, r2, #1
    b _strlen_loop
_strlen_done:
    bx lr

_printMsg:
    push {r7, lr}
    mov r7, #4
    mov r0, #1
    svc 0
    pop {r7, pc}

_printStr:
    push {r0, r2, r7, lr}
    bl _strlen
    mov r2, r0
    mov r7, #4
    mov r0, #1
    svc 0
    pop {r0, r2, r7, pc}

_printMsg1:
    push {lr}
    ldr r1, =msg_output_1_1
    ldr r2, =len_msg_output_1_1
    bl _printMsg
    pop {pc}

_printMsg2:
    push {lr}
    ldr r1, =msg_output_2_1
    bl _printStr
    ldr r1, =msg_output_2_2
    bl _printStr
    ldr r1, =msg_output_2_3
    bl _printStr
    ldr r1, =msg_output_2_4
    bl _printStr
    ldr r1, =msg_output_2_5
    bl _printStr
    pop {pc}

_printMsg3:
    push {lr}
    ldr r1, =msg_output_3_1
    bl _printStr
    pop {pc}

_print_error_invalid:
    ldr r1, =msg_error_1
    bl _printStr
    b _exit

_print_error_overflow:
    ldr r1, =msg_error_2
    bl _printStr
    b _exit

_print_error_division:
    ldr r1, =msg_error_3
    bl _printStr
    b _exit

_print_error_option:
    ldr r1, =msg_error_4
    bl _printStr
    b _exit

_exit:
    mov r0, #0
    mov r7, #1
    svc 0