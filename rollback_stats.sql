
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
