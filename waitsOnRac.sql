Select * from (
select inst_id,event,count(*) cnt from gv$session
group by inst_id,event order by 3 desc
)
pivot ( sum(cnt) for inst_id in (1,2,3,4 )
) order by 1 desc;

------
select inst_id,
       session_state,
       event,
       wait_class,
       count(*),
       round(RATIO_TO_REPORT(count(*)) OVER() * 100, 2) AS PCTTOT
  from gv$active_session_history
 group by inst_id,session_state, event, wait_class
 order by inst_id,count(*) desc --fetch first 7 rows only
/
