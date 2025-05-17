#*************************************************
# Executable name : hola
# Version : 2.0
# Created date : February 12, 2019
# Authors : 
#	Eduardo A. Canessa M
# Description : simple makefile for GAS
# Important Notice: To be used for GAS only
#*************************************************
#change the name "ejemplo" for the name of your source file
name=Operaciones
#program to use as the assembler (you could use NASM or YASM for this makefile)
ASM=as
#flags for the assember
#ASM_F= #*** place here flags if needed ***

#program to use as linker
LINKER=ld

#link executable
$(name): $(name).o
	$(LINKER) -o $(name) $(name).o

#assemble source code
$(name).o: $(name).s
	$(ASM) $(ASM_F) -o $(name).o $(name).s

