
================= ase.sql =================
- file: ase.sql
- author: weejar (anbob.com)
-- Desc. To Display all sessions of not "inactive"

set pages 1000 lines 200
col username for a10 
col machine for a10 
col program for a14 trunc 
col event for a20 trunc 
col sqltext for a30 
col sql_id for a20 
col  wai_secinwait for a10 
col bs for a10 
select his.username, his.sid, his.vent, his.machine, his.program, his.status, his.last_call_and,   
sql.hash_value,   ses.sql_id,wait_time||':'||SECONDS_IN_WAIT wai_secinwait , 
blocking_instance||':'||blocking_session bs,substr(sql.sql_text,1,30) sqltext,sql_child_number ch# 
  from    v$session ses left join    v$sql sql 
  on    ses.sql_hash_value = sql.hash_value and  
   ses.sql_child_number=sql.child_number  where  ses.type = 'USER'
   and ses.status<>'INACTIVE'    -- and sql_text like 'select t.subsid,s.servnumber,t%'  
     order by SECONDS_IN_WAIT,last_call_et,4; 
 select  sysdate current_time from dual; 
