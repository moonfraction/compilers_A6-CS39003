%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>

using namespace std;

extern void yyerror(const char *s);
extern int yylex(void);
extern int yyparse();

typedef struct _Quad {
    string op;
    string arg1;
    string arg2;
    string result;
} Quad;

typedef struct _symtable {
    string name;
    int is_temp;
    int reg;
} Symtable;


// Global variables
Quad quads[1000]; // to store the quads
Symtable st[1000]; // to store the symbol table
int nextquad = 1; // to store the next quad number
int tmpCounter = 1; // to store the temporary variable counter
int nextSymbol = 0; // to store next available symbol table entry

// Add symbol to symbol table if not already present
int add_symbol(string name, int is_temp) {
    for(int i = 0; i < nextSymbol; i++) {
        if(st[i].name == name) {
            return i;
        }
    }
    st[nextSymbol].name = name;
    st[nextSymbol].is_temp = is_temp;
    st[nextSymbol].reg = -1;
    return nextSymbol++;
}

string gentmp() { // to generate a temporary variable
    string tmp = "$" + to_string(tmpCounter++);
    add_symbol(tmp, 1); // Add temporary to symbol table
    return tmp;
}

void emit_goto(int jump_to);
void emit_set(string op, string arg, string result);
void emit_bool(string op, string arg1, string arg2);
void emit_expr(string op, string arg1, string arg2, string result);
void backpatch(int quad_no, int target_quad);
%}

%union {
    string* strval;    // IDEN, NUMB, atom
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
                                add_symbol(*$3, 0); // Add variable to symbol table
                                emit_set("=", *$4, *$3);
                                delete $3;
                                delete $4;
                              }
        ;

cond    : LP WHEN bool list RP m {
                                    backpatch($3, $6); // backpatch the target of the bool
                              }
        ;

loop    : LP LOOP WHILE m bool list RP m {
                                emit_goto($4); // goto $4
                                backpatch($5, $8+1); // backpatch the target of the bool
                              }
        ;

bool    : LP reln atom atom RP { // iffalse (expr1 reln expr2) goto _
                                emit_bool(*$2, *$3, *$4);
                                $$ = nextquad-1;
                                delete $2;
                                delete $3;
                                delete $4;
                              }
        ;

atom    : IDEN                  {
                                add_symbol(*$1, 0); // Add variable to symbol table
                                $$ = $1;
                              }
        | NUMB                  {
                                string num = *$1;
                                if (num[0] == '+') {
                                    $$ = new string(num.substr(1));  // Skip the + sign
                                } else if (num == "0" || num == "+0" || num == "-0") {
                                    $$ = new string("0");
                                } else {
                                    $$ = $1;
                                }
                              }
        | expr                  {
                                $$ = $1;
                              }
        ;

expr    : LP oper atom atom RP { // temp = expr op expr
                                string temp = gentmp();
                                emit_expr(*$2, *$3, *$4, temp);
                                $$ = new string(temp);
                                delete $2;
                                delete $3;
                                delete $4;
                              }
        ;

oper    : ADD                   { $$ = new string("+"); }
        | SUB                   { $$ = new string("-"); }
        | MUL                   { $$ = new string("*"); }
        | DIV                   { $$ = new string("/"); }
        | MOD                   { $$ = new string("%"); }
        ;

reln    : EQ                    { $$ = new string("=="); }
        | NEQ                   { $$ = new string("!="); }
        | LT                    { $$ = new string("<"); }
        | GT                    { $$ = new string(">"); }
        | LE                    { $$ = new string("<="); }
        | GE                    { $$ = new string(">="); }
        ;
%%

void backpatch(int quad_to_patch, int target_quad) {
    quads[quad_to_patch].result = to_string(target_quad);
}

void emit_goto(int jump_to) {
    quads[nextquad].op = "goto";
    quads[nextquad].result = to_string(jump_to);
    nextquad++;
}

void emit_set(string op, string arg, string result) {
    quads[nextquad].op = op;
    quads[nextquad].arg1 = arg;
    quads[nextquad].result = result;
    nextquad++;
}

void emit_bool(string op, string arg1, string arg2) {
    quads[nextquad].op = op;
    quads[nextquad].arg1 = arg1;
    quads[nextquad].arg2 = arg2;
    quads[nextquad].result = "_";
    nextquad++;
}

void emit_expr(string op, string arg1, string arg2, string result) {
    quads[nextquad].op = op;
    quads[nextquad].arg1 = arg1;
    quads[nextquad].arg2 = arg2;
    quads[nextquad].result = result;
    nextquad++;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}