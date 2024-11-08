%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
void yyerror(const char *s);

%}

%union {
    int intval;
    char* id;
}

%token <id> IDEN
%token <intval> NUMB
%token <id> SET WHEN LOOP WHILE
%token <id> ADD SUB MUL DIV MOD
%token <id> EQ NEQ LT GT LE GE
%token LPAREN RPAREN
%type <id> atom expr

%%

/* Start Rule */
list: stmt { printf("list -> stmt\n"); }
    | stmt list { printf("list -> stmt list\n"); }
    ;

/* Statements */
stmt: asgn { printf("stmt -> asgn\n"); }
    | cond { printf("stmt -> cond\n"); }
    | loop { printf("stmt -> loop\n"); }
    ;

/* Assignment */
asgn: LPAREN SET IDEN atom RPAREN {
        printf("asgn -> (set IDEN atom)\n");
    }
    ;

/* Conditional (when statement) */
cond: LPAREN WHEN bool list RPAREN {
        printf("cond -> (when bool list)\n");
    }
    ;

/* Loop (loop while statement) */
loop: LPAREN LOOP WHILE bool list RPAREN {
        printf("loop -> (loop while bool list)\n");
    }
    ;

/* Expressions and Booleans */
bool: LPAREN EQ atom atom RPAREN {
        printf("bool -> (= atom atom)\n");
    }
    | LPAREN NEQ atom atom RPAREN {
        printf("bool -> (/= atom atom)\n");
    }
    | LPAREN LT atom atom RPAREN {
        printf("bool -> (< atom atom)\n");
    }
    | LPAREN GT atom atom RPAREN {
        printf("bool -> (> atom atom)\n");
    }
    | LPAREN LE atom atom RPAREN {
        printf("bool -> (<= atom atom)\n");
    }
    | LPAREN GE atom atom RPAREN {
        printf("bool -> (>= atom atom)\n");
    }
    ;

/* Atoms and Identifiers */
atom: IDEN { printf("atom -> IDEN\n"); }
    | NUMB { printf("atom -> NUMB\n"); }
    | expr { printf("atom -> expr\n"); }
    ;

/* Arithmetic Expressions */
expr: LPAREN ADD atom atom RPAREN {
        printf("expr -> (+ atom atom)\n");
    }
    | LPAREN SUB atom atom RPAREN {
        printf("expr -> (- atom atom)\n");
    }
    | LPAREN MUL atom atom RPAREN {
        printf("expr -> (* atom atom)\n");
    }
    | LPAREN DIV atom atom RPAREN {
        printf("expr -> (/ atom atom)\n");
    }
    | LPAREN MOD atom atom RPAREN {
        printf("expr -> (%% atom atom)\n");
    }
    ;

%%

/* Helper functions */
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    yyparse();
    return 0;
}
