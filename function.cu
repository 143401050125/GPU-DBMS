#include "header.h"

node * makenode(std::string id,std::string name, node *c1 , node *c2 , node *c3 , node *c4 , node *c5 , node *c6 , node *c7 , node *c8 , node *c9 , node *c10)
{
  node * nn = new node;
  nn->name = new std::string;
  nn->id = new std::string;
  *(nn->id) = id;
  *(nn->name) = name;
  
  nn->child[0] = c1;
  nn->child[1] = c2;
  nn->child[2] = c3;
  nn->child[3] = c4;
  nn->child[4] = c5;
  nn->child[5] = c6;
  nn->child[6] = c7;
  nn->child[7] = c8;
  nn->child[8] = c9;
  nn->child[9] = c10;
  
  nn->size = 0;
  for(int i=0;i<10;i++)
    if(nn->child[i])
      nn->size++;
  
  return nn;
  if(c1)
    nn->child[0] = c1,nn->size++;
  if(c2)
    nn->child[1] = c2,nn->size++;
  if(c3)
    nn->child[2] = c3,nn->size++;
  if(c4)
    nn->child[3] = c4,nn->size++;
  if(c5)
    nn->child[4] = c5,nn->size++;
  if(c6)
    nn->child[5] = c6,nn->size++;
  if(c7)
    nn->child[6] = c7,nn->size++;
  if(c8)
    nn->child[7] = c8,nn->size++;
  if(c9)
    nn->child[8] = c9,nn->size++;
  if(c10)
    nn->child[9] = c10,nn->size++;

  return nn;
}

void yyerror(std::string s) 
{
	std::cout<<std::endl<<s<<std::endl<<std::endl;
	longjmp(env_buffer, 1);
}

void rjust(std::string &orig, int siz)
{
		int cur_len = orig.length();
		siz -= cur_len;
		orig = std::string(siz,' ') + orig;
}

void binary_op(table & t1, table & t2,const std::string &op)
{
	if(!(t1.size() == 1 && t2.size() == 1))
		yyerror("Invalid operation : operand is not a column (binary operation)");
	
	column &col1 = t1.get_first_column();
	column &col2 = t2.get_first_column();
	
	if(col1.type != col2.type)
	{
		if(col1.type)
		{
			thrust::device_vector<float> &key1 = col2.f;
			to_float funt;
			key1.resize(col2.i.size());
			thrust::transform(col2.i.begin(),col2.i.end(),key1.begin(),funt);
			col2.i.clear();
			col2.type = 1;
		}else
		{
			thrust::device_vector<float> &key1 = col1.f;
			to_float funt;
			key1.resize(col1.i.size());
			thrust::transform(col1.i.begin(),col1.i.end(),key1.begin(),funt);
			col1.i.clear();
			col1.type = 1;
		}
	}
	
	if(col1.type)
	{
		if(col1.f.size() != col2.f.size())
		{
			if(col1.f.size() == 1 && col2.f.size() > 0)
			{
				col1.f.resize(col2.f.size(),col1.f[0]);
				t1.row_count = t2.row_count;
			}else if(col2.f.size() == 1 && col1.f.size() > 0)
			{
				col2.f.resize(col1.f.size(),col2.f[0]);
				t2.row_count = t1.row_count;
			}else
			{
				yyerror("Invalid operation : operand(columns) size is not equal");
				return;
			}
		}
	}else
	{
		if(col1.i.size() != col2.i.size())
		{
			if(col1.i.size() == 1 && col2.i.size() > 0)
			{
				col1.i.resize(col2.i.size(),col1.i[0]);
				t1.row_count = t2.row_count;
			}else if(col2.i.size() == 1 && col1.i.size() > 0)
			{
				col2.i.resize(col1.i.size(),col2.i[0]);
				t2.row_count = t1.row_count;
			}else
			{
				yyerror("Invalid operation : operand(columns) size is not equal");
				return;
			}
		}
	}
	#undef TRANSFORM
	#define TRANSFORM(op) thrust::transform(key1.begin(),key1.end(),key2.begin(),key1.begin(),op)
	
	assert(t1.row_count == t2.row_count);
	thrust::device_vector<bool> is_null(t1.row_count);	

	if(col1.type)
	{
		thrust::device_vector<float> &key1 = col1.f;
		thrust::device_vector<float> &key2 = col2.f;

		thrust::transform(key1.begin(),key1.end(),key2.begin(),is_null.begin(),[=] __device__ __host__  (float &f1,float &f2) { return (f1==FLOAT_FLAG || f2==FLOAT_FLAG) ? false : true;});
		
		if (op == "NEQ")
			TRANSFORM(thrust::not_equal_to<float>());
		else if (op == ">")
			TRANSFORM(thrust::greater<float>());
		else if (op == "<")
			TRANSFORM(thrust::less<float>());
		else if (op == "GEQ")
			TRANSFORM(thrust::greater_equal<float>());
		else if (op == "LEQ")
			TRANSFORM(thrust::less_equal<float>());
		else if (op == "EQ")
			TRANSFORM(thrust::equal_to<float>());
		else if (op == "OR")
			TRANSFORM(thrust::logical_or<float>());
		else if (op == "AND")
			TRANSFORM(thrust::logical_and<float>());
		else if (op == "+")
			TRANSFORM(thrust::plus<float>());
		else if (op == "-")
			TRANSFORM(thrust::minus<float>());
		else if (op == "*")
			TRANSFORM(thrust::multiplies<float>());
		else if (op == "/")
			TRANSFORM(thrust::divides<float>());
		else if (op == "%")
		{
			fmodulus f;
			TRANSFORM(f);
		}
		else 
			yyerror("Undefined Binary Operation");
		if(op == "+" || op == "-" || op == "*" || op == "/" || op == "%")
			thrust::transform(is_null.begin(),is_null.end(),key1.begin(),key1.begin(),[=] __device__ __host__  (bool &b,float &f) { return (b==false) ? FLOAT_FLAG : f;});
		else
			thrust::transform(is_null.begin(),is_null.end(),key1.begin(),key1.begin(),[=] __device__ __host__  (bool &b,float &f) { return (b==false) ? 0 : f;});
	}else
	{
		thrust::device_vector<int> &key1 = col1.i;
		thrust::device_vector<int> &key2 = col2.i;

		thrust::transform(key1.begin(),key1.end(),key2.begin(),is_null.begin(),[=] __device__ __host__  (int &i1,int &i2) { return (i1==INT_FLAG || i2==INT_FLAG) ? false : true;});
		
		if (op == "NEQ")
			TRANSFORM(thrust::not_equal_to<int>());
		else if (op == ">")
			TRANSFORM(thrust::greater<int>());
		else if (op == "<")
			TRANSFORM(thrust::less<int>());
		else if (op == "GEQ")
			TRANSFORM(thrust::greater_equal<int>());
		else if (op == "LEQ")
			TRANSFORM(thrust::less_equal<int>());
		else if (op == "EQ")
			TRANSFORM(thrust::equal_to<int>());
		else if (op == "OR")
			TRANSFORM(thrust::logical_or<int>());
		else if (op == "AND")
			TRANSFORM(thrust::logical_and<int>());
		else if (op == "+")
			TRANSFORM(thrust::plus<int>());
		else if (op == "-")
			TRANSFORM(thrust::minus<int>());
		else if (op == "*")
			TRANSFORM(thrust::multiplies<int>());
		else if (op == "/")
			TRANSFORM(thrust::divides<int>());
		else if (op == "%")
			TRANSFORM(thrust::modulus<int>());
		else 
			yyerror("Undefined Binary Operation");
		
		if(op == "+" || op == "-" || op == "*" || op == "/" || op == "%")
			thrust::transform(is_null.begin(),is_null.end(),key1.begin(),key1.begin(),[=] __device__ __host__  (bool &b,int &i) { return (b==false) ? INT_FLAG : i;});
		else
			thrust::transform(is_null.begin(),is_null.end(),key1.begin(),key1.begin(),[=] __device__ __host__  (bool &b,int &i) { return (b==false) ? 0 : i;});
	}
	
	is_null.clear();

}


