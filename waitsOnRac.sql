Select * from (
select inst_id,event,count(*) cnt from gv$session
group by inst_id,event order by 3 desc
)
pivot ( sum(cnt) for inst_id in (1,2,3,4 )
) order by 1 desc;
