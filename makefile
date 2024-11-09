all: clean
	yacc -d prog.y
	flex prog.l
	gcc -o prog y.tab.c lex.yy.c
	@echo "Compilation Successful, use make run to generate output file"

run:
	./prog < sample.txt > output.txt

clean:
	rm -f y.tab.c y.tab.h lex.yy.c prog output.txt *.out