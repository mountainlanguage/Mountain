#pragma once


#define GENERATE_ENUM(ENUM) ENUM,
#define GENERATE_STRING(STRING) #STRING,


#include "symbols.h"



int current_file;
int current_file_line;
int current_file_character;

char **paths;
