%{
    #include "ast.h"
    #include <stdio.h>
    #include <string.h>
    void yyerror(const char *);
//    struct astnode *ROOT;
    struct astnode* astparent(enum TYPE, struct astnode*, struct astnode*);
    struct astnode* astleaf(struct nodecontent *);
    struct nodecontent* asttreval(struct astnode*);



    // struct scope_stack{
    //     struct symbol_table *S[100];
    //     int top;
    // } stack;

    struct symbol_table *symhead, *symscope, **symtable;
    int symfind(struct symbol_table **, char *);
    void SymCreate(struct symbol_table *, char *, struct astnode *);
    //void symcreate(struct symbol_table *, char *, struct astnode *);
    void symscopeassign(struct symbol_table *, struct astnode *);
    void symexprbinding(struct astnode *, struct symbol_table **);
    struct symbol_table* symlistcopy(struct symbol_table *);
    // struct symbol_table *NESTED_FUNC=NULL;
%}

%union{
    struct nodecontent n;
    struct astnode *nodeptr;
    struct symbol_table *symlist;
}

%token<n> NUM
%token<n> BOOL
%token<n> ID

%token<n> PRINT
%token<n> MOD
%token<n> AND
%token<n> OR
%token<n> NOT
%token<n> IF
%token<n> DEF
%token<n> FUNC

%type<nodeptr> num_op
%type<nodeptr> logical_op
%type<nodeptr> expr
%type<nodeptr> exprs
%type<nodeptr> if_expr
%type<nodeptr> def_stmt
%type<nodeptr> func_call
%type<nodeptr> inline_func
%type<nodeptr> func_body
%type<nodeptr> param

%type<symlist> func_ids

%%
// program
prog    :   stmt{
            fprintf(stderr,"prog-->stmt\n");
        }
        |   prog stmt{
            fprintf(stderr,"prog-->prog stmt\n");
        }
        ;
stmt    :   expr{
            fprintf(stderr,"stmt-->expr\n");
            asttreval($<nodeptr>1);
        }
        |   print_stmt{
            fprintf(stderr,"stmt-->print\n");
        }
        |   def_stmt{
            fprintf(stderr,"stmt-->def\n");
        }
        ;

// define
def_stmt    :   '(' DEF ID expr ')'{
                SymCreate(symhead, $<n>3.name, $<nodeptr>4);
            }
            |   '(' DEF ID inline_func ')'{
                SymCreate(symhead, $<n>3.name, $<nodeptr>4);
            }
            ;

// prints
print_stmt  :  '(' PRINT expr ')'{
                fprintf(stderr,"print-stmt\n");
                struct nodecontent *result;
                result = asttreval($<nodeptr>3);
                if (result->t == BOOLEAN && $<n>2.t == PBOOL) {
                    char *tf[2] = {"#f", "#t"};
                    printf("%s\n", tf[result->val]);
                }else if (result->t == NUMBER && $<n>2.t == PNUM) {
                    printf("%d\n",result->val );
                }else{
                    fprintf(stderr,"type mismatch for print and expr\n");
                    fprintf(stderr,"%d type=%d\n", result->val, result->t);
                    fprintf(stderr,"%p %p %p\n",$<nodeptr>3, $<nodeptr>3->left, $<nodeptr>3->right );
                }
            }
            ;
