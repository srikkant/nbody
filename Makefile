all: build

build:
	odin build . -out:ca -error-pos-style:unix -vet -strict-style

debug:
	odin build . -out:ca -error-pos-style:unix -debug -vet -strict-style

run:
	odin run . -out:ca -error-pos-style:unix -vet -strict-style

test:
	odin test tests/ -all-packages -error-pos-style:unix

clean:
	rm -f ca

.PHONY: all build run test clean
