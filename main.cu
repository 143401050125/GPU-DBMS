#include "yacc.cu"
#include "lex.cu"

int main()
{
	dbpath = "";
	tmp_table = 0; //assuming tmp table path is dbpath + "/tmp/table_" + tmp_table;
	print_tables = true;
	tmp_table_limit = 100;
	do 
	{
		setjmp(env_buffer);
		char *line = NULL;
		size_t len = 0;
		std::cout<<"Enter Query : ";
		getline(&line, &len, stdin);
		YY_BUFFER_STATE buffer = yy_scan_string(line);
		yy_switch_to_buffer(buffer);
		cudaEventCreate(&start); 
		cudaEventCreate(&stop);
		cudaEventRecord(start);
		yyparse();
		yy_delete_buffer(buffer);
	} while (!feof(stdin));
	
	return 0;
}