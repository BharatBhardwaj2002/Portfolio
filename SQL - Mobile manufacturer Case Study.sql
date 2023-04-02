--SQL Mobile manufacturer Case Study

--Q1. List all the states in which we have customers who have bought cellphones from 2005 till today. 

--Q1--BEGIN 
Select Distinct State
From Fact_Transactions
Left Join DIM_LOCATION
on FACT_TRANSACTIONS.IDLocation = DIM_LOCATION.IDLocation
Where YEAR(Date) Between 2005 and Year(GETDATE())

--Q1--END

--Q2. What state in the US is buying the most 'Samsung' cell phones?

--Q2--BEGIN
Select Top 1
State,
SUM(Quantity) as Tot_Qty
From
  (Select IDLocation, Quantity 
  From
	 (Select FACT_TRANSACTIONS.IDModel,
	 IDLocation, IDManufacturer , Quantity
     From FACT_TRANSACTIONS
     Left Join DIM_MODEL
     on FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
     ) as Z
  Left Join DIM_MANUFACTURER
  on Z.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
  Where Manufacturer_Name = 'Samsung'
  ) As X
Left Join DIM_LOCATION
on X.IDLocation = DIM_LOCATION.IDLocation
Where Country = 'US'
Group by State
Order by Tot_Qty Desc

--Q2--END

--Q3. Show the number of transactions for each model per zip code per state.

--Q3--BEGIN
Select State, ZipCode, Model_Name,
[Trans Count]
From
    (Select State, ZipCode,
    IDModel, COUNT(IDModel) [Trans Count]
    From FACT_TRANSACTIONS
    Left Join DIM_LOCATION
    On FACT_TRANSACTIONS.IDLocation = DIM_LOCATION.IDLocation
    Group by State, ZipCode, IDModel
    ) as Z
Left Join DIM_MODEL
On Z.IDModel = DIM_MODEL.IDModel

--Q3--END

--Q4. Show the cheapest cellphone (Output should contain the price also)

--Q4--BEGIN
Select Model_Name, Unit_price
From DIM_MODEL
Where Unit_price = (Select MIN(Unit_Price) From DIM_MODEL) 

--Q4--END

--Q5. Find out the average price for each model in the top5 manufacturers in terms of sales quantity
--    and order by average price.

--Q5--BEGIN
Select Z.IDManufacturer, IDModel, AVG(Unit_price) Avg_Price
From
    (Select Top 5 IDManufacturer,
	 SUM(Quantity) Tot_Quantity
     From FACT_TRANSACTIONS
     Right Join DIM_MODEL
     On FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
     Group by IDManufacturer
	 Order by Tot_Quantity Desc
	 ) Z
Left Join DIM_MODEL
on Z.IDManufacturer = DIM_MODEL.IDManufacturer
Group by Z.IDManufacturer, IDModel
Order by Avg_Price

--Q5--END

--Q6. List the names of the customers and the average amount spent in 2009, where the average is
--    higher than 500

--Q6--BEGIN
Select Customer_Name, AVG(TotalPrice) Avg_Spent
From FACT_TRANSACTIONS
Left Join DIM_CUSTOMER
On FACT_TRANSACTIONS.IDCustomer = DIM_CUSTOMER.IDCustomer
Where YEAR(date) = 2009
Group by Customer_Name
Having AVG(TotalPrice) > 500

--Q6--END
	
--Q7. List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008
--    , 2009 and 2010 

--Q7--BEGIN  
Select  IDModel
From
   (Select Top 5 
   IDModel, SUM(Quantity) [Qty]
   From FACT_TRANSACTIONS
   Where Year(Date) = 2008
   Group by IDModel
   Order by Qty Desc
) As X
Intersect
Select IDModel
From
   (Select Top 5  
   IDModel, SUM(Quantity) [Qty]
   From FACT_TRANSACTIONS
   Where Year(Date) = 2009
   Group by IDModel
   Order by Qty Desc
) As Y
Intersect
Select IDModel
From
   (Select Top 5 
   IDModel, SUM(Quantity) [Qty]
   From FACT_TRANSACTIONS
   Where Year(Date) = 2010
   Group by IDModel
   Order by Qty Desc
) As Z

--Q7--END	

--Q8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with 
--    the 2nd top sales in the year of 2010.

--Q8--BEGIN
Select '2009' [Year], IDManufacturer
From 
   (Select IDManufacturer, SUM(TotalPrice) Sales,
    Rank() Over(Order by SUM(TotalPrice) Desc) [Rank]
    From FACT_TRANSACTIONS
    left Join DIM_MODEL
    On FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
    Where YEAR(Date) = 2009
    Group by IDManufacturer
	) As Y
Where Rank = 2
Union
Select '2010' [Year], IDManufacturer
From 
   (Select IDManufacturer, SUM(TotalPrice) Sales,
    Rank() Over(Order by SUM(TotalPrice) Desc) [Rank]
    From FACT_TRANSACTIONS
    left Join DIM_MODEL
    On FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
    Where YEAR(Date) = 2010
    Group by IDManufacturer
	) As Y
Where Rank = 2

--Q8--END

--Q9. Show the manufacturers that sold cellphones in 2010 but did not in 2009.

--Q9--BEGIN
Select IDManufacturer
From FACT_TRANSACTIONS
Left Join DIM_MODEL
On FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
Where YEAR(Date) = 2010
Except
Select IDManufacturer
From FACT_TRANSACTIONS
Left Join DIM_MODEL
On FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
Where YEAR(Date) = 2009

--Q9--END

--Q10. Find top 100 customers and their average spend, average quantity by each year. Also find
--     the percentage of change in their spend.

--Q10--BEGIN
Select IDCustomer, Years, Avg_Spend,
Avg_Qty, (Avg_Spend - Prev) / Prev * 100 as Percent_Change
From 
     (Select X.IDCustomer, Y.Years,
      Y.Avg_Spend, Y.Avg_Qty, LAG(Y.Avg_Spend, 1) Over(Partition by X.IDCustomer order by X.IDCustomer asc , Years Asc) Prev
      From
          (Select Top 10 IDCustomer, AVG(TotalPrice) Avg_Spend
           From FACT_TRANSACTIONS
           Group by IDCustomer
      	 Order by Avg_Spend Desc
      	) As X
      Left Join 
          (Select IDCustomer, Year(Date) Years,
           AVG(TotalPrice)  Avg_Spend,
           AVG(Quantity)  Avg_Qty
           From FACT_TRANSACTIONS
           Group  by IDCustomer, Year(Date)
      	 ) As Y
      on X.IDCustomer = Y.IDCustomer
) as Z


--Q10--END
	