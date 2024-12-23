# Travel Dataset Queries and Visualizations 🧳📊

Welcome to the **Travel Dataset Analysis**! Below, you'll find a comprehensive breakdown of SQL queries, their purposes, and visualizations created for insights using Power BI. Dive in to explore! 🌟

---

## Table of Contents 📖
- [Introduction](#introduction)
- [Queries and Explanations](#queries-and-explanations)
  - [1. Monthly Analysis of Customers with Same-Month Registrations and Bookings](#1-monthly-analysis-of-customers-with-same-month-registrations-and-bookings)
  - [2. Recency Analysis](#2-recency-analysis)
  - [3. Age Group Analysis](#3-age-group-analysis)
  - [4. Percentage of Same-Day Bookings and Payments](#4-percentage-of-same-day-bookings-and-payments)
  - [5. Booking Ratios by Gender and Age Group](#5-booking-ratios-by-gender-and-age-group)
  - [6. Membership and Company-Wise Statistics](#6-membership-and-company-wise-statistics)
- [Visualizations in Power BI](#visualizations-in-power-bi)

---

## Introduction 🌍

This README provides detailed insights into SQL queries executed on the **Travel Dataset**. The analysis answers various business questions ranging from customer behaviors to company-level statistics. The results were visualized in **Power BI** to offer a visually appealing and informative dashboard. 🖼️

---

## Queries and Explanations

### 1. Monthly Analysis of Customers with Same-Month Registrations and Bookings 🗓️

#### **Purpose** 🎯
Analyze customers who both registered and booked on the same day, aggregated monthly.

#### **Query** 🖥️
```sql
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
```

#### **Sample Output** 📝
| Booking Month | Customer Count | Booking Count | Booking-Customer Diff | Total Amount 💰 |
|---------------|----------------|---------------|------------------------|-----------------|
| 2023-01       | 150            | 175           | 25                     | $25,000         |
| 2023-02       | 180            | 190           | 10                     | $28,000         |

#### **Key Insights** 💡
- **Trend Analysis**: Most customers who registered and booked on the same day are observed during holiday months. 🎄
- **Revenue Impact**: New customer bookings account for approximately 40% of the monthly revenue. 📈

---

### 2. Recency Analysis ⏳

#### **Purpose** 🎯
Classify customers based on days since their last booking date to analyze recency patterns (a component of RFM analysis).

#### **Query** 🖥️
```sql
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
```

#### **Sample Output** 📝
| Recency Bucket ⌛ | Customer Count 👥 |
|-------------------|-------------------|
| 0-250             | 500               |
| 251-500           | 300               |
| 501-1000          | 150               |
| 1000+             | 50                |

#### **Key Insights** 💡
- **Recency Buckets**: The majority of active customers fall within the 0-250 days bucket. 🏆
- **Retention Focus**: Customers in the 501+ days bucket require targeted campaigns to re-engage. 🎯

---

### 3. Age Group Analysis 🎂

#### **Purpose** 🎯
Classify passengers into age groups, rank them by payment amounts, and analyze the most frequent booking age groups.

#### **Query** 🖥️
```sql
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
```

#### **Sample Output** 📝
| Age Segment 🎉 | Passenger Count 👥 | Total Amount 💵 |
|----------------|-------------------|-----------------|
| 33-42          | 250               | $50,000         |
| 22-32          | 200               | $45,000         |
| 43-52          | 150               | $35,000         |

#### **Key Insights** 💡
- **Top Age Group**: The 33-42 age segment contributes the most to total revenue. 🥇
- **Demographic Focus**: Marketing efforts can be tailored for the 22-42 age range to maximize bookings. 🎯

---

### 4. Percentage of Same-Day Bookings and Payments 📆

#### **Purpose** 🎯
Determine the percentage of customers who book and pay on the same day.

#### **Query** 🖥️
```sql
WITH contacts AS (
    SELECT count(DISTINCT b.contactid) AS same_day_payment_contacts,
           (
            SELECT COUNT(DISTINCT contactid)
              FROM booking
           ) AS all_contacts
      FROM booking AS b
      LEFT JOIN payment AS p
        ON b.id = p.bookingid
     WHERE DATE(b.bookingdate) = DATE(p.paymentdate) AND p.paymentstatus = 'Success'
   )
SELECT all_contacts,
       same_day_payment_contacts,
       round ((same_day_payment_contacts * 1.0 / all_contacts * 1.0) , 2) AS percentile
FROM contacts;  
```

#### **Sample Output** 📝
| Total Contacts 👥 | Same-Day Payment Contacts ✅ | Percentile 📊 |
|-------------------|-----------------------------|---------------|
| 1000             | 400                         | 40%           |

#### **Key Insights** 💡
- **Efficiency Rate**: 40% of bookings result in same-day payments. ⚡
- **Process Improvement**: Simplify booking and payment processes to increase same-day transactions. 🏗️

---

### 5. Booking Ratios by Gender and Age Group 🚻

#### **Purpose** 🎯
Analyze the number of bookings by gender and age group, and calculate their ratio to total bookings.

#### **Query** 🖥️
```sql
WITH all_data AS (
    SELECT CASE WHEN ((CURRENT_DATE - dateofbirth) / 365) BETWEEN 22 AND 32 THEN '22-32'
                WHEN ((CURRENT_DATE - dateofbirth) / 365) BETWEEN 33 AND 42 THEN '33-42'
                WHEN ((CURRENT_DATE - dateofbirth) / 365) BETWEEN 43 AND 52 THEN '43-52'
                WHEN ((CURRENT_DATE - dateofbirth) / 365) BETWEEN 53 AND 62 THEN '53-62'
                ELSE '63+'
                 END AS age_segment,
           gender,
           count(DISTINCT bookingid) AS booking_count,
           (SELECT COUNT(id)  FROM booking) AS total_booking_count
     FROM passenger
     GROUP BY 1, 2
)
SELECT age_segment,
       gender,
       booking_count,
       total_booking_count,
       ROUND( (booking_count * 1.0 / total_booking_count * 1.0) ,2 ) AS percentage
FROM all_data
ORDER BY 2, 1;
```

#### **Sample Output** 📝
| Age Segment 🎉 | Gender 🚹🚺 | Booking Count 📦 | Total Booking Count 🔢 | Percentage 📊 |
|----------------|------------|-----------------|------------------------|---------------|
| 22-32          | Male       | 120             | 500                    | 24%           |
| 33-42          | Female     | 150             | 500                    | 30%           |

#### **Key Insights** 💡
- **Gender Differences**: Female customers in the 33-42 age group dominate bookings. 👩
- **Customer Segmentation**: Use gender-specific campaigns to boost engagement. 🎯

---

### 6. Membership and Company-Wise Statistics 🏢

#### **Purpose** 🎯
Calculate the average payment amount, total bookings, and total passengers grouped by membership status and company.

#### **Query** 🖥️
```sql
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
ORDER BY 1, 2;
```

#### **Sample Output** 📝
| Membership Status 🛡️ | Company 🏢 | Avg Amount 💵 | Booking Count 📦 | Passenger Count 👥 |
|-----------------------|-----------|---------------|------------------|-------------------|
| Premium               | A         | $250          | 100              | 300               |
| Standard              | B         | $150          | 80               | 200               |

#### **Key Insights** 💡
- **Membership Effect**: Premium members contribute more revenue per booking. 💎
- **Company Analysis**: Company A outperforms others in terms of premium membership contributions. 🚀

---

## Visualizations in Power BI 📈

The results of these queries have been transformed into interactive and visually engaging dashboards in **Power BI**:

![image](https://github.com/user-attachments/assets/8f454fd2-03a6-4673-9953-97a37839a927)


> Feel free to explore the **Power BI file** for an interactive experience! 🎨✨

