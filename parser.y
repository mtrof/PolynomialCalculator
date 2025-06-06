%{
#include "poly.h"

POLYNOM vars[26];
int init[26] = { 0 };
int line_num = 1;
%}

%start program

%union
{
    int ival;
    POLYNOM pval;
}

%token <ival> DIGIT
%token <ival> LETTER
%token <ival> VAR

%type <pval> expr 
%type <pval> term
%type <pval> factor1
%type <pval> factor2
%type <pval> factor3
%type <pval> monom
%type <pval> variable

%type <ival> number

%left '+' '-'
%left '*' '/'
%left UMINUS
%left '(' ')'
%left '\''
%right '^'
%right POWER

%%

program:
  | program line
;

line: statement '\n'
    {
        line_num++;
    }
;

statement:
  | set_var
  | print_expr
;

set_var: '$' VAR '=' expr
    {
        vars[$2] = $4;
        init[$2] = 1;
    }
;

print_expr: expr
    {
        print_polynom(&$1);
    }
;

expr: expr '+' term
    {
        add(&$1, &$3);
        $$ = $1;
    }
  | expr '+' '+' term
    {
        yyerror("two '+' signs");
    }
  | expr '-' term
    {
        sub(&$1, &$3);
        $$ = $1;
    }
  | term
;

term: term '*' factor1
    {
        mult(&$1, &$3, 1);
        $$ = $1;
    }
  | term '*' '*' factor1
    {
        yyerror("two '*' signs");
    }
  | factor1
;

factor1: factor2
  | '-' factor2 %prec UMINUS
    {
        neg(&$2);
        $$ = $2;
    }
;

factor2: factor3 '^' factor2
    {
        pow(&$1, &$3);
        $$ = $1;
    }
  | number LETTER '^' factor2
    {
        memset(&$$, 0, sizeof(POLYNOM));
        assign(&$$, $2, 1, 1);
        pow(&$$, &$4);
        memset(&$4, 0, sizeof(POLYNOM));
        assign(&$4, 'a', 0, $1);
        mult(&$$, &$4, 1);
    }
  | LETTER '^' factor2
    {
        memset(&$$, 0, sizeof(POLYNOM));
        assign(&$$, $1, 1, 1);
        pow(&$$, &$3);
    }
  | factor3
  | factor3 '^' '-' number
    {
        yyerror("negative power");
    }
;

factor3: monom
  | variable
  | '(' expr ')'
    {
        $$ = $2;
    }
;

monom: number LETTER
    {
        memset(&$$, 0, sizeof(POLYNOM));
        assign(&$$, $2, 1, $1);
    }
  | LETTER
    {
        memset(&$$, 0, sizeof(POLYNOM));
        assign(&$$, $1, 1, 1);
    }
  | number
    {
        memset(&$$, 0, sizeof(POLYNOM));
        assign(&$$, 'a', 0, $1);
    }
;

variable: '$' VAR
    {
        memset(&$$, 0, sizeof(POLYNOM));
        if (init[$2])
            copy_polynom(&$$, &vars[$2]);
        else
            yyerror("uninitialized variable");
    }
;

number : DIGIT
    {
        $$ = $1;
    }
  | number DIGIT
    {
        $$ = 10 * $1 + $2;
    }
;

%%

SINGLE_POLYNOM* find(POLYNOM* p, char v)
{
    SINGLE_POLYNOM* t = p->head;

    while (t != NULL)
    {
        if (v == t->var) return t;
        t = t->next;
    }

    return NULL;
}

int check_vars(POLYNOM* a, POLYNOM* b)
{
    SINGLE_POLYNOM* t1 = a->head;
    SINGLE_POLYNOM* t2 = b->head;
    int i = 0, j = 0;
    for (; t1 != NULL; t1 = t1->next, i++);
    for (; t2 != NULL; t2 = t2->next, j++);

    if (i == 0 && j == 0)
    {
        assign(a, 'x', 1, 0);
        assign(b, 'x', 1, 0);
        i++;
        j++;
    }
    else
    {
        if (i == 0)
        {
            assign(a, b->head->var, 1, 0);
            i++;
        }

        if (j == 0)
        {
            assign(b, a->head->var, 1, 0);
            j++;
        }
    }

    if (i != 1 || j != 1) return 0;

    SINGLE_POLYNOM* p1 = a->head;
    SINGLE_POLYNOM* p2 = b->head;

    if (p1->var != p2->var) return 0;

    return 1;
}

void print_polynom(POLYNOM* p)
{
    int flag = 0;
    char letter = 'a';
    SINGLE_POLYNOM* pol = p->head;

    while (pol != NULL)
    {
        letter = pol->var;
        for (int i = MAX_POWER - 1; i >= 0; i--)
        {
            int coef = pol->coefs[i];
            if (coef == 0) continue;
            if (flag)
            {
                if (coef > 0)
                    printf(" + ");
                else
                    printf(" - ");
            }
            else if (coef < 0)
                printf("-");
            flag = 1;
            int abs_coef = (coef > 0) ? (coef) : (-coef);
            if (abs_coef != 1 || i == 0)
                printf("%d", abs_coef);
            if (i >= 1)
                printf("%c", letter);
            if (i >= 2)
                printf("^%d", i);
        }
        pol = pol->next;
    }

    if (flag == 0) printf("%d", p->num_coef);
    else if (p->num_coef != 0)
    {
        int p_num_coef = p->num_coef;
        printf("%s", (p_num_coef > 0) ? " + " : " - ");
        int abs_coef = (p_num_coef > 0) ? (p_num_coef) : (-p_num_coef);
        printf("%d", abs_coef);
    }

    printf("\n");
}

