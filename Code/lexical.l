%{
#include "syntax.tab.h"
#include <stdio.h>
int yycolumn = 1;
#define YY_USER_ACTION \
    yylloc.first_line = yylloc.last_line = yylineno; \
    yylloc.first_column = yycolumn; \
    yylloc.last_column = yycolumn + yyleng - 1; \
    yycolumn += yyleng;
%}

%option yylineno
%option noyywrap

/* 正则表达式定义 */
/* 十进制、八进制、十六进制整型常数 [cite: 110, 111] */
DEC_INT     0|[1-9][0-9]*
OCT_INT     0[0-7]+
HEX_INT     0[xX][0-9a-fA-F]+

/* 普通浮点数和科学计数法浮点数 [cite: 113, 114] */
FLOAT_NORM  [0-9]+\.[0-9]+
FLOAT_EXP   ([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)[eE][+-]?[0-9]+
ILLEGAL_FLOAT_LEADING_ZERO  0[0-9]+\.[0-9]+([eE][+-]?[0-9]+)?

/* 标识符: 字母或下划线开头，由字母、数字、下划线组成 [cite: 115] */
ID          [a-zA-Z_][a-zA-Z0-9_]*

%%
    /* 空白字符处理 */
[ \t\r]+  { /* 忽略空白符 */ }
\n {yycolumn = 1;}
    /* 注释处理 [cite: 165, 166] */
"//".* { /* 单行注释 */ }
"/*"([^\*]|\*+[^/\*])*\*+"/" { /* 多行注释，无嵌套 */ }

    /* 关键字与类型 [cite: 22, 29, 30, 31, 32, 33] */
"int"|"float" { return TYPE; }
"struct"    { return STRUCT; }
"return"    { return RETURN; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }

    /* 常数与标识符识别 */
{ILLEGAL_FLOAT_LEADING_ZERO} { fprintf(stdout, "Error type A at Line %d: illegal number '%s'\n", yylineno, yytext); }
{DEC_INT}   { return INT; }
{OCT_INT}   { return INT; }
{HEX_INT}   { return INT; }
{FLOAT_NORM} { return FLOAT; }
{FLOAT_EXP} { return FLOAT; }
{ID}        { return ID; }

    /* 标点符号与运算符 [cite: 10-28] */
";"         { return SEMI; }
","         { return COMMA; }
"="         { return ASSIGNOP; }
">"|"<"|">="|"<="|"=="|"!=" { return RELOP; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return STAR; }
"/"         { return DIV; }
"&&"        { return AND; }
"||"        { return OR; }
"."         { return DOT; }
"!"         { return NOT; }
"("         { return LP; }
")"         { return RP; }
"["         { return LB; }
"]"         { return RB; }
"{"         { return LC; }
"}"         { return RC; }

.           { fprintf(stdout, "Error type A at Line %d: illegal token '%s'\n", yylineno, yytext); }
%%