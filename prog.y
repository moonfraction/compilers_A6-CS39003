%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

// Structure for expression attributes
struct expr_attr {
    char* addr;      // address or temporary name
    int lineno;
    int blockno;
};

// Global variables
char quads[1000][100];
int nextquad = 1;
int tmpCounter = 1;
int blockCounter = 1;

char* gentmp() {
    char* temp = malloc(10);
    sprintf(temp, "$%d", tmpCounter++);
    return temp;
}

void backpatch(int quad_to_patch, int target_quad);
void emit(char* op, char* arg1, char* arg2, char* result);
%}
%union {
    int intval;      // NUMB tokens
    char* strval;    // IDEN tokens
    struct expr_attr* expr;  // expressions - addr, lineno, blockno
    int linemark;     // marking positions in code for backpatching - quad number
    int blockmark;    // marking positions in code for backpatching - block number
}

%token <strval> IDEN NUMB
%token LP RP SET WHEN LOOP WHILE
%token ADD SUB MUL DIV MOD
%token EQ NEQ LT GT LE GE

%type <expr> list stmt asgn cond loop expr bool atom
%type <linemark> m
%type <blockmark> n
%type <strval> oper reln
%start list

%%

m       : /* empty */          { 
                                $$ = nextquad;
                              }
        ;

n       : /* empty */          { 
                                $$ = blockCounter++; 
                              }
        ;

list    : stmt                  { 
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->lineno = $1->lineno;
                                $$->blockno = $1->blockno;
                              }
        | stmt list          { 
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->lineno = $1->lineno;
                                $$->blockno = $1->blockno;
                              }
        ;

stmt    : asgn                 { 
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->lineno = $1->lineno;
                              }
        | cond                 { 
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->lineno = $1->lineno; 
                              }
        | loop                 { 
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->lineno = $1->lineno; 
                              }
        ;

asgn    : LP SET IDEN atom RP {
                                $$ = malloc(sizeof(struct expr_attr));
                                emit("=", $4->addr, "", $3);
                                $$->lineno = nextquad-1;
                              }
        ;
cond    : LP n WHEN bool n list RP m {
                                $$ = malloc(sizeof(struct expr_attr));
                                backpatch($4->lineno, $8);
                                $4->blockno = $5;
                                $$->lineno = nextquad-1;
                              }
        ;

loop    : LP n LOOP WHILE bool n list RP m {
                                $$ = malloc(sizeof(struct expr_attr));
                                emit("goto", "", "", "_");
                                backpatch(nextquad, $5->lineno);
                                backpatch($5->lineno, $9);
                                $5->blockno = $6;
                                $$->lineno = nextquad-1;
                                $$->blockno = $2;
                              }
        ;

bool    : LP reln atom atom RP {
                                $$ = malloc(sizeof(struct expr_attr));
                                emit($2, $3->addr, $4->addr, "_");
                                $$->lineno = nextquad-1;
                              }
        ;

atom    : IDEN                  {
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->addr = $1;
                              }
        | NUMB                  {
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->addr = $1;
                              }
        | expr                  {
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->addr = $1->addr;
                                $$->lineno = $1->lineno;
                              }
        ;

expr    : LP oper atom atom RP {
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->addr = gentmp();
                                emit($2, $3->addr, $4->addr, $$->addr);
                                $$->lineno = nextquad-1;
                              }
        ;

oper    : ADD                   { $$ = "+" ; }
        | SUB                   { $$ = "-" ; }
        | MUL                   { $$ = "*" ; }
        | DIV                   { $$ = "/" ; }
        | MOD                   { $$ = "%" ; }
        ;

reln    : EQ                    { $$ = "==" ; }
        | NEQ                   { $$ = "!=" ; }
        | LT                    { $$ = "<" ; }
        | GT                    { $$ = ">" ; }
        | LE                    { $$ = "<=" ; }
        | GE                    { $$ = ">=" ; }
        ;
%%

void backpatch(int quad_to_patch, int target_quad) {
    char str[10];
    sprintf(str, "%d", target_quad);
    char* quadStr = quads[quad_to_patch];
    char* target = strstr(quadStr, "_");
    if (target) {
        strcpy(target, str);
    }
}

void emit(char* op, char* arg1, char* arg2, char* result) {
    if (strcmp(op, "goto") == 0) {
        sprintf(quads[nextquad++], "goto %s", result);
    }
    else if (strcmp(op, "=") == 0) {
        sprintf(quads[nextquad++], "%s = %s", result, arg1);
    }
    else if (strcmp(op, "==") == 0) {
        sprintf(quads[nextquad++], "iffalse (%s == %s) goto _", arg1, arg2);
    }
    else if (strcmp(op, "!=") == 0) {
        sprintf(quads[nextquad++], "iffalse (%s != %s) goto _", arg1, arg2);
    }
    else if (strcmp(op, "<") == 0) {
        sprintf(quads[nextquad++], "iffalse (%s < %s) goto _", arg1, arg2);
    }
    else if (strcmp(op, ">") == 0) {
        sprintf(quads[nextquad++], "iffalse (%s > %s) goto _", arg1, arg2);
    }
    else if (strcmp(op, "<=") == 0) {
        sprintf(quads[nextquad++], "iffalse (%s <= %s) goto _", arg1, arg2);
    }
    else if (strcmp(op, ">=") == 0) {
        sprintf(quads[nextquad++], "iffalse (%s >= %s) goto _", arg1, arg2);
    }
    else {
        sprintf(quads[nextquad++], "%s = %s %s %s", result, arg1, op, arg2);
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    yyparse();
    // Print generated quadruples
    for(int i = 1; i < nextquad; i++) {
        printf("%-5d: %s\n", i, quads[i]);
    }
    return 0;
} 