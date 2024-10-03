# MiniLisp final_project
## 學號:110201532 姓名:范植緯 系級:資工3A
## 以下為程式碼的解釋
### LEX檔
```
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
```
以上為可以將輸入轉成token的一些種類，首先先定義了letter、digit和true false的形式，底下的部分則是當抓到特殊字串就會return到yacc，像是基本抓到的+、-、*、/在我遇到之後，就會return到yacc給他知道有這些字串(名子都是自己訂的)，比較特別的是當遇到上述digit符合那樣規則的話，要先將數值轉到yacc裡union所定義的形式，再來return到yacc中。
使用這種定義的variable，如以下形式
```
%union {
    int ival;
    char *cval;
    struct node *nd;
}
%token <ival> number
```
定義了number為ival的形式，我在lex檔中使用yylval.ival代表著形式，轉送的variable是number，其餘的character也是這樣，最後還設定了當遇到不是rule裡面的字串就輸出"Unexpected Character!"
## 以上為將輸入的資料轉成token到yacc做處理的lex檔，接下來來說說該怎麼處理這些token吧~
## yacc檔
```
%{
#include <stdio.h>
#include<stdlib.h>
#include <string.h>
void yyerror(const char *message);
void printerror();
enum ASTtype
{
ast_plus,ast_minus,ast_multiply,ast_divide,ast_greater,ast_smaller,ast_equal,ast_mod,ast_and,
ast_or,ast_not,ast_num,ast_var
};
typedef struct node{
    enum ASTtype type;			
    char *name;						
    int val;						
    struct node *l;                 
    struct node *r;                 
}ast_node;

typedef struct var{ 				
    char* name;						
    int val;						
    struct node *tree;
}Var;

ast_node *CreateNode(enum ASTtype newnode_type,int Value,char *Name);	
int get_varindex(char *Name);
int DFS_evaluate(ast_node *tree);					
void put_paramater(ast_node *tree);					
void clear_fun_variable();					
int set_function_var(char *Name,int position);
int get_fun_varindex(char *Name);
Var variable_stack[300];							
int vstop=0;							

Var function_variable_stack[300];	  	
int fun_vsp=0;	 						
int fun_position=0;						
int para[300]={0}; 						
int pa_position=0; 						
%}

%union {
    int ival;
    char *cval;
    struct node *nd;
}
%token <ival> number
%token <ival> bool
%token<cval>id

%token PLUS MINUS MUL DIV MOD GREATER SMALLER EQUAL AND OR NOT lpr rpr DEFINE FUN IF PRINTNUM PRINTBOOL
%start program
%type <nd> exp variable NUM_OP LOGICAL_OP FUN_EXP FUN_CALL IF_EXP fun_body
%type <nd> exps_plus exps_mul exps_equal exps_and exps_or
%type <nd> and_op or_op not_op
%type <nd> test_exp then_exp else_exp
%type <nd> plus minus multipy modulus divide greater smaller equal 
%type <ival>param params fun_name

```
首先就是先引入一些接下來C語言會用到的Library，再來定義的ASTtype是我們要做ast_tree時會用到的type形式，並且為了要使用ast tree，定義了node形式可以放入名子(當要接收variable時可使用)，和數值(當接收數值或bool值使用)及這個node的type是什麼和左右child
並且定義了var這個struct，裡面是為了要讓variable可以跟數值做連結，專門用在和parameter或define時使用，接者就是一連串的prototype，並設定了兩種不同的stack，一個負責記錄單純define 的variable，一個負責記錄function的variable，並且還有para[300]這是負責記錄function會傳的parameter，其餘的vstop，fun_vsp等都是為了做stack的操作用的。
最後union還有token、type等定義就是yacc負責用來抓形式做動作的東西。
## 在開始看規則前，先來看function吧
```
ast_node *CreateNode(enum ASTtype newnode_type,int Value,char *Name){
    ast_node* new_node=(ast_node*)malloc(sizeof(ast_node));
    new_node->type=newnode_type;
    new_node->val=Value;
    new_node->name=Name;
    new_node->l=NULL;
    new_node->r=NULL;
    return new_node;
}
int get_varindex(char *Name){
    for(int i=0;i<vstop;i++){
        if(strcmp(Name,variable_stack[i].name)==0){
            return i;
        }
    }
    return -1;
}
int set_function_var(char *Name,int position){
    int sp=get_fun_varindex(Name);
    if (sp==-1){
        fun_vsp++;
        function_variable_stack[fun_vsp].name=Name;
        function_variable_stack[fun_vsp].val=position;
        return fun_vsp;
    }else {
        function_variable_stack[sp].val=position;
        return sp;
    }
}
int get_fun_varindex(char *Name){
    for(int i=1;i<=fun_vsp;i++){
        if(strcmp(Name,function_variable_stack[i].name)==0){return i;}
    }
    return -1;
}

int DFS_evaluate(ast_node* tree){
    if(tree==NULL)return 0;
    if(tree->type<=10&&tree->type>=0){
        int left=0; int right=0;
        left=DFS_evaluate(tree->l);
        right=DFS_evaluate(tree->r);
        switch(tree->type){
            case ast_plus:
                return left+right;
            case ast_minus:
                return left-right;
            case ast_multiply:
                return left*right;
            case ast_divide:
                return left/right;
            case ast_mod:
                return left%right;
            case ast_and:
                return left&&right;
            case ast_or:
                return left||right;
            case ast_not:
                return !left;
            case ast_equal:
                return left==right;
            case ast_greater:
                return left>right;
            case ast_smaller:
                return left<right;
            default:
                return 0;
        }
    }
    else {
        int tmp;
        switch(tree->type){
            case ast_num:
                return tree->val;
            case ast_var:
                tmp=get_varindex(tree->name);
                return variable_stack[tmp].val;
            default:
                return 0;
        }
    }
}

void put_paramater(ast_node *tree){
    if(tree!=NULL){
        if(tree->type==ast_var&&function_variable_stack[get_fun_varindex(tree->name)].val!=0){ 
    	    tree->type=ast_num;
	    tree->val=para[function_variable_stack[get_fun_varindex(tree->name)].val];
	}
	put_paramater(tree->l);
	put_paramater(tree->r);
    }
}
void clear_fun_variable(){
    for(int i=1;i<=fun_vsp;i++){
        function_variable_stack[i].val=0;
    }
}
void printerror(){
    printf("type error");
}
void yyerror (const char *message)
{
        fprintf (stderr, "%s\n",message);
}

int main(int argc, char *argv[]) {
        yyparse();
        return(0);
}

```
以上function一一做介紹
CreateNode:

    負責創造新的node，在輸入為variable或數值時，就會使用這個function創造node，並且沒有左右的child，最後return回規則。
