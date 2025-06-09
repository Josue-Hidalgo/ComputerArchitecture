name=OrdenarPalabra
ASM=as
LINKER=ld

$(name): $(name).o
	$(LINKER) -o $(name) $(name).o

$(name).o: $(name).s
	$(ASM) -o $(name).o $(name).s

clean:
	rm -f $(name).o $(name)