#!/bin/bash

cat>common.h<<'EOF'
#include "parser.h"
int yylex();
void yyerror(const char* msg);

extern FILE* yyin;
EOF

cat>README<<'EOF'
build commands:
    mkdir build && cd $_
    cmake ..
    make
EOF

cat>lex.l<<'EOF'
%option noyywrap
%{
#include "common.h"
%}

%%
"+"             { return ADD;}
"-"             { return SUB; }
"*"             { return MUL; }
"/"             { return DIV; }
"|"             { return ABS; }
"("             { return OP; }
")"             { return CP; }
[0-9]+          { yylval.number = atoi(yytext); return NUMBER; }

\n              { return EOL; }
"//".*  
[ \t]           { /* ignore white space */ }
.               { yyerror("Mystery char");}
%%
EOF


cat>parser.y<<'EOF'
%{
#include <stdio.h>
#include "common.h"

%}
%error-verbose

%union{
    int number;
}


/* declare tokens */
/*
 * 只有需要用到值的终结符才用尖括号括起来
 * 并且它的值类型是union中定义的名称，并且要在lex.l中给它赋值 
 */
%token<number> NUMBER
%token ADD SUB MUL DIV ABS
%token OP CP
%token EOL

/*
 * 只有需要用到值的非终结符才用尖括号括起来
 * 并且它的值类型是union中定义的名称，并且要在lex.l中给它赋值 
 */
%type <number> term factor exp

%%

calclist: /* nothing */
 | calclist exp EOL { printf("= %d\n> ", $2); }
 ;

exp: factor
 | exp ADD factor { $$ = $1 + $3; }
 | exp SUB factor { $$ = $1 - $3; }
 ;

factor: term
 | factor MUL term { $$ = $1 * $3; }
 | factor DIV term { $$ = $1 / $3; }
 ;

term: NUMBER
 | ABS term { $$ = $2 >= 0? $2 : - $2; }
 | OP exp CP { $$ = $2; }
 ;
%%


void yyerror(const char *s)
{
  fprintf(stderr, "error: %s\n", s);
}

EOF

cat>main.c<<'EOF'
#include <stdio.h>
#include "common.h"

int main(int argc,char* argv[])
{
    if(argc > 1)
    {
        for(int i = 1; i < argc; ++i)
        {
            yyin = fopen(argv[i],"r");
            if(yyin == NULL)
            {
                printf("open %s error\n",argv[i]);
                return (-1);
            }
            yyparse();
        }
        return 0;
    }
  yyparse();
}

EOF

cat>CMakeLists.txt<<'EOF'
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
PROJECT(parser)


add_custom_command(
    OUTPUT ${PROJECT_SOURCE_DIR}/lex.c ${PROJECT_SOURCE_DIR}/parser.c ${PROJECT_SOURCE_DIR}/parser.h ${CMAKE_SOURCE_DIR}/parser.output
    COMMAND flex -o ${PROJECT_SOURCE_DIR}/lex.c ${PROJECT_SOURCE_DIR}/lex.l
    COMMAND bison -dvt -o ${PROJECT_SOURCE_DIR}/parser.c ${PROJECT_SOURCE_DIR}/parser.y
    DEPENDS lex.l parser.y
)

SET(srcs lex.c parser.c main.c)
SET(exename parser)

ADD_EXECUTABLE(${exename} ${srcs})

EOF