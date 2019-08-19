--https://carlos-sierra.net/2017/09/01/poors-man-script-to-summarize-reasons-why-cursors-are-not-shared/

select 'select reason_not_shared, count(*) cursors, count(distinct sql_id) sql_ids
from v$sql_shared_cursor
unpivot(val for reason_not_shared in(
' 
|| listagg(
  '  '||listagg(column_name,',') within group (order by column_id) ,
  ',
') within group(order by line_no)
||'
))
where val = ''Y''
group by reason_not_shared
order by 2 desc, 3, 1;'
sql_text
from (
  select column_name,
  column_id,
  ceil(row_number() over(order by column_id) / 4) line_no
  from dba_tab_columns where owner = 'SYS' and table_name = 'V_$SQL_SHARED_CURSOR'
  and data_length = 1
)
group by line_no;

-- Üstteki Sql bunu oluşturmak için.
select reason_not_shared, count(*) cursors, count(distinct sql_id) sql_ids
from v$sql_shared_cursor
unpivot(val for reason_not_shared in(
  UNBOUND_CURSOR,SQL_TYPE_MISMATCH,OPTIMIZER_MISMATCH,OUTLINE_MISMATCH,
  STATS_ROW_MISMATCH,LITERAL_MISMATCH,FORCE_HARD_PARSE,EXPLAIN_PLAN_CURSOR,
  BUFFERED_DML_MISMATCH,PDML_ENV_MISMATCH,INST_DRTLD_MISMATCH,SLAVE_QC_MISMATCH,
  TYPECHECK_MISMATCH,AUTH_CHECK_MISMATCH,BIND_MISMATCH,DESCRIBE_MISMATCH,
  LANGUAGE_MISMATCH,TRANSLATION_MISMATCH,BIND_EQUIV_FAILURE,INSUFF_PRIVS,
  INSUFF_PRIVS_REM,REMOTE_TRANS_MISMATCH,LOGMINER_SESSION_MISMATCH,INCOMP_LTRL_MISMATCH,
  OVERLAP_TIME_MISMATCH,EDITION_MISMATCH,MV_QUERY_GEN_MISMATCH,USER_BIND_PEEK_MISMATCH,
  TYPCHK_DEP_MISMATCH,NO_TRIGGER_MISMATCH,FLASHBACK_CURSOR,ANYDATA_TRANSFORMATION,
  PDDL_ENV_MISMATCH,TOP_LEVEL_RPI_CURSOR,DIFFERENT_LONG_LENGTH,LOGICAL_STANDBY_APPLY,
  DIFF_CALL_DURN,BIND_UACS_DIFF,PLSQL_CMP_SWITCHS_DIFF,CURSOR_PARTS_MISMATCH,
  STB_OBJECT_MISMATCH,CROSSEDITION_TRIGGER_MISMATCH,PQ_SLAVE_MISMATCH,TOP_LEVEL_DDL_MISMATCH,
  MULTI_PX_MISMATCH,BIND_PEEKED_PQ_MISMATCH,MV_REWRITE_MISMATCH,ROLL_INVALID_MISMATCH,
  OPTIMIZER_MODE_MISMATCH,PX_MISMATCH,MV_STALEOBJ_MISMATCH,FLASHBACK_TABLE_MISMATCH,
  LITREP_COMP_MISMATCH,PLSQL_DEBUG,LOAD_OPTIMIZER_STATS,ACL_MISMATCH,
  FLASHBACK_ARCHIVE_MISMATCH,LOCK_USER_SCHEMA_FAILED,REMOTE_MAPPING_MISMATCH,LOAD_RUNTIME_HEAP_FAILED,
  HASH_MATCH_FAILED,PURGED_CURSOR,BIND_LENGTH_UPGRADEABLE,USE_FEEDBACK_STATS
))
where val = 'Y'
group by reason_not_shared
order by 2 desc, 3, 1;
---
  
--https://blog.tuningsql.com/why-is-my-cursor-not-shared/
  
 select q'<select *
 from gv$sql_shared_cursor
 unpivot ( flag for reason_not_sharing in (>' || listagg(column_name, ', ') within group (order by null) || q'<) )
 where sql_id = nvl('>' || '&' || q'<v_sql_id.', sql_id)
   and flag = 'Y'>'x
 from dba_tab_columns
 where owner = 'SYS'
   and table_name = 'V_$SQL_SHARED_CURSOR'
   and data_type = 'VARCHAR2'
   and data_length = 1;
  
