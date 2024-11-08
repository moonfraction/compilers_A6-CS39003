#include "y.tab.c"
#include "lex.yy.c"
#include <stdio.h>

void backpatch(int quad_to_patch, int target_quad) {
    char str[10];
    sprintf(str, "%d", target_quad);
    char* target = strstr(quads[quad_to_patch].text, "_");
    if (target) {
        strcpy(target, str);
    }
}

void emit_goto(int jump_to, int block_no) {
    sprintf(quads[nextquad].text, "goto %d", jump_to);
    quads[nextquad].blockno = block_no;
    nextquad++;
}

void emit_set(char* op, char* arg, char* result, int block_no) {
    sprintf(quads[nextquad].text, "%s = %s", result, arg);
    quads[nextquad].blockno = block_no;
    nextquad++;
}

void emit_bool(char* op, char* arg1, char* arg2, int block_no) {
    sprintf(quads[nextquad].text, "iffalse (%s %s %s) goto _", arg1, op, arg2);
    quads[nextquad].blockno = block_no;
    nextquad++;
}

void emit_expr(char* op, char* arg1, char* arg2, char* result, int block_no) {
    sprintf(quads[nextquad].text, "%s = %s %s %s", result, arg1, op, arg2);
    quads[nextquad].blockno = block_no;
    nextquad++;
}

int main() {
    yyparse();

    int currentBlock = 1;
    int currentQuad = 1;
    int block_no = 1;
    printf("Block %d\n", block_no++);
    for(int i=1; i<blockCounter; i++) {
        int block_changed = 0;
       
        while(currentQuad < nextquad && quads[currentQuad].blockno == i) {
            printf("%-5d: %s\n", currentQuad, quads[currentQuad].text);
            currentQuad++;
            block_changed = 1;
        }
        if(block_changed && i != blockCounter-1) {
             printf("Block %d\n", block_no++);
        }
    }

    return 0;
} 