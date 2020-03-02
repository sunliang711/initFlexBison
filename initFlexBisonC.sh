#!/bin/bash

dest=${1}
if [ -z "${dest}" ];then
    echo -n "Enter install destination: "
    read dest
fi
if [ -z "${dest}" ];then
    echo "Wrong empty,Bye!"
    exit 1
fi

if [ ! -d "${dest}" ];then
    echo "Creating ${dest}..."
    mkdir -p "${dest}"
fi

cd "${dest}"

cat>common.h<<'EOF'
#include "__parser.h"

int yylex();
void yyerror(const char* msg);

extern int yylineno;
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
%option yylineno
%x C_COMMENT
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

        /* c style comments*/
"/*"            { BEGIN(C_COMMENT); }
<C_COMMENT>"*/" { BEGIN(INITIAL); }
<C_COMMENT>.    { }
<C_COMMENT>\n   { }
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


SET(PSD ${PROJECT_SOURCE_DIR})
SET(INTER_FILES ${PSD}/__lex.c ${PSD}/__parser.c ${PSD}/__parser.h ${PSD}/__parser.output)

add_custom_command(
    OUTPUT ${INTER_FILES}
    COMMAND flex -o ${PSD}/__lex.c ${PSD}/lex.l
    COMMAND bison -dvt -o ${PSD}/__parser.c ${PSD}/parser.y
    DEPENDS lex.l parser.y
)

SET(srcs __lex.c __parser.c main.c)
SET(exename parser)

ADD_EXECUTABLE(${exename} ${srcs})

EOF