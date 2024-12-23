--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- <> Welcome back and hello again. 
-- <> This time I will provide the information requested by the relevant departments over the Travel dataset. 
-- <> Thank you for reviewing my queries I prepared while meeting these requests. 
-- <> I would also like to point out that I visualized the results of my queries with Power BI. 
-- <> If you look at the Power BI file after reviewing the codes I used in my queries, 
-- you can see the great graphics that the queries reveal.
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- <1>Analyze the customers who are both members and make reservations in the same month on a monthly basis.
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- <Note>: I would like to show that we can choose one of 3 different methods when analyzing by month.
--------------------------------------------------------------------------------------------------------------

SELECT * FROM booking
WHERE date_trunc('day' , userregisterdate) = date_trunc('day' , bookingdate)
;

SELECT * FROM booking
WHERE userregisterdate::date = bookingdate::date
;

SELECT * FROM booking
WHERE to_char( userregisterdate, 'YYYY-MM-DD') = to_char( bookingdate, 'YYYY-MM-DD') 
;
--------------------------------------------------------------------------------------------------------------

WITH customers AS 
(
	SELECT contactid 
    FROM booking
    WHERE DATE_TRUNC('day', userregisterdate) = DATE_TRUNC('day', bookingdate)
)
SELECT 
    TO_CHAR(b.bookingdate, 'YYYY-MM') AS booking_month,
    COUNT(DISTINCT c.contactid) AS customer_count,
    COUNT(b.id) AS booking_count,
    COUNT(b.id) - COUNT(DISTINCT c.contactid) AS booking_customer_diff,
    SUM(p.amount) AS total_amount
FROM 
    customers AS c 
INNER JOIN booking AS b 
	ON b.contactid = c.contactid
INNER JOIN payment AS p 
	ON b.id = p.bookingid
GROUP BY 1
ORDER BY 1;



--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- <2> Categorize customers according to the days since the last booking date.
-- 0-250, 250-500, 500-1000, 1000+
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- <Note>: Here we can say that we will examine the Recency part of the RFM analysis. 
-- Normally, the analysis should be based on current time, but the data set is a bit old. 
-- To ensure accuracy, I will analyze according to the maximum bookingdate in the data set. 
-- I will also add the analysis according to the Current_Date.
--------------------------------------------------------------------------------------------------------------
-- <2.1> With maximum bookingdate
--------------------------------------------------------------------------------------------------------------
select max(bookingdate)::date from booking
;
-- 2021-05-27


WITH max_date AS (
    SELECT 
        contactid,
        MAX(bookingdate)::date AS max_date
    FROM booking
    GROUP BY 1
)
SELECT 
    COUNT(contactid) AS customer_count,
    CASE 
        WHEN (DATE '2021-05-27' - max_date) BETWEEN 0 AND 250 THEN '0-250'
        WHEN (DATE '2021-05-27' - max_date) BETWEEN 251 AND 500 THEN '251-500'
        WHEN (DATE '2021-05-27' - max_date) BETWEEN 501 AND 1000 THEN '501-1000'
        ELSE '1000+'
    END AS recency
FROM max_date
GROUP BY 2
ORDER BY 2;

--------------------------------------------------------------------------------------------------------------
-- <2.2> With CURRENT_DATE
--------------------------------------------------------------------------------------------------------------

WITH max_date AS (
	SELECT
		contactid,
		MAX(bookingdate)::DATE AS max_date
	FROM booking
	GROUP BY 1
)
SELECT
	COUNT(contactid) AS customer_count,
	CASE
		WHEN (CURRENT_DATE - max_date) >= 0 AND (CURRENT_DATE - max_date) <= 250 THEN '0-250'
		WHEN (CURRENT_DATE - max_date) > 250 AND (CURRENT_DATE - max_date) <= 500 THEN '250-500'
		WHEN (CURRENT_DATE - max_date) > 500 AND (CURRENT_DATE - max_date) <= 1000 THEN '500-1000'
		WHEN (CURRENT_DATE - max_date) > 1000 THEN '1000+'
	END AS recency