void unary_op(table & t1, std::string &op)
{
	if(t1.size() != 1)
	{
		yyerror("Invalid operation : operand is not a column (unary operation)");
		return;
	}
	column &col1 = t1.get_first_column();
	thrust::device_vector<bool> is_null(t1.row_count,false);	
	
	if(col1.type)
	{
		thrust::device_vector<float> &key1 = col1.f;
		thrust::transform(key1.begin(),key1.end(),is_null.begin(),[=] __device__ __host__  (float &f) { return (f==FLOAT_FLAG) ? false : true;});
		if (op == "!")
			thrust::transform(key1.begin(),key1.end(),key1.begin(),thrust::logical_not<float>());
		else if (op == "-")
			thrust::transform(key1.begin(),key1.end(),key1.begin(),thrust::negate<float>());
		else if(op != "+")
			yyerror("Undefined Unary Operation");

		if(op == "!")
			thrust::transform(is_null.begin(),is_null.end(),key1.begin(),key1.begin(),[=] __device__ __host__  (bool &b,float &f) { return (b==false) ? 0 : f;});
		else
			thrust::transform(is_null.begin(),is_null.end(),key1.begin(),key1.begin(),[=] __device__ __host__  (bool &b,float &f) { return (b==false) ? FLOAT_FLAG : f;});
	}else
	{
		thrust::device_vector<int> &key1 = col1.i;
		thrust::transform(key1.begin(),key1.end(),is_null.begin(),[=] __device__ __host__  (int &i) { return (i==INT_FLAG) ? false : true;});
		if (op == "!")
			thrust::transform(key1.begin(),key1.end(),key1.begin(),thrust::logical_not<int>());
		else if (op == "-")
			thrust::transform(key1.begin(),key1.end(),key1.begin(),thrust::negate<int>());
		else if(op != "+")
			yyerror("Undefined Unary Operation");
		
		if(op == "!")
			thrust::transform(is_null.begin(),is_null.end(),key1.begin(),key1.begin(),[=] __device__ __host__  (bool &b,int &i) { return (b==false) ? 0 : i;});
		else
			thrust::transform(is_null.begin(),is_null.end(),key1.begin(),key1.begin(),[=] __device__ __host__  (bool &b,int &i) { return (b==false) ? INT_FLAG : i;});
	}
	is_null.clear();
}


