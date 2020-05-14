%start program

%token SELECT FROM WHERE AS ON EXIT INNER OUTER LEFT RIGHT FULL JOIN SUM COUNT AVG ORDER_BY ASC DESC MAX MIN USE LIMIT
%token OR EQ NEQ LEQ GEQ AND
%token FLOAT_LITERAL INTEGER_LITERAL IDENTIFIER


%{
	#include "header.h"
%}


%%
program:
	cmd limit ';'
	{
		table &t = *(new table);
		table &t1 = eval($1,t);
		if($1->size > 3)
		{
			std::vector<std::string> col_order;
			get_column_order($1->child[1],col_order);
			if($2->size == 0)
				t1.print(col_order);
			else
				t1.print(col_order,atoi($2->child[1]->name->c_str()));
		}
		for(auto t:all_table)
			t->clear();
		all_table.clear();
	};

limit:
	LIMIT INTEGER_LITERAL
	{
		$1 = makenode("LIMIT","LIMIT");
		$2 = makenode(std::string(yytext),std::string(yytext));
		$$ = makenode("limit",*$1->name + " " + *$2->name,$1,$2);
	}
|	%empty
	{
		$$ = makenode("limit","limit");
	};

cmd:
	SELECT columns FROM tables WHERE expr ORDER_BY sort_info
	{
		$1 = makenode("SELECT","SELECT");
		$3 = makenode("FROM","FROM");
		$5 = makenode("WHERE","WHERE");
		$7 = makenode("ORDER_BY","ORDER_BY");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name) + " " + *($4->name) + " " + *($5->name) + " " + *($6->name) + " " + *($7->name) + " "+ *($8->name);
		$$ = makenode("cmd",name,$1,$2,$3,$4,$5,$6,$7,$8);
	}
|	SELECT columns FROM tables WHERE expr 
	{
		$1 = makenode("SELECT","SELECT");
		$3 = makenode("FROM","FROM");
		$5 = makenode("WHERE","WHERE");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name) + " " + *($4->name) + " " + *($5->name) + " " + *($6->name);
		$$ = makenode("cmd",name,$1,$2,$3,$4,$5,$6);
	}
|	SELECT columns FROM tables ORDER_BY sort_info
	{
		$1 = makenode("SELECT","SELECT");
		$3 = makenode("FROM","FROM");
		$5 = makenode("ORDER_BY","ORDER_BY");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name) + " " + *($4->name) + " " + *($5->name) + " " + *($6->name) ;
		$$ = makenode("cmd",name,$1,$2,$3,$4,$5,$6);
	}
|	SELECT columns FROM tables
	{
		$1 = makenode("SELECT","SELECT");
		$3 = makenode("FROM","FROM");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name) + " " + *($4->name);
		$$ = makenode("cmd",name,$1,$2,$3,$4);
	}
|	USE database
	{
		$1 = makenode("USE","USE");
		std::string name = *($1->name) + " " + *($2->name);
		$$ = makenode("cmd",name,$1,$2);
	}	
|	EXIT
	{
		$1 = makenode("EXIT","EXIT");
		$$ = makenode("cmd",*($1->name),$1);
	};

database:
	database identifier '/'
	{
		$3 = makenode("/","/");
		std::string name = *($1->name)+ *($2->name) + *($3->name);
		$$ = makenode("database",name,$1,$2,$3);
	}
|	%empty
	{
		$$ = makenode("database","");
	};

sort_info:
	column ASC
	{
		$2 = makenode("ASC","ASC");
		$$ = makenode("sort_info",*($1->name) + " ASC",$1,$2);
	}
|	column DESC
	{
		$2 = makenode("DESC","DESC");
		$$ = makenode("sort_info",*($1->name) + " DESC",$1,$2);		
	}
|	column
	{
		$$ = makenode("sort_info",*($1->name),$1);
	};

columns: 
	column
	{
		$$ = makenode("columns",*($1->name),$1);
	}
|	columns ',' column
	{
		$2 = makenode(",",",");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("columns",name,$1,$2,$3);
	};

column:
	Pexpr	AS	identifier
	{
		$2 = makenode("AS","AS");
		std::string name = *($3->name);
		$$ = makenode("column",name,$1,$2,$3);
	}
|	Pexpr
	{
		$$ = makenode("column",*($1->name),$1);
	}
|	'*'
	{
		$1 = makenode("*","*");
		$$ = makenode("column",*($1->name),$1);
	};	
	
