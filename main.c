#define _CRT_SECURE_NO_WARNINGS

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "poly.h"
#include "y.tab.h"

FILE* yyin;

extern int line_num;

int new_line = 0, finish = 0, read_var = 0;

void input_end()
{
	getchar();
	exit(0);
}

int yylex()
{
	if (finish) input_end();

	int c;

	while (1)
	{
		c = getc(yyin);
		if (c == EOF)
		{
			finish = 1;
			if (new_line == 0) return '\n';
			input_end();
		}
		if (c != ' ') break;
	}

	if (c == '#')
	{
		while (1)
		{
			c = getc(yyin);
			if (c == EOF)
			{
				finish = 1;
				if (new_line == 0) return '\n';
				input_end();
			}
			if (c == '\n') break;
		}
	}

	if (read_var)
	{
		if (isupper(c))
		{
			yylval.ival = c - 'A';
			new_line = 0;
			read_var = 0;
			return (VAR);
		}
		else
		{
			printf("Error: bad variable name: $%c at line %d", c, line_num);
			getchar();
			exit(1);
		}
	}

	if (islower(c))
	{
		yylval.ival = c;
		new_line = 0;
		return (LETTER);
	}
	else if (isupper(c))
	{
		yylval.ival = c - 'A';
		new_line = 0;
		return (VAR);
	}
	else if (isdigit(c))
	{
		yylval.ival = c - '0';
		new_line = 0;
		return (DIGIT);
	}

	if (c == '+' || c == '-'
		|| c == '*' || c == '/' || c == '(' || c == ')'
		|| c == '^' || c == '\'' || c == '$' || c == '=')
	{
		if (c == '$') read_var = 1;
		new_line = 0;
		return c;
	}
	else if (c == '\n')
	{
		new_line = 1;
		return '\n';
	}
	else
	{
		printf("Error: bad symbol %c at line %d", c, line_num);
		getchar();
		exit(1);
	}
}

void yyerror(const char* msg)
{
	printf("Error at line %d: %s", line_num, msg);
	getchar();
	exit(1);
}

int main(int argc, char* argv[])
{
	yyin = fopen("input.txt", "r");
	yyparse();
}