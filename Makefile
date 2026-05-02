all: build

build:
	odin build . -out:ca -error-pos-style:unix

debug:
	odin build . -out:ca -error-pos-style:unix -debug

run:
	odin run . -out:ca -error-pos-style:unix

test:
	odin test tests/ -all-packages -error-pos-style:unix

clean: 
	rm -f ca

.PHONY: all build run test clean