void assign(POLYNOM* p, char v, int power, int coef)
{
    if (power == 0)
    {
        p->num_coef = coef;
        return;
    }

    if (power >= MAX_POWER)
        yyerror("polynom power is too huge");

    SINGLE_POLYNOM* sp = find(p, v);

    if (sp == NULL)
    {
        SINGLE_POLYNOM* new = (SINGLE_POLYNOM*)malloc(sizeof(SINGLE_POLYNOM));
        memset(new, 0, sizeof(SINGLE_POLYNOM));

        new->var = v;
        new->coefs[power] = coef;
        new->next = p->head;
        p->head = new;
    }
    else
    {
        sp->coefs[power] = coef;
    }
}

void copy_polynom(POLYNOM* dst, POLYNOM* src)
{
    SINGLE_POLYNOM* src_ptr = src->head;
    SINGLE_POLYNOM* list_start = NULL;
    SINGLE_POLYNOM* prev_new = NULL;

    int i = 0;

    while (src_ptr != NULL)
    {
        SINGLE_POLYNOM* new = (SINGLE_POLYNOM*)malloc(sizeof(SINGLE_POLYNOM));
        memcpy(new, src_ptr, sizeof(SINGLE_POLYNOM));
        if (prev_new != NULL) prev_new->next = new;
        
        if (i == 0) list_start = new;

        src_ptr = src_ptr->next;
        i++;
        prev_new = new;
    }

    dst->head = list_start;
    dst->num_coef = src->num_coef;
}

void free_polynom(POLYNOM* p)
{
    SINGLE_POLYNOM* old = p->head;
    SINGLE_POLYNOM* cur = p->head;

    while (cur != NULL)
    {
        old = cur;
        cur = cur->next;
        free(old);
    }
}

void add(POLYNOM* a, POLYNOM* b)
{
    if (!check_vars(a, b))
        yyerror("operation is not allowed");

    SINGLE_POLYNOM* bt = b->head;
    while (bt != NULL)
    {
        SINGLE_POLYNOM* at = find(a, bt->var);
        if (at == NULL)
        {
            SINGLE_POLYNOM* new = (SINGLE_POLYNOM*)malloc(sizeof(SINGLE_POLYNOM));

            new->var = bt->var;
            memcpy(new->coefs, bt->coefs, MAX_POWER * sizeof(int));

            new->next = a->head;
            a->head = new;
        }
        else
        {
            for (int i = 0; i < MAX_POWER; i++)
                at->coefs[i] += bt->coefs[i];
        }
        bt = bt->next;
    }
    a->num_coef += b->num_coef;

    free_polynom(b);
}

void neg(POLYNOM* p)
{   
    SINGLE_POLYNOM* ptr = p->head;

    while (ptr != NULL)
    {
        for (int i = 0; i < MAX_POWER; i++)
            ptr->coefs[i] = -(ptr->coefs[i]);
        ptr = ptr->next;
    }

    p->num_coef = -(p->num_coef);
}

void sub(POLYNOM* a, POLYNOM* b)
{
    neg(b);
    add(a, b);
}

void mult(POLYNOM* a, POLYNOM* b, int free_mem)
{
    if (!check_vars(a, b))
        yyerror("operation is not allowed");

    SINGLE_POLYNOM* p1 = a->head;
    SINGLE_POLYNOM* p2 = b->head;

    p1->coefs[0] = a->num_coef;
    p2->coefs[0] = b->num_coef;
    int coefs[MAX_POWER] = { 0 };

    for (int k = 0; k < MAX_POWER; k++)
    {
        for (int l = 0; l < MAX_POWER; l++)
        {
            if (k + l < MAX_POWER)
                coefs[k + l] += p1->coefs[k] * p2->coefs[l];
            else if (p1->coefs[k] * p2->coefs[l] != 0)
                yyerror("polynom power is too huge");
        }
    }

    p1->coefs[0] = 0;
    p2->coefs[0] = 0;

    a->num_coef = coefs[0];
    for (int h = 1; h < MAX_POWER; h++)
        p1->coefs[h] = coefs[h];

    if (free_mem) free_polynom(b);
}

void pow(POLYNOM* p, POLYNOM* power)
{
    int num_power = power->num_coef;

    SINGLE_POLYNOM* tmp_ptr = power->head;
    while(tmp_ptr != NULL)
    {
        for (int i = 1; i < MAX_POWER; i++)
        {
            if (tmp_ptr->coefs[i]) yyerror("operation is not allowed");
        }
        tmp_ptr = tmp_ptr->next;
    }

    if (num_power < 0) yyerror("negative power");

    if (num_power != 0)
    {
        POLYNOM tmp;
        copy_polynom(&tmp, p);
        for (int i = 1; i < num_power; i++)
            mult(p, &tmp, 0);
        free_polynom(&tmp);
    }
    else
    {
        free_polynom(p);
        p->head = NULL;
        p->num_coef = 1;
    }

    free_polynom(power);
}