%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>

#include <iconv.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern size_t lineno;
extern size_t level;

iconv_t toutf8;

void indent();

char * fix_name(char * name) {
    size_t i = 0;
    while (name[i]) i++;
    if (name[i-1] == '=') name[i-1] = '\0';
    return name;
}

bool characters = false;
bool characters_done = false;
bool character_name = false;

void process_name(char * name) {
    switch(level) {
    case 1:
        if (characters) {
            if (strcmp(name, "character")) {
                characters = false;
                characters_done = true;
            }
        } else if (!characters_done) {
            if (!strcmp(name, "character")) {
                characters = true;
            }
        }
        break;
    case 3:
        if (!strcmp(name, "bn")) {
            character_name = true;
        }
        break;
    default:
        break;
    }
}

void process_int(int value) {
    if (level == 2 && characters) {
        printf("%d: ", value);
    }
}

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

void process_string(char * string) {
    switch(level) {
    case 3:
        if (character_name) {
            char * utf8 = convert_to_utf8(string);
            printf("%s\n", utf8);
            character_name = false;
            free(utf8);
        }
    default:
        break;
    }
}

struct dict {
    struct dict * parent;
};

%}

%code requires {
void yyerror(const char* s);
}

%union {
    int int_value;
    float float_value;
    char * string_value;
}

%token MAGIC_NUMBER_TOKEN
%token EQUALS_TOKEN
%token START_TOKEN
%token END_TOKEN
%token<string_value> NAME_TOKEN
%token<string_value> DATE_TOKEN
%token<string_value> STRING_TOKEN
%token<int_value> INT_TOKEN
%token<int_value> BOOL_TOKEN
%token<float_value> FLOAT_TOKEN

%start ck2file

%%

ck2file: MAGIC_NUMBER_TOKEN entries END_TOKEN;

entries: entries entry | entry;

entry: key EQUALS_TOKEN value;

key: NAME_TOKEN { process_name(fix_name($1)); }
   | INT_TOKEN { process_int($1); }
   | DATE_TOKEN
   ;

value: DATE_TOKEN
     | STRING_TOKEN { process_string($1); }
     | BOOL_TOKEN
     | INT_TOKEN
     | FLOAT_TOKEN
     | NAME_TOKEN
     | array
     | dict
     ;

dict: START_TOKEN entries END_TOKEN | START_TOKEN END_TOKEN;

array: START_TOKEN array_contents END_TOKEN;
array_contents: int_array | float_array | name_array | dict_array;
int_array: int_array INT_TOKEN | INT_TOKEN;
float_array: float_array FLOAT_TOKEN | FLOAT_TOKEN;
name_array: name_array NAME_TOKEN | NAME_TOKEN;
dict_array: dict_array dict| dict;

%%

int main(int argc, char * argv[]) {
    toutf8 = iconv_open("UTF-8", "LATIN6");
    if (toutf8 == (iconv_t) -1) {
        fprintf(stderr, "This iconv does not support \"LATIN6\" to \"UTF-8\"!");
        return 1;
    }
    yydebug = 0;
    lineno = 1;
    level = 1;
	yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Couldn't Open %s: %s\n", argv[1], strerror(errno));
        return 1;
    }
	do { 
		yyparse();
	} while(!feof(yyin));
    fclose(yyin);
	return 0;
}

void indent() {
    for (size_t l = 0; l < level; l++) printf("    ");
}

void yyerror(const char* s) {
	fprintf(stderr, "Parse error on line %lu: %s\n", lineno, s);
    fclose(yyin);
	exit(1);
}
