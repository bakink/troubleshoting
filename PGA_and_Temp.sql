--http://o-dba.blogspot.com/2017/01/oracle-database-handy-scripts-pga-and.html

Finding PGA/Temp Usage for as Session - SQL & PL/SQL  over time.

The below query accepts the session_id and serial# and gives you PGA/Tempconsumption over time of the session.

This can help in cases like when you want to see how the PGA/TEMP allocation changed for the session over period of time.


select top_level_sql_id, SQL_ID,SAMPLE_TIME,PGA_ALLOCATED/(1024*1024) as PGA_MB
from
v$active_session_history
where
session_id = &sess_ion
and session_serial# = &serial 
order by 3;


select top_level_sql_id, SQL_ID,SAMPLE_TIME,temp_space_allocated/(1024*1024) as TEMP_MB
from
v$active_session_history
where
session_id = &sess_ion
and session_serial# = &serial
order by 3;




Temp and PGA - Usage History 
Source - https://bdrouvot.wordpress.com/2013/03/19/link-huge-pga-temp/

The output tells you which SQL_ID asked for maximum PGA w.r.t to PGA that was allocated for this particular session.



The SQL can be changed per your requirement for example by giving custom time stamp with sample_time or providing specific Session ID and Serial#.
 You can change v$active_session_history to dba_hist_active_sess_history  to find more historical Data.



accept seconds prompt "Last Seconds [60] : " default 60;
accept top prompt "Top  Rows    [10] : " default 10;

