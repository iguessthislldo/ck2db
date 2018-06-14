%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>

#include "read_ck2.tab.h"

size_t lineno;
size_t level;

%}

%%

[\n] { lineno++; }
"CK2txt" { return MAGIC_NUMBER_TOKEN; }
[ \t] ; // ignore all other whitespace
"{" { level++; return START_TOKEN; }
"}" { level--; return END_TOKEN; }
"=" { return EQUALS_TOKEN; }
[0-9]+\.[0-9]+\.[0-9]+ { yylval.string_value = yytext; return DATE_TOKEN; }
\"[0-9]+\.[0-9]+\.[0-9]+\" { yylval.string_value = yytext; return DATE_TOKEN; }
[+-]?[0-9]+\.[0-9]+ { yylval.float_value = atof(yytext); return FLOAT_TOKEN; }
[+-]?[0-9]+ { yylval.int_value = atoi(yytext); return INT_TOKEN; }
"yes" { yylval.int_value = 1; return BOOL_TOKEN; }
"no" { yylval.int_value = 0; return BOOL_TOKEN; }
[A-Za-z0-9\_\.\-]+ { yylval.string_value = yytext; return NAME_TOKEN; }
\"[^"]*\" { yylval.string_value = yytext; return STRING_TOKEN; }
. { yyerror("Invalid Token"); }

%%
