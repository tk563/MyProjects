#################### 1) Subscription #########################

select year(a.payment_date) || '-' || month(a.payment_date) as yr_mo, sum(a.payment_amount)
from payments as a inner join subscriptions as b
on a.subscription_id=b.subscription_id
where b.subscription_typ = 2
group by yr_mo;

select a.student_id, a.username, count(b.practice_date) as daycount
from students a inner join student_practice_days b
on a.student_id=b.student_id
where a.subscription_id = 12345 and month(b.practice_date) = (select max(month(b.practice_date)) from student_practice_days) 
group by a.student_id, a.username
order by daycount desc limit 10; 

create table students2 as
select a.*, b.practice_date
from students a, 
(
	select 
	student_id, 
	count(distinct practice_date) as uniq_days,
	case when uniq_days >= 30 then 1 else 0 end as keep_indicator
	from student_practice_days
	where practice_date between (select curdate() - interval 90 day as min_dt) and curdate()
	group by student_id
) b
where a.student_id=b.student_id;

select b.*, b.uniq_days/a.num_stuents_allowed as utilization
from subscriptions a inner join students2 b
on a.subscription_id=b.subscription_id
where keep_indicator = 1;


#################### 2) Company funding #########################

# description
show tables;
select * from Crunchbase limit 15;
select count(*) from Crunchbase;
describe Crunchbase;

# Number of occurrences per market
select market, count(name) as num_occur 
from Crunchbase
where market <> ''
group by market
order by num_occur desc limit 25;

# top 25~50 highest funded w/ status oeprating/acquired 
# temporary table gets deleted when the current client session terminates.
set @rank = 0;

create temporary table top_funded as 
(
select name, funding_total_usd, @rank:=@rank+1 as row_num
from Crunchbase
where status in ('acquired','operating')
order by funding_total_usd desc
);

select * from top_funded limit 5;
select * from Crunchbase order by funding_total_usd desc;
select * from Crunchbase where name in ('Verizon Communicatins', 'Clearwire', 'Charter Communications');

select * 
from top_funded
where row_num between 25 and 50;

# 10 oldest, currently operating
select name, founded_year
from Crunchbase
where status = 'operating' and founded_year < 2000 and founded_year <> ''
order by founded_year limit 10;

# Top 25 markets in CA and NY, operating
select market, sum(funding_total_usd) as total_funding
from Crunchbase
where state_code in ('NY','CA') and status = 'operating' and market <> ''
group by market 
order by total_funding desc limit 25;

# Top 10 markets by funding, number of start-ups per market
select market, count(distinct name), funding_total_usd as tot_funding
from Crunchbase
where founded_year between 2010 and 2014
group by market
order by tot_funding desc limit 10;


#################### 3) School Funding #########################

/* Highest federal revenue of each state with State Name listed */
select stcode, to_char( max(c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13), '999,999,999') as max_fed_rev,
  (select stname 
    from state_t s 
    where s.stcode=f.stcode) stname
from Fedrev_t f
group by stcode 
order by max_fed_rev desc;

/* School District Name with Highest Fed Revenue */
select stname, a.stcode, to_char( max_fed_rev, '999,999,999') as max_fed_rev, sd_name
from
  (select stcode, max(c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13) as max_fed_rev,
    (select stname 
      from state_t s 
      where s.stcode=f.stcode) stname
   from Fedrev_t f
   group by stcode o
   order by max_fed_rev desc) a,
  
  (select stcode, idcensus as fid, c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13 as tfedrev 
   from fedrev_t) b,
   
   school_t c
   
where a.max_fed_rev=b.tfedrev and fid=c.idcensus
order by max_fed_rev desc;
