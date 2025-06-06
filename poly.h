#ifndef POLY_H
#define POLY_H

#include <stdlib.h>
#include <string.h>

#define MAX_POWER 32

typedef struct single_polynom {
    char var;
    int coefs[MAX_POWER];
    struct single_polynom* next;
} SINGLE_POLYNOM;

typedef struct polynom {
    SINGLE_POLYNOM* head;
    int num_coef;
} POLYNOM;

SINGLE_POLYNOM* find(POLYNOM* p, char v);
int check_vars(POLYNOM* a, POLYNOM* b);
void assign(POLYNOM* p, char v, int power, int coef);
void copy_polynom(POLYNOM* dst, POLYNOM* src);
void free_polynom(POLYNOM* p);
void add(POLYNOM* a, POLYNOM* b);
void neg(POLYNOM* p);
void sub(POLYNOM* a, POLYNOM* b);
void mult(POLYNOM* a, POLYNOM* b, int free_mem);
void pow(POLYNOM* p, POLYNOM* power);
void print_polynom(POLYNOM* p);

#endif