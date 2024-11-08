%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

struct _quad{
    int blockno;
    char text[100];
} quads[1000];

// Global variables
int nextquad = 1;
int tmpCounter = 1;
int blockCounter = 1;

char* gentmp() {
    char* temp = malloc(10);
    sprintf(temp, "$%d", tmpCounter++);
    return temp;
}

void emit_goto(int jump_to, int block_no);
void emit_set(char* op, char* arg, char* result, int block_no);
void emit_bool(char* op, char* arg1, char* arg2, int block_no);
void emit_expr(char* op, char* arg1, char* arg2, char* result, int block_no);
void backpatch(int quad_no, int target_quad);


%}
%union {
    char* strval;    // IDEN, NUMB, atom
    int quadno;  // for bool
    int linemark;     // m
    int blockmark;    // n
}

%token <strval> IDEN NUMB
%token LP RP SET WHEN LOOP WHILE
%token ADD SUB MUL DIV MOD
%token EQ NEQ LT GT LE GE

%type <quadno> bool
%type <linemark> m
%type <blockmark> n
%type <strval> atom oper reln expr

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

list    : stmt
        | stmt list
        ;

stmt    : asgn
        | cond
        | loop
        ;

asgn    : LP SET IDEN atom RP { // id = atom
                                emit_set("=", $4, $3, blockCounter);
                              }
        ;

cond    : LP WHEN bool n list RP m {
                                    backpatch($4, $7); // backpatch the target of the bool
                              }
        ;

loop    : LP LOOP WHILE m bool n list RP m {
                                emit_goto($4, blockCounter); // goto $4
                                backpatch($5, $9); // backpatch the target of the bool
                              }
        ;

bool    : LP reln atom atom RP { // iffalse (expr1 reln expr2) goto _
                                emit_bool($2, $3, $4, blockCounter);
                                $$ = nextquad-1;
                              }
        ;

atom    : IDEN                  {
                                $$ = $1;
                              }
        | NUMB                  {
                                $$ = $1;
                              }
        | expr                  {
                                $$ = $1;
                              }
        ;

expr    : LP oper atom atom RP { // temp = expr op expr
                                char *temp = gentmp();
                                emit_expr($2, $3, $4, temp, blockCounter);
                                $$ = temp;
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

// void emit(char* op, char* arg1, char* arg2, char* result) {
//     if (strcmp(op, "goto") == 0) {
//         sprintf(quads[nextquad++], "goto %s", result);
//     }
//     else if (strcmp(op, "=") == 0) {
//         sprintf(quads[nextquad++], "%s = %s", result, arg1);
//     }
//     else if (strcmp(op, "==") == 0) {
//         sprintf(quads[nextquad++], "iffalse (%s == %s) goto _", arg1, arg2);
//     }
//     else if (strcmp(op, "!=") == 0) {
//         sprintf(quads[nextquad++], "iffalse (%s != %s) goto _", arg1, arg2);
//     }
//     else if (strcmp(op, "<") == 0) {
//         sprintf(quads[nextquad++], "iffalse (%s < %s) goto _", arg1, arg2);
//     }
//     else if (strcmp(op, ">") == 0) {
//         sprintf(quads[nextquad++], "iffalse (%s > %s) goto _", arg1, arg2);
//     }
//     else if (strcmp(op, "<=") == 0) {
//         sprintf(quads[nextquad++], "iffalse (%s <= %s) goto _", arg1, arg2);
//     }
//     else if (strcmp(op, ">=") == 0) {
//         sprintf(quads[nextquad++], "iffalse (%s >= %s) goto _", arg1, arg2);
//     }
//     else {
//         sprintf(quads[nextquad++], "%s = %s %s %s", result, arg1, op, arg2);
//     }
// }

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    yyparse();

    int currentBlock = 1;
    int currentQuad = 1;

    for(int i=1; i<blockCounter; i++) {
        printf("Block %d\n", i);
        while(currentQuad < nextquad && quads[currentQuad].blockno == i) {
            printf("%-5d: %s\n", currentQuad, quads[currentQuad].text);
            currentQuad++;
        }
    }

    return 0;
} 