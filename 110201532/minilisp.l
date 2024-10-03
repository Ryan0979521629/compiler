%{
#include "minilisp.tab.h"
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
%}
letter [a-z]
digit [0-9]
bool_valof_t  #t
bool_valof_f #f
%%
"+" {return PLUS;}
"-" {return MINUS;}
"*" {return MUL;}
"/" {return DIV;}
"mod" {return MOD;}
">" {return GREATER;}
"<" {return SMALLER;}
"=" {return EQUAL;}
"and" {return AND;}
"or" {return OR;}
"not" {return NOT;}
"define" {return DEFINE;}
"fun" {return FUN;}
"if" {return IF;} 
"print-num" {return PRINTNUM;}
"print-bool" {return PRINTBOOL;}
"(" {return lpr;}
")" {return rpr;}

[ |\t|\n|\r] {;}
0|[1-9]{digit}*|-[1-9]{digit}* {yylval.ival=atoi(yytext);return number;}
#t {yylval.ival=1; return bool;}
#f {yylval.ival=0; return bool;}
{letter}({letter}|{digit}|\-)* {
						char *tem=(char*)malloc(strlen(yytext));
						for(int i=0;i<strlen(yytext);i++){
						    tem[i]=yytext[i];
						}
						yylval.cval=tem;
						return id;
                        }
.       {printf("Unexpected Character! %s\n",yytext); exit(1);}
%%
int yywrap() {
    return 1;
}