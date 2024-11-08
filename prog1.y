%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
void yyerror(const char *s);

// Quad generation
int nextquad = 1; // Keeps track of the next quad index
void emit(const char* op, const char* arg1, const char* arg2, const char* result);
void backpatch(int quad, int target);
int newlabel();

// Structs for attributes used in backpatching
typedef struct backpatching_t {
    int truelist;
    int falselist;
    int nextlist;
} bkp;
typedef bkp* bkp_ptr;

// Symbol table management (simplified for illustration)
#define YYSTYPE char*

%}

%union {
    int intval;
    char* id;
    struct backpatching_t* bp; // pointer to backpatching_t
}

%token <id> IDEN
%token <intval> NUMB
%token <id> SET WHEN LOOP WHILE
%token <id> ADD SUB MUL DIV MOD
%token <id> EQ NEQ LT GT LE GE
%token LPAREN RPAREN
%type <bp> bool list stmt
%type <intval> m
%type <id> atom expr

%%

/* Marker non-terminals for backpatching */
m: /* empty */ { 
        // $$ = nextquad;
    }
    ;

/* Start Rule */
list: stmt | stmt list ;

/* Statements */
stmt: asgn { }
    | cond { }
    | loop { }
    ;

/* Assignment */
asgn: LPAREN SET IDEN atom RPAREN {
        emit("assign", $4, "", $3);
    }
    
    ;

/* Conditional (when statement) */
cond: LPAREN WHEN bool m list RPAREN {
        backpatch($3->truelist, $4);   // If true, execute the list
        backpatch($3->falselist, nextquad);     // If false, skip the list
    }
    ;

/* Loop (loop while statement) */
loop: LPAREN LOOP WHILE m bool m list RPAREN {
        backpatch($5->truelist, $6);     // If true, execute the list
        backpatch($5->falselist, nextquad); // Exit if condition is false
        emit("goto", "", "", $4);       // Jump back to condition
    }
    ;

/* Expressions and Booleans */
bool: LPAREN EQ atom atom RPAREN m {
        $$ = (bkp_ptr*)malloc(sizeof(bkp));
        $$->truelist = nextquad;
        $$->falselist = nextquad + 1;
        emit("if", $3, "==", $4);
        emit("goto", "", "", "-");
    }
    | LPAREN NEQ atom atom RPAREN m {
        $$ = (bkp_ptr*)malloc(sizeof(bkp));
        $$->truelist = nextquad;
        $$->falselist = nextquad + 1;
        emit("if", $3, "!=", $4);
        emit("goto", "", "", "-");
    }
    | LPAREN LT atom atom RPAREN m {
        $$ = (bkp_ptr*)malloc(sizeof(bkp));
        $$->truelist = nextquad;
        $$->falselist = nextquad + 1;
        emit("if", $3, "<", $4);
        emit("goto", "", "", "-");
    }
    | LPAREN GT atom atom RPAREN m {
        $$ = (bkp_ptr*)malloc(sizeof(bkp));
        $$->truelist = nextquad;
        $$->falselist = nextquad + 1;
        emit("if", $3, ">", $4);
        emit("goto", "", "", "-");
    }
    | LPAREN LE atom atom RPAREN m {
        $$ = (bkp_ptr*)malloc(sizeof(bkp));
        $$->truelist = nextquad;
        $$->falselist = nextquad + 1;
        emit("if", $3, "<=", $4);
        emit("goto", "", "", "-");
    }
    | LPAREN GE atom atom RPAREN m {
        $$ = (bkp_ptr*)malloc(sizeof(bkp));
        $$->truelist = nextquad;
        $$->falselist = nextquad + 1;
        emit("if", $3, ">=", $4);
        emit("goto", "", "", "-");
    }
    ;

/* Atoms and Identifiers */
atom: IDEN { $$ = $1; }
    | NUMB { $$ = $1; }
    | expr { $$ = $1; }
    ;

/* Arithmetic Expressions */
expr: LPAREN ADD atom atom RPAREN {
        $$ = newtemp();
        emit("+", $3, $4, $$);
    }
    | LPAREN SUB atom atom RPAREN {
        $$ = newtemp();
        emit("-", $3, $4, $$);
    }
    | LPAREN MUL atom atom RPAREN {
        $$ = newtemp();
        emit("*", $3, $4, $$);
    }
    | LPAREN DIV atom atom RPAREN {
        $$ = newtemp();
        emit("/", $3, $4, $$);
    }
    | LPAREN MOD atom atom RPAREN {
        $$ = newtemp();
        emit("%", $3, $4, $$);
    }
    ;

%%

/* Helper functions */
void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

void emit(const char* op, const char* arg1, const char* arg2, const char* result) {
    printf("%d: %s %s %s %s\n", nextquad++, op, arg1, arg2, result);
}

void backpatch(int quad, int target) {
    printf("Backpatching quad %d to target %d\n", quad, target);
    // In a real implementation, this would modify the code at quad to jump to target
}

int newlabel() {
    return nextquad;
}

char* newtemp() {
    static int tempCount = 0;
    char* temp = (char*)malloc(8);
    sprintf(temp, "t%d", tempCount++);
    return temp;
}

int main() {
    yyparse();
    return 0;
}