get_varindex:

    負責回傳variable在我們的variable stack中的index位置，如果都找不到return -1。
set_function_var:

    負責將function的variable丟入function_variable_stack中，首先檢查有沒有重複的已經在stack，沒有的話就放入stack，並回傳放入stack的位置，如果有就更改數值，並回傳位置。
get_fun_varindex:
    
    檢查在function_var_stack有沒有相同名子，有就回傳位置，沒有就回傳-1
DFS_evaluate:

    這個function很重要，輸入進來的是node，他會先用recursive的方式找到最下面的leaf，並且檢查type，如果type是加就讓底下兩個node做加法，依此類推，那如果今天碰到的是數值，就回傳數值，如果是variable，就去variable_stack抓數值並回傳，用這個function主要的目的就是算出node的數值。
put_paramater:

    丟進來的是node，他會將輸入的node去跟parameter做配對，原因是因為輸入的function_variable跟parameter順序是相同的，所以可以直接去做對應。
clear_fun_variable:

    當function用完後，把function_variable_stack的數值清空，代表不需要這些variable了。
    
## 以上為function的介紹，接下來是rule
## 基本上就是跟MiniLisp上給的Grammar相同
```
program     : stmts     {;}
            ;
stmts       : stmts stmt
            | stmt
            ;
stmt        :exp        {;}
            |def_stmt   {;}
            |print_def  {;}
            ;
print_def   :lpr PRINTNUM exp rpr {printf("%d\n",DFS_evaluate($3));}
            |lpr PRINTBOOL exp rpr {int result=DFS_evaluate($3);
                                    if(result){printf("#t\n");}else{printf("#f\n");}}
            ;
```
比較需要注意的是右方做的動作，當是要print-num時，就將expression藉由剛剛介紹的DFS_evaluate來算出數值並且print出來，print-bool也是相同。
```
exp         :bool       {ast_node *newnode=CreateNode(ast_num,$1,"");
                        $$=newnode;}
            |number     {ast_node *newnode=CreateNode(ast_num,$1,"");
                        $$=newnode;}
            |variable   {$$=$1;}
            |NUM_OP     {$$=$1;}
            |LOGICAL_OP {$$=$1;}
            |FUN_EXP    {$$=$1;}
            |FUN_CALL   {$$=$1;}
            |IF_EXP     {$$=$1;}
            ;
NUM_OP      :plus       {$$=$1;}
            |minus      {$$=$1;}
            |multipy    {$$=$1;}
            |divide     {$$=$1;}
            |modulus    {$$=$1;}
            |greater    {$$=$1;}
            |smaller    {$$=$1;}
            |equal      {$$=$1;}
            ;
```
exp這部分特別的是在當遇到num和bool型態的東西時，就創建node，把數值丟入並且設定相關的type，其餘的都只是將數值傳回$$就好。
```
plus        :lpr PLUS exp exps_plus rpr  {ast_node *newnode=CreateNode(ast_plus,0,"");
                                        newnode->l=$3;
                                        newnode->r=$4;
                                        $$=newnode;}
            |lpr PLUS rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr PLUS exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;
exps_plus   :exp        {$$=$1;}
            |exps_plus exp   {ast_node *newnode=CreateNode(ast_plus,0,"");
                        newnode->l=$1;
                        newnode->r=$2;
                        $$=newnode;
                        }
            ;
minus       :lpr MINUS exp exp rpr  {ast_node *newnode=CreateNode(ast_minus,0,"");
                                    newnode->l=$3;
                                    newnode->r=$4;
                                    $$=newnode;}
            |lpr MINUS rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr MINUS exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;
multipy     :lpr MUL exp exps_mul rpr{ast_node *newnode=CreateNode(ast_multiply,0,"");
                                    newnode->l=$3;
                                    newnode->r=$4;
                                    $$=newnode;}
            |lpr MUL rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr MUL exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;
exps_mul    :exp    {$$=$1;}
            |exps_mul exp   {ast_node *newnode=CreateNode(ast_multiply,0,"");
                            newnode->l=$1;
                            newnode->r=$2;
                            $$=newnode;
            }
            ;
divide      :lpr DIV exp exp rpr    {ast_node *newnode=CreateNode(ast_divide,0,"");
                                    newnode->l=$3;
                                    newnode->r=$4;
                                    $$=newnode;}
            |lpr DIV rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr DIV exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;
modulus     :lpr MOD exp exp rpr    {ast_node *newnode=CreateNode(ast_mod,0,"");
                                    newnode->l=$3;
                                    newnode->r=$4;
                                    $$=newnode;}
            |lpr MOD rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr MOD exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;

greater     :lpr GREATER exp exp rpr{ast_node *newnode=CreateNode(ast_greater,0,"");
                                    newnode->l=$3;
                                    newnode->r=$4;
                                    $$=newnode;}
            |lpr GREATER rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr GREATER exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;

smaller     :lpr SMALLER exp exp rpr{ast_node *newnode=CreateNode(ast_smaller,0,"");
                                    newnode->l=$3;
                                    newnode->r=$4;
                                    $$=newnode;}
            |lpr SMALLER rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr SMALLER exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;
equal       :lpr EQUAL exp exps_equal rpr{ast_node *newnode=CreateNode(ast_equal,0,"");
                                    newnode->l=$3;
                                    newnode->r=$4;
                                    $$=newnode;}
            |lpr EQUAL rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr EQUAL exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;
exps_equal  :exp                        {$$=$1;}
            |exps_equal exp         {ast_node *newnode=CreateNode(ast_equal,0,"");
                            newnode->l=$1;
                            newnode->r=$2;
                            $$=newnode;
                            }
            ;

LOGICAL_OP  :and_op {$$=$1;}
            |or_op  {$$=$1;}
            |not_op {$$=$1;}
            ;
and_op      :lpr AND exp exps_and rpr   {ast_node *newnode=CreateNode(ast_and,0,"");
                                    newnode->l=$3;
                                    newnode->r=$4;
                                    $$=newnode;}
            |lpr AND rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr AND exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;
exps_and    :exp    {$$=$1;}
            |exps_and exp   {ast_node *newnode=CreateNode(ast_and,0,"");
                                    newnode->l=$1;
                                    newnode->r=$2;
                                    $$=newnode;}
            ;
or_op      :lpr OR exp exps_or rpr   {ast_node *newnode=CreateNode(ast_or,0,"");
                                    newnode->l=$3;
                                    newnode->r=$4;
                                    $$=newnode;}
            |lpr OR rpr               {printf("Need 2 arguments, but got 0.  \n");exit(1);}
            |lpr OR exp rpr           {printf("Need 2 arguments, but got 1.  \n");exit(1);}
            ;
exps_or    :exp    {$$=$1;}
            |exps_or exp   {ast_node *newnode=CreateNode(ast_or,0,"");
                                    newnode->l=$1;
                                    newnode->r=$2;
                                    $$=newnode;}
            ;
not_op      :lpr NOT exp rpr    {ast_node *newnode=CreateNode(ast_not,0,"");
                                    newnode->l=$3;
                                    $$=newnode;}
            |lpr NOT rpr        {printf("Need 1 arguments, but got 0.  \n");exit(1);}
            ;
```
接下來的這些code做法都差不多，因此一起講解，在plus部分，碰到這樣形式時，我們使用的方法是一樣創建node，並且左右child就是後面的兩個數值，但這個node是plus形式，DFS_evaluate碰到時就會做加法
那如果今天少一個argument，偵測到就會print(Need 2 arguments, but got 1.)兩個都沒有就會print(Need 2 arguments, but got 0)
其他的operation其實也都是照上面的想法一併撰寫，只是設定的type比較不同而已。
要注意的是今天題目可以同時+、*、equal、and、or很多個，因此遇到這樣的情況，我們的做法就是再做一個node，並且左右child一樣也設他給的數值，由於DFS_evaluate會先抓最深處，所以整體不會有影響。

