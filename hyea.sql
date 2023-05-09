
--Phát hiện các dòng thiếu dữ liệu. Sử dụng view để hiển thị các dữ liệu đầy đủ
Create view sale_view 
as
select * from sale where quantity <> 0
select * from sale_view
--Doanh thu sau thuế của cửa hàng qua các năm
with sale_year as
(
	select *
		, year([Created At]) as year
	from sale_view
)

select year
	, [Created At]
	, sum([net sales]) over(partition by year order by year) as Total
from sale_year

---Doanh thu của cửa hàng qua các tháng mỗi năm
with sale_month as
(
	select *
		, month([Created At]) as month
		, year([Created At]) as year
	from sale_view
)

select year
	, month
	, [Created At]
	, sum([net sales]) over(partition by year,month order by month) as Total
from sale_month

-- Doanh thu theo sản phẩm qua các tháng mỗi năm
with sale_month as
(
	select *
		, month([Created At]) as month
		, year([Created At]) as year
	from sale_view
)
select distinct year
	 , month
	 , a.[Product ID]
	 , [Product Name]
	 , Category
	 , sum(quantity) over(partition by year,month,a.[Product ID] order by a.[Product ID]) as Total_quantity
	 , sum([Net Sales]) over(partition by year,month,a.[Product ID] order by a.[Product ID]) as [Total Net Sale]
from sale_month a join dbo.product b
on a.[Product ID] = b.[Product ID]
order by 1,2,6 desc
--Top 20% sản phẩm bán chạy nhất qua các năm
with sale_month as
(
	select *
		 , year([Created At]) as year 
		 ,month([Created At]) as month
	from sale_view
)

, product_year as
(
	select year
		  , month
		 , a.[Product ID]
		 , [Product Name]
		 , Category
		 , sum([Net Sales]) over(partition by year,month,a.[Product ID] order by a.[Product ID]) as [Total Net Sale]
	from sale_month as a  join dbo.product b
on a.[Product ID] = b.[Product ID]
)
,  product_total_sale_dist as
(
	select  distinct * from product_year
)
, product_sale_rank as
(
	select	 *
		   , percent_rank() over(partition by year,month order by [total net sale] ) as total_net_sale_rank
	from product_total_sale_dist 
)
select * 
	, case when total_net_sale_rank > 0.8 then 'Best Seller'
	       when total_net_sale_rank between 0.5 and 0.8 then 'Good'
	       when total_net_sale_rank between 0 and 0.5 then 'Slowest'
           else 'NaN' end
	   as product_rank
from product_sale_rank

--Tỷ trọng đóng góp vào doanh thu của các kênh bán hàng
with sale_source as
(
	select a.[Sales ID]
		, year([Created At]) as year
		,month([Created At]) as month
		, a.[Created At]
		, a.[Net Sales]
		, a.[Customer ID]
		, b.[Customer Source]
	from sale_view a join customer b on a.[Customer ID] = b.[Customer ID]
)
, sale_distribute as
(
	select year
		  , month
		  , [Customer Source]
		  , sum([Net Sales]) over(partition by year,month, [Customer Source] order by [Customer Source]) as Total
	from sale_source
)
select distinct * from sale_distribute 
order by 1,3 desc
--số lượng khách hàng mới qua mỗi tháng
with customer_first_order as
(
	select 
		   a.[Customer ID]
		  , [Customer Name]
		  , min([Created At]) over(partition by a.[Customer ID] order by a.[Customer ID]) as first_order_date
	from sale_view a join customer b 
	on a.[Customer ID] = b.[Customer ID]
)
select distinct *
			   , month(first_order_date) as month
			   , year(first_order_date) as year
