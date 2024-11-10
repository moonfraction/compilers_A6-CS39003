%{
#include "y.tab.h"
#include <stdio.h>
%}

%option noyywrap

%%
[ \t\n]         ; /* Skip whitespace */
"("             { return LP; }
")"             { return RP; }
"set"           { return SET; }
"when"          { return WHEN; }
"loop"          { return LOOP; }
"while"         { return WHILE; }
"+"             { return ADD; }
"-"             { return SUB; }
"*"             { return MUL; }
"/"             { return DIV; }
"%"             { return MOD; }
"="             { return EQ; }
"/="            { return NEQ; }
"<"             { return LT; }
">"             { return GT; }
"<="            { return LE; }
">="            { return GE; }
[+-]?([1-9][0-9]*|0) { yylval.strval = new string(yytext); return NUMB; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.strval = new string(yytext); return IDEN; }
.               { printf("Unexpected character: %s\n", yytext); }
%%
