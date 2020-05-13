'''
RUN as $python3 generate_dataset.py n, where n is the number of rows  
This code will generate a database with tables card,account,loan,order,trans,disp,district,client
The column names of each of the table is present as a list from line 50 below
The values are randomly generated
'''
import pandas as pd
import numpy as np
import sys

def write_to_file(account_df):
  fname = get_df_name(account_df).split('_')[0]
  fil = open(fname + ".txt",'w')
  row = account_df.shape[0]
  col = account_df.shape[1]
  mp = account_df.dtypes
  metadata = "" + str(row) + " " + str(col) + " "
  cc = 0
  for dat in account_df.columns:
    metadata += dat + " " +dtype_parse(mp[dat]) +" "+str(1000 + cc*(row +1)*12) + " "
    cc += 1
  metadata = metadata[:-1]
  metadata += '\n'
  fil.write(metadata.rjust(1000))
  for dat in account_df.columns:
    cur_col = "0 "
    cur_col = cur_col.rjust(12)
    for i in range(row):
      cur_col += str(account_df[dat][i]).rjust(11) + " "
    cur_col = cur_col[:-1]
    cur_col += '\n'
    fil.write(cur_col)
  fil.close()
  
  
def dtype_parse(dtp):
  if(dtp == 'int64' or dtp == 'int32' or dtp == 'int'):
    return 'int'
  else:
    return 'float'
def get_df_name(df):
    name =[x for x in globals() if globals()[x] is df][0]
    return name


if(len(sys.argv) != 2):
	print("Enter total rows as command line argument, exiting")
  sys.exit()	
row_size = int(sys.argv[1])

column_names = {}    
column_names["account_df"] = ["account_id","account_district_id","statement_freq","date"] 
column_names["card_df"] = ["card_id","disp_id","type","issued"]
column_names["disp_df"] = ["disp_id","client_id","account_id","disp_type"]
column_names["district_df"] = ["district_id","num_inhabitants","num_munipalities_gt499", "num_munipalities_500to1999", "num_munipalities_2000to9999", "num_munipalities_gt10000","num_cities" ,"ratio_urban","average_salary","unemp_rate95","unemp_rate96","num_entrep_per1000","num_crimes95","num_crimes96"]
column_names["loan_df"] = ["loan_id","account_id","date","loan_amount","loan_duration","monthly_loan_payment","loan_status"]
column_names["order_df"] = ["order_id","account_id","order_bank_to","order_account_to","order_amount","order_k_symbol"]
column_names["client_df"] = ["client_id","district_id","client_age","client_gender"]
column_names["trans_df"] = ["trans_id","account_id","date","trans_amount","balance_after_trans","trans_bank_partner","trans_account_partner","trans_type","trans_operation","trans_k_symbol"]   

card_df = pd.DataFrame(np.random.randint(0,row_size,size=(row_size, len(column_names["card_df"]))), columns = column_names["card_df"])
account_df = pd.DataFrame(np.random.randint(0,row_size,size=(row_size, len(column_names["account_df"]))), columns = column_names["account_df"])
disp_df = pd.DataFrame(np.random.randint(0,row_size,size=(row_size, len(column_names["disp_df"]))), columns = column_names["disp_df"])
district_df = pd.DataFrame(np.random.randint(0,row_size,size=(row_size, len(column_names["district_df"]))), columns = column_names["district_df"])
loan_df = pd.DataFrame(np.random.randint(0,row_size,size=(row_size, len(column_names["loan_df"]))), columns = column_names["loan_df"])
order_df = pd.DataFrame(np.random.randint(0,row_size,size=(row_size, len(column_names["order_df"]))), columns = column_names["order_df"])
client_df = pd.DataFrame(np.random.randint(0,row_size,size=(row_size, len(column_names["client_df"]))), columns = column_names["client_df"])
trans_df = pd.DataFrame(np.random.randint(0,row_size,size=(row_size, len(column_names["trans_df"]))), columns = column_names["trans_df"])

district_df = district_df.astype({"ratio_urban" :float,"unemp_rate95": float,"unemp_rate96": float})
loan_df = loan_df.astype({"monthly_loan_payment":float})
order_df = order_df.astype({"order_amount":float})
trans_df = trans_df.astype({"trans_amount":float, "balance_after_trans":float,"trans_account_partner":float})

write_to_file(card_df)
write_to_file(client_df)
write_to_file(account_df)
write_to_file(district_df)
write_to_file(loan_df)
write_to_file(order_df)
write_to_file(trans_df)
write_to_file(disp_df)
