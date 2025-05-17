#*************************************************
# Executable name : hexDump_x64
# Version : 2.0
# Created date : February 4, 2015
# Last update : April 22, 2017
# Authors : 
#	Erick Hernandez
#	Eduardo A. Canessa M
# Description : simple makefile
# Important Notice: You should install NASM and/or
# YASM firs to run this makefile withot problems.
#*************************************************
#change the name "ejemplo" for the name of your source file
name=Operaciones
#program to use as the assembler (you could use NASM or YASM for this makefile)
ASM=nasm
#flags for the assember
ASM_F=-f elf64  #for x86-64 architecture use ASM_F=-f elf64 besides ASM_F=-f elf

#program to use as linker
LINKER=ld

#link executable
$(name): $(name).o
	$(LINKER) -o $(name) $(name).o

#assemble source code
$(name).o: $(name).asm
	$(ASM) $(ASM_F) -o $(name).o $(name).asm

