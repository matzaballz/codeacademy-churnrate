{\rtf1\ansi\ansicpg1252\cocoartf1561\cocoasubrtf600
{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww10800\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0  --1. Get familiar with the company\
 --What segments of users exist\
 /*\
 SELECT *\
 FROM subscriptions\
 LIMIT 100;\
 */\
 SELECT DISTINCT segment AS 'Segments'\
 FROM subscriptions;\
 --Result is '87' and '30'\
 \
 --2. Determine the range of months to calculate churn from\
 SELECT MIN(subscription_start) AS 'Beginning Range',\
 				MAX(subscription_start) AS 'End Range'\
 FROM subscriptions;\
 --Result 12/01/2016 to 3/30/2017\
\
--3. Calculating Churn Rate--\
WITH months AS \
	(SELECT --January 2017\
   		'2017-01-01' AS first_day,\
   		'2017-01-31' AS last_day\
   UNION\
      SELECT --February 2017\
   					'2017-02-01' AS first_day,\
   					'2017-02-28' AS last_day\
   UNION\
      SELECT -- March 2017\
   					'2017-03-01' AS first_day,\
   					'2017-03-31' AS last_day\
  ),\
 --4. cross_join table--\
  cross_join AS (\
  	SELECT *\
    FROM subscriptions\
    CROSS JOIN months\
  ),\
  --5. status table--\
  status AS (\
  SELECT id,\
    first_day AS month,\
    CASE\
    	WHEN (subscription_start < first_day)\
    		AND(\
        	subscription_end > first_day\
          OR subscription_end IS NULL) \
    		AND segment = '30' THEN 1\
    		ELSE 0\
    	END AS is_active_30,\
    CASE\
    	WHEN (subscription_start < first_day)\
    		AND(\
        	subscription_end > first_day\
          OR subscription_end IS NULL\
          ) \
    		AND segment = '87' THEN 1\
    	ELSE 0\
    END AS is_active_87,\
  --6. Add is_canceled status --\
  CASE  \
   WHEN (subscription_end BETWEEN first_day AND last_day) \
    	AND segment = '87' THEN 1\
    ELSE 0\
    END AS is_canceled_87,\
  CASE  \
   WHEN (subscription_end BETWEEN first_day AND last_day) \
    	AND segment = '30' THEN 1\
    ELSE 0\
  	END AS is_canceled_30\
FROM cross_join\
        ),\
--7. Status aggregate table--\
status_aggregate AS (\
SELECT month,\
  SUM(is_active_87) AS sum_active_87,\
  SUM(is_active_30) AS sum_active_30,\
  SUM(is_canceled_87) AS sum_canceled_87,\
  SUM(is_canceled_30) AS sum_canceled_30\
FROM status\
GROUP BY month\
)\
\
--8. Calculating Churn Rate --\
SELECT month,\
			ROUND(1.0* sum_canceled_87 / sum_active_87,2) AS churn_rate_87,\
			ROUND(1.0 * sum_canceled_30 / sum_active_30,2) AS churn_rate_30\
FROM status_aggregate;}