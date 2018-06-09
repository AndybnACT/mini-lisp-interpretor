%{
    #include "ast.h"
    #include <stdio.h>
    #include <string.h>
    void yyerror(const char *);
    struct astnode *ROOT;
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
            printf("prog-->stmt\n");
        }
        |   prog stmt{
            printf("prog-->prog stmt\n");
        }
        ;
stmt    :   expr{
            printf("stmt-->expr\n");
        }
        |   print_stmt{
            printf("stmt-->print\n");
        }
        |   def_stmt{
            printf("stmt-->def\n");
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
                printf("print-stmt\n");
                struct nodecontent *result;
                result = asttreval($<nodeptr>3);
                if (result->t == BOOLEAN && $<n>2.t == PBOOL) {
                    char *tf[2] = {"#f", "#t"};
                    printf("result = %s\n", tf[result->val]);
                }else if (result->t == NUMBER && $<n>2.t == PNUM) {
                    printf("result = %d\n",result->val );
                }else{
                    printf("type mismatch for print and expr\n");
                    printf("%d type=%d\n", result->val, result->t);
                    printf("%p %p %p\n",$<nodeptr>3, $<nodeptr>3->left, $<nodeptr>3->right );
                }
            }
            ;
// expressions
expr    :   BOOL {
            printf("expr-->bool\n");
            $<nodeptr>$ = astleaf(&($<n>1));
            //printf("%p\n", $<nodeptr>$);
        }
        |   NUM{
            printf("expr-->number\n");
            $<nodeptr>$ = astleaf(&($<n>1));
            printf("%p\n", $<nodeptr>$);
        }
        |   ID {
            printf("expr-->ID\n");
            // struct symbol_table *symcur = symscope;
            // if (symfind(&symcur, $<n>1.name) == 0) {
            //     printf("unknown variable\n");
            // }else{
            //     $<nodeptr>$ = symcur->expr;
            // }
            $<nodeptr>$ = astleaf(&($<n>1));
            printf("%p\n", $<nodeptr>$);
        }
        |   num_op {
            printf("expr-->numerical_op\n");
            $<nodeptr>$ = $<nodeptr>1;
            printf("%p\n", $<nodeptr>$);
        }
        |   logical_op{
            printf("expr-->logical_op\n");
            $<nodeptr>$ = $<nodeptr>1;
        }
        |   if_expr{
            printf("expr-->if_expr\n");
            $<nodeptr>$ = $<nodeptr>1;
        }
        |   func_call{
            printf("expr-->func_call\n");
        }
        ;
exprs   :   expr {
            printf("exprs-->expr\n");
            $<nodeptr>$ = $<nodeptr>1;
        }
        |   exprs expr{
            printf("exprs-->exprs expr\n");
            $<nodeptr>$ = astparent(CATEXP, $<nodeptr>1, $<nodeptr>2);
        }
        ;