void apply_result(table &t1, table &t2)
{
	int row_count = t1.row_count;
	assert(t1.row_count == t2.row_count);
	if(t2.size() != 1)
		yyerror("Invalid Opeartion : key is not present");
	
	bool flag1 = false,flag2 = false;
	column &key = t2.get_first_column();
	if(key.type)
	{
		if(key.f.size() == 1)
		{
			flag1 = true;
			flag2 = (key.f[0] != 0.0);
		}else if(key.f.size() != row_count)
		{
			yyerror("key size does not match column size");
			return;
		}
	}else
	{
		if(key.i.size() == 1)
		{
			flag1 = true;
			flag2 = (key.i[0] != 0);
		}else if(key.i.size() != row_count)
		{
			yyerror("key size does not match column size");
			return;
		}
	}

	for(auto cname:t1.columnNames)
	{
		column &col = t1.get_column(cname);
		if(col.type)
		{
			if(col.f.size() == 1)
			{
				col.f.resize(row_count,col.f[0]);
			}else if(col.f.size() != row_count)
			{
				yyerror("Column " + cname + " has elements not equal to rowcount of table.");
				return;
			}

			if(flag1)
			{
				if(flag2 == false)
					col.f.clear();
			}else
			{
				thrust::device_vector<float>::iterator it_end;
				if(key.type)
					it_end = thrust::remove_if(col.f.begin(),col.f.end(),key.f.begin(),thrust::logical_not<float>());
				else
					it_end = thrust::remove_if(col.f.begin(),col.f.end(),key.i.begin(),thrust::logical_not<int>());
				int newCount = it_end - col.f.begin();
				col.f.resize(newCount);
				t1.row_count = newCount;
			}
		}else
		{
			if(col.i.size() == 1)
			{
				col.i.resize(row_count,col.i[0]);
			}else if(col.i.size() != row_count)
			{
				yyerror("column " + cname + " has elements not equal to rowcount of table");
				return;
			}

			if(flag1)
			{
				if(flag2 == false)
					col.i.clear();
			}else
			{
				thrust::device_vector<int>::iterator it_end;
				if(key.type)
					it_end = thrust::remove_if(col.i.begin(),col.i.end(),key.f.begin(),thrust::logical_not<float>());
				else
					it_end = thrust::remove_if(col.i.begin(),col.i.end(),key.i.begin(),thrust::logical_not<int>());
				int newCount = it_end - col.i.begin();
				col.i.resize(newCount);
				t1.row_count = newCount;
			}
		}
	}
}

table &cross_prod(table &t1,table &t2)
{
	table &t = *(new table);
	t.row_count = t1.row_count * t2.row_count;
	bool write = false;
	if(t.row_count > tmp_table_limit)
 	{
		write = true;	 	
		t.write_metadata("tmp/table_" + std::to_string(tmp_table++),t.row_count,t1.columnNames.size()+t2.columnNames.size());
	}
	for(auto col_name1:t1.columnNames)
	{
		std::string col_name2 = col_name1;
		if(t2.columnNames.find(col_name1) != t2.columnNames.end())
			col_name2 = t1.get_column(col_name1).tname + "." + col_name1;
		column &col = t.new_column(col_name2);
		column &col1 = t1.get_column(col_name1);
		col.tname = col1.tname;
		if(col1.type)
		{
			col.type = 1;
			col.f.resize(t1.row_count * t2.row_count);
			assert(col1.f.size() == t1.row_count);

			typedef thrust::device_vector<float>::iterator Iterator;
			repeated_range<Iterator> Itr(col1.f.begin(), col1.f.end(), t2.row_count);
			thrust::copy(Itr.begin(), Itr.end(),col.f.begin());
		}else
		{
			col.type = 0;
			col.i.resize(t1.row_count * t2.row_count);
			assert(col1.i.size() == t1.row_count);
			
			typedef thrust::device_vector<int>::iterator Iterator;
			repeated_range<Iterator> Itr(col1.i.begin(), col1.i.end(), t2.row_count);
			thrust::copy(Itr.begin(), Itr.end(),col.i.begin());
		}
		if(write)
			t.write_column(col_name2);
	}
	
	for(auto col_name1 : t2.columnNames)
	{
		std::string col_name2 = col_name1;
		if(t1.columnNames.find(col_name1) != t1.columnNames.end())
			col_name2 = t2.get_column(col_name1).tname + "." + col_name1;
		column &col = t.new_column(col_name2);
		column &col2 = t2.get_column(col_name1);
		col.tname = col2.tname;
		if(col2.type)
		{
			col.type = 1;
			col.f.resize(t1.row_count * t2.row_count);
			assert(col2.f.size() == t2.row_count);
			
			typedef thrust::device_vector<float>::iterator Iterator;
			tiled_range<Iterator> Itr(col2.f.begin(), col2.f.end(), t1.row_count);
			thrust::copy(Itr.begin(), Itr.end(),col.f.begin());
		}else
		{
			col.type = 0;
			col.i.resize(t1.row_count * t2.row_count);
			assert(col2.i.size() == t2.row_count);
			
			typedef thrust::device_vector<int>::iterator Iterator;
			tiled_range<Iterator> Itr(col2.i.begin(), col2.i.end(), t1.row_count);
			thrust::copy(Itr.begin(), Itr.end(),col.i.begin());
		}
		if(write)
			t.write_column(col_name2);
	}


	return t;
}	

