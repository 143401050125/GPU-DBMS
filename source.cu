#include "header.h"

cudaEvent_t start, stop;
float et;
jmp_buf env_buffer;
std::string dbpath;
int tmp_table;
bool print_tables;
int tmp_table_limit;
std::set<table *> all_table;

column::column()
{
  type = -1;
  tname = "";
}

table::table(std::string nn)
{
  all_table.insert(this);
  name = nn;
  original_name = nn;
  flag = false;
  umap.clear();
  row_count = -1;
  if(nn != "")
  {
    std::ifstream f;
    std::string table_name = dbpath + original_name + ".txt";
    f.open(table_name);
    if(!f.is_open())
    {
      yyerror(name + " : No such table2 ");
    }
    std::string cur_word, meta;
    int num_rows;
    int num_cols;
    f >> num_rows;
    f >> num_cols;
    row_count = num_rows;
    getline(f,meta);
    f.close();
    std::stringstream s(meta);
    while(num_cols--)
    {
        s >> cur_word;
        columnNames.insert(cur_word);
        s >> cur_word;
        s >> cur_word;
    }	
  }
}
std::string table::get_column_name(std::string colname)
{
  size_t found = colname.find_first_of(".");
  std::string tname = colname.substr(0,found);
  std::string cname = colname.substr(found+1);
  if(found != std::string::npos && tname == name)
    colname = cname;
  return colname;
}
column& table::get_column(std::string col)
{
  col = this->get_column_name(col);
  if(umap.find(col) != umap.end())
    return umap[col];
      
  if(original_name == "")
    yyerror(col + " : Column not found.");
  
  std::ifstream f;
  std::string table_name = dbpath + original_name + ".txt";
  f.open(table_name);
  
  if(!f.is_open())
    yyerror(name + " : No such table3 ");
  
  std::string cur_word, col_type;
  int get_num, num_rows, num_cols, offset_of_col, is_present;
  bool flag = false;
  f >> num_rows;
  f >> num_cols;
  while(num_cols--)
  {
    f >> cur_word;
    if(cur_word == col)
      {
        f >> col_type;
        f >> offset_of_col;
        flag = true;
        break;
      }
    else
    {
        f >> cur_word;
        f >> get_num;
    }
  }
  if(flag)
  {
      column &newCol = umap[col];
      newCol.tname = name;
      f.seekg(offset_of_col,std::ios::beg);
      f >> is_present;
      if(is_present)
        f >> newCol.tname;
      int row_iter = 0;
      if(col_type == "int")
      {
          newCol.type = 0;
          thrust::host_vector<int> h(num_rows);
          while(row_iter < num_rows)
          {
            f >> h[row_iter++];
          }
          newCol.i = h;
      }
      else
      {
          newCol.type = 1;
          thrust::host_vector<float> h(num_rows);
          while(row_iter < num_rows)
          {
            f >> h[row_iter++];
          }
          newCol.f = h;
      }
  }
  else
  {
    {
      std::cout<<"column of " + original_name <<std::endl;
      for(auto c:columnNames)
        std::cout<<c<<" ";
      std::cout<<std::endl;
    }
    yyerror(col + " : No such column found in database -- '" + name + "' ---- " + original_name);
  }
  f.close();
  
  if(key.size() != 0)
  {
    column &col_ = umap[col];
    if(col_.type)
    {
      thrust::device_vector<float>::iterator it_end;
      it_end = thrust::remove_if(col_.f.begin(),col_.f.end(),key.begin(),thrust::logical_not<bool>());
      col_.f.resize(it_end - col_.f.begin());
    }else
    {
      thrust::device_vector<int>::iterator it_end;
      it_end = thrust::remove_if(col_.i.begin(),col_.i.end(),key.begin(),thrust::logical_not<bool>());
      col_.i.resize(it_end - col_.i.begin());
    }
  }
  return umap[col];
}

void table::set_column(std::string colname,column &col)
{
  colname = this->get_column_name(colname);
  umap[colname] = col;
  if(col.type)
    row_count = col.f.size();
  else
    row_count = col.i.size();
  columnNames.insert(colname);
}

