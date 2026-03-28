%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
void yyerror(const char *s);
int yylex(void);
extern char* yytext;
extern int yylineno;
extern YYLTYPE yylloc;
static int last_b_error_line = -1;

struct node {
    char *token;
    char *name;
    struct node *children[10]; /* 假设每个节点最多有10个子节点 */
    int child_count;
    int line_no; /* 行号 */
};

static struct node *create_node(const char *symbol_name, int line_no) {
  struct node *n = (struct node *)malloc(sizeof(struct node));
  if (!n) {
    return NULL;
  }
  n->token = strdup(symbol_name);
  n->name = strdup(symbol_name);
  n->child_count = 0;
  n->line_no = line_no;
  return n;
}

static void ensure_token(struct node *n, const char *symbol_name) {
  if (!n) {
    return;
  }
  if (!n->token) {
    n->token = strdup(symbol_name);
  }
  if (!n->name) {
    n->name = strdup(symbol_name);
  }
}

static void add_child(struct node *parent, struct node *child) {
  if (parent && child && parent->child_count < 10) {
    parent->children[parent->child_count++] = child;
    }
}

static struct node *make_nonterminal(const char *symbol_name) {
  return create_node(symbol_name, yylineno);
}

#include "lex.yy.c"
%}
%union{
  struct node *n;
}

%locations
/* 声明终结符 (Tokens) */
%token <n> INT FLOAT ID
%token <n> TYPE STRUCT RETURN IF ELSE WHILE
%token <n> SEMI COMMA ASSIGNOP RELOP PLUS MINUS STAR DIV
%token <n> AND OR DOT NOT LP RP LB RB LC RC

%type <n> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier
%type <n> OptTag Tag VarDec FunDec VarList ParamDec CompSt StmtList Stmt
%type <n> DefList Def DecList Dec Exp Args

/* * 运算符优先级与结合性声明 (数字越大优先级越高)
 * 解决表达式规约时的二义性问题 
 */
%right ASSIGNOP          /* 优先级 8: 赋值，右结合 */
%left OR                 /* 优先级 7: 逻辑或，左结合 */
%left AND                /* 优先级 6: 逻辑与，左结合 */
%left RELOP              /* 优先级 5: 关系运算，左结合 */
%left PLUS MINUS         /* 优先级 4: 加减，左结合 */
%left STAR DIV           /* 优先级 3: 乘除，左结合 */
%right NOT UMINUS        /* 优先级 2: 逻辑非与取负(一元)，右结合 */
%left LP RP LB RB DOT    /* 优先级 1: 括号与访问符，左结合 */

/* 解决 IF-ELSE 悬挂问题 */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
/* High-level Definitions */
Program:
      ExtDefList
      {
          $$ = make_nonterminal("Program");
          add_child($$, $1);
      }
    ;

ExtDefList:
      ExtDef ExtDefList
      {
          $$ = make_nonterminal("ExtDefList");
          add_child($$, $1);
          add_child($$, $2);
      }
    | /* empty */
      {
          $$ = make_nonterminal("ExtDefList");
      }
    ;

