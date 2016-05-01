#### 1) US Start-ups (MySQL) #####

# description
show tables;
select * from Crunchbase limit 15;
select count(*) from Crunchbase;
describe Crunchbase;

# Cleveland, Ohio
select count(distinct name), city
from Crunchbase 
where region = 'Cleveland'
group by city;

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


#### 2) US Public Schools (Oracle Database XE 11g) ####

/* Highest federal revenue of each state with State Name listed */
select stcode, to_char( max(c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13), '999,999,999') as max_fed_rev,
  (select stname 
    from state_t s 
    where s.stcode=f.stcode) stname
from Fedrev_t f
group by stcode order by max_fed_rev desc;

/* School District Name with Highest Fed Revenue */
select stname, a.stcode, to_char( max_fed_rev, '999,999,999') as max_fed_rev, sd_name
from
  (select stcode, max(c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13) as max_fed_rev,
    (select stname 
      from state_t s 
      where s.stcode=f.stcode) stname
   from Fedrev_t f
   group by stcode order by max_fed_rev desc) a,
  
  (select stcode, idcensus as fid, c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13 as tfedrev 
   from fedrev_t) b,
   
   school_t c
   
where a.max_fed_rev=b.tfedrev and fid=c.idcensus
order by max_fed_rev desc;
