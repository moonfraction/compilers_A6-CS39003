%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

// Structure for expression attributes
struct expr_attr {
    int truelist;    // quad number for true jump
    int falselist;   // quad number for false jump
    int nextlist;    // quad number for next instruction
    char* addr;      // address or temporary name 
};

// Structure for marker - quad number
struct marker {
    int quad;
};

// Global variables
int nextquad = 1;
char quads[1000][100];
int tmpCounter = 1;

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
    struct expr_attr* expr;  // expressions - contains truelist, falselist, nextlist and temporary address
    struct marker* mark;     // marking positions in code for backpatching - quad number
}

%token <strval> IDEN NUMB
%token LP RP SET WHEN LOOP WHILE
%token ADD SUB MUL DIV MOD
%token EQ NEQ LT GT LE GE

%type <expr> list stmt asgn cond loop expr bool atom
%type <mark> m
%type <strval> oper reln
%start list

%%

m       : /* empty */          { 
                                $$ = malloc(sizeof(struct marker));
                                $$->quad = nextquad; 
                              }
        ;

list    : stmt                  { 
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->nextlist = $1->nextlist; 
                              }
        | stmt list          { 
                                $$ = malloc(sizeof(struct expr_attr));
                                backpatch($1->nextlist, $2->nextlist);
                                $$->nextlist = $2->nextlist; 
                              }
        ;

stmt    : asgn                 { 
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->nextlist = -1; 
                              }
        | cond                 { 
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->nextlist = $1->nextlist; 
                              }
        | loop                 { 
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->nextlist = $1->nextlist; 
                              }
        ;

asgn    : LP SET IDEN atom RP {
                                $$ = malloc(sizeof(struct expr_attr));
                                emit("=", $4->addr, "", $3);
                                $$->nextlist = -1;
                              }
        ;

cond    : LP m WHEN bool m list RP m {
                                $$ = malloc(sizeof(struct expr_attr));
                                // backpatch($4->truelist, $5->quad);
                                backpatch($4->falselist, $5->quad);
                                $$->nextlist = $8->quad;
                              } 
        ;

loop    : LP m LOOP WHILE bool m list RP m {
                                $$ = malloc(sizeof(struct expr_attr));
                                backpatch($7->nextlist, $2->quad);
                                backpatch($5->truelist, $6->quad);
                                backpatch($5->falselist, $9->quad);
                                emit("goto", "", "", "_");
                                backpatch(nextquad, $2->quad);
                                $$->nextlist = $9->quad;
                              }
        ;

bool    : LP reln atom atom RP {
                                $$ = malloc(sizeof(struct expr_attr));
                                emit($2, $3->addr, $4->addr, "_");
                                $$->truelist = nextquad;
                                $$->falselist = nextquad+1;
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
                              }
        ;

expr    : LP oper atom atom RP {
                                $$ = malloc(sizeof(struct expr_attr));
                                $$->addr = gentmp();
                                emit($2, $3->addr, $4->addr, $$->addr);
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
    if (quad_to_patch != -1) {
        char str[10];
        sprintf(str, "%d", target_quad);
        char* quadStr = quads[quad_to_patch];
        char* target = strstr(quadStr, "_");
        if (target) {
            strcpy(target, str);
        }
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