#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "ck2json.h"

char * copy_string(const char * orig) {
    size_t l = strlen(orig);
    char * copy = malloc(l);
    strncpy(copy, orig, l);
    return copy;
}

Node * new_node(enum node_type type) {
    Node * node = malloc(sizeof(Node));
    node->parent = 0;
    node->sibling = 0;
    node->type = type;
    return node;
}

Node * new_int(char * value) {
    Node * node = new_node(INT_NODE_TYPE);
    node->value.string_value = copy_string(value);
    return node;
}

Node * new_float(char * value) {
    Node * node = new_node(INT_NODE_TYPE);
    node->value.string_value = copy_string(value);
    return node;
}

Node * new_string_keep(char * value) {
    Node * node = new_node(STR_NODE_TYPE);
    node->value.string_value = value;
    return node;
}

Node * new_string(char * value) {
    return new_string_keep(copy_string(value));
}

Node * new_bool(char * value) {
    Node * node = new_node(BOOL_NODE_TYPE);
    node->value.string_value = value;
    return node;
}

Node * new_prop(Node * name, Node * value) {
    Node * node = new_node(PROP_NODE_TYPE);
    node->value.prop_value.name = name;
    node->value.prop_value.value = value;
    return node;
}

void print_char(FILE * f, char c) {
    // Fix Cases of "1, and "1}
    static int state = 0;
    switch (state) {
    case 0:
        if (c == '\"') state = 1;
        break;
    case 1:
        if (c == '1') {
            state = 2;
            return;
        }
        state = 0;
        break;
    case 2:
        if (!(c == ',' || c == '}')) {
            fputc(f, '1');
        }
        state = 0;
    }
    // Remove CK2 Specfic Characters
    if (c >= 0x74 && c <= 0xa0) {
        c = '?';
    }
    fputc(f, c);
}

void print_string(FILE * f, const char * s) {
    for (;*s;s++) print_char(f, *s);
}

void print_quoted_string(FILE * f, char * s) {
    if (*s != '\"') {
        print_char('\"');
        print_string(f, s);
        print_char('\"');
    } else {
        print_string(f, s);
    }
}

void emit_json(FILE* file, Node *node) {
    if (!node) return;
    switch(node->type) {
    case OBJ_NODE_TYPE:
        print_char('{');
        emit_json(file, node->childern);
        print_string("{\n");
        break;
    case PROP_NODE_TYPE:
        print_quoted_string(file, node->value.prop_type.name->value.string_type);
        print_char(':');
        emit_json(file, node->value.prop_type.value);
        break;
    case INT_NODE_TYPE:
        print_string(file, node->value.string_type);
        break;
    case ARRAY_NODE_TYPE:
        print_char('[');
        emit_json(file, node->childern);
        print_string("]\n");
        break;
    case FLOAT_NODE_TYPE:
        print_string(file, node->value.string_type);
        break;
    case BOOL_NODE_TYPE:
        print_string(file, node->value.string_type);
        break;
    case STR_NODE_TYPE:
        print_quoted_string(file, node->value.prop_type.name->value.string_type);
    }
    if (node->sibling) {
        print_char(',');
        emit_json(node->sibling);
    }
}

Node * node_append(Node * oldest, Node * newest) {
    Node * n = oldest;
    if (!n) return newest;
    for (; n->sibling; n = n->sibling);
    n->sibling = newest;
    return oldest;
}
