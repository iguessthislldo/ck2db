#ifndef JSON_HEADER
#define JSON_HEADER

enum node_type {
    OBJ_NODE_TYPE,
    PROP_NODE_TYPE,
    INT_NODE_TYPE,
    ARRAY_NODE_TYPE,
    FLOAT_NODE_TYPE,
    BOOL_NODE_TYPE,
    STR_NODE_TYPE
};

// OBJ is OBJ-(childern)->PROP-(sibling)->PROP-(sibling)->..->0
//                          |              |
//                       (value)         (value)
//                          |              |
//                          V              V
//                        CHILD1         CHILD2
// ARRAY is ARRAY-(childern)->CHILD1-(sibling)->CHILD-(sibling)->..->0

struct prop {
    struct node * name;
    struct node * value;
};

union node_value {
    struct node *childern; // OBJ or ARRAY
    char * string_value; // STR
    struct prop prop_value; // PROP
};

typedef struct node {
    struct node *parent, *sibling;
    enum node_type type;
    union node_value value;
} Node;

Node * new_node(enum node_type type);

Node * new_int(char * value);
Node * new_float(char * value);
Node * new_string(char * value);
Node * new_string_keep(char * value);
Node * new_bool(char * value);
Node * new_prop(Node * name, Node * value);

void emit_json(FILE* file, Node *node);
Node * node_append(Node * oldest, Node * newest);

#endif