// calculator
num_op  :   '(' '+' expr exprs ')'{
            printf("plus\n");
            $<nodeptr>$ = astparent(OPPLUS, $<nodeptr>3, $<nodeptr>4);
            printf("%p %p %p\n", $<nodeptr>$, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '-' expr expr ')'{
            printf("minus\n");
            $<nodeptr>$ = astparent(OPMINUS, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '*' expr exprs ')'{
            printf("mul\n");
            $<nodeptr>$ = astparent(OPMUL, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '/' expr expr ')'{
            printf("divide\n");
            $<nodeptr>$ = astparent(OPDIVD, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' MOD expr expr ')'{
            printf("mod\n");
            $<nodeptr>$ = astparent(OPMOD, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '>' expr expr ')'{
            printf("greater\n");
            $<nodeptr>$ = astparent(OPGT, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '<' expr expr ')'{
            printf("less\n");
            $<nodeptr>$ = astparent(OPLT, $<nodeptr>3, $<nodeptr>4);
        }
        |   '(' '=' expr expr ')'{
            printf("equal\n");
            $<nodeptr>$ = astparent(OPEQ, $<nodeptr>3, $<nodeptr>4);
        }
        ;
logical_op  :   '(' AND expr exprs ')'{
                printf("and\n");
                $<nodeptr>$ = astparent(OPAND, $<nodeptr>3, $<nodeptr>4);
            }
            |   '('  OR expr exprs ')'{
                printf("or\n");
                $<nodeptr>$ = astparent(OPOR, $<nodeptr>3, $<nodeptr>4);
            }
            |   '(' NOT expr ')'{
                printf("not\n");
                $<nodeptr>$ = astparent(OPNOT, NULL, $<nodeptr>3);
            }
            ;
// if-then-else
if_expr :   '(' IF expr expr expr ')'{ //NOTE bind into asttreval to support function calls
            struct astnode *selection;
            selection = astparent(IFBODY, $<nodeptr>4, $<nodeptr>5);
            $<nodeptr>$ = astparent(IFHEAD, $<nodeptr>3, selection);
            // struct nodecontent *testexp, *thenexp, *elseexp;
            // testexp = asttreval($<nodeptr>3);
            // if (testexp->t == BOOLEAN) {
            //     // thenexp = asttreval($<nodeptr>4);
            //     // elseexp = asttreval($<nodeptr>5);
            //     if (testexp->val == 1)
            //         $<nodeptr>$ = $<nodeptr>4;
            //     else
            //         $<nodeptr>$ = $<nodeptr>5;
            //
            // }else{
            //     printf("test expression of if-then-else must be BOOLEAN\n");
            // }

        }
        ;
// functions

func_call   :   '(' inline_func param ')'{ //--->bind expr to corresponding symbol tabal
                struct symbol_table *paramlist = symlistcopy($<nodeptr>2->scopehead);
                printf("func_call-->inline_func param\n");
                // struct symbol_table *tmphead =  $<nodeptr>2->scopehead;
                printf("%p\n",paramlist );
                if (paramlist) { // if the function takes at least one variable(s)
                    printf("[variable->ast]\n");
                    symscopeassign(paramlist ,$<nodeptr>2);
                    printf("[expr->variable->ast]\n");
                    symexprbinding($<nodeptr>3 , &(paramlist));
                }
                $<nodeptr>$ = $<nodeptr>2;

            }
            |   '(' ID param ')'{
                printf("func_call-->id param\n");

                struct symbol_table *findfunc = symhead, *paramlist;
                struct astnode *found;
                if (symfind(&findfunc, $<n>2.name)){
                    found = findfunc->expr;
                    paramlist = symlistcopy(found->scopehead);
                    printf("%p\n",&found );
                    if (paramlist) { // if the function takes at least one variable(s)
                        printf("[variable->ast]\n");
                        symscopeassign(paramlist ,found);
                        printf("[expr->variable->ast]\n");
                        symexprbinding($<nodeptr>3 , &(paramlist));
                    }
                    $<nodeptr>$ = found;
                }else{
                    printf("error function not found\n");
                }

            }
            ;
inline_func :   '(' FUNC '(' func_ids ')' func_body ')'{
                printf("inline_func\n");
                $<nodeptr>6->scopehead = $<symlist>4;
                $<nodeptr>$ = $<nodeptr>6;

            }
            ;
func_body   :   expr{
                $<nodeptr>$ = $<nodeptr>1;
            }
            |   '(' DEF ID inline_func ')' {
                    printf("func_body--> def part\n");
                    SymCreate($<nodeptr>4->scopehead, $<n>3.name, $<nodeptr>4);
                    struct symbol_table *lowest = symhead;
                    for (; lowest; lowest=lowest->below);
                    lowest = $<nodeptr>4->scopehead;
                } expr {
                    printf("func_body -->( DEF ID inline_func ) expr\n");


            }
            ;
//-->create symbol table
func_ids    :  {
                printf("func_ids-->null\n");
                $<symlist>$ = NULL;
            }
            |   ID{
                printf("func_ids-->id\n");
                struct symbol_table *id;
                id = (struct symbol_table *)malloc(sizeof(struct symbol_table));
                id->next = NULL;
                SymCreate(id, $<n>1.name, NULL);
                $<symlist>$ = id;
                printf("scope head %p\n", id );
            }
            |   func_ids ID{
                printf("func_ids-->func_ids id\n");
                SymCreate($<symlist>1, $<n>2.name, NULL);
                $<symlist>$ = $<symlist>1;

            }
            ;
param       :
            |   exprs{
                printf("param-->exprs\n");
                $<nodeptr>$ = $<nodeptr>1;
            }
            ;
%%
struct nodecontent* asttreval(struct astnode* root){
    struct nodecontent *ret;
    struct nodecontent *rchild, *lchild;
    printf("start %p\n", root);
    if (!root) return NULL; // 'not' case
    enum TYPE op = root->t;
    ret = (struct nodecontent *) malloc(sizeof(struct nodecontent));
    ret->t = NONE;

    if (op == NUMBER || op == BOOLEAN) {
        ret->val = root->val;
        ret->t = root->t;
        printf("operand--------->%d\n", ret->val);
        return ret;
    }else if (op == VARIABLE) {
        printf("variable\n");
        struct symbol_table *symcur = root->scopehead == NULL ? symhead:root->scopehead;
        printf("scopehead=%p\n", symcur);
        if (symfind(&symcur, root->name) == 0) {
            printf("unknown variable\n");
            return ret;
        }else{
            printf("variable found\n==>%s\n==>expr %p\n", symcur->sym, symcur->expr);
            ret = asttreval(symcur->expr);
            printf("variable value = %d, type = %d\n",ret->val, ret->t );
            return ret;
        }

    }else if (op == IFHEAD) {
        ret = asttreval(root->left);
        if (ret->t == BOOLEAN) {
            //printf("taken-->%p, not taken-->%p\n",root->right->left, root->right->right);
            if (ret->val == 1) {
                ret = asttreval(root->right->left);
            }else{
                ret = asttreval(root->right->right);
            }
            return ret;
        }else{
            printf("test statement of if-then-else must be BOOLEAN\n");
            return ret;
        }
    }else{
        printf("operator========>%d\n", op);
        if (root->left && root->right) {
            if (root->left->t == CATEXP) root->left->t = op;
            if (root->right->t == CATEXP) root->right->t = op;
        }
        lchild = asttreval(root->left);
        rchild = asttreval(root->right);
        if (!lchild || !rchild) { // 'not' takes only one operand
            lchild = rchild;

        }
        if (lchild->t != rchild->t) {
            printf("type mismatch ltype=%d rtype=%d\n", lchild->t, rchild->t);
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
                    printf("wrong op type for numeric @%d line\n", __LINE__);
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
                    printf("wrong op type for boolean @%d line\n", __LINE__);
            }
        }else{
            printf("unkown operand type @%d line\n", __LINE__);
        }
        printf("result ====> %d, type=%d\n",ret->val, ret->t );
        return ret;
    }
}
struct astnode* astparent(enum TYPE op, struct astnode* left, struct astnode* right){
    struct astnode *parent;
    parent = (struct astnode *) malloc(sizeof(struct astnode));
    parent->t = op;
    parent->name = NULL;
    parent->left = left;
    parent->right = right;
    return parent;
}
struct astnode* astleaf(struct nodecontent *source){
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
    for (; (*st)->next != NULL; (*st)=(*st)->next)
        if (strcmp(sym, (*st)->sym) == 0) return 1;
    return 0;
}
void symcreate(struct symbol_table *cur, char *sym, struct astnode *expr){
    cur->next = (struct symbol_table *) malloc(sizeof(struct symbol_table));
    cur->next->next = NULL;
    cur->below = NULL;
    cur->sym = sym;
    cur->expr = expr;
}

void SymCreate(struct symbol_table *cur, char *sym, struct astnode *expr){
    struct symbol_table *symend = cur;
    if (symfind(&cur, sym)) {
        printf("error redefinition of variable\n");
    }else{
        symcreate(cur, sym, expr);
    }
}

void symscopeassign(struct symbol_table *scopehead, struct astnode *funexpr){
    if (!funexpr) return;
    else if (funexpr->t == VARIABLE) {
        funexpr->scopehead = scopehead;
        printf("assign %p to scopr %p\n", funexpr, scopehead);
        return;
    }
    symscopeassign(scopehead, funexpr->left);
    symscopeassign(scopehead, funexpr->right);
}
void symexprbinding(struct astnode *exprs, struct symbol_table **scopehead) {
    if (exprs->t == CATEXP) {
        symexprbinding(exprs->left, scopehead);
        symexprbinding(exprs->right, scopehead);
    }else{
        printf("%p\n",(*scopehead) );
        if ((*scopehead) == NULL) {
            printf("error number of param\n");
        }else{
            (*scopehead)->expr = exprs;
            (*scopehead) = (*scopehead)->next;
        }
    }
}
struct symbol_table* symlistcopy(struct symbol_table *source){
    struct symbol_table *dest, *copyto;
    if (source) {
        dest = (struct symbol_table *)malloc(sizeof(struct symbol_table));
        copyto = dest;
        for (; source != NULL; source=source->next, copyto=copyto->next) {
            memcpy(copyto, source, sizeof(struct symbol_table));
            copyto->next = (struct symbol_table *) malloc(sizeof(struct symbol_table));
        }
        return dest;
    }else{
        return NULL;
    }
}

void yyerror(const char *msg) {
    fprintf(stderr, "Syntax Error\n");
}
int main(int argc, char const *argv[]) {
    ROOT = (struct astnode *) malloc(sizeof(struct astnode));
    symhead = (struct symbol_table *) malloc(sizeof(struct symbol_table));
    symhead->next = NULL;
    symhead->below = NULL;
    symscope = symhead;

    yyparse();
    return 0;
}
