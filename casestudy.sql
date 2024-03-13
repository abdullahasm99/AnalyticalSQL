-----------------------------------Q1-----------------------------------
--1
select customer_id, total_quantity,total_spent, quantity_per_customer_rank
from (select customer_id, sum(quantity) total_quantity, sum(price*quantity) total_spent, rank() over(order by sum(quantity) desc) quantity_per_customer_rank from tableretail group by customer_id );

--2
select stockcode, total_quan,quantity_per_stock_rank
from (select stockcode, sum(quantity) total_quan, rank() over(order by sum(quantity)desc) quantity_per_stock_rank from tableretail group by stockcode );

--3
select stockcode, total_quantity, total_amount, spent_on_stock_rank
from (select stockcode, sum(quantity) total_quantity, sum(price*quantity) total_amount, rank() over(order by sum(price*quantity)desc) spent_on_stock_rank from tableretail group by stockcode );

--4
select years, total_amount, rank 
from(select extract (year from to_date(substr(invoicedate,0,9),'mm/dd/yyyy')) years,  sum(price*quantity) total_amount, rank() over (order by sum(price*quantity)desc) rank from tableretail group by extract (year from to_date(substr(invoicedate,0,9),'mm/dd/yyyy')));

--5
select customer_id, first_purchase, last_purchase
from (select customer_id, first_value(to_date(substr(invoicedate,0,9), 'mm/dd/yyyy')) over(partition by customer_id order by to_date(substr(invoicedate,0,9), 'mm/dd/yyyy')) first_purchase, 
                                      last_value(to_date(substr(invoicedate,0,9), 'mm/dd/yyyy')) over(partition by customer_id order by to_date(substr(invoicedate,0,9), 'mm/dd/yyyy') rows between unbounded preceding and unbounded following ) last_purchase from tableretail)
group by customer_id, first_purchase, last_purchase
order by customer_id;

-----------------------------------Q2-----------------------------------
select fin.*, case 
when ( r_score=5 and (fm_score=5 or fm_score =4))  or  ( r_score=4 and fm_score=5) then 'Champions'
when  ( r_score=3 and (fm_score=5 or fm_score =4)) or ( r_score=4 and r_score=4) or ( r_score=5 and fm_score=3) then 'Loyal Customers'
when   ( r_score=4 and (fm_score=2 OR fm_score =3)) or  ( r_score=3 and r_score=3) or ( r_score=5 and fm_score=2) then 'Potential Loyalists'
when  (FM_SCORE=1 and ( r_score=3 or r_score=4)) then 'Promising'
when ( r_score=5 and fm_score =1) then 'Recent Customers'
when ( r_score=3 and fm_score =2) or  ( r_score=2 and (fm_score=3 or fm_score =2)) then 'Customers Needing Attention'
when ( r_score=2 and (fm_score=5 or fm_score =4)) or ( r_score=1 and fm_score =3) then 'At Risk'
when r_score=1 and (fm_score=4 or fm_score =5) then 'Cant Lose Them'
when r_score=1 and fm_score =2 then 'Hibernating'
when r_score= 1 and fm_score =1 then 'Lost'
else 'UNKOWN' 
end as cust_segment
from (
select customer_id, recency, frequency, monetary, ntile (5) over(order by recency desc) r_score, ntile(5) over(order by avg) fm_score from(
select customer_id, recency, frequency, monetary, (frequency+monetary)/2 avg
from(
select customer_id, recency, count(distinct invoice) frequency, sum(price*quantity) monetary
from (select customer_id, invoice, price, quantity, (to_date('12/9/2011','MM/DD/YYYY') - last_value (to_date(substr(invoicedate,0,9),'MM/DD/YYYY')) over (partition by customer_id order by to_date(substr(invoicedate,0,9),'MM/DD/YYYY') rows between unbounded preceding and unbounded following)) recency from tableretail)
group by customer_id, recency)
group by customer_id, recency, frequency, monetary)) fin
order by recency, frequency desc,monetary desc;

-----------------------------------Q3-----------------------------------
--1
with cons_days as (select cust_id, row_number() over(partition by cust_id, cons_days order by calendar_dt) cons
from (select cust_id, calendar_dt, calendar_dt - row_number() over (partition by cust_id order by calendar_dt) cons_days
from customers))
select cust_id, max(cons) consecutive_days
from cons_days
group by cust_id;


--2
with TransactionAvg as(
select cust_id, min(row_num) frist_250_or_more
from(select cust_id, calendar_dt, cumm_amount, row_number() over (partition by cust_id order by calendar_dt) row_num
from(select cust_id, calendar_dt, sum(amt_le) over(partition by cust_id order by calendar_dt) cumm_amount from customers))
where cumm_amount >= 250
group by cust_id)
select avg(frist_250_or_more) avg_transactions
from TransactionAvg;