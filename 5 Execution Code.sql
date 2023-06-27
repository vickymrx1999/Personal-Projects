-- Below campaign requirements need to be applied and hold 20% for control.
-- General
-- Clients must be over 18+ years old.
-- Clients in QC will not be targeted.
-- Clients in Do-Not-Contact list need to be scrubbed from all marketing activities.
-- Campaign Specific
-- Clients with existing Premium Card will be excluded.
-- Clients must have a total balance of $10,000.
-- Clients haven¡¯t been contacted in the last 3 months.
-- Channel Eligibility
-- Exclude clients who have unsubscribed from our marketing communication.
-- Clients must have valid Email Address.


-- Create master table

create table Input_Cust_Info as
select
a.Cust_ID,
a.Approved_Limit,
b.Age,
b.First_NA,
b.Last_NA,
b.Email_Addr,
b.Province,
c.Last_Contact_DT,
d.CASL_Cards,
e.Acct_ID,
e.Balance,
e.Acct_Type_ID,
f.Acct_Type_NA
from Input_from_BU a
left join Customer b
on a.Cust_ID = b.Cust_ID
left join Last_Contact c
on a.Cust_ID = c.Cust_ID
left join CASL_Cards d
on a.Cust_ID = d.Cust_ID
left join Cust_Acct e
on a.Cust_ID = e.Cust_ID
left join Acct_Type f
on e.Acct_Type_ID = f.Acct_Type_ID
order by a.Cust_ID;


-- Apply general scrub
-- Clients must be over 18+ years old.
-- Clients in QC will not be targeted.
-- Clients in Do-Not-Contact list need to be scrubbed from all marketing activities.

create table Cust_General_Scrub as
select
Cust_ID,
Approved_Limit,
Age,
First_NA,
Last_NA,
Email_Addr,
Province,
Last_Contact_DT,
CASL_Cards,
Acct_ID,
Balance,
Acct_Type_ID,
Acct_Type_NA
from Input_Cust_Info
where age >= 18 -- Clients must be over 18+ years old.
and province <> 'QC' -- Clients in QC will not be targeted.
and cust_id not in (select distinct cust_id from Do_Not_Contact);
-- Clients in Do-Not-Contact list need to be scrubbed from all marketing activities.



-- Apply campaign scrub
-- Clients with existing Premium Card will be excluded.
-- Clients must have a total balance of $10,000.
-- Clients haven't been contacted in the last 3 months.

create table Cust_Campgn_Scrub AS
select
distinct a.Cust_ID,
a.Approved_Limit,
a.First_NA,
a.Last_NA,
a.Email_Addr,
a.CASL_Cards,
b.Recent_Contact_DT,
b.Ttl_Bal
from Cust_General_Scrub a
inner join 
(select cust_id,
max(Last_Contact_DT) as Recent_Contact_DT,
sum(case when Acct_Type_ID in (9345,2579,9770) then Balance else 0 end) as Ttl_Bal
from Cust_General_Scrub	c
group by Cust_ID
having sum(case when Acct_Type_ID in (9345,2579,9770) then Balance else 0 end) >= 10000 -- Clients must have a total balance of $10,000.
and max(Last_Contact_DT) < '2022-02-01' -- Clients haven't been contacted in the last 3 months.
) b
on a.cust_id = b.cust_id
where a.cust_id not in (select cust_id from Cust_General_Scrub where Acct_Type_NA = 'Premium Credit Card')
-- where  Acct_Type_NA <> 'Premium Credit Card'
-- exclude clients with existing Premium Card will be excluded.
;



-- Apply channel eligibility
-- Exclude clients who have unsubscribed from our marketing communication.
-- Clients must have valid Email Address.

create table Contact_History AS
select Cust_ID,
Approved_Limit,
First_NA,
Last_Na,
Email_Addr,
CASL_Cards
from Cust_Campgn_Scrub
where Email_Addr is not null -- Email Address not blank
and (CASL_Cards is null or CASL_Cards = 'Y') -- Exclude unsubscribers
;