// expressions
expr    :   BOOL {
            fprintf(stderr,"expr-->bool\n");
            $<nodeptr>$ = astleaf(&($<n>1));
            //fprintf(stderr,"%p\n", $<nodeptr>$);
        }
        |   NUM{
            fprintf(stderr,"expr-->number\n");
            $<nodeptr>$ = astleaf(&($<n>1));
            fprintf(stderr,"%p\n", $<nodeptr>$);
        }
        |   ID {
            fprintf(stderr,"expr-->ID\n");
            $<nodeptr>$ = astleaf(&($<n>1));
            fprintf(stderr,"%p\n", $<nodeptr>$);
        }
        |   num_op {
            fprintf(stderr,"expr-->numerical_op\n");
            $<nodeptr>$ = $<nodeptr>1;
            fprintf(stderr,"%p\n", $<nodeptr>$);
        }
        |   logical_op{
            fprintf(stderr,"expr-->logical_op\n");
            $<nodeptr>$ = $<nodeptr>1;
        }
        |   if_expr{
            fprintf(stderr,"expr-->if_expr\n");
            $<nodeptr>$ = $<nodeptr>1;
        }
        |   func_call{
            fprintf(stderr,"expr-->func_call\n");
        }
        ;
exprs   :   expr {
            fprintf(stderr,"exprs-->expr\n");
            $<nodeptr>$ = $<nodeptr>1;
        }
        |   exprs expr{
            fprintf(stderr,"exprs-->exprs expr\n");
            $<nodeptr>$ = astparent(CATEXP, $<nodeptr>1, $<nodeptr>2);
        }
        ;
