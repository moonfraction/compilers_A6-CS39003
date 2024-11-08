%{
#include "y.tab.h"
#include <stdio.h>
%}

%option noyywrap

%%
[ \t\n]         { printf("WHITESPACE: '%s'\n", yytext); }; /* Skip whitespace */
"("             { printf("LPAREN: '%s'\n", yytext); }
")"             { printf("RPAREN: '%s'\n", yytext); }
"set"           { printf("SET: '%s'\n", yytext); }
"when"          { printf("WHEN: '%s'\n", yytext); }
"loop"          { printf("LOOP: '%s'\n", yytext); }
"while"         { printf("WHILE: '%s'\n", yytext); }
"+"             { printf("ADD: '%s'\n", yytext); }
"-"             { printf("SUB: '%s'\n", yytext); }
"*"             { printf("MUL: '%s'\n", yytext); }
"/"             { printf("DIV: '%s'\n", yytext); }
"%"             { printf("MOD: '%s'\n", yytext); }
"="             { printf("EQ: '%s'\n", yytext); }
"/="            { printf("NEQ: '%s'\n", yytext); }
"<"             { printf("LT: '%s'\n", yytext); }
">"             { printf("GT: '%s'\n", yytext); }
"<="            { printf("LE: '%s'\n", yytext); }
">="            { printf("GE: '%s'\n", yytext); }
[0-9]+          { printf("NUMBER: '%s'\n", yytext);}
[a-zA-Z_][a-zA-Z0-9_]* { printf("IDENTIFIER: '%s'\n", yytext); }
.               { printf("Unexpected character: %s\n", yytext); }
%%

int main(int argc, char **argv) {
    yylex();
    return 0;
}