#ifndef AST
#define AST

enum TYPE{NUMBER, BOOLEAN, VARIABLE,
          PNUM, PBOOL,
          OPPLUS, OPMINUS, OPMUL, OPMOD, OPDIVD, OPGT, OPLT, OPEQ,
          OPAND, OPOR, OPNOT,
          CATEXP, NONE, IFBODY, IFHEAD, UNSOVED_FUNC
     };

 struct symbol_table{
     //struct nodecontent c;
     char *sym;
     struct symbol_table *next;
     struct symbol_table *parent;
     struct astnode *expr;
 };



struct nodecontent{
    enum TYPE t;
    int val;
    char *name;
    struct symbol_table *scopehead;
};


struct astnode{
    enum TYPE t;
    int val;
    char *name;
    struct astnode *left, *right;
    struct symbol_table *scopehead; // rootnode-->prototype of function variables \
                                    // leafnode-->current scope
    struct symbol_table *scope_cur; // rootnode-->current scope
};



#endif
