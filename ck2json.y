/*
 * ck2_read
 * Process contents of ck2 files
 *
 * Bison file for read_ck2
 */
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>
#include <ctype.h>

#include "ck2json.h"

Node * root;
Node * current_node;

#include <iconv.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern size_t lineno;
extern size_t level;

iconv_t toutf8;

// Print Indent on stdout according to level
void indent();

void cleanup();

/*
 * Remove '=' that bison is leaving in for what ever reason on object names
 */
char * fix_name(char * name) {
    size_t i = 0;
    while (name[i]) i++;
    if (name[i-1] == '=') name[i-1] = '\0';
    return name;
}

char * fix_string(char * string) {
    size_t l = strlen(string);
    if (string[l-1] != '\"') {
        char * s;
        for (s = string + 1; *s != '\"'; s++);
        s++;
        *s = '\0';
    }
    return string;
}

bool characters = false;
bool characters_done = false;
bool character_name = false;

char * convert_to_utf8(char * string) {
    size_t in_left = strlen(string);
    char * in = string;
    char * out = calloc(4*in_left, 1);
    char * result = out;
    size_t out_left = 4*in_left;
    size_t iconv_result = 0;
    iconv_result = iconv(toutf8, &in, &in_left, &out, &out_left);
    if (iconv_result == -1) {
        fprintf(stderr, "iconv error on line %lu: %s\n", lineno, strerror(errno));
        exit(2);
    }
    return result;
}

%}

%code requires {
void yyerror(const char* s);
}

%union {
    Node * node;
}

%token MAGIC_NUMBER_TOKEN
%token EQUALS_TOKEN
%token START_TOKEN
%token END_TOKEN
%token<node> NAME_TOKEN
%token<node> DATE_TOKEN
%token<node> STRING_TOKEN
%token<node> INT_TOKEN
%token<node> BOOL_TOKEN
%token<node> FLOAT_TOKEN

%type<node> entries
%type<node> entry
%type<node> key
%type<node> value
%type<node> dict
%type<node> array
%type<node> array_contents
%type<node> number_array 
%type<node> number
%type<node> dict_array 
%type<node> name_string_array 
%type<node> name_string

%start ck2file

%%

ck2file: MAGIC_NUMBER_TOKEN entries END_TOKEN { root = new_object($2); }
       | entries { root = new_object($1); }
       ;

entries:
    entries entry { $$ = node_set($1, $2); }
    | entry
;

entry: key EQUALS_TOKEN value { $$ = new_prop($1, $3); } ;

key: NAME_TOKEN
    {
        $1->value.string_value = fix_name($1->value.string_value);
        $$ = $1;
    }
   | INT_TOKEN
   | DATE_TOKEN
   ;

value: DATE_TOKEN
     | STRING_TOKEN { $1->value.string_value = fix_string($1->value.string_value); $$ = $1; }
     | BOOL_TOKEN
     | INT_TOKEN
     | FLOAT_TOKEN
     | NAME_TOKEN
     | array
     | dict
     ;

dict: START_TOKEN entries END_TOKEN { $$ = new_object($2); }
    | START_TOKEN END_TOKEN { $$ = new_object(0); };

array: START_TOKEN array_contents END_TOKEN { $$ = new_array($2); }
array_contents: number_array | name_string_array | dict_array;
number_array: number_array number { $$ = node_append($1, $2); } | number;
number: FLOAT_TOKEN | INT_TOKEN;
name_string_array: name_string_array name_string { $$ = node_append($1, $2); } | name_string;
name_string: NAME_TOKEN | STRING_TOKEN;
dict_array: dict_array dict { $$ = node_append($1, $2); } | dict;

%%

void cleanup() {
    if (yyin) fclose(yyin);
    iconv_close(toutf8);
}

int main(int argc, char * argv[]) {
    
    // Init iconv
    toutf8 = iconv_open("UTF-8", "LATIN6");
    if (toutf8 == (iconv_t) -1) {
        fprintf(stderr, "This iconv does not support \"LATIN6\" to \"UTF-8\"!");
        return 1;
    }

    // Set up global variables
    //yydebug = 0;
    lineno = 1;
    level = 1;
    
    // Open File
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Couldn't Open %s: %s\n", argv[1], strerror(errno));
        cleanup();
        return 1;
    }

    // Parse File
    do {
        yyparse();
    } while(!feof(yyin));

    emit_json(stdout, root);

    cleanup();
    return 0;
}

void indent() {
    for (size_t l = 0; l < level; l++) printf("    ");
}

void yyerror(const char* s) {
    fprintf(stderr, "Parse error on line %lu: %s\n", lineno, s);
    cleanup();
    exit(1);
}