void table::print(std::vector<std::string> &col_order,int row_limit)
{
  std::cout<<std::endl;
  class col{
    public:
      int type;
      thrust::host_vector<int> i;
      thrust::host_vector<float> f;
  };
  std::unordered_map<std::string,col>::iterator it;
  std::unordered_map<std::string,col> umap;
 
  if(col_order.size() == 0)
  {
    for(auto cname:columnNames)
      col_order.push_back(cname);
  }
 
  for(auto &p: this->umap)
  {
    umap[p.first].type = p.second.type;
    if(p.second.type)
      umap[p.first].f = p.second.f;
    else
      umap[p.first].i = p.second.i;
  }
  
  int tot_row = row_count;
  
  cudaEventRecord(stop);
  cudaEventSynchronize(stop);
  cudaEventElapsedTime(&et, start, stop);

  if(tot_row == 0)
  {
    std::cout<<"Empty set in "<<et/1000<<" seconds."<<std::endl;
    return;
  }
  
  TextTable t( '-', '|', '+' );
  for(auto cname : col_order)
    t.add(cname);
  t.endOfRow();
  int row_max = tot_row;
  if(row_limit != -1 && row_limit < row_max)
      row_max = row_limit;
  if(print_tables)
  {
    for(int cur_row = 0; cur_row < row_max; cur_row++)
    {	
      for(auto cname:col_order)
      {
        col &c = umap[this->get_column_name(cname)];
        if(c.type)
          t.add( (c.f[cur_row] != FLOAT_FLAG) ? std::to_string(c.f[cur_row]) : "NULL");
        else
          t.add( (c.i[cur_row] != INT_FLAG) ? std::to_string(c.i[cur_row]) : "NULL");
      }
      t.endOfRow();
    }
    t.setAlignment( 2, TextTable::Alignment::LEFT );
    std::cout << t;
  } 
  std::cout<<tot_row<< " rows in "<<et/1000<<" seconds."<<std::endl;
}

int table::size()
{
  return umap.size();
}

column& table::get_first_column()
{
  if(umap.size() == 0)
    yyerror("Table is empty.");
  return umap.begin()->second;
}

std::string table::get_first_column_name()
{
  if(umap.size() == 0)
    yyerror("Table is empty.");
  return umap.begin()->first;
}
column& table::new_column(std::string cname)
{
  cname = this->get_column_name(cname);
  if(columnNames.find(cname) != columnNames.end() || umap.find(cname) != umap.end())
    yyerror(cname + " : Column already exist");
  columnNames.insert(cname);
  return umap[cname];
}

void table::erase_column(std::string cname)
{
  cname = this->get_column_name(cname);
  if(columnNames.find(cname) == columnNames.end() && umap.find(cname) == umap.end())
    yyerror(cname + " : No such Column to erase");
  columnNames.erase(cname);
  umap.erase(cname);
}

void table::print_column()
{
  std::cout<<"Column of '"<<name<<"' :"<<std::endl;
  for(auto p:umap)
    std::cout<<p.first<<" ";
  std::cout<<std::endl;
}

void table::updatekey(table &t1)
{
  if(t1.size() != 1)
    yyerror("Invalid Opeartion : key is not present");
  column &col = t1.get_first_column();
  if(col.type)
  {
    key.resize(col.f.size());
    thrust::transform(col.f.begin(),col.f.end(),key.begin(),[=] __device__ __host__  (float &f) { return (f==0) ? false : true;});
  }
  else
  {
    key.resize(col.i.size());
    thrust::transform(col.i.begin(),col.i.end(),key.begin(),[=] __device__ __host__ (int &i) { return (i==0) ? false : true;});
  }
  
  row_count = thrust::count_if(key.begin(),key.end(),thrust::identity<bool>());
  //applying key on loaded columns 
  for(auto &p:umap)
  {
    column &col = p.second;
    if(col.type)
    {
      thrust::device_vector<float>::iterator it_end;
      it_end = thrust::remove_if(col.f.begin(),col.f.end(),key.begin(),thrust::logical_not<bool>());
      col.f.resize(it_end - col.f.begin());
    }
    else
    {
      thrust::device_vector<int>::iterator it_end;
      it_end = thrust::remove_if(col.i.begin(),col.i.end(),key.begin(),thrust::logical_not<bool>());
      col.i.resize(it_end - col.i.begin());
    }
  }
}

