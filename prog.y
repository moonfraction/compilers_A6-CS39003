%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

// Global variables
char quads[1000][100]; // to store the quads
int leaders[1000]; // to store the leaders
int nextquad = 1; // to store the next quad number
int tmpCounter = 1; // to store the temporary variable counter
int blockCounter = 1; // to store the block counter


char* gentmp() { // to generate a temporary variable
    char* temp = malloc(10);
    sprintf(temp, "$%d", tmpCounter++);
    return temp;
}

void emit_goto(int jump_to);
void emit_set(char* op, char* arg, char* result);
void emit_bool(char* op, char* arg1, char* arg2);
void emit_expr(char* op, char* arg1, char* arg2, char* result);
void backpatch(int quad_no, int target_quad);
void add_leader(int leader);
%}

%union {
    char* strval;    // IDEN, NUMB, atom
    int quadno;  // for bool
    int linemark;     // m
}

%token <strval> IDEN NUMB
%token LP RP SET WHEN LOOP WHILE
%token ADD SUB MUL DIV MOD
%token EQ NEQ LT GT LE GE

%type <quadno> bool
%type <linemark> m
%type <strval> atom oper reln expr

%start list

%%

m       : /* empty */          { 
                                $$ = nextquad;
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
                                emit_set("=", $4, $3);
                              }
        ;

cond    : LP WHEN bool list RP m {
                                    backpatch($3, $6); // backpatch the target of the bool
                                    add_leader($3+1);
                                    add_leader($6);
                              }
        ;

loop    : LP LOOP WHILE m bool list RP m {
                                emit_goto($4); // goto $4
                                add_leader($4);

                                backpatch($5, $8+1); // backpatch the target of the bool
                                add_leader($5+1);
                                add_leader($8+1);
                              }
        ;

bool    : LP reln atom atom RP { // iffalse (expr1 reln expr2) goto _
                                emit_bool($2, $3, $4);
                                // add_leader(nextquad-2);
                                $$ = nextquad-1;
                              }
        ;

atom    : IDEN                  {
                                $$ = $1;
                              }
        | NUMB                  {
                                char *num = $1;
                                if (num[0] == '+') {
                                    $$ = num + 1;  // Skip the + sign
                                } else if (strcmp(num, "0") == 0 || strcmp(num, "+0") == 0 || strcmp(num, "-0") == 0) {
                                    $$ = "0";
                                } else {
                                    $$ = num;
                                }
                              }
        | expr                  {
                                $$ = $1;
                              }
        ;

expr    : LP oper atom atom RP { // temp = expr op expr
                                char *temp = gentmp();
                                emit_expr($2, $3, $4, temp);
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

void add_leader(int leader) {
    if(leaders[blockCounter-1] != leader) {
        leaders[blockCounter++] = leader;
    }
}

void backpatch(int quad_to_patch, int target_quad) {
    char str[10];
    sprintf(str, "%d", target_quad);
    char* target = strstr(quads[quad_to_patch], "_");
    if (target) {
        strcpy(target, str);
    }
}

void emit_goto(int jump_to) {
    sprintf(quads[nextquad++], "goto %d", jump_to);
}

void emit_set(char* op, char* arg, char* result) {
    sprintf(quads[nextquad++], "%s = %s", result, arg);
}

void emit_bool(char* op, char* arg1, char* arg2) {
    sprintf(quads[nextquad++], "iffalse (%s %s %s) goto _", arg1, op, arg2);
}

void emit_expr(char* op, char* arg1, char* arg2, char* result) {
    sprintf(quads[nextquad++], "%s = %s %s %s", result, arg1, op, arg2);
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

void sort(int leader[], int n) {
    for(int i=0; i<n; i++) {
        for(int j=i+1; j<n; j++) {
            if(leader[i] > leader[j]) {
                int temp = leader[i];
                leader[i] = leader[j];
                leader[j] = temp;
            }
        }
    }
}

int main(void) {
    yyparse();
    leaders[0] = 1;
    sort(leaders, blockCounter);
    int current_block = 0;

    for(int i=1; i<nextquad; i++) {
        if(leaders[current_block] == i) {
            if(i > 1) printf("\n");
            printf("Block %d\n", ++current_block);
        }
        printf("   %-5d: %s\n", i, quads[i]);
    }

    printf("\n");
    printf("   %-5d:", nextquad);

    return 0;
} 