ExtDef:
      Specifier ExtDecList SEMI
      {
          $$ = make_nonterminal("ExtDef");
          ensure_token($3, "SEMI");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Specifier SEMI
      {
          $$ = make_nonterminal("ExtDef");
          ensure_token($2, "SEMI");
          add_child($$, $1);
          add_child($$, $2);
      }
    | Specifier FunDec CompSt
      {
          $$ = make_nonterminal("ExtDef");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Specifier error SEMI    
      {
          yyerrok; 
      }
    ;

ExtDecList:
      VarDec
      {
          $$ = make_nonterminal("ExtDecList");
          add_child($$, $1);
      }
    | VarDec COMMA ExtDecList
      {
          $$ = make_nonterminal("ExtDecList");
          ensure_token($2, "COMMA");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    ;

/* Specifiers */
Specifier:
      TYPE
      {
          $$ = make_nonterminal("Specifier");
          ensure_token($1, "TYPE");
          add_child($$, $1);
      }
    | StructSpecifier
      {
          $$ = make_nonterminal("Specifier");
          add_child($$, $1);
      }
    ;

StructSpecifier:
      STRUCT OptTag LC DefList RC
      {
          $$ = make_nonterminal("StructSpecifier");
          ensure_token($1, "STRUCT");
          ensure_token($3, "LC");
          ensure_token($5, "RC");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
          add_child($$, $4);
          add_child($$, $5);
      }
    | STRUCT Tag
      {
          $$ = make_nonterminal("StructSpecifier");
          ensure_token($1, "STRUCT");
          add_child($$, $1);
          add_child($$, $2);
      }
    ;

OptTag:
      ID
      {
          $$ = make_nonterminal("OptTag");
          ensure_token($1, "ID");
          add_child($$, $1);
      }
    | /* empty */
      {
          $$ = make_nonterminal("OptTag");
      }
    ;

Tag:
      ID
      {
          $$ = make_nonterminal("Tag");
          ensure_token($1, "ID");
          add_child($$, $1);
      }
    ;

/* Declarators */
VarDec:
      ID
      {
          $$ = make_nonterminal("VarDec");
          ensure_token($1, "ID");
          add_child($$, $1);
      }
    | VarDec LB INT RB
      {
          $$ = make_nonterminal("VarDec");
          ensure_token($2, "LB");
          ensure_token($3, "INT");
          ensure_token($4, "RB");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
          add_child($$, $4);
      }
    ;

FunDec:
      ID LP VarList RP
      {
          $$ = make_nonterminal("FunDec");
          ensure_token($1, "ID");
          ensure_token($2, "LP");
          ensure_token($4, "RP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
          add_child($$, $4);
      }
    | ID LP RP
      {
          $$ = make_nonterminal("FunDec");
          ensure_token($1, "ID");
          ensure_token($2, "LP");
          ensure_token($3, "RP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    ;

VarList:
      ParamDec COMMA VarList
      {
          $$ = make_nonterminal("VarList");
          ensure_token($2, "COMMA");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | ParamDec
      {
          $$ = make_nonterminal("VarList");
          add_child($$, $1);
      }
    ;

ParamDec:
      Specifier VarDec
      {
          $$ = make_nonterminal("ParamDec");
          add_child($$, $1);
          add_child($$, $2);
      }
    ;

/* Statements */
CompSt:
      LC DefList StmtList RC
      {
          $$ = make_nonterminal("CompSt");
          ensure_token($1, "LC");
          ensure_token($4, "RC");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
          add_child($$, $4);
      }
    | LC error RC  
      { 
          yyerrok; 
      }
    ;

StmtList:
      Stmt StmtList
      {
          $$ = make_nonterminal("StmtList");
          add_child($$, $1);
          add_child($$, $2);
      }
    | /* empty */
      {
          $$ = make_nonterminal("StmtList");
      }
    ;

Stmt:
      Exp SEMI
      {
          $$ = make_nonterminal("Stmt");
          ensure_token($2, "SEMI");
          add_child($$, $1);
          add_child($$, $2);
      }
    | CompSt
      {
          $$ = make_nonterminal("Stmt");
          add_child($$, $1);
      }
    | RETURN Exp SEMI
      {
          $$ = make_nonterminal("Stmt");
          ensure_token($1, "RETURN");
          ensure_token($3, "SEMI");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | IF LP Exp RP Stmt %prec LOWER_THAN_ELSE
      {
          $$ = make_nonterminal("Stmt");
          ensure_token($1, "IF");
          ensure_token($2, "LP");
          ensure_token($4, "RP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
          add_child($$, $4);
          add_child($$, $5);
      }
    | IF LP Exp RP Stmt ELSE Stmt
      {
          $$ = make_nonterminal("Stmt");
          ensure_token($1, "IF");
          ensure_token($2, "LP");
          ensure_token($4, "RP");
          ensure_token($6, "ELSE");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
          add_child($$, $4);
          add_child($$, $5);
          add_child($$, $6);
          add_child($$, $7);
      }
    | WHILE LP Exp RP Stmt
      {
          $$ = make_nonterminal("Stmt");
          ensure_token($1, "WHILE");
          ensure_token($2, "LP");
          ensure_token($4, "RP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
          add_child($$, $4);
          add_child($$, $5);
      }
    | error SEMI              
      { 
          yyerrok; 
      }
    | RETURN error SEMI       
      { 
          yyerrok; 
      }
    | IF LP error RP Stmt %prec LOWER_THAN_ELSE 
      { 
          yyerrok; 
      }
    | IF LP error RP Stmt ELSE Stmt 
      { 
          yyerrok; 
      }
    | WHILE LP error RP Stmt  
      { 
          yyerrok; 
      }
    ;

/* Local Definitions */
DefList:
      Def DefList
      {
          $$ = make_nonterminal("DefList");
          add_child($$, $1);
          add_child($$, $2);
      }
    | /* empty */
      {
          $$ = make_nonterminal("DefList");
      }
    ;

Def:
      Specifier DecList SEMI
      {
          $$ = make_nonterminal("Def");
          ensure_token($3, "SEMI");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Specifier error SEMI    
      { 
          yyerrok; 
      }
    ;

DecList:
      Dec
      {
          $$ = make_nonterminal("DecList");
          add_child($$, $1);
      }
    | Dec COMMA DecList
      {
          $$ = make_nonterminal("DecList");
          ensure_token($2, "COMMA");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    ;

Dec:
      VarDec
      {
          $$ = make_nonterminal("Dec");
          add_child($$, $1);
      }
    | VarDec ASSIGNOP Exp
      {
          $$ = make_nonterminal("Dec");
          ensure_token($2, "ASSIGNOP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    ;

/* Expressions */
Exp:
      Exp ASSIGNOP Exp
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "ASSIGNOP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Exp AND Exp
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "AND");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Exp OR Exp
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "OR");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Exp RELOP Exp
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "RELOP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Exp PLUS Exp
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "PLUS");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Exp MINUS Exp
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "MINUS");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Exp STAR Exp
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "STAR");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Exp DIV Exp
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "DIV");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | LP Exp RP
      {
          $$ = make_nonterminal("Exp");
          ensure_token($1, "LP");
          ensure_token($3, "RP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | MINUS Exp %prec UMINUS  /* 取负运算，依赖前面声明的优先级 */
      {
          $$ = make_nonterminal("Exp");
          ensure_token($1, "MINUS");
          add_child($$, $1);
          add_child($$, $2);
      }
    | NOT Exp
      {
          $$ = make_nonterminal("Exp");
          ensure_token($1, "NOT");
          add_child($$, $1);
          add_child($$, $2);
      }
    | ID LP Args RP
      {
          $$ = make_nonterminal("Exp");
          ensure_token($1, "ID");
          ensure_token($2, "LP");
          ensure_token($4, "RP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
          add_child($$, $4);
      }
    | ID LP RP
      {
          $$ = make_nonterminal("Exp");
          ensure_token($1, "ID");
          ensure_token($2, "LP");
          ensure_token($3, "RP");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Exp LB Exp RB
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "LB");
          ensure_token($4, "RB");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
          add_child($$, $4);
      }
    | Exp DOT ID
      {
          $$ = make_nonterminal("Exp");
          ensure_token($2, "DOT");
          ensure_token($3, "ID");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | ID
      {
          $$ = make_nonterminal("Exp");
          ensure_token($1, "ID");
          add_child($$, $1);
      }
    | INT
      {
          $$ = make_nonterminal("Exp");
          ensure_token($1, "INT");
          add_child($$, $1);
      }
    | FLOAT
      {
          $$ = make_nonterminal("Exp");
          ensure_token($1, "FLOAT");
          add_child($$, $1);
      }
    ;

Args:
      Exp COMMA Args
      {
          $$ = make_nonterminal("Args");
          ensure_token($2, "COMMA");
          add_child($$, $1);
          add_child($$, $2);
          add_child($$, $3);
      }
    | Exp
      {
          $$ = make_nonterminal("Args");
          add_child($$, $1);
      }
    ;
%%

void yyerror(const char *s) {
  int line = yylloc.first_line;
  if (line <= 0) {
    line = yylineno;
  }
  if (line != last_b_error_line) {
    fprintf(stdout, "Error type B at Line %d: illegal '%s'\n", line, yytext ? yytext : "");
    last_b_error_line = line;
  }
}
