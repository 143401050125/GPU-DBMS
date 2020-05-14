# GPU-DBMS
A GPU accelerated Relational Database Management System implemented using CUDA C++
## How to Run

Run the Makefile
```bash
$ make 
```
It will the code and produce an executable a.out
To start the execution
```bash
$ ./a.out
```
## DataBase Structure(Storage on Disk)

Storage is as multiple databases which contains tables in them
### Table

It should be a file with .txt extension

### Database

It should be a folder which should contain all the tables(files) within it. The name of this folder is the name of the database 

### Structure of a Table

It is stored in column major order
The file contains two parts 
* metadata
* data

The metadata id of a fixed size and is at the begining of the file. It is of the format
Number_of_Rows Number_of_Columns Column1_Name Data_Type starting_position Column2_Name Data_Type starting_position .... 
The starting position is the number of bytes from the begining where the column starts in the file
For each column the elements within a column are space separated and consecutive columns are newline separated

## PreRequisites

The folder where the executable is present should have the databases.
The tables should have only int or float data types, strings and blobs are not supported

## Operations Supported 

This program implements a subset of SQL's Data Query Language. Data Definition and Data Manipulation is not supported

1. **SELECT**
2. **Aggregate Functions**
   * MIN
   * MAX
   * COUNT
   * SUM
   * AVG
3. **ORDER_BY**
   * ASC
   * DESC
4. **ALIAS**
5. **WHERE**
6. **JOIN**
   * INNER JOIN
   * LEFT OUTER JOIN
   * RIGHT OUTER JOIN
   * FULL OUTER JOIN
7. **USE**
8. **LIMIT**
## Use
*   USE

      * USE database;

*  SELECT

     * SELECT * FROM tables;
     * SELECT (column1 + column2) FROM tables;
     * SELECT column1,column2...,column_n FROM tables;

*  WHERE

     * SELECT columns FROM tables WHERE expr;

*  ORDER_BY
  
     * SELECT columns from tables WHERE expr ORDER_BY column_name;
     * SELECT columns from tables ORDER_BY column_name ASC;
     * SELECT columns from tables WHERE expr ORDER_BY DESC;

*   AS
     
     * SELECT column AS temp FROM tables;
     * SELCT column FROM (another select query returning a table) AS temp_name;

*  MIN | MAX | SUM | AVG | COUNT
     
     * SELECT MIN(column_name) FROM table;
     * SELECT columns FROM table WHERE column < AVG(other_column);

* JOIN
     
     * SELECT columns FROM table1, table2 ON c1.feature2 == c2.feature1;
     * SELECT columns FROM table1 AS t1 JOIN table2 AS t2 ON t1.col1 >= t2.col2;
     * SELECT columns FROM table1 as t1 FULL OUTER JOIN table2 AS t2 ON t1.col1 < t2.col2;
     * SELECT columns FROM table1 as t1 LEFT OUTER JOIN table2 AS t2 ON t1.col2 == t2.col2 RIGHT OUTER JOIN table3 AS t3 on t1.somecol == t3.somecol;
* LIMIT
    * SELECT columns FROM tables WHERE expr LIMIT n;
     
### Grammar for expressions
**expr**:

>Pexpr OR Pexpr
 
>|	Pexpr == Pexpr

>|	Pexpr != Pexpr

>|	Pexpr <= Pexpr

>|	Pexpr < Pexpr

>|	Pexpr >= Pexpr

>|	Pexpr > Pexpr

>|	Pexpr AND Pexpr

>|	Pexpr + Pexpr

>|	Pexpr - Pexpr

>|	Pexpr * Pexpr

>|	Pexpr / Pexpr

>|	Pexpr % Pexpr

>|	! Pexpr

>|	- Pexpr

>|	+ Pexpr

>|	Pexpr

**Pexpr**:

>	integerLit

>|	floatLit

>|	identifier . identifier

>|	identifier

>|	( expr )

>|	( some select query )

>|	aggregate ( expr )

>|	aggregate ( some select query )

## Test on Sample Data
```bash
$ make
$ python3 generate_dataset.py 500 ../sample
$ ./a.out < Query
```

## How it works
The program is implemented in CUDA C++. For parsing the input we have used Lex and Yacc. After reading a query from the user we build an expression tree using yacc. The expression tree is then evaluated. Data is loaded into memory from disk and then passed to GPU to perform the required operation in parallel. We have used Thrust Library to perform some operations. The processed data is then moved back to main memory and printed using the CPU.

The project mainly focuses on optimizing the operations(like sorting, reducing ) in parallel using GPU and not on the data retrieval part, though the current schema is choosen to give significant speed up in data retrieval from disk.

## Future Work
String and blob may also be supported later alongwith group by clause. The scope of the project could be fully realised if Data manipulation and Data definition are also supported. 

## Authors
Adarsh Singh and Rishabh Thakur
