
SELECT s.username,
       s.sid,
       s.serial#,
       t.used_ublk,
       t.used_urec,
       rs.segment_name,
       r.rssize,
       r.status
FROM   v$transaction t,
       v$session s,
       v$rollstat r,
       dba_rollback_segs rs
WHERE  s.saddr = t.ses_addr
AND    t.xidusn = r.usn
AND   rs.segment_id = t.xidusn
ORDER BY t.used_ublk DESC
/

select usn, state, undoblockstotal "Total",
       undoblocksdone "Done",
       undoblockstotal-undoblocksdone "ToDo",
       decode(cputime,0,'unknown',To_Char(sysdate+(((undoblockstotal-undoblocksdone) / (undoblocksdone / cputime)) / 86400),'yyyy-mm-dd hh24:mi:ss')) "Estimated time"
from v$fast_start_transactions
/

select t.INST_ID
       , s.sid
       , s.program
       , t.status as transaction_status
       , s.status as session_status
       , s.lockwait
       , s.pq_status
       , t.used_ublk as undo_blocks_used
       , decode(bitand(t.flag, 128), 0, 'NO', 'YES') rolling_back
from
    gv$session s
    , gv$transaction t
where s.taddr = t.addr
and s.inst_id = t.inst_id
and s.STATUS = 'KILLED'
order by t.inst_id;

---http://o-dba.blogspot.com/2017/01/how-to-view-current-transaction-status.html
              
select ss.sid, ss.serial#, ss.username, st.used_ublk, st.used_urec, ss.status, decode(st.flag,7683,'ONGOING',7811,'ROLLBACK', st.flag) tr_status,  sqt.command_name, ss.sql_id, ss.prev_sql_id
from v$session ss , v$transaction st, V$sqlcommand sqt
where ss.saddr = st.ses_addr
and sqt.command_type = ss.command
order by 3;