select SQL_ID,round(PGA_MB,1) PGA_MB,percent,rpad('*',percent*10/100,'*') star
from
(
select SQL_ID,sum(DELTA_PGA_MB) PGA_MB ,(ratio_to_report(sum(DELTA_PGA_MB)) over ())*100 percent,rank() over(order by sum(DELTA_PGA_MB) desc) rank
from
(
select SESSION_ID,SESSION_SERIAL#,sample_id,SQL_ID,SAMPLE_TIME,IS_SQLID_CURRENT,SQL_CHILD_NUMBER,PGA_ALLOCATED,
greatest(PGA_ALLOCATED - first_value(PGA_ALLOCATED) over (partition by SESSION_ID,SESSION_SERIAL# order by sample_time rows 1 preceding),0)/power(1024,2) "DELTA_PGA_MB"
from
v$active_session_history
where
IS_SQLID_CURRENT='Y'
and sample_time > sysdate-&seconds/86400
order by 1,2,3,4
)
group by sql_id
having sum(DELTA_PGA_MB) > 0
)
where rank < (&top+1)
order by rank;

Below SQL is the same however for Temp Usage.


col percent head '%' for 99990.99
col star for A10 head ''

accept seconds prompt "Last Seconds [60] : " default 60;
accept top prompt "Top  Rows    [10] : " default 10;

select SQL_ID,TEMP_MB,percent,rpad('*',percent*10/100,'*') star
from
(
select SQL_ID,sum(DELTA_TEMP_MB) TEMP_MB ,(ratio_to_report(sum(DELTA_TEMP_MB)) over ())*100 percent,rank() over(order by sum(DELTA_TEMP_MB) desc) rank
from
(
select SESSION_ID,SESSION_SERIAL#,sample_id,SQL_ID,SAMPLE_TIME,IS_SQLID_CURRENT,SQL_CHILD_NUMBER,temp_space_allocated,
greatest(temp_space_allocated - first_value(temp_space_allocated) over (partition by SESSION_ID,SESSION_SERIAL# order by sample_time rows 1 preceding),0)/power(1024,2) "DELTA_TEMP_MB"
from
v$active_session_history
where
IS_SQLID_CURRENT='Y'
and sample_time > sysdate-&seconds/86400
order by 1,2,3,4
)
group by sql_id
having sum(DELTA_TEMP_MB) > 0
)
where rank < (&top+1)
order by rank;


Sort Segment Usage Queries

SELECT tablespace_name, TOTAL_BLOCKS, USED_BLOCKS,
         FREE_BLOCKS, MAX_USED_BLOCKS
      FROM v$sort_segment;


Total Temp Tablespace Consumption

select tablespace, sum(blocks)*8192/1024/1024 consuming_TEMP_MB from
v$session, v$sort_usage where tablespace in (select tablespace_name from
dba_tablespaces where contents = 'TEMPORARY') and session_addr=saddr
group by tablespace;

Tablespace Space Allocations

Tablespace Name                CONSUMING_TEMP_MB
------------------------------ -----------------
TEMP_TS                                      332
 

Sessions Consuming More than 10 MB of TEMP Space.

select sid, tablespace,
sum(blocks)*8192/1024/1024 consuming_TEMP_MB from v$session,
v$sort_usage where tablespace in (select tablespace_name from
dba_tablespaces where contents = 'TEMPORARY') and session_addr=saddr
group by sid, tablespace having sum(blocks)*8192/1024/1024 > 10
order by sum(blocks)*8192/1024/1024 desc ;

Tablespace Space Allocations
       SID Tablespace Name                CONSUMING_TEMP_MB
---------- ------------------------------ -----------------
      5454 TEMP_TS                                       16
     20306 TEMP_TS                                       16
     15046 TEMP_TS                                       16
     21064 TEMP_TS                                       16
     20687 TEMP_TS                                       16
     21060 TEMP_TS                                       16
      4518 TEMP_TS                                       16
      6024 TEMP_TS                                       16
     20870 TEMP_TS                                       16
      4708 TEMP_TS                                       16
     21249 TEMP_TS                                       16
     21434 TEMP_TS                                       16
      5265 TEMP_TS                                       16
      6393 TEMP_TS                                       16
     10535 TEMP_TS                                       16
     22004 TEMP_TS                                       15
 


Temp Segment Used Percent

set pagesize 60
column "Tablespace" heading "Tablespace Name" format a30
column "Size" heading "Tablespace|Size (mb)" format 9999999.9
column "Used" heading "Used|Space (mb)" format 9999999.9
column "Left" heading "Available|Space (mb)" format 9999999.9
column "PCTFree" heading "% Free" format 999.99

ttitle left "Tablespace Space Allocations"
break on report
-- compute sum of "Size", "Left", "Used" on report
select /*+ RULE */
t.tablespace_name,
NVL(round(((sum(u.blocks)*p.value)/1024/1024),2),0) Used_mb,
t.Tot_MB,
NVL(round(sum(u.blocks)*p.value/1024/1024/t.Tot_MB*100,2),0) "USED %"
from v$sort_usage u,
v$parameter p,
(select tablespace_name,sum(bytes)/1024/1024 Tot_MB
from dba_temp_files
group by tablespace_name
) t
where p.name = 'db_block_size'
and u.tablespace (+) = t.tablespace_name
group by
t.tablespace_name,p.value,t.Tot_MB
order by 1,2;

Tablespace Space Allocations
TABLESPACE_NAME                   USED_MB     TOT_MB     USED %
------------------------------ ---------- ---------- ----------
TEMP_TS                               332     352011        .09

PGA ----

PGA used > 20 MB

select s.inst_id, s.sid, s.username, s.logon_time, s.program, PGA_USED_MEM/1024/1024 PGA_USED_MEM, PGA_ALLOC_MEM/1024/1024 PGA_ALLOC_MEM
from gv$session s
, gv$process p
Where s.paddr = p.addr
and s.inst_id = p.inst_id
and PGA_USED_MEM/1024/1024 > 20  -- pga_used memory over 20mb
order by PGA_USED_MEM;


Current PGA Statistics
  1* select * from v$pgastat

NAME                                            VALUE UNIT
------------------------------------- --------------- ------------
aggregate PGA target parameter             4294967296 bytes
aggregate PGA auto target                  2819801088 bytes
global memory bound                         429496320 bytes
total PGA inuse                            1161867264 bytes
total PGA allocated                        1868928000 bytes
maximum PGA allocated                     13390500864 bytes
total freeable PGA memory                   392167424 bytes
process count                                     492
max processes count                               842
PGA memory freed back to OS            11206414630912 bytes
total PGA used for auto workareas                   0 bytes
maximum PGA used for auto workareas        4478357504 bytes
total PGA used for manual workareas                 0 bytes
maximum PGA used for manual workareas      8881704960 bytes
over allocation count                            7202
bytes processed                        54360669887488 bytes
extra bytes read/written               15766446106624 bytes
cache hit percentage                            77.51 percent
recompute count (total)                       3070407
