/* The code below was utilized to check again the cardinality of relationships between SCHOOL to FEDREV, STREV, LOCREV respectively.
The result "no rows selected" implies that there are no instances of Idcensus that do not exist in both tables. */
select * from fedrev_t where idcensus NOT IN (select idcensus from school_t);
select * from strev_t where idcensus NOT IN (select idcensus from school_t);
select * from locrev_t where idcensus NOT IN (select idcensus from school_t);

/* Find districts that received more than $1 Billion */
select idcensus, stcode, c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13 as tfedrev
from Fedrev_t
where c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13 > 1000000;

select idcensus, stcode, c01+c04+c05+c06+c07+c08+c09+c10+c11+c12+c13+c24+c35+c38+c39 as tstrev
from Strev_t
where c01+c04+c05+c06+c07+c08+c09+c10+c11+c12+c13+c24+c35+c38+c39 > 1000000;

select idcensus, stcode, t02+t06+t09+t15+t40+t99+d11+d23+a07+a08+a09+a11+a13+a15+a20+a40+u11+u22+u30+u50+u97 as tlocrev
from Locrev_t
where t02+t06+t09+t15+t40+t99+d11+d23+a07+a08+a09+a11+a13+a15+a20+a40+u11+u22+u30+u50+u97 > 1000000;

/* State with the highest number of school districts */
select *
from 
  (select stcode, to_char( count(stcode), '999,999') as count
  from Fedrev_t
  group by stcode order by count desc)
where rownum=1;

/* Highest federal, state, and local revenues for each state */
select stcode, to_char( max(c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13), '999,999,999') as max_fed_rev
from Fedrev_t
group by stcode order by stcode;

select stcode, to_char( max(c01+c04+c05+c06+c07+c08+c09+c10+c11+c12+c13+c24+c35+c38+c39), '999,999,999') as max_st_rev
from Strev_t
group by stcode order by stcode;

select stcode, to_char( max(t02+t06+t09+t15+t40+t99+d11+d23+a07+a08+a09+a11+a13+a15+a20+a40+u11+u22+u30+u50+u97), '999,999,999') as max_loc_rev
from locrev_t
group by stcode order by stcode;

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

/* Create a View from three tables */
create view Total_Rev_v as
select f.idcensus, f.stcode, 
       c14+c15+c16+c17+c18+c19+b11+c20+c25+c36+b10+b12+b13 as tfedrev,
       c01+c04+c05+c06+c07+c08+c09+c10+c11+c12+c13+c24+c35+c38+c39 as tstrev,
       t02+t06+t09+t15+t40+t99+d11+d23+a07+a08+a09+a11+a13+a15+a20+a40+u11+u22+u30+u50+u97 as tlocrev
from fedrev_t f,strev_t s, locrev_t l
where f.idcensus=s.idcensus and f.idcensus=l.idcensus and s.idcensus=l.idcensus;

/* Top 5 states with highest revenues per Federal, State, and Local */
select stname, to_char( fed_rev_total, '999,999,999') as fed_rev_total
from state_t stName,
    (select stcode, sum(tfedrev) as fed_rev_total 
     from total_rev_v 
     group by stcode order by fed_rev_total desc) tView
where tView.stcode=stName.stcode and rownum<=5;

select stname, to_char( st_rev_total, '999,999,999') as st_rev_total
from state_t stName,
    (select stcode, sum(tstrev) as st_rev_total 
     from total_rev_v 
     group by stcode order by st_rev_total desc) tView
where tView.stcode=stName.stcode and rownum<=5;

select stname, to_char( loc_rev_total, '999,999,999') as loc_rev_total
from state_t stName,
    (select stcode, sum(tlocrev) as loc_rev_total 
     from total_rev_v 
     group by stcode order by loc_rev_total desc) tView
where tView.stcode=stName.stcode and rownum<=5;

/* Total Revenue in descending order with each school district name included */
select *
from
(select tView.stcode, stname, sd_name, to_char( Total_revenue, '999,999,999') as Total_revenue
from state_t stName, 
     (select idcensus, stcode, tfedrev+tstrev+tlocrev as Total_revenue
      from total_rev_v) tView, 
     school_t sd
where stName.stcode=tView.stcode and tView.idcensus=sd.idcensus
order by Total_revenue desc)
where rownum<=100;