expr:
	Pexpr OR Pexpr
	{
		$2 = makenode("OR","OR");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr EQ Pexpr
	{
		$2 = makenode("EQ","EQ");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr NEQ Pexpr
	{
		$2 = makenode("NEQ","NEQ");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr LEQ Pexpr
	{
		$2 = makenode("LEQ","LEQ");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr '<' Pexpr
	{
		$2 = makenode("<","<");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr GEQ Pexpr
	{
		$2 = makenode("GEQ","GEQ");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr '>' Pexpr
	{
		$2 = makenode(">",">");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr AND Pexpr
	{
		$2 = makenode("AND","AND");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr '+' Pexpr
	{
		$2 = makenode("+","+");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr '-' Pexpr
	{
		$2 = makenode("-","-");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr '*' Pexpr
	{
		$2 = makenode("*","*");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr '/' Pexpr
	{
		$2 = makenode("/","/");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	Pexpr '%' Pexpr
	{
		$2 = makenode("%","%");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("expr",name,$1,$2,$3);
	}
|	'!' Pexpr
	{
		$1 = makenode("!","!");
		std::string name = *($1->name) + " " + *($2->name);
		$$ = makenode("expr",name,$1,$2);
	}
|	'-' Pexpr
	{
		$1 = makenode("-","-");
		std::string name = *($1->name) + " " + *($2->name);
		$$ = makenode("expr",name,$1,$2);
	}
|	'+' Pexpr
	{
		$1 = makenode("+","+");
		std::string name = *($1->name) + " " + *($2->name);
		$$ = makenode("expr",name,$1,$2);
	}
|	Pexpr
	{
		$$ = makenode("expr",*($1->name),$1);
	};

Pexpr:
	integerLit
	{
		$$ = makenode("Pexpr",*($1->name),$1);
	}
|	floatLit
	{
		$$ = makenode("Pexpr",*($1->name),$1);
	}
|	identifier '.' identifier
	{
		$2 = makenode(".",".");
		std::string name = *($1->name) + *($2->name) + *($3->name);
		$$ = makenode("Pexpr",name,$1,$2,$3);
	}
|	identifier
	{
		$$ = makenode("Pexpr",*($1->name),$1);
	}
|	'(' expr ')'
	{
		$1 = makenode("(","(");
		$3 = makenode(")",")");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("Pexpr",name,$1,$2,$3);
	}
|	'(' cmd ')'
	{
		$1 = makenode("(","(");
		$3 = makenode(")",")");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("Pexpr",name,$1,$2,$3);
	}
|	aggregate '(' expr ')'
	{
		$2 = makenode("(","(");
		$4 = makenode(")",")");
		std::string name = *($1->name) + *($2->name) + " " + *($3->name) + " " + *($4->name);
		$$ = makenode("Pexpr",name,$1,$2,$3,$4);
	}
|	aggregate '(' cmd ')'
	{
		$2 = makenode("(","(");
		$4 = makenode(")",")");
		std::string name = *($1->name) + *($2->name) + " " + *($3->name) + " " + *($4->name);
		$$ = makenode("Pexpr",name,$1,$2,$3,$4);
	};

aggregate: 
	SUM
	{
		$1 = makenode("SUM","SUM");
		$$ = makenode("aggregate","SUM",$1);
	}
|	AVG
	{
		$1 = makenode("AVG","AVG");
		$$ = makenode("aggregate","AVG",$1);
	}
|	COUNT
	{
		$1 = makenode("COUNT","COUNT");
		$$ = makenode("aggregate","COUNT",$1);
	}
|	MAX
	{
		$1 = makenode("MAX","MAX");
		$$ = makenode("aggregate","MAX",$1);
	}
|	MIN
	{
		$1 = makenode("MIN","MIN");
		$$ = makenode("aggregate","MIN",$1);
	};

integerLit:
	INTEGER_LITERAL
	{
		$1 = makenode(std::string(yytext),std::string(yytext));
		$$ = makenode("integerLit",*($1->name),$1);
	};

floatLit:
	FLOAT_LITERAL
	{
		$1 = makenode(std::string(yytext),std::string(yytext));
		$$ = makenode("floatLit",*($1->name),$1);
	};

identifier:
	IDENTIFIER
	{
		$1 = makenode(std::string(yytext),std::string(yytext));
		$$ = makenode("identifier",*($1->name),$1);
	};

table: 
	identifier AS identifier
	{
		$2 = makenode("AS","AS");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("table",name,$1,$2,$3);
	}
|	identifier 
	{
		$$ = makenode("table",*($1->name),$1);
	}
|	'(' cmd ')' AS identifier
	{
		$1 = makenode("(","(");
		$3 = makenode(")",")");
		$4 = makenode("AS","AS");
		std::string name = *($5->name);
		$$ = makenode("table",name,$1,$2,$3,$4,$5);
	};

tables:
	tables join table ON expr
	{
		$4 = makenode("ON","ON");
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name) + " " + *($4->name) + " " + *($5->name);
		$$ = makenode("tables",name,$1,$2,$3,$4,$5);
	}
|	tables join table
	{
		std::string name = *($1->name) + " " + *($2->name) + " " + *($3->name);
		$$ = makenode("tables",name,$1,$2,$3);
	}
|	table
	{
		$$ = makenode("tables",*($1->name),$1);
	};

join:
	JOIN
	{
		$1 = makenode("INNER JOIN","INNER JOIN");
		$$ = makenode("join",*($1->name),$1);
	}
|	INNER JOIN
	{
		$1 = makenode("INNER JOIN","INNER JOIN");
		$$ = makenode("join",*($1->name),$1);
	}
|	LEFT outer JOIN
	{
		$1 = makenode("LEFT OUTER JOIN","LEFT OUTER JOIN");
		$$ = makenode("join",*($1->name),$1);
	}
|	RIGHT outer JOIN
	{
		$1 = makenode("RIGHT OUTER JOIN","RIGHT OUTER JOIN");
		$$ = makenode("join",*($1->name),$1);
	}
|	FULL outer JOIN
	{
		$1 = makenode("FULL OUTER JOIN","FULL OUTER JOIN");
		$$ = makenode("join",*($1->name),$1);
	}
|	','
	{
		$1 = makenode(",",",");
		$$ = makenode("join",*($1->name),$1);
	};

outer:
	%empty
	{
		
	}
|	OUTER
	{
			
	}
%%
