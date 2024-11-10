all: clean
	yacc -d prog.y
	flex prog.l
	g++ -o prog codegen.cpp
	@echo "Compilation Successful, use 'make run' to generate output file"

run:
	./prog < sample.txt > output.txt

clean:
	rm -f y.tab.c y.tab.h lex.yy.c prog output.txt *.out