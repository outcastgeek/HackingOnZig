
#include <stdio.h>
#include "mylib.h"

int multiply(int a, int b)
{
	char buffer[64];
	getCurrentTime(buffer);

	printf("[%s] calling c multiply with function arguments: a=%d, and b=%d", buffer, a, b);

	int product = a * b;
	return product;
}

