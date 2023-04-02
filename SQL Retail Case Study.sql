Select * from Customer
Select * From Transactions
Select * from prod_cat_info
--------------------------------------- Data Prep And Understanding -------------------------------------------------------------

--Q1. What is the total numeber of rows in each of the three tables in the dataset?

--Ans1.
Select 'Customer' [Table Name],COUNT(*) [No. of Rows]
From Customer
Union All
Select 'Transactions', Count(*)
From Transactions
Union All
Select 'prod_cat_info' , COUNT(*)
From prod_cat_info


--Q2. What is the total number of transactions that have a return?

--Ans2.
Select Count(transaction_id) [No. of Ruturns]
From Transactions
Where CAST(Total_Amt as numeric) < 0


--Q3. As you would have noticed, the dates provided across the datasets are not in a correct format. As first step,
--    please convert date variables in to valid date formats before proceeding ahead.

--Ans3.
Select Convert(date, DOB,105) [Date]
From Customer
Union All
Select Convert(date, tran_date,105)
From Transactions


--Q4. What is the range of the transaction data available for analysis? show the output in number of days, months and
--    years simultaneously in diffrent columns.

--Ans4.
Select DATEDIFF(DAY,MIN(Convert(Date,Tran_Date,105)), MAX(Convert(Date,Tran_Date,105))) As [Days],
DATEDIFF(MONTH,MIN(Convert(Date,Tran_Date,105)), MAX(Convert(Date,Tran_Date,105))) As [Months],
DATEDIFF(Year,MIN(Convert(Date,Tran_Date,105)), MAX(Convert(Date,Tran_Date,105))) As [Years]
From Transactions


--Q5. Which product category does the sub-category "DIY" belongs to?

--Ans5.
Select prod_cat
From prod_cat_info
Where prod_subcat = 'DIY'

---------------------------------------------------------- Data Analysis-----------------------------------------------------------------

--Q1. Whicht channel is most frequently used for transactions?

--Ans1.
Select Top 1 (Store_type)
From
  (Select Store_type, 
   COUNT(Transaction_id) Transaction_Count 
   From Transactions
   Group by Store_type
   ) As Z
Order by Transaction_Count Desc


--Q2. What is the count of Male and Female customers in the database?

--Ans2.
Select 'Male' [Gender], COUNT(Gender) [Cust_Count]
From Customer
Where Gender = 'M'
Union All 
Select 'Female', COUNT(Gender)
From Customer
Where Gender = 'F'


--Q3. From which city do we have the maximum number of the customers and how many?

--Ans3.
Select Top 1 *
From
     (Select city_code,
     COUNT(Customer_ID) Customer_Count
     From Customer
     Group by city_code
     ) as Z
Order By Customer_Count Desc


--Q4. How many sub-categories are there under Books category?

--Ans4.
Select prod_cat,
COUNT(Prod_Subcat) [No. of Subcat]
From prod_cat_info
Where prod_cat = 'Books'
Group by prod_cat


--Q5. What is the maximum quantity of products ever ordered?

--Ans5.
Select MAX(Qty) Prod_Qty
From Transactions


--Q6. What is the net total revenue generated in categories Books and Electronics?

--Ans6.
Select
SUM(Cast(Total_Amt as numeric)) [Net Total Revenue]
From Transactions
left Join prod_cat_info
On Transactions.prod_cat_code = prod_cat_info.prod_cat_code
                             And
	Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
Where prod_cat in ('Electronics','Books')


--Q7. How many custoemers have >10 transactions with us excluding returns?

--Ans7.
Select COUNT(*) As Cust_Count
From
   (Select cust_id,
    COUNT(Transaction_ID) As Trans_Count
    From Transactions
    Where Cast(total_amt as numeric) > 0
    Group By cust_id
    Having COUNT(Transaction_ID) > 10
) As Z


--Q8. What is the combined revenue earned from the Electronics and Clothing categories, from Flagship stores?

--Ans8.
Select SUM(Cast(Total_amt as Numeric)) [Revenue]
From Transactions
Left Join prod_cat_info
On Transactions.prod_cat_code = prod_cat_info.prod_cat_code
                             And
	Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
Where Store_type = 'Flagship Store' And
prod_cat in ( 'Electronics' , 'Clothing')


--Q9. What is the total revenue from Males customers in Electronics category? Output should display total revenue
--    by prod sub-cat.