void eval_join(table &t1,table &t2,table &t3,table &t4,table &t5)
{
	//t1 corss product, t2 join condition, t3 first table, t4 second table, t5 join type
	if(t5.size() != 1 || t5.get_first_column().type != 0 || t5.get_first_column().i.size() != 1)
		yyerror("Invalid Join : error with join type");
	
	int type = t5.get_first_column().i[0];
	column &cond = t2.get_first_column();
	if(type == 1 || type == 2)
	{
		// cross product and inner join
		apply_result(t1,t2);
	}else if(type == 3)
	{
		// left outer join
		int N = t3.row_count;
		int K = t4.row_count;
		thrust::device_vector<int> sums(N,0);

		if(cond.type)
		{
			thrust::device_vector<float> &data = cond.f;
			assert(data.size() == N*K);
			thrust::transform(data.begin(),data.end(),data.begin(),thrust::placeholders::_1 != 0);
			thrust::reduce_by_key(thrust::device, thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor1(K)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor1(K)), data.begin(), thrust::discard_iterator<int>(), sums.begin());
			
			typedef thrust::device_vector<float>::iterator Iterator;
			strided_range<Iterator> it(data.begin(),data.end(),K);
			thrust::transform(it.begin(),it.end(),sums.begin(),it.begin(),[=] __device__ __host__ (float &a,int &b){return (b == 0) ? 1 : a;});
		} else 
		{
			thrust::device_vector<int> &data = cond.i;
			assert(data.size() == N*K);
			thrust::transform(data.begin(),data.end(),data.begin(),thrust::placeholders::_1 != 0);
			thrust::reduce_by_key(thrust::device, thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor1(K)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor1(K)), data.begin(), thrust::discard_iterator<int>(), sums.begin());
			//thrust::transform(sums.begin(),sums.end(),sums.begin(),thrust::placeholders::_1 == 0);
			
			typedef thrust::device_vector<int>::iterator Iterator;
			strided_range<Iterator> it(data.begin(),data.end(),K);
			thrust::transform(it.begin(),it.end(),sums.begin(),it.begin(),[=] __device__ __host__ (int &a,int &b){return (b == 0) ? 1 : a;});
		}
		for(auto cname:t4.columnNames)
		{
			if(t1.columnNames.find(cname) == t1.columnNames.end())
	 			cname = t4.get_column(cname).tname + "." + cname;
			column &col = t1.get_column(cname);
			if(col.type)
			{
				thrust::device_vector<float> &data = col.f;
				typedef thrust::device_vector<float>::iterator Iterator;
				strided_range<Iterator> it(data.begin(),data.end(),K);
				thrust::transform(it.begin(),it.end(),sums.begin(),it.begin(),[=] __device__ __host__ (float &a,int &b){return (b == 0) ? FLOAT_FLAG : a;});
			}else
			{
				thrust::device_vector<int> &data = col.i;
				typedef thrust::device_vector<int>::iterator Iterator;
				strided_range<Iterator> it(data.begin(),data.end(),K);
				thrust::transform(it.begin(),it.end(),sums.begin(),it.begin(),[=] __device__ __host__ (int &a,int &b){return (b == 0) ? INT_FLAG : a;});
			}
		}
		
		apply_result(t1,t2);
		
	}else if(type == 4)
	{
		//right outer join
		int N = t3.row_count;
		int K = t4.row_count;
		thrust::device_vector<int> sums(K,0);

		if(cond.type)
		{
			thrust::device_vector<float> &data = cond.f;
			assert(data.size() == N*K);
			thrust::device_vector<float> output(data.size());
			thrust::transform(data.begin(),data.end(),data.begin(),thrust::placeholders::_1 != 0);
			thrust::gather(thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor2(N,K)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor2(N,K)), data.begin(), output.begin());
			thrust::reduce_by_key(thrust::device, thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor1(N)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor1(N)), output.begin(), thrust::discard_iterator<int>(), sums.begin());
			
			thrust::transform(data.begin(),data.begin() + K,sums.begin(),data.begin(),[=] __device__ __host__ (float &a,int &b){return (b == 0) ? 1 : a;});
		} else 
		{
			thrust::device_vector<int> &data = cond.i;
			assert(data.size() == N*K);
			thrust::device_vector<int> output(data.size());
			thrust::transform(data.begin(),data.end(),data.begin(),thrust::placeholders::_1 != 0);
			thrust::gather(thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor2(N,K)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor2(N,K)), data.begin(), output.begin());
			thrust::reduce_by_key(thrust::device, thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor1(N)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor1(N)), output.begin(), thrust::discard_iterator<int>(), sums.begin());
			
			thrust::transform(data.begin(),data.begin() + K,sums.begin(),data.begin(),[=] __device__ __host__ (int &a,int &b){return (b == 0) ? 1 : a;});
		}
		for(auto cname:t3.columnNames)
		{
			if(t1.columnNames.find(cname) == t1.columnNames.end())
	 			cname = t3.get_column(cname).tname + "." + cname;
			column &col = t1.get_column(cname);
			if(col.type)
			{
				thrust::device_vector<float> &data = col.f;
				thrust::transform(data.begin(),data.begin() + K,sums.begin(),data.begin(),[=] __device__ __host__ (float &a,int &b){return (b == 0) ? FLOAT_FLAG : a;});
			}else
			{
				thrust::device_vector<int> &data = col.i;
				thrust::transform(data.begin(),data.begin() + K,sums.begin(),data.begin(),[=] __device__ __host__ (int &a,int &b){return (b == 0) ? INT_FLAG : a;});
			}
		}
		
		apply_result(t1,t2);
		
	}else if(type == 5)
	{
		//full outer join
		typedef struct dtypes
		{
			int i;
			float f;
			std::string s;
		}dtypes;
		std::unordered_map<std::string,dtypes> store_overlap;
		{
			// left outer join
			int N = t3.row_count;
			int K = t4.row_count;
			thrust::device_vector<int> sums(N,0);

			if(cond.type)
			{
				thrust::device_vector<float> &data = cond.f;
				assert(data.size() == N*K);
				thrust::transform(data.begin(),data.end(),data.begin(),thrust::placeholders::_1 != 0);
				thrust::reduce_by_key(thrust::device, thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor1(K)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor1(K)), data.begin(), thrust::discard_iterator<int>(), sums.begin());
				//thrust::transform(sums.begin(),sums.end(),sums.begin(),thrust::placeholders::_1 == 0);
				
				typedef thrust::device_vector<float>::iterator Iterator;
				strided_range<Iterator> it(data.begin(),data.end(),K);
				thrust::transform(it.begin(),it.end(),sums.begin(),it.begin(),[=] __device__ __host__ (float &a,int &b){return (b == 0) ? 1 : a;});
				if(sums[0]==0)
					data[0] = 0;
			} else 
			{
				thrust::device_vector<int> &data = cond.i;
				assert(data.size() == N*K);
				thrust::transform(data.begin(),data.end(),data.begin(),thrust::placeholders::_1 != 0);
				thrust::reduce_by_key(thrust::device, thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor1(K)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor1(K)), data.begin(), thrust::discard_iterator<int>(), sums.begin());
				//thrust::transform(sums.begin(),sums.end(),sums.begin(),thrust::placeholders::_1 == 0);
				
				typedef thrust::device_vector<int>::iterator Iterator;
				strided_range<Iterator> it(data.begin(),data.end(),K);
				thrust::transform(it.begin(),it.end(),sums.begin(),it.begin(),[=] __device__ __host__ (int &a,int &b){return (b == 0) ? 1 : a;});
				if(sums[0]==0)
					data[0] = 0;
			}
			
			if(sums[0]==0)
	 		{
				for(auto cname:t1.columnNames)
				{
					column &col = t1.get_column(cname);
					if(col.type)
						store_overlap[cname].f = col.f[0];
					else	
						store_overlap[cname].i = col.i[0];
				}
			}

			for(auto cname:t4.columnNames)
			{
				if(t1.columnNames.find(cname) == t1.columnNames.end())
					cname = t4.get_column(cname).tname + "." + cname;
				column &col = t1.get_column(cname);
				if(col.type)
				{
					thrust::device_vector<float> &data = col.f;
					typedef thrust::device_vector<float>::iterator Iterator;
					strided_range<Iterator> it(data.begin(),data.end(),K);
					thrust::transform(it.begin(),it.end(),sums.begin(),it.begin(),[=] __device__ __host__ (float &a,int &b){return (b == 0) ? FLOAT_FLAG : a;});
					if(sums[0]==0)
		 				col.f[0] = store_overlap[cname].f, store_overlap[cname].f = FLOAT_FLAG;
				}else
				{
					thrust::device_vector<int> &data = col.i;
					typedef thrust::device_vector<int>::iterator Iterator;
					strided_range<Iterator> it(data.begin(),data.end(),K);
					thrust::transform(it.begin(),it.end(),sums.begin(),it.begin(),[=] __device__ __host__ (int &a,int &b){return (b == 0) ? INT_FLAG : a;});
					if(sums[0]==0)
		 				col.i[0] = store_overlap[cname].i, store_overlap[cname].i = INT_FLAG;
				}
			}
			
		
		}
		
		{
			//right outer join
			int N = t3.row_count;
			int K = t4.row_count;
			thrust::device_vector<int> sums(K,0);

			if(cond.type)
			{
				thrust::device_vector<float> &data = cond.f;
				assert(data.size() == N*K);
				thrust::device_vector<float> output(data.size());
				thrust::transform(data.begin(),data.end(),data.begin(),thrust::placeholders::_1 != 0);
				thrust::gather(thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor2(N,K)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor2(N,K)), data.begin(), output.begin());
				thrust::reduce_by_key(thrust::device, thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor1(N)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor1(N)), output.begin(), thrust::discard_iterator<int>(), sums.begin());
				
				thrust::transform(data.begin(),data.begin() + K,sums.begin(),data.begin(),[=] __device__ __host__ (float &a,int &b){return (b == 0) ? 1 : a;});
			} else 
			{
				thrust::device_vector<int> &data = cond.i;
				assert(data.size() == N*K);
				thrust::device_vector<int> output(data.size());
				thrust::transform(data.begin(),data.end(),data.begin(),thrust::placeholders::_1 != 0);
				thrust::gather(thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor2(N,K)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor2(N,K)), data.begin(), output.begin());
				thrust::reduce_by_key(thrust::device, thrust::make_transform_iterator(thrust::counting_iterator<int>(0), functor1(N)), thrust::make_transform_iterator(thrust::counting_iterator<int>(N*K), functor1(N)), output.begin(), thrust::discard_iterator<int>(), sums.begin());
				
				thrust::transform(data.begin(),data.begin() + K,sums.begin(),data.begin(),[=] __device__ __host__ (int &a,int &b){return (b == 0) ? 1 : a;});
			}
			for(auto cname:t3.columnNames)
			{
				if(t1.columnNames.find(cname) == t1.columnNames.end())
					cname = t3.get_column(cname).tname + "." + cname;
				column &col = t1.get_column(cname);
				if(col.type)
				{
					thrust::device_vector<float> &data = col.f;
					thrust::transform(data.begin(),data.begin() + K,sums.begin(),data.begin(),[=] __device__ __host__ (float &a,int &b){return (b == 0) ? FLOAT_FLAG : a;});
				}else
				{
					thrust::device_vector<int> &data = col.i;
					thrust::transform(data.begin(),data.begin() + K,sums.begin(),data.begin(),[=] __device__ __host__ (int &a,int &b){return (b == 0) ? INT_FLAG : a;});
				}
			}
			
			
		}
		if(store_overlap.size())
		{
			for(auto &p:store_overlap)
			{
				column &col = t1.get_column(p.first);
				if(col.type)
					col.f.push_back(p.second.f);
				else
					col.i.push_back(p.second.i);
			}
			t1.row_count += 1;
			t2.row_count += 1;
	 		if(cond.type)
				cond.f.push_back(1);
			else
				cond.i.push_back(1);
		}
		apply_result(t1,t2);

	}
	
}

