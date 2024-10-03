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
%% 

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

IF_EXP      :lpr IF test_exp then_exp else_exp rpr {if(DFS_evaluate($3)){$$=$4;}else{$$=$5;} }
            ;
test_exp    :exp    {$$=$1;}
            ;
then_exp    :exp    {$$=$1;}
            ;
else_exp    :exp    {$$=$1;}
            ;
%%
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
