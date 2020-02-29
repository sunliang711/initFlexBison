#!/bin/bash
rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
root="$(cd $(dirname $rpath) && pwd)"
# write your code below

cat>README<<'EOF'
build commands:
    mkdir build && cd $_
    cmake ..
    make
EOF

cat>lex.l<<'EOF'
   /*Comment like this*/
%option noyywrap

%{
#include <stdio.h>

int chars = 0;
int words = 0;
int lines = 0;
%}

%%
    /* COMMENT like this,not begin at the begining of line */
[a-zA-Z]+   { words++; chars += strlen(yytext); }
\n          { chars++; lines++; }
.           { chars++; }
%%

int main(int argc, char **argv)
{
    yylex();
    printf("%8d%8d%8d\n", lines, words, chars);
}
EOF

cat>CMakeLists.txt<<'EOF'
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
PROJECT(lexer)

SET(exename lexer)
SET(srcs lex.yy.c)

ADD_CUSTOM_COMMAND(
    OUTPUT ${PROJECT_SOURCE_DIR}/lex.yy.c
    COMMAND flex -o ${PROJECT_SOURCE_DIR}/lex.yy.c ${PROJECT_SOURCE_DIR}/lex.l
    DEPENDS lex.l
)

ADD_EXECUTABLE(${exename} ${srcs})
EOF