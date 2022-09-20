
#include <stdio.h>
#include <time.h>
#include "mylib.h"

void printCurrentTime(char *buffer)
{
	time_t now = time(NULL);
	struct tm l = *localtime(&now);

	sprintf(buffer, "%02d-%02d-%02d %02d:%02d:%02d", l.tm_year + 1900, l.tm_mon + 1, l.tm_mday, l.tm_hour, l.tm_min, l.tm_sec);
}

