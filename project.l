%{
    #include "ast.h"
    #include "project.tab.h"

%}

num     0|[1-9][0-9]*|-[1-9][0-9]*
id      [a-z]([a-z]|[0-9]|\-)*
boolean #t|#f
pnum    "print-num"
pbool   "print-bool"
print   {pnum}|{pbool}
%%
[ \t\n]+    {}
mod       {return MOD;}
and       {return AND;}
or        {return OR;}
not       {return NOT;}
if        {return IF;}
define    {return DEF;}
fun       {return FUNC;}
{print}   {yylval.n.t = yytext[6] == 'n' ? PNUM:PBOOL; return PRINT;}

{num}     {yylval.n.val = atoi(yytext); yylval.n.t=NUMBER; return NUM;}
{id}      {yylval.n.name = strndup(yytext, yyleng); yylval.n.t = VARIABLE; yylval.n.scopehead=NULL; return ID;}
{boolean} {yylval.n.val = yytext[1] == 't' ? 1:0; yylval.n.t=BOOLEAN; return BOOL;}
.         {return yytext[0];}

%%
//
// int main(int argc, char const *argv[]) {
//     yylex();
//     return 0;
// }
