
#include <iostream>
#include <string>
#include <fstream>
#include <set>
#include <unordered_map>
#include <setjmp.h>
#include <utility>
#include <thrust/extrema.h>
#include <stdlib.h>

#include <cuda.h>
#include <sys/stat.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/transform_iterator.h>
#include <thrust/iterator/permutation_iterator.h>
#include <thrust/iterator/discard_iterator.h>
#include <thrust/functional.h>
#include <thrust/fill.h>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/transform.h>
#include <thrust/reduce.h>
#include <thrust/gather.h>
#include <thrust/scan.h>
#include <thrust/binary_search.h>

#include "table.h"
#include "template.h"

#define INT_FLAG -2147483648
#define FLOAT_FLAG 1.17549e-38

//----------------------- program global variables and function declaration-----------------------------

//variables to capture time taken by a query
extern cudaEvent_t start, stop;
extern float et;

//jmup buffer : jump to ignore the current query when some error has occurred
extern jmp_buf env_buffer;

//path of current database
extern std::string dbpath;

//count for temporary table
extern int tmp_table;

//true if we want to print tables in the output
extern bool print_tables;

//flag to start storing temporary table into files
extern int tmp_table_limit;

//------------------------------------lex yacc extern variables and functions-----------------------------------------

extern char* yytext;

//called when some error has occurred completly ignores the current executing query and jump to next query  
void yyerror(std::string);

//lex function to take input to do the lexing
int yylex(void);

typedef struct yy_buffer_state * YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char * str); // it does not work.
extern YY_BUFFER_STATE yy_scan_buffer(char *, size_t);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);
extern void yy_switch_to_buffer(YY_BUFFER_STATE buffer);
#define YYSTYPE struct node *


//------------------------------------structures and class -------------------------------------------------------------

//AST node
typedef struct node{
  
  //pointer to name of the AST node 
  std::string *name;

  //pointer to id of the AST node
  std::string *id;

  //pointer to childrens of AST node 
  node * child[10];

  //number of childrens of AST node
  int size;
}node;


struct functor1 : public thrust::unary_function<int, int>
{
	int K;
	functor1(int k): K(k) {};
	__host__ __device__ int operator()(const int &x) {
	return x/K;
	}
};

struct functor2 : public thrust::unary_function<int, int>
{
	int K,N;
	functor2(int n,int k): N(n),K(k) {};
	__host__ __device__ int operator()(const int &x) {
		int d = x/N;
		int r = x%N;
	return K*r+d;
	}
};

//type int to float
struct to_float{
	__host__ __device__ float operator()(int &x) const{
    if(x == INT_FLAG)
      return FLOAT_FLAG;
		return (float)x;
	}
};

//float modulus 
struct fmodulus{
	__host__ __device__ float operator()(float &x, float &y) const{
		return fmod(x,y);
	}
};


//column data type
class column{
  public:

    //name of table
    std::string tname;
    
    //type of column  0: int , 1: float
    int type;

    //column storage for int type
    thrust::device_vector<int> i;

    //column storage for float type
    thrust::device_vector<float> f;

    //constructor
    column();
};

//table data type
class table
{
  private:
 
    // column name to column mapping
    std::unordered_map<std::string,column> umap;
 
  public:
    
    // table name and its alias
    std::string name;
 
    // name of table in our database 
    std::string original_name;
 
    //key of table 
    thrust::device_vector<bool> key;
 
    bool flag;
    
    //name of all the columns of table
    std::set<std::string> columnNames;
 
    //number of rows in the table
    int row_count;
 
    //constructor
    table(std::string nn = "");
    
    //returns parse column name from colname
    std::string get_column_name(std::string colname);
 
    //returns column with name col
    column &get_column(std::string col);

    //copy the column col into the table with column name as colname
    void set_column(std::string colname,column &col);

    //prints the table
    void print(int row_limit = -1);

    //number of loaded column in the table
    int size();

    //returns the first column in the table
    column &get_first_column();
    
    //retunrs name of first column in loaded column
    std::string get_first_column_name();

    //creates a new column and returns reference to it
    column &new_column(std::string cname);

    //erase column with name as cname
    void erase_column(std::string cname);

    //prints all the loaded column of table
    void print_column();
    
    //apply condition on the table 
    void updatekey(table &t1);
  
    //renaming column with name cname1 to cname2
    void move_column(std::string cname1,std::string cname2);

    //moving the content of col into current table as cname
    void copy_column(std::string cname,column &col);

    //writing metadata of the temporary table
    void write_metadata(std::string tname = "",int nrows = 0, int ncols = 0);

    //writing column of temporary table
    void write_column(std::string cname);

    //writes the temporary table
    void write(std::string tname );

    //clear all the vector assigned to columns of the table
    void clear();
};

//create a AST node with given parameters 
node * makenode(std::string id,std::string name, node *c1 = NULL, node *c2 = NULL, node *c3 = NULL, node *c4 = NULL, node *c5 = NULL, node *c6 = NULL, node *c7 = NULL, node *c8 = NULL, node *c9 = NULL, node *c10 = NULL );

//t1 is a column, t2 is a column, 
//this function does binary operation (op) on both the columns 
void binary_op(table & t1, table & t2,const std::string &op);

//t1 is a column
//this function does unary operation on the column and write the output in t1
void unary_op(table & t1, std::string &op);

//t1 is a table with multiple columns, t2 is a column which represent the key of the table t1
//this function apply the condition in t2 to table t1 and write the output in t1
void apply_result(table &t1, table &t2);

//t1 and t2 both are tables with multiple columns
//this function find the corss product of both the tables and write the output in t1
//---- special case if number of rows in the output is more than tmp_table_limit then we write it as temporary table
table &cross_prod(table &t1,table &t2);

//t1 is a table with multiple column representing cross product of table t3 and t4, 
//t2 is a column representing the key of the table t1, t5 is a int which represent the type of join
void eval_join(table &t1,table &t2,table &t3,table &t4,table &t5);

//t1 is a column, agunc is name of aggregated function, new_name is name of column
void aggregate_function(table &t1, std::string agfunc, std::string new_name);

//t2 is a table, col_order is name of column on which sorting has to be done,
//col_present is true if col_order is present in the t2, is_desc is true if we are suppose to sort t1 in descending order
void make_sorted(table &t2, std::string col_order, bool col_present, bool is_desc = false);

//does analysis on the AST tree, depending on the id of AST node 
table &eval(node *root,table &t);

//sets the size of orig to siz by appending spaces at the front
void rjust(std::string &orig, int siz);