void table::move_column(std::string cname1,std::string cname2)
{
  cname1 = this->get_column_name(cname1);
  cname2 = this->get_column_name(cname2);
  umap[cname2] = std::move(umap[cname1]);
  umap.erase(cname1);
  /*auto nodeHandler = umap.extract(cname1);
  nodeHandler.key() = cname2;
  umap.insert(std::move(nodeHandler));*/
  columnNames.erase(cname1);
  columnNames.insert(cname2);
}

void table::copy_column(std::string cname,column &col)
{
  cname = this->get_column_name(cname);
  umap[cname] = std::move(col);
  columnNames.insert(cname);
}

void table::write_metadata(std::string tname,int nrows, int ncols)
{
  if(tname != "")
    original_name = tname;
  //write information related to table 
  //-------useless-----write meta data using use column names from s1 and s2;
  std::ofstream f;
  std::string table_name_cur = dbpath + tname + ".txt";
  f.open(table_name_cur);
  if(!f.is_open())
  {
    yyerror(name + " : Unable to write temporaray table");
  }
  std::string to_writ, cur_wrd;
  to_writ = std::to_string(nrows) + " " + std::to_string(ncols);
  rjust(to_writ,999);
  to_writ += "\n";
  f << to_writ;
  f.close();
}

void table::write_column(std::string cname)
{
  //write metadata and values 
  //of this->get_column(cname) in to file
  column &tcol = this->get_column(cname);
  std::ifstream f;
  std::string table_name = "./" + original_name + ".txt";
  f.open(table_name);
  if(!f.is_open())
  {
    yyerror(name + " : No such table to write column ");
  }
  std::string to_add, meta;
  int nrows,ncols;
  f >> nrows;
  f >> ncols;
  getline(f,meta);
  f.close();
  
  to_add = " "+cname;
  if(tcol.type)
    to_add += " float ";
  else
    to_add += " int ";
  std::string fin_col = "", ele_str;
  fin_col = "1 ";
  rjust(fin_col,12);
  ele_str = tcol.tname;
  fin_col += (ele_str + " ");

  if(tcol.type)
  {
      thrust::host_vector<float> f = tcol.f;
      tcol.f.clear();
      for(int c_it = 0;c_it < nrows;c_it++)
      {
        ele_str = std::to_string(f[c_it]);
        rjust(ele_str,12);
        if(c_it == (nrows-1))
          fin_col += ele_str + "\n";
        else
          fin_col += ele_str + " ";
      }
  }
  else
  {
      thrust::host_vector<int> i = tcol.i;
      tcol.i.clear();
      for(int c_it = 0;c_it < nrows;c_it++)
      {
        ele_str = std::to_string(i[c_it]);
        rjust(ele_str,12);
        if(c_it == (nrows-1))
          fin_col += ele_str + "\n";
        else
          fin_col += ele_str + " ";
      }
  }
  std::ofstream fot;
  fot.open(table_name,std::ios::in | std::ios::out);
  fot.seekp(0,std::ios::end);
  int last = fot.tellp();
  to_add += std::to_string(last);
  to_add += "\n"; 
  std::string fin_meta = std::to_string(nrows) + " " + std::to_string(ncols+1) + " " + meta + to_add;
  rjust(fin_meta,1000);
  fot << fin_col;
  fot.seekp(0,std::ios::beg);
  fot << fin_meta;
  fot.close();
  umap.erase(cname);	//dont erase cname from this->columnNames 
}

void table::write(std::string tname = "")
{
  this->write_metadata(tname);
  for(auto cname:this->columnNames)
    this->write_column(cname);
}

void table::clear()
{
  columnNames.clear();
  for(auto &p:umap)
    p.second.i.clear(),p.second.f.clear();
  umap.clear();
}