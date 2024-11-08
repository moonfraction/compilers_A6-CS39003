%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
void yyerror(const char *s);

// Quad generation
int nextquad = 1;
char temp_count = '1';

// Symbol table entry structure
typedef struct {
    char* name;
    int offset;
} symbol_entry;

// Backpatching structure
typedef struct bplist_t {
    int truelist;
    int falselist;
} bplist;

// Function declarations
void emit(const char* op, const char* arg1, const char* arg2, const char* result);
void backpatch(int quad_number, int target);
char* new_temp();

%}

%union {
    char* strval;
    int intval;
    int instr;
    struct bplist_t * bp;  // Changed to pointer
}

/* Token declarations */
%token <strval> IDEN
%token <intval> NUMB
%token SET WHEN LOOP WHILE
%token ADD SUB MUL DIV MOD
%token EQ NEQ LT GT LE GE
%token LPAREN RPAREN 

/* Type declarations for non-terminals */
%type <strval> atom expr
%type <bp> bool
%type <instr> m
%start list

%%
list    : stmt
        | stmt list
        ;

stmt    : asgn
        | cond
        | loop
        ;

asgn    : LPAREN SET IDEN atom RPAREN {
            emit("=", $4, "", $3);
        }
        ;

cond    : LPAREN WHEN bool m list RPAREN {
            backpatch($3->truelist, $4);
            backpatch($3->falselist, nextquad);
        }
        ;

loop    : LPAREN LOOP WHILE m bool m list RPAREN {
            backpatch($5->truelist, $6);
            backpatch($5->falselist, nextquad);
            emit("goto", "", "", (char*)$4);
        }
        ;

m       : /* empty */ {
            $$ = nextquad;
        }
        ;

bool    : LPAREN EQ atom atom RPAREN {
            $$ = (bplist*)malloc(sizeof(bplist));
            $$->truelist = nextquad;
            $$->falselist = nextquad + 1;
            emit("iffalse", $3, "==", $4);
            emit("goto", "", "", "");
        }
        | LPAREN NEQ atom atom RPAREN {
            $$ = (bplist*)malloc(sizeof(bplist));
            $$->truelist = nextquad;
            $$->falselist = nextquad + 1;
            emit("iffalse", $3, "!=", $4);
            emit("goto", "", "", "");
        }
        | LPAREN LT atom atom RPAREN {
            $$ = (bplist*)malloc(sizeof(bplist));
            $$->truelist = nextquad;
            $$->falselist = nextquad + 1;
            emit("iffalse", $3, "<", $4);
            emit("goto", "", "", "");
        }
        | LPAREN GT atom atom RPAREN {
            $$ = (bplist*)malloc(sizeof(bplist));
            $$->truelist = nextquad;
            $$->falselist = nextquad + 1;
            emit("iffalse", $3, ">", $4);
            emit("goto", "", "", "");
        }
        | LPAREN LE atom atom RPAREN {
            $$ = (bplist*)malloc(sizeof(bplist));
            $$->truelist = nextquad;
            $$->falselist = nextquad + 1;
            emit("iffalse", $3, "<=", $4);
            emit("goto", "", "", "");
        }
        | LPAREN GE atom atom RPAREN {
            $$ = (bplist*)malloc(sizeof(bplist));
            $$->truelist = nextquad;
            $$->falselist = nextquad + 1;
            emit("iffalse", $3, ">=", $4);
            emit("goto", "", "", "");
        }
        ;

expr    : LPAREN ADD atom atom RPAREN {
            $$ = new_temp();
            emit("+", $3, $4, $$);
        }
        | LPAREN SUB atom atom RPAREN {
            $$ = new_temp();
            emit("-", $3, $4, $$);
        }
        | LPAREN MUL atom atom RPAREN {
            $$ = new_temp();
            emit("*", $3, $4, $$);
        }
        | LPAREN DIV atom atom RPAREN {
            $$ = new_temp();
            emit("/", $3, $4, $$);
        }
        | LPAREN MOD atom atom RPAREN {
            $$ = new_temp();
            emit("%", $3, $4, $$);
        }
        ;

atom    : IDEN { $$ = $1; }
        | NUMB {
            char* num = (char*)malloc(12);
            sprintf(num, "%d", $1);
            $$ = num;
        }
        | expr { $$ = $1; }
        ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

void emit(const char* op, const char* arg1, const char* arg2, const char* result) {
    printf("%d : ", nextquad);
    if (strcmp(op, "goto") == 0) {
        printf("goto %s\n", result);
    } else if (strcmp(op, "iffalse") == 0) {
        printf("iffalse (%s %s %s) goto L\n", arg1, arg2, result);
    } else if (strcmp(op, "=") == 0) {
        printf("%s = %s\n", result, arg1);
    } else {
        printf("%s = %s %s %s\n", result, arg1, op, arg2);
    }
    nextquad++;
}

void backpatch(int quad_number, int target) {
    // In a real implementation, this would modify the quad table
    printf("Backpatching quad %d to %d\n", quad_number, target);
}

char* new_temp() {
    char* temp = (char*)malloc(3);
    sprintf(temp, "$%c", temp_count++);
    return temp;
}

int main() {
    yyparse();
    return 0;
}