
--http://dbaparadise.com/2018/10/who-is-holding-the-lock-on-the-table/
col object for A30
col object_type for A12
col serial# for 999999999
col osuser for A15
col lock_mode for A25
col username for A15

select
   c.owner || '.' ||  c.object_name object,
   c.object_type,
   DECODE(a.locked_mode, 0, NONE
           ,  1, '1 - Null'
           ,  2, '2 - Row Share Lock'
           ,  3, '3 - Row Exclusive Table Lock.'
           ,  4, '4 - Share Table Lock'
           ,  5, '5 - Share Row Exclusive Table Lock.'
           ,  6, '6 - Exclusive Table Lock'
           ,  locked_mode, ltrim(to_char(locked_mode,'990'))) lock_mode,
   b.inst_id as node,
   b.sid,
   b.serial#,
   b.status,
   b.username,
   b.osuser
from
   gv$locked_object a ,
   gv$session b,
   dba_objects c
where b.sid = a.session_id
and   a.object_id = c.object_id
and   a.inst_id=b.inst_id;

--Sample Output

OBJECT        OBJECT_TYPE LOCK_MODE                      node  sid   SERIAL# STATUS   USERNAME OSUSER  
------------- ----------- -----------------------------  ----- ----- ------- -----    -------  --------
HR.EMPLOYEES  TABLE       3 - Row Exclusive Table Lock.     1  397   26193   INACTIVE HRAPP    drobete  
