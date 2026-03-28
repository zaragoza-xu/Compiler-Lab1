%{
#include "syntax.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static struct node *make_token_node(const char *symbol_name) {
    struct node *n = (struct node *)malloc(sizeof(struct node));
    if (!n) {
        return NULL;
    }
    n->token = strdup(symbol_name);
    n->name = strdup(symbol_name);
    n->child_count = 0;
    n->line_no = yylineno;
    return n;
}

int yycolumn = 1;
static int last_a_error_line = -1;

static void report_type_a_error(const char *kind, const char *text) {
    if (yylineno == last_a_error_line) {
        return;
    }
    fprintf(stdout, "Error type A at Line %d: illegal %s '%s'\n", yylineno, kind, text);
    last_a_error_line = yylineno;
}

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
    /* 注释处理: 注释在本实验中视为词法错误 */
"//".* { report_type_a_error("comment", yytext); }
"/*"([^\*]|\*+[^/\*])*\*+"/" { report_type_a_error("comment", yytext); }

    /* 关键字与类型 [cite: 22, 29, 30, 31, 32, 33] */
"int"|"float" { yylval.n = make_token_node("TYPE"); return TYPE; }
"struct"    { yylval.n = make_token_node("STRUCT"); return STRUCT; }
"return"    { yylval.n = make_token_node("RETURN"); return RETURN; }
"if"        { yylval.n = make_token_node("IF"); return IF; }
"else"      { yylval.n = make_token_node("ELSE"); return ELSE; }
"while"     { yylval.n = make_token_node("WHILE"); return WHILE; }

    /* 常数与标识符识别 */
{ILLEGAL_FLOAT_LEADING_ZERO} { report_type_a_error("number", yytext); }
{DEC_INT}   { yylval.n = make_token_node("INT"); return INT; }
{OCT_INT}   { yylval.n = make_token_node("INT"); return INT; }
{HEX_INT}   { yylval.n = make_token_node("INT"); return INT; }
{FLOAT_NORM} { yylval.n = make_token_node("FLOAT"); return FLOAT; }
{FLOAT_EXP} { report_type_a_error("number", yytext); }
{ID}        { yylval.n = make_token_node("ID"); return ID; }

    /* 标点符号与运算符 [cite: 10-28] */
";"         { yylval.n = make_token_node("SEMI"); return SEMI; }
","         { yylval.n = make_token_node("COMMA"); return COMMA; }
"="         { yylval.n = make_token_node("ASSIGNOP"); return ASSIGNOP; }
">"|"<"|">="|"<="|"=="|"!=" { yylval.n = make_token_node("RELOP"); return RELOP; }
"+"         { yylval.n = make_token_node("PLUS"); return PLUS; }
"-"         { yylval.n = make_token_node("MINUS"); return MINUS; }
"*"         { yylval.n = make_token_node("STAR"); return STAR; }
"/"         { yylval.n = make_token_node("DIV"); return DIV; }
"&&"        { yylval.n = make_token_node("AND"); return AND; }
"||"        { yylval.n = make_token_node("OR"); return OR; }
"."         { yylval.n = make_token_node("DOT"); return DOT; }
"!"         { yylval.n = make_token_node("NOT"); return NOT; }
"("         { yylval.n = make_token_node("LP"); return LP; }
")"         { yylval.n = make_token_node("RP"); return RP; }
"["         { yylval.n = make_token_node("LB"); return LB; }
"]"         { yylval.n = make_token_node("RB"); return RB; }
"{"         { yylval.n = make_token_node("LC"); return LC; }
"}"         { yylval.n = make_token_node("RC"); return RC; }

.           { report_type_a_error("token", yytext); }
%%