from customer_first_order
order by year, month, [Customer ID]
--Mô hình RFM
with rfm_metric as
(
	select [Customer ID]
		  ,datediff(day, convert(date,max([Created At])),convert(date,getdate())) as recency
		  ,count(distinct([Sales ID])) as frequent
		  , sum([Net Sales]) as monetary
	from sale_view where convert(date,[Created At]) > convert(date,getdate() - 365) 
	group by [Customer ID]
)
, rfm_rank as
(
	select *
		  , round(percent_rank() over(order by frequent),3) as frequent_rank
		 , round(percent_rank() over(order by monetary),3) as monetary_rank
	from rfm_metric
)
, rfm_percent_rank as
(
	select *
		  , case when recency between 0 and 100 then 1
				 when recency between 100 and 200 then 2
				 when recency between 200 and 365 then 3
				 else 0 end
			as recency_percent_rank
		  , case when frequent_rank between 0.8 and 1 then 1
				 when frequent_rank between 0.5 and 0.8 then 2
				 when frequent_rank between 0 and 0.5 then 3
				 else 0 end
			as frequent_percent_rank
		  , case when monetary_rank between 0.8 and 1 then 1
				 when monetary_rank between 0.5 and 0.8 then 2
				 when monetary_rank between 0 and 0.5 then 3
				 else 0 end
			as monetary_percent_rank
	from rfm_rank
)
, class_customer as
(
	select * 
		  , case when  recency_percent_rank = 1 and frequent_percent_rank = 1 and monetary_percent_rank = 1 then 'Diamond'
				 when recency_percent_rank = 1 and frequent_percent_rank = 1 and monetary_percent_rank = 2 then 'Diamond'
				 when recency_percent_rank = 1 and frequent_percent_rank = 1 and monetary_percent_rank = 3 then 'Platinum'
				 when recency_percent_rank = 1 and frequent_percent_rank = 2 and monetary_percent_rank = 1 then 'Diamond'
				 when recency_percent_rank = 1 and frequent_percent_rank = 2 and monetary_percent_rank = 2 then 'Platinum'
				 when recency_percent_rank = 1 and frequent_percent_rank = 2 and monetary_percent_rank = 3 then 'Gold'
				 when recency_percent_rank = 1 and frequent_percent_rank = 3 and monetary_percent_rank = 1 then 'Platinum'
				 when recency_percent_rank = 1 and frequent_percent_rank = 3 and monetary_percent_rank = 2 then 'Gold'
				 when recency_percent_rank = 1 and frequent_percent_rank = 3 and monetary_percent_rank = 3 then 'Silver'

				 when  recency_percent_rank = 2 and frequent_percent_rank = 1 and monetary_percent_rank = 1 then 'Platinum'
				 when recency_percent_rank = 2 and frequent_percent_rank = 1 and monetary_percent_rank = 2 then 'Platinum'
				 when recency_percent_rank = 2 and frequent_percent_rank = 1 and monetary_percent_rank = 3 then 'Gold'
				 when recency_percent_rank = 2 and frequent_percent_rank = 2 and monetary_percent_rank = 1 then 'Platinum'
				 when recency_percent_rank = 2 and frequent_percent_rank = 2 and monetary_percent_rank = 2 then 'Gold'
				 when recency_percent_rank = 2 and frequent_percent_rank = 2 and monetary_percent_rank = 3 then 'Silver'
				 when recency_percent_rank = 2 and frequent_percent_rank = 3 and monetary_percent_rank = 1 then 'Gold'
				 when recency_percent_rank = 2 and frequent_percent_rank = 3 and monetary_percent_rank = 2 then 'Silver'
				 when recency_percent_rank = 2 and frequent_percent_rank = 3 and monetary_percent_rank = 3 then 'Bronze'

				 when  recency_percent_rank = 3 and frequent_percent_rank = 1 and monetary_percent_rank = 1 then 'Gold'
				 when recency_percent_rank = 3 and frequent_percent_rank = 1 and monetary_percent_rank = 2 then 'Gold'
				 when recency_percent_rank = 3 and frequent_percent_rank = 1 and monetary_percent_rank = 3 then 'Silver'
				 when recency_percent_rank = 3 and frequent_percent_rank = 2 and monetary_percent_rank = 1 then 'Gold'
				 when recency_percent_rank = 3 and frequent_percent_rank = 2 and monetary_percent_rank = 2 then 'Silver'
				 when recency_percent_rank = 3 and frequent_percent_rank = 2 and monetary_percent_rank = 3 then 'Bronze'
				 when recency_percent_rank = 3 and frequent_percent_rank = 3 and monetary_percent_rank = 1 then 'Silver'
				 when recency_percent_rank = 3 and frequent_percent_rank = 3 and monetary_percent_rank = 2 then 'Bronze'
				 when recency_percent_rank = 3 and frequent_percent_rank = 3 and monetary_percent_rank = 3 then 'Member'
				 else 'out' end
			as Class
	from rfm_percent_rank
)
select a.[Customer ID]
	   ,[Customer Name]
	   , Class
from class_customer a join customer b 
on a.[Customer ID] = b.[Customer ID]
order by class 
----Top 20% sản phẩm có lượng bán ra cao nhất
with sale_month as
(
	select *
		 , year([Created At]) as year 
		 ,month([Created At]) as month
	from sale_view
)

, product_year as
(
	select year
		  , month
		 , a.[Product ID]
		 , [Product Name]
		 , Category
		 , sum(Quantity) over(partition by year,month,a.[Product ID] order by a.[Product ID]) as total_quantity
		 , sum([Net Sales]) over(partition by year,month,a.[Product ID] order by a.[Product ID]) as [Total Net Sale]
	from sale_month as a  join dbo.product b
on a.[Product ID] = b.[Product ID]
)
,  product_total_sale_dist as
(
	select  distinct * from product_year
)
, product_sale_rank as
(
	select	 *
		   , percent_rank() over(partition by year,month order by total_quantity ) as quantity_rank
	from product_total_sale_dist 
)
select * 
	, case when quantity_rank > 0.8 then 'Best Seller'
	       when quantity_rank between 0.5 and 0.8 then 'Good'
	       when quantity_rank between 0 and 0.5 then 'Slowest'
           else 'NaN' end
	   as product_rank
from product_sale_rank
