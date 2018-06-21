/*
 * ck2_read
 * Process contents of ck2 files
 *
 * Flex file for read_ck2
 */
%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>

#include "ck2json.h"
#include "ck2json.tab.h"

size_t lineno;
size_t level;

%}

%%

"#".* ; // Ignore Comments
[\n] { lineno++; }
"CK2txt" { return MAGIC_NUMBER_TOKEN; }
[\x00-\x20] ; // ignore ascii control and whitespace characters
[\x7f-\xa0] ; // ignore characters not in Latin6
"{" { level++; return START_TOKEN; }
"}" { level--; return END_TOKEN; }
"=" { return EQUALS_TOKEN; }
[0-9]+\.[0-9]+\.[0-9]+ {
    int year, month, day;
    sscanf(yytext, "%d.%d.%d", &year, &month, &day);
    char * date = malloc(13);
    snprintf(date, 13, "\"%.4d-%.2d-%.2d\"", year, month, day);
    yylval.node = new_string_keep(date);
    return DATE_TOKEN;
}
\"[0-9]+\.[0-9]+\.[0-9]+\" {
    int year, month, day;
    sscanf(yytext, "\"%d.%d.%d\"", &year, &month, &day);
    char * date = malloc(13);
    snprintf(date, 13, "\"%.4d-%.2d-%.2d\"", year, month, day);
    yylval.node = new_string_keep(date);
    return DATE_TOKEN;
}
[+-]?[0-9]+\.[0-9]+ { yylval.node = new_float(yytext); return FLOAT_TOKEN; }
[+-]?[0-9]+ { yylval.node = new_int(yytext); return INT_TOKEN; }
"yes" { yylval.node = new_bool("true"); return BOOL_TOKEN; }
"no" { yylval.node = new_bool("false"); return BOOL_TOKEN; }
[\'A-Za-z0-9\_\.\-\xa1-\xff]+ { yylval.node = new_string(yytext); return NAME_TOKEN; }
\"[^"]*\" { yylval.node = new_string(yytext); return STRING_TOKEN; }
. { fprintf(stderr, "Invalid Character is %s\n", yytext); yyerror("Invalid Token"); }

%%