void aggregate_function(table &t1, std::string agfunc, std::string new_name)
{
	if(t1.size() != 1)
		yyerror("aggregate function called on a table not column");
	column &opcol = t1.get_first_column();
	column &newcol = *(new column);
	if(opcol.type)
	{
	 	if( agfunc == "SUM")
		{
			float init = 0.0; 
			float sum = thrust::reduce(opcol.f.begin(), opcol.f.end(), init, thrust::plus<float>());
			opcol.f.clear();
			newcol.type = 1;
			newcol.f.push_back(sum);
		}
		else if(agfunc == "AVG")
		{
			float init = 0.0; 
			float sum = thrust::reduce(opcol.f.begin(), opcol.f.end(), init, thrust::plus<float>());
			float fsize = (float)opcol.f.size();
			opcol.f.clear();
			newcol.type = 1;
			newcol.f.push_back(sum/fsize);
		 }
		else if(agfunc == "COUNT")
		{
			int fcount = opcol.f.size(); 
			opcol.f.clear();
			newcol.type= 0;
			newcol.i.push_back(fcount);
		}else if(agfunc == "MAX")
		{
			float max = *thrust::max_element(opcol.f.begin(),opcol.f.end()); 
			opcol.f.clear();
			newcol.type= 1;
			newcol.f.push_back(max);
		}else if(agfunc == "MIN")
		{
			thrust::sort(opcol.f.begin(),opcol.f.end());
			thrust::device_vector<float>::iterator it;
			it = thrust::upper_bound(opcol.f.begin(),opcol.f.end(),FLOAT_FLAG);
			float min = FLOAT_FLAG;
			if(it != opcol.f.end())
				min = *it;
			opcol.f.clear();
			newcol.type= 1;
			newcol.f.push_back(min);
		}
		else
			yyerror(agfunc + " : No such aggregate function");
	}
	else
	{
	 	if( agfunc == "SUM")
		{
			int init = 0; 
			int sum = thrust::reduce(opcol.i.begin(), opcol.i.end(), init, thrust::plus<int>());
			opcol.i.clear();
			newcol.type = 0;
			newcol.i.push_back(sum);
		}
		else if(agfunc == "AVG")
		{
			int init = 0; 
			int sum = thrust::reduce(opcol.i.begin(), opcol.i.end(), init, thrust::plus<int>());
			float isize = (float)opcol.i.size();
			opcol.i.clear();
			newcol.type = 1;
			newcol.f.push_back(sum/isize);
		}
		else if(agfunc == "COUNT")
		{
			int icount = opcol.i.size(); 
			opcol.i.clear();
			newcol.type = 0;
			newcol.i.push_back(icount);
		}else if(agfunc == "MAX")
		{
			int max = *thrust::max_element(opcol.i.begin(),opcol.i.end()); 
			opcol.i.clear();
			newcol.type= 0;
			newcol.i.push_back(max);
		}else if(agfunc == "MIN")
		{
			thrust::sort(opcol.i.begin(),opcol.i.end());
			thrust::device_vector<int>::iterator it;
			it = thrust::upper_bound(opcol.i.begin(),opcol.i.end(),INT_FLAG);
			int min = INT_FLAG;
			if(it != opcol.i.end())
				min = *it;
			opcol.i.clear();
			newcol.type= 0;
			newcol.i.push_back(min);
		}
		else
			yyerror(agfunc + " : No such aggregate function");
	}
	
	t1.erase_column(t1.get_first_column_name());
	t1.row_count = 1;
	t1.copy_column(new_name,newcol);
}