```
def_stmt    :lpr DEFINE variable exp rpr    {
                                            variable_stack[get_varindex($3->name)].val=DFS_evaluate($4);
                                            variable_stack[get_varindex($3->name)].tree=$4;}
            ;
variable    :id     {if( get_varindex($1)==-1){
                        variable_stack[vstop].name=$1;
                        variable_stack[vstop].val=0;
                        vstop++;
                    }
                    ast_node *newnode=CreateNode(ast_var,0,$1);
                    $$=newnode;
                    }
```
這部分是當我遇到的輸入是id時，則variable的名子就要丟入variable_stack中，並且創造node表明這是一個variable
在define部分就是去stack找這個variable，並且把數值丟入(tree是負責給function_name做使用)。
```
FUN_EXP     :lpr FUN fun_ids fun_body rpr {$$=$4;}
            ;
fun_ids     :lpr rpr        {;}
            |lpr ids rpr    {;}
            ;
ids         :id             {
                            fun_position++;
                            set_function_var($1,fun_position);
}
            |ids id         {
                            fun_position++;
                            set_function_var($2,fun_position);
}
            ;
fun_body    :exp            {$$=$1;}
            ;
FUN_CALL    :lpr FUN_EXP rpr {$$=$2;}
            |lpr FUN_EXP params rpr {
                                    put_paramater($2);
                                    $$=$2;
                                    clear_fun_variable();
                                    pa_position=0;
                                    fun_position=0;
                                    }
            |lpr fun_name rpr   {$$=variable_stack[$2].tree;}
            |lpr fun_name params rpr {
                	put_paramater(variable_stack[$2].tree);
					$$=variable_stack[$2].tree;
					clear_fun_variable();
					pa_position=0;
					fun_position=0;
            }

params      :param          {
                            pa_position++;
                            para[pa_position]=$1;
                            $$=pa_position;
                            }

            |params param   {
                            pa_position++;
                            para[pa_position]=$2;
                            $$=pa_position;
}
            ;
param       :exp        {$$=DFS_evaluate($1);}
            ;
fun_name    :variable       {$$=get_varindex($1->name);}
            ;

```
這部分是function的定義，首先function id可能沒有也可能很多個，當遇到很多個時，"按照順序"把id丟是function_variable_stack裡，遇到function call時，首先來看param，把數值算出來，並且丟到para這個stack裡，同時也是按照順序的丟入，因此可以跟function_variable_stack一一對應，當碰到function_call後面有接parameter時，會使用put_parameter()把數值跟變數一一對應，傳回$$，並且把function_variable_stack清空，遇到function_name也是做相同的事情。
```
IF_EXP      :lpr IF test_exp then_exp else_exp rpr {if(DFS_evaluate($3)){$$=$4;}else{$$=$5;} }
            ;
test_exp    :exp    {$$=$1;}
            ;
then_exp    :exp    {$$=$1;}
            ;
else_exp    :exp    {$$=$1;}
            ;
```
最後的if就只是先將$3的東西利用DFS_evaluate算出結論，如果可以就做then_exp不行就做else_exp