// calculator
num_op  :   '(' '+' expr exprs ')'{
            fprintf(stderr,"plus\n");
            $<nodeptr>$ = astparent(OPPLUS, $<nodeptr>3, $<nodeptr>4);
            fprintf(stderr,"%p %p %p\n", $<nodeptr>$, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '-' expr expr ')'{
            fprintf(stderr,"minus\n");
            $<nodeptr>$ = astparent(OPMINUS, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '*' expr exprs ')'{
            fprintf(stderr,"mul\n");
            $<nodeptr>$ = astparent(OPMUL, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '/' expr expr ')'{
            fprintf(stderr,"divide\n");
            $<nodeptr>$ = astparent(OPDIVD, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' MOD expr expr ')'{
            fprintf(stderr,"mod\n");
            $<nodeptr>$ = astparent(OPMOD, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '>' expr expr ')'{
            fprintf(stderr,"greater\n");
            $<nodeptr>$ = astparent(OPGT, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '<' expr expr ')'{
            fprintf(stderr,"less\n");
            $<nodeptr>$ = astparent(OPLT, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '=' expr expr ')'{
            fprintf(stderr,"equal\n");
            $<nodeptr>$ = astparent(OPEQ, $<nodeptr>3, $<nodeptr>4);
        }
        ;
logical_op  :   '(' AND expr exprs ')'{
                fprintf(stderr,"and\n");
                $<nodeptr>$ = astparent(OPAND, $<nodeptr>3, $<nodeptr>4);
            }
            |   '('  OR expr exprs ')'{
                fprintf(stderr,"or\n");
                $<nodeptr>$ = astparent(OPOR, $<nodeptr>3, $<nodeptr>4);
            }
            |   '(' NOT expr ')'{
                fprintf(stderr,"not\n");
                $<nodeptr>$ = astparent(OPNOT, NULL, $<nodeptr>3);
            }
            ;
// if-then-else
if_expr :   '(' IF expr expr expr ')'{
            struct astnode *selection;
            selection = astparent(IFBODY, $<nodeptr>4, $<nodeptr>5);
            $<nodeptr>$ = astparent(IFHEAD, $<nodeptr>3, selection);

        }
        ;
// functions

func_call   :   '(' inline_func param ')'{ //--->bind expr to corresponding symbol tabal
                struct symbol_table *paramlist = symlistcopy($<nodeptr>2->scopehead);
                fprintf(stderr,"func_call-->inline_func param\n");
                // struct symbol_table *tmphead =  $<nodeptr>2->scopehead;
                fprintf(stderr,"%p\n",paramlist );
                if (paramlist) { // if the function takes at least one variable(s)
                    fprintf(stderr,"[variable->ast]\n");
                    symscopeassign(paramlist ,$<nodeptr>2);
                    fprintf(stderr,"[expr->variable->ast]\n");
                    symexprbinding($<nodeptr>3 , &(paramlist));
                }
                $<nodeptr>$ = $<nodeptr>2;

            }
            |   '(' ID param ')'{
                fprintf(stderr,"func_call-->id param\n");

                struct symbol_table *findfunc = symhead, *paramlist;
                struct astnode *found;
                if (symfind(&findfunc, $<n>2.name)){
                    found = findfunc->expr;
                    paramlist = symlistcopy(found->scopehead);
                    fprintf(stderr,"%p\n",&found );
                    if (paramlist) { // if the function takes at least one variable(s)
                        fprintf(stderr,"[variable->ast]\n");
                        symscopeassign(paramlist ,found);
                        found->scope_cur = paramlist;
                        fprintf(stderr,"[expr->variable->ast]\n");
                        symexprbinding($<nodeptr>3 , &(paramlist));
                    }
                    $<nodeptr>$ = found;
                }else{
                    fprintf(stderr,"function not found\n");
                    fprintf(stderr, "creating function symbol to be resolved at runtime\n");
                    struct astnode *unsolved = (struct astnode *)malloc(sizeof(struct astnode));
                    unsolved->t = UNSOVED_FUNC;
                    unsolved->name = $<n>2.name;
                    unsolved->left = NULL;
                    unsolved->right =  $<nodeptr>3;;
                    unsolved->scopehead = NULL;
                    unsolved->scope_cur = NULL;
                    $<nodeptr>$ = unsolved;
                }

            }
            ;
inline_func :   '(' FUNC '(' func_ids ')' func_body ')'{
                fprintf(stderr,"inline_func\n");
                $<nodeptr>6->scopehead = $<symlist>4;
                $<nodeptr>$ = $<nodeptr>6;


            }
            ;
func_body   :   expr{
                $<nodeptr>$ = $<nodeptr>1;
            }
            |   '(' DEF ID inline_func ')' {
                    fprintf(stderr,"func_body--> def part\n");
                    // SymCreate($<nodeptr>4->scopehead, $<n>3.name, $<nodeptr>4);
                    // NESTED_FUNC = $<nodeptr>4->scopehead;
                } expr {
                    fprintf(stderr,"func_body -->( DEF ID inline_func ) expr\n");
                    // $<nodeptr>$ = $<nodeptr>6;
                    // printf("%p\n",$<nodeptr>6);
                    // NESTED_FUNC = NULL;

            }
            ;
//-->create symbol table
func_ids    :  {
                fprintf(stderr,"func_ids-->null\n");
                $<symlist>$ = NULL;
            }
            |   ID{
                fprintf(stderr,"func_ids-->id\n");
                struct symbol_table *id;
                id = (struct symbol_table *)malloc(sizeof(struct symbol_table));
                id->next = NULL;
                SymCreate(id, $<n>1.name, NULL);
                $<symlist>$ = id;
                fprintf(stderr,"scope head %p\n", id );
            }
            |   func_ids ID{
                fprintf(stderr,"func_ids-->func_ids id\n");
                SymCreate($<symlist>1, $<n>2.name, NULL);
                $<symlist>$ = $<symlist>1;

            }
            ;
param       :
            |   exprs{
                fprintf(stderr,"param-->exprs\n");
                $<nodeptr>$ = $<nodeptr>1;
            }
            ;
%%
struct astnode* astcopy(struct astnode* root){
    // return copy of the ast tree pointed by root
    // used by dynamic(runtime) function calls (recursion)
    if (!root) return NULL;
    struct astnode* cpy = (struct astnode*)malloc(sizeof(struct astnode));

    cpy->t = root->t;
    cpy->val = root->val;
    cpy->name = root->name;
    cpy->scopehead = root->scopehead;
    cpy->scope_cur = root->scope_cur;
    cpy->left = astcopy(root->left);
    cpy->right = astcopy(root->right);
    return cpy;
}
struct nodecontent* asttreval(struct astnode* root){
    // evaluate the ast tree pointed by root and return the result
    // returned nodecontent will be NONE type if error(s) occured
    // executions will be determined by optype of root
    // ==============[NUMBER || BOOLEAN]===========
    // > return values set in root
    // > we define val=1 for BOOLEAN's tree and val=0 for BOOLEAN's false
    // > user should check 't' before using these types
    // ==============[VARIABLE]============
    // > return the evaluation of variable
    // > user should assign VARIABLE to its scope(symhead)
    // > and bind an expression(expr) to every VARIABLE's scope
    // > before calling asttreval
    // ==================[IFHEAD]==================
    // > evaluate the 'test' expression and return the evaluation
    // > of 'true-stmt'
    // >          [IFHEAD]
    // >         /.       \.
    // >   <test expr>   [IFBODY]
    // >                 /.      \.
    // >            <#t expr>   <#f expr>
    // ====================[UNSOVED_FUNC]=======================
    // > Recursion
    // > if the function is not binded at linktime (yacc's func_call CFG processing)
    // > then the op type of the function will be UNSOVED_FUNC
    // >          [UNSOVED_FUNC]
    // >         /.             \.
    // >       null            <param exprs>
    // > When asttreval sees UNSOVED_FUNC, it then finds the function's expression
    // > at the top level symbol table, copies the ast and prototype of its symbol table,
    // > and binds the corresponding expressions to each symbol. Then return the
    // > evaluation of the newly generated ast
    // > BUG we save the scope of current function at scope_cur of the top level (symhead)
    // >>>>> symbol table everytime we call UNSOVED_FUNC in order to evaluate the value
    // >>>>> of parameters inside function
    // > BUG the newly copied ast will not be freed after calling
    // ================[OP*] [CATEXP]=================
    // > checks the operand type and operate on it
    // > copies the current operatoin if child's type == [CATEXP]
    struct nodecontent *ret;
    struct nodecontent *rchild, *lchild;
    fprintf(stderr,"start %p\n", root);
    if (!root) return NULL; // 'not' case (see 'not' case in 'logical_op')
    enum TYPE op = root->t;
    ret = (struct nodecontent *) malloc(sizeof(struct nodecontent));
    ret->t = NONE;

    if (op == NUMBER || op == BOOLEAN) {
        ret->val = root->val;
        ret->t = root->t;
        fprintf(stderr,"operand--------->%d\n", ret->val);
        return ret;
    }else if (op == VARIABLE) {
        fprintf(stderr,"variable\n");
        struct symbol_table *symcur = root->scopehead == NULL ? symhead:root->scopehead;
        fprintf(stderr,"scopehead=%p\n", symcur);
        if (symfind(&symcur, root->name) == 0) {
            fprintf(stderr,"unknown variable\n");
            return ret;
        }else{
            fprintf(stderr,"variable found\n==>%s\n==>expr %p\n", symcur->sym, symcur->expr);
            ret = asttreval(symcur->expr);
            fprintf(stderr,"variable value = %d, type = %d\n",ret->val, ret->t );
            return ret;
        }

    }else if (op == IFHEAD) {
        ret = asttreval(root->left);
        if (ret->t == BOOLEAN) {
            //fprintf(stderr,"taken-->%p, not taken-->%p\n",root->right->left, root->right->right);
            if (ret->val == 1) {
                ret = asttreval(root->right->left);
            }else{
                ret = asttreval(root->right->right);
            }
            return ret;
        }else{
            fprintf(stderr,"test statement of if-then-else must be BOOLEAN\n");
            return ret;
        }
    }else if (op == UNSOVED_FUNC) {
        fprintf(stderr, "unsolved func: %s\n", root->name);
        //findfunc
        struct symbol_table *findfunc = symhead, *paramlist, *tmp;
        struct astnode *foundast;
        if (!symfind(&findfunc, root->name)) {
            fprintf(stderr, "error function not found\n");
            return ret;
        }
        // copy ast, symbols
        foundast = astcopy(findfunc->expr);
        paramlist = symlistcopy(foundast->scopehead);
        fprintf(stderr, "%p paramlist\n", paramlist);
        // assign symbols to param exprs
        symscopeassign(foundast->scope_cur, root->right);
        if (paramlist){
            symscopeassign(paramlist, foundast);

            tmp = findfunc->expr->scope_cur;
            foundast->scope_cur = paramlist;
            findfunc->expr->scope_cur = paramlist;
            fprintf(stderr, "DEBUG\n");
            fprintf(stderr, "----------->%p %s\n",paramlist->expr,paramlist->sym );
            // ret = asttreval(paramlist->expr);
            fprintf(stderr, "%d\n",ret->val );
            // fprintf(stderr, "-------------------scope cur = %p\n",findfunc->expr );
            fprintf(stderr, "DEBUG\n");
            symexprbinding(root->right, &paramlist);
        }
        ret = asttreval(foundast);
        findfunc->expr->scope_cur = tmp;
        return ret;
    }else{
        fprintf(stderr,"operator========>%d\n", op);
        if (root->left && root->right) {
            if (root->left->t == CATEXP) root->left->t = op;
            if (root->right->t == CATEXP) root->right->t = op;
        }
        lchild = asttreval(root->left);
        rchild = asttreval(root->right);
        if (!lchild || !rchild) { // 'not' takes only one operand
            lchild = rchild;

        }
        if (lchild->t == NONE || rchild->t == NONE) {
            fprintf(stderr, "asttreval returned NONE type, abort!!\n");
            return ret;
        }
        if (lchild->t != rchild->t) {
            fprintf(stderr,"type mismatch ltype=%d rtype=%d\n", lchild->t, rchild->t);
            fprintf(stdout, "Type error!\n");
            return ret;
        }else if (lchild->t == NUMBER) {
            switch (op) {
                case OPPLUS:
                    ret->t = NUMBER;
                    ret->val = lchild->val + rchild->val;
                    break;
                case OPMINUS:
                    ret->t = NUMBER;
                    ret->val = lchild->val - rchild->val;
                    break;
                case OPMUL:
                    ret->t = NUMBER;
                    ret->val = lchild->val * rchild->val;
                    break;
                case OPMOD:
                    ret->t = NUMBER;
                    ret->val = lchild->val % rchild->val;
                    break;
                case OPDIVD:
                    ret->t = NUMBER;
                    ret->val = lchild->val / rchild->val;
                    break;
                case OPGT:
                    ret->t = BOOLEAN;
                    ret->val = lchild->val > rchild->val ? 1:0;
                    break;
                case OPLT:
                    ret->t = BOOLEAN;
                    ret->val = lchild->val < rchild->val ? 1:0;
                    break;
                case OPEQ:
                    ret->t = BOOLEAN;
                    ret->val = lchild->val == rchild->val ? 1:0;
                    break;
                default:
                    fprintf(stderr,"wrong op type for numeric @%d line\n", __LINE__);
            }
        }else if (lchild->t == BOOLEAN) {
            ret->t = BOOLEAN;
            switch (op) {
                case OPAND:
                    ret->val = lchild->val && rchild->val ? 1:0;
                    break;
                case OPOR:
                    ret->val = lchild->val || rchild->val ? 1:0;
                    break;
                case OPNOT:
                    ret->val = lchild->val == 1 ? 0:1;
                    break;
                default:
                    fprintf(stderr,"wrong op type for boolean @%d line\n", __LINE__);
            }
        }else{
            fprintf(stderr,"unkown operand type @%d line\n", __LINE__);
        }
        fprintf(stderr,"result ====> %d, type=%d\n",ret->val, ret->t );
        return ret;
    }
}
struct astnode* astparent(enum TYPE op, struct astnode* left, struct astnode* right){
    // generates a parent node with op type of input enum
    // and links given childs to the parent
    struct astnode *parent;
    parent = (struct astnode *) malloc(sizeof(struct astnode));
    parent->t = op;
    parent->name = NULL;
    parent->left = left;
    parent->right = right;
    return parent;
}
struct astnode* astleaf(struct nodecontent *source){
    // generates leaf node
    struct astnode *leaf;
    leaf = (struct astnode *) malloc(sizeof(struct astnode));
    leaf->t = source->t;
    leaf->val = source->val;
    leaf->name = source->name;
    leaf->scopehead = source->scopehead;
    leaf->left = NULL;
    leaf->right = NULL;
    return leaf;
}

int symfind(struct symbol_table **st, char *sym){
    // returns 1 if symbol is found
    //         0              not found
    // inputed st will be directed to the poninter points to found symbol
    for (; (*st)->next != NULL; (*st)=(*st)->next)
        if (strcmp(sym, (*st)->sym) == 0) return 1;
    return 0;
}
void symcreate(struct symbol_table *cur, char *sym, struct astnode *expr){
    // creates symbol
    // only used by SymCreate
    cur->next = (struct symbol_table *) malloc(sizeof(struct symbol_table));
    cur->next->next = NULL;
    cur->parent = NULL;
    cur->sym = sym;
    cur->expr = expr;
}

void SymCreate(struct symbol_table *cur, char *sym, struct astnode *expr){
    struct symbol_table *symend = cur;
    // creates symbol if the symbol is not found in the given scope
    if (symfind(&cur, sym)) {
        fprintf(stderr,"error redefinition of variable\n");
    }else{
        symcreate(cur, sym, expr);
    }
}

void symscopeassign(struct symbol_table *scopehead, struct astnode *funexpr){
    // assign head of scope(symbol table) to every VARIABLE set in ast tree
    if (!funexpr) return;
    else if (funexpr->t == VARIABLE) {
        funexpr->scopehead = scopehead;
        fprintf(stderr,"assign %p to scopr %p\n", funexpr, scopehead);
        return;
    }
    symscopeassign(scopehead, funexpr->left);
    symscopeassign(scopehead, funexpr->right);
}
void symexprbinding(struct astnode *exprs, struct symbol_table **scopehead) {
    //         [CATEXP]
    //        /       \.
    //    <expr>      <expr>
    //      |            |
    //  <symbol> +--> <symbol>
    // parses the expression tree to each symbol in scopehead
    // NOTE DO NOT USE scopehead AFTER this function
    if (exprs->t == CATEXP) {
        symexprbinding(exprs->left, scopehead);
        symexprbinding(exprs->right, scopehead);
    }else{
        fprintf(stderr,"%p\n",(*scopehead) );
        if ((*scopehead) == NULL) {
            fprintf(stderr,"error number of param\n");
        }else{
            (*scopehead)->expr = exprs;
            (*scopehead) = (*scopehead)->next;
        }
    }
}
struct symbol_table* symlistcopy(struct symbol_table *source){
    // returns  the copied symbol table
    struct symbol_table *dest, *copyto;
    if (source) {
        dest = (struct symbol_table *)malloc(sizeof(struct symbol_table));
        copyto = dest;
        for (; source != NULL; source=source->next, copyto=copyto->next) {
            memcpy(copyto, source, sizeof(struct symbol_table));

            copyto->next = (struct symbol_table *) malloc(sizeof(struct symbol_table));
            //printf("copiny %p to %p, %s\n",source, copyto, source->sym );
        }
        return dest;
    }else{
        return NULL;
    }
}

void yyerror(const char *msg) {
    fprintf(stdout, "Syntax Error\n");
}
int main(int argc, char const *argv[]) {
//    ROOT = (struct astnode *) malloc(sizeof(struct astnode));
    symhead = (struct symbol_table *) malloc(sizeof(struct symbol_table));
    symhead->next = NULL;
    symhead->parent = NULL;
    symscope = symhead;

    yyparse();
    return 0;
}
