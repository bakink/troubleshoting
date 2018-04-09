--https://hourim.wordpress.com/2018/03/17/library-cache-lock/
--The ASH of my customer case was showing the following list of predominant wait events:
select event, count(1)
from gv$active_session_history
where
    sample_time between to_date('09032018 00:46:00', 'ddmmyyyy hh24:mi:ss')
                and     to_date('09032018 10:44:00', 'ddmmyyyy hh24:mi:ss')
group by event
order by 2 desc;

--Naturally I wanted to know what sql_id is responsible of these library cache wait events first via ASH

select sql_id, count(1)
from gv$active_session_history
where
    sample_time between to_date('09032018 00:46:00', 'ddmmyyyy hh24:mi:ss')
                and     to_date('09032018 10:44:00', 'ddmmyyyy hh24:mi:ss')
and event in
 ('library cache lock','library cache: mutex X','cursor: pin S wait on X')
group by sql_id
order by 2 desc;

--and then via classical dbms_xplan to get the corresponding execution plan and v$sql to get the SQL text respectively:
select * from table(dbms_xplan.display_cursor('6tcs65pchhp71',null));
select sql_fulltext, executions, end_of_fetch_count
    from gv$sql
    where sql_id = '6tcs65pchhp71';
 
no rows selected

--Let’s summarize: there is a sql_id which is responsible of a dramatic library cache wait event that I am monitoring at real time basis and which

--has no execution plan in memory
--and is not present in gv$sql
--The above two points manifestly are symptoms of a sql query which hasn’t gone beyond the parse phase. 
--In other words it might be a query which Oracle is not able to soft parse and thereby it has never reached the hard parse phase nor the execution step. 
--Hopefully ASH can clearly show this:

select
     in_parse
    ,in_hard_parse
    ,in_sql_execution
    ,count(1)
from gv$active_session_history
where
    sample_time between to_date('09032018 00:46:00', 'ddmmyyyy hh24:mi:ss')
                and     to_date('09032018 10:44:00', 'ddmmyyyy hh24:mi:ss')
and
   sql_id = '6tcs65pchhp71'
group by
     in_parse
    ,in_hard_parse
    ,in_sql_execution
order by 4 desc;
 
I I I   COUNT(1)
- - - ----------
Y N N     162758
Y Y N        385

--indeed this query is almost always in the “parse” phase. So the initial question of what is causing this dramatic library cache lock turned to be : why this query is sticking at the parse phase?
--I don’t know why I decided to look at the dba_hist_sqltext but it made my day:
select sql_text from dba_hist_sqltext where sql_id = '6tcs65pchhp71';
