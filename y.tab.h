/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     IDEN = 258,
     NUMB = 259,
     LP = 260,
     RP = 261,
     SET = 262,
     WHEN = 263,
     LOOP = 264,
     WHILE = 265,
     ADD = 266,
     SUB = 267,
     MUL = 268,
     DIV = 269,
     MOD = 270,
     EQ = 271,
     NEQ = 272,
     LT = 273,
     GT = 274,
     LE = 275,
     GE = 276
   };
#endif
/* Tokens.  */
#define IDEN 258
#define NUMB 259
#define LP 260
#define RP 261
#define SET 262
#define WHEN 263
#define LOOP 264
#define WHILE 265
#define ADD 266
#define SUB 267
#define MUL 268
#define DIV 269
#define MOD 270
#define EQ 271
#define NEQ 272
#define LT 273
#define GT 274
#define LE 275
#define GE 276




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 33 "prog.y"
{
    char* strval;    // IDEN, NUMB, atom
    int quadno;  // for bool
    int linemark;     // m
    int blockmark;    // n
}
/* Line 1529 of yacc.c.  */
#line 98 "y.tab.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE yylval;

