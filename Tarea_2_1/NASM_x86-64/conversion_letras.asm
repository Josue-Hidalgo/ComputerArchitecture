; Curso: Arquitectura de Computadores
; Nombre: Allan José Jimenez Rivera y Josué Santiago Hidalgo Sandoval

section .data
	mensaje db "Escriba una oración (maximo 100 caracteres):",10
	mensajeError db "Error: la oracion contiene caracteres invalidos",10

section .bss
	oracion resb 100
	longitud resb 1 			; reserva espacio para la longitud del mensaje escrito

section .text
	global _start

_start:
	call _printMensaje
	call _getOracion
	call _procesarLetras
	call _printResultado

	mov rax, 60
	mov rdi, 0
	syscall

; imprimir el mensaje
_printMensaje:
	mov rax, 1
	mov rdi, 1
	mov rsi, mensaje
	mov rdx, 46
	syscall
	ret

; obtener la oración
_getOracion:
	mov rax, 0
	mov rdi, 0
	mov rsi, oracion
	mov rdx, 100
	syscall

	mov [longitud], al 			; mueve la longitud del mensaje a al
	ret

; inicializa el iterable y guarda la longitud del mensaje
_procesarLetras:
	mov rcx, 0 					; el "iterable", 
	movzx rdx, byte [longitud]	; se guarda la longitud del mensaje escrito
	jmp _for					; salta al bucle
	ret

; el bucle que revisa las letras
_for:
	cmp rcx, rdx				; si el iterable es igual a la longitud del mensaje, termina
	jge _fin 					

	mov al, [oracion + rcx]

	cmp al, 'A'					; Compara al con 'A', si su código ascii es
	jl _verificarInvalido		; menor que el de a, revisa si el caracter es invalido
	
	cmp al, 'Z'					; Si el caracter es mayor a 'Z', es una minúscula, por lo que 
	jg _convertirAMayuscula		; la convierte en mayúscula

	jmp _convertirAMinuscula	; si el caracter no es espacio ni minúscula, y no es un caracter 							 ; inválido, es una mayúscula, por lo que se convierte
	
; convierte la letra a mayúscula
_convertirAMinuscula:
	add al, 32					; suma 32, o sea, la convierte en minúscula
	mov [oracion + rcx], al 	; guarda el caracter
	jmp _siguiente				; pasa al siguiente caracter

; convierte la letra a minúscula
_convertirAMayuscula:
	cmp al, 'a'					; mismo proceso para las mayúsculas
	jl _siguiente

	cmp al, 'z'					; si es mayor a 'z', es otro caracter inválido
	jg _verificarInvalido
	
	sub al, 32					; resta 32, o sea, convierte a mayúscula
	mov [oracion + rcx], al		; guarda el caracter
	jmp _siguiente


; verifica si el caracter es válido
_verificarInvalido:
	cmp al, ' '					; el espacio es un caracter válido
	je _siguiente

	cmp al, 10					; 10 es un enter, también es válido, sin esta línea
	je _siguiente				; el programa lanza error siempre

	call _printError
	mov rax, 60
	mov rdi, 1
	syscall

; pasa a la siguiente letra
_siguiente:
	inc rcx						; incrementa el iterable
	jmp _for					; vuelve al bucle

; termina el programa
_fin:
	ret

; imprime el mensaje de error
_printError:
	mov rax, 1
	mov rdi, 1
	mov rsi, mensajeError
	mov rdx, 48
	syscall
	ret

; imprime la oración con sus letras cambiadas
_printResultado:
	mov rax, 1
	mov rdi, 1
	mov rsi, oracion
	mov rdx, [longitud]
	syscall
	ret