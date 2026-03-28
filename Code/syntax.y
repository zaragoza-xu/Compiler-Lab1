%{
#include <stdio.h>
#include "lex.yy.c"
void yyerror(const char *s);
int yylex(void);
extern char* yytext;
extern YYLTYPE yylloc;
%}
%union{
  int type_int;
  float type_float;
  double type_double;
}

%locations
/* 声明终结符 (Tokens) */
%token <type_int>INT
%token <type_float>FLOAT
%token ID
%token TYPE STRUCT RETURN IF ELSE WHILE
%token SEMI COMMA ASSIGNOP RELOP PLUS MINUS STAR DIV
%token AND OR DOT NOT LP RP LB RB LC RC

/* * 运算符优先级与结合性声明 (数字越大优先级越高)
 * 解决表达式规约时的二义性问题 
 */
%right ASSIGNOP          /* 优先级 8: 赋值，右结合 [cite: 150] */
%left OR                 /* 优先级 7: 逻辑或，左结合 [cite: 150] */
%left AND                /* 优先级 6: 逻辑与，左结合 [cite: 150] */
%left RELOP              /* 优先级 5: 关系运算，左结合 [cite: 150] */
%left PLUS MINUS         /* 优先级 4: 加减，左结合 [cite: 150] */
%left STAR DIV           /* 优先级 3: 乘除，左结合 [cite: 150] */
%right NOT UMINUS        /* 优先级 2: 逻辑非与取负(一元)，右结合 [cite: 150] */
%left LP RP LB RB DOT    /* 优先级 1: 括号与访问符，左结合 [cite: 150] */

/* 解决 IF-ELSE 悬挂问题 */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
/* High-level Definitions [cite: 36] */
Program:
      ExtDefList              /* [cite: 37] */
    ;

ExtDefList:
      ExtDef ExtDefList       /* [cite: 38] */
    | /* empty */             /* [cite: 39] */
    ;

ExtDef:
      Specifier ExtDecList SEMI /* [cite: 41] */
    | Specifier SEMI          /* [cite: 42] */
    | Specifier FunDec CompSt   /* [cite: 43] */
    ;

ExtDecList:
      VarDec                  /* [cite: 44] */
    | VarDec COMMA ExtDecList /* [cite: 45] */
    ;

/* Specifiers [cite: 46] */
Specifier:
      TYPE                    /* [cite: 47] */
    | StructSpecifier         /* [cite: 48] */
    ;

StructSpecifier:
      STRUCT OptTag LC DefList RC /* [cite: 49] */
    | STRUCT Tag              /* [cite: 50] */
    ;

OptTag:
      ID                      /* [cite: 52] */
    | /* empty */             /* [cite: 53] */
    ;

Tag:
      ID                      /* [cite: 54] */
    ;

/* Declarators [cite: 55] */
VarDec:
      ID                      /* [cite: 56] */
    | VarDec LB INT RB        /* [cite: 61] */
    ;

FunDec:
      ID LP VarList RP        /* [cite: 62] */
    | ID LP RP                /* [cite: 63] */
    ;

VarList:
      ParamDec COMMA VarList  /* [cite: 66] */
    | ParamDec                /* [cite: 65] */
    ;

ParamDec:
      Specifier VarDec        /* [cite: 67] */
    ;

/* Statements [cite: 68] */
CompSt:
      LC DefList StmtList RC  /* [cite: 69] */
    ;

StmtList:
      Stmt StmtList           /* [cite: 70] */
    | /* empty */             /* [cite: 71] */
    ;

Stmt:
      Exp SEMI                /* [cite: 72] */
    | CompSt                  /* [cite: 73] */
    | RETURN Exp SEMI         /* [cite: 74] */
    | IF LP Exp RP Stmt %prec LOWER_THAN_ELSE /* [cite: 75] */
    | IF LP Exp RP Stmt ELSE Stmt /* [cite: 76] */
    | WHILE LP Exp RP Stmt    /* [cite: 77] */
    ;

/* Local Definitions [cite: 78] */
DefList:
      Def DefList             /* [cite: 79] */
    | /* empty */             /* [cite: 80] */
    ;

Def:
      Specifier DecList SEMI  /* [cite: 81] */
    ;

DecList:
      Dec                     /* [cite: 81] */
    | Dec COMMA DecList       /* [cite: 82] */
    ;

Dec:
      VarDec                  /* [cite: 83] */
    | VarDec ASSIGNOP Exp     /* [cite: 84] */
    ;

/* Expressions [cite: 85] */
Exp:
      Exp ASSIGNOP Exp        /* [cite: 86] */
    | Exp AND Exp             /* [cite: 87] */
    | Exp OR Exp              /* [cite: 88] */
    | Exp RELOP Exp           /* [cite: 89] */
    | Exp PLUS Exp            /* [cite: 90] */
    | Exp MINUS Exp           /* [cite: 91] */
    | Exp STAR Exp            /* [cite: 92] */
    | Exp DIV Exp             /* [cite: 93] */
    | LP Exp RP               /* [cite: 94] */
    | MINUS Exp %prec UMINUS  /* 取负运算，依赖前面声明的优先级 [cite: 95] */
    | NOT Exp                 /* [cite: 96] */
    | ID LP Args RP           /* [cite: 97] */
    | ID LP RP                /* [cite: 98] */
    | Exp LB Exp RB           /* [cite: 99] */
    | Exp DOT ID              /* [cite: 100] */
    | ID                      /* [cite: 101] */
    | INT                     /* [cite: 102] */
    | FLOAT                   /* [cite: 103] */
    ;

Args:
      Exp COMMA Args          /* [cite: 104] */
    | Exp                     /* [cite: 105] */
    ;
%%

void yyerror(const char *s) {
  fprintf(stdout, "Error type B at Line %d: illegal '%s'\n", yylloc.first_line, yytext ? yytext : "");
}