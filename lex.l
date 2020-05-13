%{ 
 	#include <iostream>
 	#include <string>
	#include "yacc.hu"
	void yyerror(std::string s);
	extern int yyreject(void);
	extern int line;
%}

%% 
\#.*		;
(?i:exit)			{return EXIT;}
(?i:use)			{return USE;}
(?i:limit)			{return LIMIT;}
(?i:inner) 			{return INNER;}
(?i:outer) 			{return OUTER;}
(?i:left) 			{return LEFT;}
(?i:right) 			{return RIGHT;}
(?i:full) 			{return FULL;}
(?i:join) 			{return JOIN;}
(?i:select) 		{return SELECT;}
(?i:from) 			{return FROM;}
(?i:where)	 		{return WHERE;}
(?i:and) 			{return AND;}
(?i:or) 				{return OR;}
(?i:not)				{return '!';}
(?i:as) 				{return AS;}
(?i:on) 				{return ON;}
(?i:sum) 			{return SUM;}
(?i:count) 		{return COUNT;}
(?i:avg) 			{return AVG;}
(?i:max) 			{return MAX;}
(?i:min) 			{return MIN;}
(?i:order_by) 	{return ORDER_BY;}
(?i:asc) 			{return ASC;}
(?i:desc) 			{return DESC;}
"||"		{return  OR;}
"=="		{return  EQ;}
"!="		{return  NEQ;}
"<="		{return  LEQ;}
">="		{return  GEQ;}
"&&"		{return  AND;}
;|,|\[|\]|\*|\(|\)|\=|\{|\}|\.	{return  *yytext;}
\<|\>|\+|\-|\/|\%|\!|\&			{return  *yytext;}
[_a-zA-Z][_a-zA-Z0-9]* 	{return  IDENTIFIER;}
[0-9]+ 			{return  INTEGER_LITERAL;}
([0-9]+\.[0-9]*|[0-9]*\.[0-9]+) {return  FLOAT_LITERAL;}
[ \t]	;
.	{yyerror("Invalid Input");}	
%% 

int yywrap(void) {
    return 1;
}