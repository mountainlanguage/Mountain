#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>

#include "parser.h"
#include "ast.h"


struct TOKEN next_token(FILE *source_file)
{
	struct TOKEN token = {true, TOKEN_WORD, strdup("")};
	bool in_token = false;
	char car;
	while(true)
	{
		car = fgetc(source_file);
		if(car == EOF)
		{
			goto return_token;
		}

		if(!in_token)
		{
			switch(car)
			{
				case ':':
				{
					token.type = TOKEN_COLON;
					goto return_car_as_token;
				}

				case ';':
				{
					token.type = TOKEN_SEMICOLON;
					goto return_car_as_token;
				}

				case '#':
				{
					token.type = TOKEN_COMMENT;
					goto return_car_as_token;
				}
			}
		}

		switch(car)
		{
			case ' ':
			case '\t':
			case '\n':
			case ':':
			case ';':
			case '#':
			{
				if(!in_token)
					continue;
				else
				{
					ungetc(car, source_file); //HACK FIXME
					goto return_token;
				}

				break;
			}
			default:
				in_token = true;
		}

		int old_token_length = strlen(token.string);
		char *new_token = malloc(sizeof(char) * (old_token_length+2)); //Two larger than originally
		strcpy(new_token, token.string);
		free(token.string);
		token.string = new_token;
		token.string[old_token_length] = car; //Place in first new spot
		token.string[old_token_length + 1] = '\0'; //Null terminate in second new spot
	}

return_token: ;
	if(strlen(token.string) <= 0 && car == EOF) //If token is blank and is at the end of the file
	{
		token.valid = false;
		return token; //Return NULL
	}
	return token; //Otherwise return the token

return_car_as_token: ;
	free(token.string);
	token.string = malloc(sizeof(char) * 2);
	token.string[0] = car;
	token.string[1] = '\0';
	return token;
}


struct TOKEN next_token_no_semicolon(FILE* source_file, char *expected) //Exits on semicolon while printing message
{
	struct TOKEN token = next_token(source_file);

	if(token.type == TOKEN_SEMICOLON)
	{
		printf("Expected %s: found semicolon\n", expected);
		exit(EXIT_FAILURE);
	}

	return token;
}


bool parse_next_statement(FILE *source_file)
{
	struct TOKEN token = next_token(source_file);
	if(!token.valid)
	{
		printf("Reached end of file\n");
		free(token.string);
		return false;
	}

	if(token.type == TOKEN_COMMENT)
	{
		printf("Encountered comment, reading to end of line\n");
		free(token.string);

		//Consume until end of comment
		char car = ' ';
		while(car != '\n')
		{
			car = getc(source_file);
		}

		return true;
	}

	if(token.type == TOKEN_SEMICOLON)
	{
		printf("Reached end of statement\n");
		free(token.string);
		return true;
	}

	if(token.type == TOKEN_WORD)
	{
		printf("Word found: %s\n", token.string);
		if(strcmp(token.string, "def") == 0)
		{
			free(next_token_no_semicolon(source_file, "colon").string);

			//We must be dealing with a variable definition
			struct NODE *new_node = create_node(AST_DEF);
			new_node->def_location = current_parse_parent_node->stack_len;
			current_parse_parent_node->stack_len += 1;

			free(new_node->type_name);
			new_node->type_name = next_token_no_semicolon(source_file, "type").string;

			free(new_node->def_name);
			new_node->def_name = next_token_no_semicolon(source_file, "name").string;

			add_node(new_node);
		}
	}
	else if(token.type == TOKEN_COLON)
		printf("Colon found\n");

	free(token.string);
	return true;
}