--Ans9.
Select prod_subcat,
Sum(Cast(Total_Amt as Numeric)) [Revenue]
From 
	(Select cust_id ,prod_subcat,
    Total_Amt  
	From Transactions 
    Left Join prod_cat_info
    On Transactions.prod_cat_code = prod_cat_info.prod_cat_code
                                 And
    	Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
    Where prod_cat = 'Electronics'
	    ) as Z
Left Join Customer
on Z.cust_id = Customer.customer_Id
Where Gender = 'M'
Group by prod_subcat


--Q10. What is the percentage of sales and returns by product sub category? display only top 5 sub categories in
--     terms of sales.

--Ans10.
Select Top 5
prod_subcat,SUM(Cast(Total_Amt as numeric)) [Total Sales], Sum(Sales)*100 / Sum(Sum(Sales)) Over() Percent_Sales,
Sum(Returns)*100 / Sum(Sum(Returns)) Over() Percent_Return
From 
     (Select prod_subcat, total_amt,
     Case When CAST(Total_Amt as numeric) < 0
          Then Abs(CAST(Total_Amt as numeric))
     	 Else 0
     End [Returns],
	 Case When CAST(Total_Amt as numeric) > 0
          Then Abs(CAST(Total_Amt as numeric))
     	 Else 0
     End [Sales]
     From Transactions
	 Left Join prod_cat_info
     On Transactions.prod_cat_code = prod_cat_info.prod_cat_code
                                 And
    Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
	) as X
Group by prod_subcat
Order by [Total Sales] Desc


--Q11. For all customers aged between 25 to 35 years find what is the total revenue generated by these consumers
--     in last 30 days of transactions from max transaction date available in the data.

--Ans11.
Select SUM(Cast(Total_amt as Numeric)) [Total Revenue]
From
    (Select total_amt 
     From Transactions
     Left Join Customer
     on Transactions.cust_id = Customer.customer_Id
     Where DATEDIFF(YEAR,Convert(Date,DOB,105),GETDATE()) Between 25 and 35
	                             And
          DATEDIFF(Day,Convert(Date,Tran_Date, 105),(Select Max(Convert(Date,Tran_Date,105)) from Transactions))  <=30
) as Z


--Q12. Which product category has seen the max value of returns in last 3 months of transactions?

--Ans12.
Select Top 1 Prod_Cat
From
     (Select prod_cat, Count(Transaction_id) Return_Count
      From Transactions
      Left Join prod_cat_info
      on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
                                    And
      Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
      Where CAST(Total_amt as numeric) < 0
                    And
      	 Datediff(MONTH, Convert(Date,Tran_Date,105),(Select Max(Convert(Date,Tran_Date,105)) from Transactions)) <= 3
      Group by prod_cat
) as Z
Order by Return_Count Desc


--Q13. Which store-type sells maximum products; by value of sales amount and quantity sold?

--Ans13.
Select Top 1 Store_type
From
   (Select Store_type, Sum(Cast(Total_Amt as Numeric)) as [Sales],
    Sum(Cast(Qty as numeric)) as [Quantity]
    From Transactions
    Group by Store_type
   ) As Z 
Order by Sales desc , Quantity Desc


--Q14. What are the categories for which average revenue is above the overall average?

--Ans14.
Select prod_cat
From
   (Select prod_cat , AVG(Cast(Total_Amt as Numeric)) [Category Average]
    From Transactions
    Left Join prod_cat_info
    on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
                                 And
       Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
    Group by prod_cat
   ) as X
Where [Category Average] > (Select AVG(Cast(Total_amt as numeric)) From Transactions)


--Q15. Find the average and total revenue by each sub-category for the categories which are among top 5 categories
--     in terms of quantity sold.

--Ans15
Select y.prod_cat, prod_subcat , [Average Revenue], [Total Revenue]
From
    (Select Top 5 prod_cat , SUM(Cast(Qty as numeric)) Quantity
    From Transactions
    Left Join prod_cat_info
    on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
                                 And
       Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
    Group by prod_cat
    Order by Quantity desc) as X
Inner Join    
    (Select prod_cat, prod_subcat , AVG(Cast(Total_amt as Numeric)) [Average Revenue] , SUM(Cast(Total_amt as Numeric)) [Total Revenue]
    From Transactions
    Left Join prod_cat_info
    on Transactions.prod_cat_code = prod_cat_info.prod_cat_code
                                 And
       Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
    Group by prod_cat, prod_subcat
    ) As Y
on X.prod_cat = y.prod_cat

