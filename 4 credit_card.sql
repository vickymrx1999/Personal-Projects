-- Create master table

CREATE TABLE Master_Table AS
SELECT a.Cust_ID, a.Approved_Limit, b.Age, b.First_NA, b.Last_NA, b.Email_Addr, b.Province, d.Last_Contact_DT,
		e.CASL_Cards, f.Acct_ID, f.Balance, f.Acct_Type_ID,  g.Acct_Type_NA, c.cust_id as do_not_contact
FROM input_from_bu a
LEFT JOIN customer b
ON a.cust_id=b.cust_id
LEFT JOIN last_contact d
ON a.cust_id=d.cust_id
LEFT JOIN casl_cards e
ON a.cust_id=e.cust_id
LEFT JOIN cust_acct f
ON a.cust_id=f.cust_id
LEFT JOIN acct_type g
ON f.acct_type_id=g.acct_type_id
LEFT JOIN do_not_contact c
ON a.cust_id=c.cust_id;


-- General Requirement

-- Clients must be over 18+ years old.
-- Clients in Quebec (province) will not be targeted.
-- Clients in Do-Not-Contact list need to be scrubbed from all marketing activities.

CREATE TABLE General_Cust AS
SELECT *
FROM master_table
WHERE age>=18
AND province != 'QC'
AND cust_id not in (select distinct cust_id from do_not_contact);


-- Campaign Specific

-- Clients with existing Platinum Card will be excluded.
-- Clients must have a total asset balance of $10,000 from savings, chequing and investment.
-- Clients haven’t been contacted in the last 3 months prior to the campaign launch date 
-- May 1st , 2022 - last contact date earlier than Feb 1st , 2022.

CREATE TABLE Campaign_Specific AS
SELECT distinct gen.Cust_ID, First_NA, Last_NA, Email_Addr, CASL_Cards, Approved_Limit, sum_bal.ttl_balance, sum_bal.Last_Contact_DT
FROM General_Cust gen
JOIN 
	(SELECT Cust_ID, max(Last_Contact_DT) as Last_Contact_DT,
			SUM(CASE WHEN Acct_Type_ID in (9345,2579,9770) THEN balance ELSE 0 END) as ttl_balance
	FROM General_Cust
	GROUP BY 1
	HAVING SUM(CASE WHEN Acct_Type_ID in (9345,2579,9770) THEN balance ELSE 0 END)>=10000
    -- Acct_Type_NA in ('Savings', 'Chequing', 'Direct Investing')
    AND max(Last_Contact_DT) < '2022-02-01') sum_bal
ON gen.cust_id=sum_bal.cust_id
WHERE gen.cust_id not in (select cust_id from general_cust where Acct_Type_NA = 'Premium Credit Card');


-- Channel Eligibility

-- Exclude clients who have unsubscribed from our marketing communication.
-- Clients must have a valid Email Address.

CREATE TABLE Contact_History AS
SELECT distinct Cust_ID, First_NA, Last_NA, Email_Addr, CASL_Cards, Approved_Limit
FROM Campaign_Specific
WHERE Email_Addr is not null and (CASL_Cards is null or CASL_Cards = 'Y');









