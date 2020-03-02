#!/bin/bash
rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath=${BASH_SOURCE}
fi
root="$(cd $(dirname $rpath) && pwd)"
# write your code below

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

cat>README<<'EOF'
build commands:
    mkdir build && cd $_
    cmake ..
    make
EOF

cat>lex.l<<'EOF'
   /*Comment like this*/
%option noyywrap
%x C_COMMENT

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

        /* c style comments*/
"/*"                        { BEGIN(C_COMMENT); }
<C_COMMENT>"*/"             { BEGIN(INITIAL); }
<C_COMMENT>.                { }
<C_COMMENT>\n               { }
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