FROM
	max_date
GROUP BY 2;



------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- <3> Classify the passengers according to their age and rank them from the highest to the lowest payment amount.
-- <3> In which age group of passengers are most make reservations?
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- We can choose one of 2 different ways to select the age group.
------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT id AS passenger_id, 
(current_date - dateofbirth)/365 as age, -- First Way
EXTRACT ( YEAR FROM (AGE (current_date , dateofbirth ) )) as age_ -- Second Way
FROM passenger
;
------------------------------------------------------------------------------------------------------------------

SELECT 
	CASE 
		WHEN ((CURRENT_DATE - dateofbirth)/365) BETWEEN 22 AND 32 THEN '22-32'
		WHEN ((CURRENT_DATE - dateofbirth)/365) BETWEEN 33 AND 42 THEN '33-42'
		WHEN ((CURRENT_DATE - dateofbirth)/365) BETWEEN 43 AND 52 THEN '43-52'
		WHEN ((CURRENT_DATE - dateofbirth)/365) BETWEEN 53 AND 62 THEN '53-62'
	ELSE '63+' END AS age_segment,
	COUNT(p.id) AS passenger_count,
	SUM(amount) AS total_amount
FROM passenger AS p
JOIN payment AS py
	ON py.bookingid = p.bookingid
GROUP BY 1 
ORDER BY 3 DESC;



------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- <4> What percentage of total customers are customers whose payment day and booking day are on the same day?
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

WITH contacts AS (
        SELECT count(DISTINCT b.contactid) AS same_day_payment_contacts,
               (
                SELECT COUNT(DISTINCT contactid)
                  FROM booking
               ) AS all_contacts
          FROM booking AS b
          LEFT JOIN payment AS p
            ON b.id = p.bookingid
         WHERE DATE(b.bookingdate) = DATE(p.paymentdate) AND p.paymentstatus = 'ÇekimBaşarılı'
       ) 
SELECT all_contacts,
       same_day_payment_contacts,
       round ((same_day_payment_contacts * 1.0 / all_contacts * 1.0) , 2) AS percentile
FROM contacts  
  
  

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- <5> Calculate the number of bookings by gender and age group and the ratio of these bookings to all bookings.
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

WITH all_data AS (
        SELECT CASE WHEN ((CURRENT_DATE - dateofbirth) / 365) BETWEEN 22 AND 32 THEN '22-32'
                    WHEN ((CURRENT_DATE - dateofbirth) / 365) BETWEEN 33 AND 42 THEN '33-42'
                    WHEN ((CURRENT_DATE - dateofbirth) / 365) BETWEEN 43 AND 52 THEN '43-52'
                    WHEN ((CURRENT_DATE - dateofbirth) / 365) BETWEEN 53 AND 62 THEN '53-62'
                    WHEN ((CURRENT_DATE - dateofbirth) / 365) BETWEEN 63 AND 72 THEN '63-72'
                    ELSE '73+'
                     END AS age_segment,
               gender,
               count(DISTINCT bookingid) AS booking_count,
               (SELECT COUNT(id)  FROM booking) AS total_booking_count
         FROM passenger
         GROUP BY 1, 2
         ORDER BY 2, 1
       )
SELECT age_segment,
       gender,
       booking_count,
       total_booking_count,
       ROUND( (booking_count * 1.0 / total_booking_count * 1.0) ,2 ) AS percentage
FROM all_data
ORDER BY 2, 1
	



------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- <6> Calculate: 
-- - Average payment amount, 
-- - Number of bookings,
-- - Total number of passengers 
-- by membership status and company.
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

SELECT membersales,
       company,
       ROUND(AVG(py.amount),2) AS avg_amount,
       COUNT(DISTINCT b.id) AS booking_count,
       COUNT(DISTINCT p.id) AS passenger_count
FROM booking AS b
LEFT JOIN passenger AS p
	ON b.id = p.bookingid
LEFT JOIN payment AS py
	ON b.id = py.bookingid
GROUP BY 1, 2
ORDER BY 1, 2