void make_sorted(table &t2, std::string col_order, bool col_present, bool is_desc)
{
	column &order_on1 = t2.get_column(col_order);
	thrust::device_vector<int> new_order(t2.row_count);
	thrust::sequence(new_order.begin(),new_order.end(),0);
	if(order_on1.type)
	{
		if(is_desc)
			thrust::sort_by_key(order_on1.f.begin(),order_on1.f.end(),new_order.begin(),thrust::greater<float>());
		else
			thrust::sort_by_key(order_on1.f.begin(),order_on1.f.end(),new_order.begin());
	}
	else
	{
		if(is_desc)
			thrust::sort_by_key(order_on1.i.begin(),order_on1.i.end(),new_order.begin(),thrust::greater<int>());
		else
			thrust::sort_by_key(order_on1.i.begin(),order_on1.i.end(),new_order.begin());
	}
	
	auto iter_col = t2.columnNames.begin();
	thrust::device_vector<int> temp_i(t2.row_count);
	thrust::device_vector<float> temp_f(t2.row_count);

	while(iter_col != t2.columnNames.end())
	{
		if(*iter_col != col_order)
		{
			column &temp_col = t2.get_column(*iter_col);
			if(temp_col.type)
			{
				thrust::gather(new_order.begin(), new_order.end(), temp_col.f.begin(), temp_f.begin());
				temp_col.f = temp_f;
			}
			else
			{
				thrust::gather(new_order.begin(), new_order.end(), temp_col.i.begin(), temp_i.begin());
				temp_col.i = temp_i;
			}
		}
		iter_col++;
	}
	if(!col_present)
		t2.erase_column(col_order);
}
/*
void validate_columns(table &t3)
{
	assert(t3.size() == t3.columnNames.size());
	for(auto c:t3.columnNames)
	{
		column &col = t3.get_column(c);
		if(col.type)
		{
			if(col.f.size() != t3.row_count)
				if(col.f.size() == 1)
					col.f.resize(t3.row_count,col.f[0]);
				else
					yyerror("Invalid Column elements.");
		}else
		{
			if(col.i.size() != t3.row_count)
				if(col.i.size() == 1)
					col.i.resize(t3.row_count,col.i[0]);
				else
					yyerror("Invalid Column elements.");
		}
	}
}

bool check_keys(table &t)
{
	if(t.size() != 1)
		yyerror("Invalid keys.");
	column &col = t.get_first_column();
	int count = t.row_count;
	if(col.type)
		count -= thrust::count_if(col.f.begin(),col.f.end(),thrust::logical_not<float>());
	else	
		count -= thrust::count_if(col.i.begin(),col.i.end(),thrust::logical_not<int>());
	return (count != 0);
}
*/
table &eval(node *root,table &t)
{
	std::string &name = *(root->name);
	std::string &id = *(root->id);
	if(id == "cmd")
	{
		if(root->size == 1)
		{
			std::cout<<std::endl<<"Logging Out.\n"<<std::endl;
			exit(0);
		}else if(root->size == 2)
		{
			dbpath = *root->child[1]->name;
			if(dbpath == "")
				dbpath = "./";
			std::string cmd = "mkdir -p " + dbpath + "tmp/";
			int i = system(cmd.c_str());
			if(i != 0)
	 		{
				std::cout<<"Unable to create space for temporary table."<<std::endl;
				exit(0);
			}
			cmd = "rm -rf " + dbpath + "tmp/*";
			i = system(cmd.c_str());
			if(i != 0)
	 		{
				std::cout<<"Unable to clear the space for temporary table."<<std::endl;
				exit(0);
			}
			yyerror("Database changed");
		}
		table &t1 = eval(root->child[3],t);
		if(t1.row_count == 0)
			return t1;
		if(root->size > 6)
		{
			table &t2 = eval(root->child[5],t1);
			t1.updatekey(t2);
			if(t1.row_count == 0)
				return t1;
			
			table &t3 = eval(root->child[1],t1);
			
			std::string col_order = t3.get_column_name(*(root->child[7]->child[0]->name));
			bool col_present = true;
			if(t3.columnNames.find(col_order) == t3.columnNames.end())
			{
				table &t4 = eval(root->child[7]->child[0],t1);
				column &order_on = t4.get_first_column();
				t3.copy_column(col_order, order_on);
				col_present = false;
			}
			
			bool is_desc = false;
			if(root->child[7]->child[1])
			{				if(*(root->child[7]->child[1]->name) == "DESC")

		 			is_desc = true;		
			}
			make_sorted(t3,col_order,col_present,is_desc);
			return t3;	
		}
		else if(root->size == 6)
		{
			if(*(root->child[4]->id) == "ORDER_BY")
			{
				table &t2 = eval(root->child[1],t1);
				//validate_columns(t2);
				std::string col_order = t2.get_column_name(*(root->child[5]->child[0]->name));
				bool col_present = true;
				if(t2.columnNames.find(col_order) == t2.columnNames.end())
				{
					table &t3 = eval(root->child[5]->child[0],t1);
					column &order_on = t3.get_first_column();
					t2.copy_column(col_order, order_on);
					col_present = false;
				}
				bool is_desc = false;
				if(root->child[5]->child[1])
				{
					if(*(root->child[5]->child[1]->name) == "DESC")
		 				is_desc = true;		
				}
				make_sorted(t2,col_order,col_present,is_desc);
				return t2;	 	
			}
			else
			{
				table &t2 = eval(root->child[5],t1);
				t1.updatekey(t2);
				if(t1.row_count == 0)
					return t1;
				table &t3 = eval(root->child[1],t1);
				//validate_columns(t3);
				
				//use t2 as key to select rows from table t3

				//apply_result(t3,t2);
				return t3;
			}
		}else
		{
			table &t2 = eval(root->child[1],t1);
			return t2;
		}
	}else if(id == "columns")
	{
		if(root->size == 1)
		{
			table &t1 = eval(root->child[0],t);
			return t1;
		}
		table &t1 = eval(root->child[0],t);
		table &t2 = eval(root->child[2],t);
		if(t1.row_count != t2.row_count)
			yyerror("Aggregated column with nonaggregated colmns. (different number of rows)");
		t1.copy_column(*(root->child[2]->name),t2.get_column(*(root->child[2]->name)));
		
		return t1;
	}else if(id == "column")
	{
		if(*(root->child[0]->name) == "*")
		{
			for(auto col:t.columnNames)
				t.get_column(col);
			return t;
		}
		table &t1 = eval(root->child[0],t);
		if(root->size > 1)
			t1.move_column(*(root->child[0]->name),*(root->child[2]->name));
		return t1;
	}else if(id == "expr")
	{
		if(root->size == 3)
		{
			table &t1 = eval(root->child[0],t);
			table &t2 = eval(root->child[2],t);

			binary_op(t1,t2,*(root->child[1]->id));
			t1.move_column(t1.get_first_column_name(),name);
			return t1;	
		}else if(root->size == 2)
		{
			table &t1 = eval(root->child[1],t);
			unary_op(t1,*(root->child[1]->id));
			t1.move_column(t1.get_first_column_name(),name);
			return t1;
		}else
		{	
			return eval(root->child[0],t);
		}

	}else if(id == "Pexpr")
	{
		if(*(root->child[0]->id) == "aggregate")
		{	
			std::string agfunc = *(root->child[0]->name);
			std::string fname = *(root->name);
			if(root->size == 6)
			{
				if(t.name == *(root->child[2]->name))
				{
					table &t1	= *(new table);
					t1.name = t.name;
					t1.set_column(*(root->child[4]->name),t.get_column(*(root->child[4]->name)));
					aggregate_function(t1,agfunc,fname);
					return t1;
				}else 
				{
					if(t.columnNames.find(name) == t.columnNames.end())
					{
						yyerror(name + ": No such column in " + t.name);
					}else
					{
						table &t1 = *(new table);
						t1.name = t.name;
						t1.set_column(name,t.get_column(name));
						aggregate_function(t1,agfunc,fname);
						return t1;
					}
				}
			}else
			{
				if(*(root->child[2]->id) == "cmd")
				{
					table &t1 = eval(root->child[2],t);
					if(t1.size() == 1)
					{
						std::string cname = t1.get_first_column_name();
						t1.move_column(cname,*root->name);
						aggregate_function(t1,agfunc,fname);
					}
					else
						yyerror("subquery has more than one column");
					return t1;
				}else if(*(root->child[2]->id) == "expr")
				{
					table &t1 = eval(root->child[2],t);
					if(t1.size() == 1)
					{
						std::string cname = t1.get_first_column_name();
						t1.move_column(cname,*root->name);
						aggregate_function(t1,agfunc,fname);
					}
					else
						yyerror("subquery has more than one column");
					return t1;
				}
				else
				{
					if(t.columnNames.find(*(root->child[2]->name)) == t.columnNames.end())
					{
						yyerror("aggregate called on table");
					}else
					{
						table &t1 = *(new table);
						t1.name = t.name;
						t1.set_column(*(root->child[2]->name),t.get_column(*(root->child[2]->name)));
						aggregate_function(t1,agfunc,fname);
						return t1;
					}
				}
			}
		}
		else
		{	
			if(root->size == 3)
			{
				if(*(root->child[1]->id) == ".")
				{
					if(t.name == *(root->child[0]->name))
					{
						table &t1 = *(new table);
						t1.name = t.name;
						t1.set_column(*(root->child[2]->name),t.get_column(*(root->child[2]->name)));
						return t1;
					}else 
					{
						if(t.columnNames.find(name) == t.columnNames.end())
						{
							yyerror(name + ": No such column in " + t.name);
						}else
						{
							table &t1 = *(new table);
							t1.name = t.name;
							t1.set_column(name,t.get_column(name));
							return t1;
						}
					}
				}else
				{
					table &t1 = eval(root->child[1],t);
					t1.move_column(t1.get_first_column_name(),name);
					return t1;
				}
			}else
			{
				if(*(root->child[0]->id) == "integerLit")
				{
					table &t1 = *(new table);
					column col;
					col.type = 0;
					col.i.push_back(atoi(root->child[0]->name->c_str()));
					t1.set_column(*(root->child[0]->name),col);
					return t1;
				}else if(*(root->child[0]->id) == "floatLit")
				{
					table &t1 = *(new table);
					column col;
					col.type = 1;
					col.f.push_back(atof(root->child[0]->name->c_str()));
					t1.set_column(*(root->child[0]->name),col);
					return t1;
				}else
				{
					if(t.columnNames.find(*(root->child[0]->name)) == t.columnNames.end())
					{
						yyerror(*(root->child[0]->name) + " : No such column ");
					}else
					{
						table &t1 = *(new table);
						t1.name = t.name;
						t1.set_column(*(root->child[0]->name),t.get_column(*(root->child[0]->name)));
						return t1;
					}
				}
			}
		}
	}else if(id == "tables")
	{
		if(root->size == 5)
		{
			table &t1 = eval(root->child[0],t);
			table &t2 = eval(root->child[2],t1);
			
			table &t3 = eval(root->child[1],t);
			table &t4 = cross_prod(t1,t2);
			table &t5 = eval(root->child[4],t4);
			eval_join(t4,t5,t1,t2,t3);
			t4.name = name;
			return t4;
		}else if(root->size == 3)
		{
			table &t1 = eval(root->child[0],t);
			table &t2 = eval(root->child[2],t);
			
			table &t3 = eval(root->child[1],t);
			table &t4 = cross_prod(t1,t2);
			t4.name = name;
			return t4;
		}else
		{
			return eval(root->child[0],t);
		}
	}else if(id == "table")
	{
		if(root->size > 3)
		{
			table &t1 = eval(root->child[1],t);
			t1.name = *(root->child[4]->name);
			for(auto cname:t1.columnNames)
	 		{
				column &col = t1.get_column(cname);
				col.tname = t1.name;
			}
			return t1;
		}else if(root->size > 1)
		{
			table &t1 = *(new table(*(root->child[0]->name)));
			t1.name = *(root->child[2]->name);
			return t1;
		}else 
		{
			table &t1 = *(new table(name));
			return t1;
		}
	}else if(id == "join")
	{
		table &t1 = *(new table);
		if(*root->child[0]->id == ",")
		{
			column &col = t1.new_column(",");
			col.type = 0;
			col.i.push_back(1);
			t1.row_count = 1;
		}else if(*root->child[0]->id == "INNER JOIN")
		{
			column &col = t1.new_column("INNER JOIN");
			col.type = 0;
			col.i.push_back(2);
			t1.row_count = 1;
		}else if(*root->child[0]->id == "LEFT OUTER JOIN")
		{
			column &col = t1.new_column("LEFT OUTER JOIN");
			col.type = 0;
			col.i.push_back(3);
			t1.row_count = 1;
		}else if(*root->child[0]->id == "RIGHT OUTER JOIN")
		{
			column &col = t1.new_column("RIGHT OUTER JOIN");
			col.type = 0;
			col.i.push_back(4);
			t1.row_count = 1;
		}else if(*root->child[0]->id == "FULL OUTER JOIN")
		{
			column &col = t1.new_column("FULL OUTER JOIN");
			col.type = 0;
			col.i.push_back(5);
			t1.row_count = 1;
		}else
		{
			column &col = t1.new_column("ERROR TYPE");
			col.type = 0;
			col.i.push_back(0);
			t1.row_count = 1;
		}
		return t1;
	}
	return t;
}