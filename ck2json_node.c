#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include "ck2json.h"

#define PROP_VALUE(node) ((node)->value.prop_value.value)
#define PROP_NAME_NODE(node) ((node)->value.prop_value.name)
#define PROP_NAME(node) (PROP_NAME_NODE(node)->value.string_value)

char * copy_string(const char * orig) {
    size_t l = strlen(orig);
    char * copy = malloc(l);
    strncpy(copy, orig, l);
    return copy;
}

Node * new_node(enum node_type type) {
    Node * node = malloc(sizeof(Node));
    node->head = node;
    node->sibling = 0;
    node->type = type;
    return node;
}

Node * new_object(Node * childern) {
    Node * node = new_node(OBJ_NODE_TYPE);
    node->value.childern = childern;
    return node;
}

Node * new_array(Node * childern) {
    Node * node = new_node(ARRAY_NODE_TYPE);
    node->value.childern = childern;
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

char last_char = 'x';
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
            fputc('1', f);
        }
        state = 0;
    }
    // Ignore Latin1 non printables
    if (c == '\t' || c == '\n' || (c > 0x1f && c < 0x7f) || (c > 0xa0 && c <= 0xff)) {
        //last_char = c;
        fputc(c, f);
    }/* else if (last_char == '\"' && (c != '"' || c != ',' || c != '}' || c != ']')) {
        __builtin_trap();
    }*/
}

void print_string(FILE * f, const char * s) {
    for (;*s;s++) print_char(f, *s);
}

void print_quoted_string(FILE * f, char * s) {
    if (*s != '\"') {
        print_char(f, '\"');
        print_string(f, s);
        print_char(f, '\"');
    } else {
        print_string(f, s);
    }
}

void emit_json(FILE* file, Node *node) {
    if (!node) return;
    switch(node->type) {
    case OBJ_NODE_TYPE:
        print_char(file, '{');
        emit_json(file, node->value.childern);
        print_string(file, "}\n");
        break;
    case PROP_NODE_TYPE:
        print_quoted_string(file, PROP_NAME(node));
        print_char(file, ':');
        emit_json(file, node->value.prop_value.value);
        break;
    case INT_NODE_TYPE:
        print_string(file, node->value.string_value);
        break;
    case ARRAY_NODE_TYPE:
        print_char(file, '[');
        emit_json(file, node->value.childern);
        print_string(file, "]\n");
        break;
    case FLOAT_NODE_TYPE:
        print_string(file, node->value.string_value);
        break;
    case BOOL_NODE_TYPE:
        print_string(file, node->value.string_value);
        break;
    case STR_NODE_TYPE:
        print_quoted_string(file, node->value.string_value);
    }
    if (node->sibling) {
        print_char(file, ',');
        emit_json(file, node->sibling);
    }
}

Node * node_append(Node * childern, Node * newest) {
    Node * n = childern;
    if (!n) {
        newest->head = newest;
        return newest;
    }
    for (; n->sibling; n = n->sibling);
    n->head = childern;
    n->sibling = newest;
    return childern;
}

Node * node_set(Node * childern, Node * new_prop) {
    Node * name = new_prop->value.prop_value.name;
    Node * value = new_prop->value.prop_value.value;
    Node * child_prop = childern;

    // No Current Childern, Return new Property to be used
    if (!child_prop) {
        return new_prop;
    }

    // Find the matching child or the last child
    bool found = false;
    while (true) {
        if (!strcmp(PROP_NAME(child_prop), name->value.string_value)) {
            found = true;
            break;
        }
        if (child_prop->sibling) {
            child_prop = child_prop->sibling;
        } else break;
    }
    if (found) { // There is a child property with that name
        // Get the current value of the child property
        Node * current_value = PROP_VALUE(child_prop);
        // If the current value is not an array, put it in one
        if (current_value->type != ARRAY_NODE_TYPE) {
            PROP_VALUE(child_prop) = new_node(ARRAY_NODE_TYPE);
            PROP_VALUE(child_prop)->value.childern = current_value;
            // Name or new_prop will not be used anymore
            /*
            free(name);
            free(new_prop);
            */
        }
        // Append the new property value to the array in the child property
        PROP_VALUE(child_prop)->value.childern = node_append(PROP_VALUE(child_prop)->value.childern, value);
        return childern;
    } else { // There isn't, add it to the end like normal
        child_prop->sibling = new_prop;
        new_prop->head = childern;
        return childern;
    }
}
