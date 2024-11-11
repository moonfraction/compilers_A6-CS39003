all: clean
	yacc -d prog.y
	flex prog.l
	g++ -o codegen codegen.cpp
	@echo "Compilation Successful, use 'make run REGS=N' to generate output file with N registers (default: REGS=5)"

run:
	@if [ -z "$(REGS)" ]; then \
		./codegen < sample.txt > output.txt; \
		echo "./codegen < sample.txt > output.txt"; \
	else \
		./codegen $(REGS) < sample.txt > output.txt; \
		echo "./codegen $(REGS) < sample.txt > output.txt"; \
	fi
	@echo "Output file generated successfully --> output.txt"

clean:
	rm -f y.tab.c y.tab.h lex.yy.c codegen output.txt *.out