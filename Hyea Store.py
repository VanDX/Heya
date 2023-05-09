#!/usr/bin/env python
# coding: utf-8

# In[52]:


import pandas as pd
sale_log = pd.read_excel('D:\PBI\saleduck.xlsx')
product_log = pd.read_excel('D:\PBI\produck.xlsx')
customer_log = pd.read_excel('D:\PBI\customer_duck.xlsx')


# In[54]:


#Kiểm tra kiểu dữ liệu 
sale_log.info()
product_log.info()
customer_log.info()
#kiểm tra dữ liệu thiếu 
sale_log.isna().any()
product_log.isna().any()
customer_log.isna().any()


# In[55]:


#Kiểm tra dữ liệu trùng lặp
sale_dup = ['Customer ID','Product ID','Created At']
sale_log_dup = sale_log.duplicated(sale_dup, keep = False)
sale_log_dup_rows = sale_log[sale_log_dup]
sale_log_dup_rows

product_dup = product_log.duplicated(['Product Name','Category'], keep = False)
produc_dup_rows = product_log[product_dup]
produc_dup_rows

customer_dup = customer_log.duplicated(['Customer City','Customer Name','Customer State'], keep = False)
customer_dup_rows = customer_log[customer_dup]
customer_dup_rows


# In[56]:


#Kiểm tra giá trị ngày giờ
import datetime as dt
today = dt.date.today()
sale_log['Created At_date'] = sale_log['Created At'].dt.date
assert sale_log['Created At_date'].max() < today
#Kiểm tra tính hợp lệ của dữ liệu ngày giờ
sale_log['Created At'] = pd.to_datetime(sale_log['Created At'],infer_datetime_format = True,errors = 'coerce')
sale_log['Created At'].isna()


# In[57]:


# làm tròn dữ liệu
sale_log[['Gross Sales','Discount','Tax','Net Sales']] = sale_log[['Gross Sales','Discount','Tax','Net Sales']].round(3)


# In[58]:


#Loại bỏ khoảng trắng thừa
product_log['Product Name'] = product_log['Product Name'].str.strip()
product_log['Category'] = product_log['Category'].str.strip()
#Viết hoa chữ cái đầu mỗi từ
product_log['Product Name'] = product_log['Product Name'].str.title()
product_log['Category'] = product_log['Category'].str.capitalize()
product_log
#loại bỏ kí tự đặc biệt, phát hiện các lỗi, có số và kí tự đặc biệt trong dữ liệu
product_log['Category'] = product_log['Category'].str.replace('\W', '', regex=True)
product_log['Category'] = product_log['Category'].str.replace('0','o')
product_log['Category'] = product_log['Category'].str.replace('Gadgget','Gadget')
product_log['Category'] = product_log['Category'].str.replace('Doohickey7','Doohickey')
product_log['Category'].unique()
product_log['Product Name_check'] = product_log['Product Name'].str.replace(' ','')
check = product_log['Product Name_check'].str.isalpha()
product_log[check == False]
product_log['Product Name'] = product_log['Product Name'].str.replace('@','')
del product_log['Product Name_check']
product_log


# In[59]:


#Loại bỏ khoảng trắng thừa
customer_log['Customer City'] = customer_log['Customer City'].str.strip()
customer_log['Customer Name'] = customer_log['Customer Name'].str.strip()
customer_log['Customer State'] = customer_log['Customer State'].str.strip()
customer_log['Customer Source'] = customer_log['Customer Source'].str.strip()
#Viết hoa chữ các đầu, riêng cột state viết caplocks
customer_log['Customer Name'] = customer_log['Customer Name'].str.title()
customer_log['Customer City'] = customer_log['Customer City'].str.title()
customer_log['Customer Source'] = customer_log['Customer Source'].str.title()
customer_log['Customer State'] = customer_log['Customer State'].str.upper()


# In[60]:


#loại bỏ kí tự đặc biệt, phát hiện các lỗi, có số và kí tự đặc biệt trong dữ liệu
customer_log['Customer Name check'] = customer_log['Customer Name'].str.replace(' ','')
check = customer_log['Customer Name check'].str.isalpha()
customer_log[check == False]
customer_log['Customer Name'] = customer_log['Customer Name'].str.replace('!|@','',regex = True)
customer_log['Customer Name'] = customer_log['Customer Name'].str.replace('Abb0Tt','Abbott')
del customer_log['Customer Name check']

customer_log['Customer City check'] = customer_log['Customer City'].str.replace(' ','')
check = customer_log['Customer City check'].str.isalpha()
customer_log[check == False]
del customer_log['Customer City check']

customer_log['Customer State check'] = customer_log['Customer State'].str.replace(' ','')
check = customer_log['Customer State check'].str.isalpha()
customer_log[check == False]
del customer_log['Customer State check']

customer_log['Customer Source'].value_counts()
customer_log['Customer Source'] = customer_log['Customer Source'].str.replace('Fb','Facebook')
customer_log['Customer Source'] = customer_log['Customer Source'].str.replace('Gg','Google')
customer_log['Customer Source'] = customer_log['Customer Source'].str.replace('Twiter','Twitter')


# In[61]:


#xuất file
sale_log.to_excel('sale_log.xlsx', index = False)
product_log.to_excel('product_log.xlsx', index = False)
customer_log.to_excel('customer_log.xlsx', index = False)


# In[62]:


sale_log.to_excel('hyea_store.xlsx', index = False)
product_log.to_excel('hyea_store.xlsx', index = False)


# In[ ]:




