set showmode off
set echo off
set linesize 80
set pagesize 0
set heading off
set timing off
set feedback off
set recsep off
rem
rem Script: move_indexes.sql
rem Purpose: Move regular and primary key indexes to a given tablespace
rem          for a given index, table, or owner, or a wildcard set of them.
rem          Can also be used to rebuild a single index, freeing up unused
rem          space, by specifying the index name and owner and leaving the
rem          tablespace name blank (no wildcards allowed for rebuild).
!echo
accept indexes char prompt 'Enter index name or wildcard (% for all): '
accept tables char prompt 'Enter table name or wildcard (% for all): '
accept owners char prompt 'Enter table owner or wildcard (% for all): '
accept tsname char prompt 'Enter tablespace name to move indexes to: '
set termout off
set verify off
rem
rem Set origcurr to 'O' to use original next_extent (from dba_extents
rem bytes where extent_id is 1, which is the first next_extent), or 'C'
rem to use current next_extent (from dba_indexes next_extent adjusted
rem for pctincrease > 0).
rem
define origcurr = 'O'
spool mi_do.sql
select 'define indexes = ' || upper('&indexes') from dual;
select 'define tables = ' || upper('&tables') from dual;
select 'define owners = ' || upper('&owners') from dual;
select 'define tsname = ' || upper('&tsname') from dual;
spool off
@mi_do.sql
spool mi_do.sql
select 'define tsname = ' || decode('&tsname','',tablespace_name,'&tsname')
   from dba_segments where segment_name = '&indexes' and owner = '&owners';
spool off
@mi_do.sql
column o1 noprint
column o2 noprint
column o3 noprint
column o4 noprint
column o5 noprint
spool mi_do.sql
select 1 as o1, owner as o2, table_name as o3, r_constraint_name as o4, 1 as o5,
   'alter table ' || owner || '.' || table_name ||
   ' drop constraint ' || constraint_name || ';' as line
   from dba_constraints where constraint_type = 'R'
   and r_owner like '&owners' and r_constraint_name like '&indexes'
   and r_constraint_name like 'PK_&tables'
   and owner not in ('SYS','SYSTEM','SCOTT')
union all
   select 2, di.table_owner, di.table_name, di.index_name, 2,
   'drop index ' || di.owner || '.' || di.index_name || ';'
   from dba_indexes di
   where di.index_name like '&indexes'
   and di.table_name like '&tables'
   and di.table_owner like '&owners'
   and di.table_owner not in ('SYS','SYSTEM','SCOTT')
   and not exists
      (select 'x' from dba_constraints dc
         where dc.constraint_name = di.index_name
         and dc.table_name = di.table_name
         and dc.owner = di.table_owner
         and dc.constraint_type = 'P')
union all
   select 2, di.table_owner, di.table_name, di.index_name, 2,
   'alter table ' || di.table_owner || '.' || di.table_name ||
   ' drop primary key;'
   from dba_indexes di
   where di.index_name like '&indexes'
   and di.table_name like '&tables'
   and di.table_owner like '&owners'
   and di.table_owner not in ('SYS','SYSTEM','SCOTT')
   and exists
      (select 'x' from dba_constraints dc
         where dc.constraint_name = di.index_name
         and dc.table_name = di.table_name
         and dc.owner = di.table_owner
         and dc.constraint_type = 'P')
union all
   select 3, di.table_owner, di.table_name, di.index_name, 3,
   'create' || decode(di.uniqueness,'UNIQUE',' unique','') || ' index ' ||
   di.owner || '.' || di.index_name || ' on ' || di.table_owner || '.' ||
   di.table_name ||
   ' ('
   from dba_indexes di
   where di.index_name like '&indexes'
   and di.table_name like '&tables'
   and di.table_owner like '&owners'
   and di.table_owner not in ('SYS','SYSTEM','SCOTT')
   and not exists
      (select 3, 'x' from dba_constraints dc
         where dc.constraint_name = di.index_name
         and dc.table_name = di.table_name
         and dc.owner = di.table_owner
         and dc.constraint_type = 'P')
union all
   select 3, di.table_owner, di.table_name, di.index_name, 3,
   'alter table ' || di.table_owner || '.' || di.table_name ||
   ' add constraint ' || di.index_name || ' primary key ('
   from dba_indexes di
   where di.index_name like '&indexes'
   and di.table_name like '&tables'
   and di.table_owner like '&owners'
   and di.table_owner not in ('SYS','SYSTEM','SCOTT')
   and exists
      (select 3, 'x' from dba_constraints dc
         where dc.constraint_name = di.index_name
         and dc.table_name = di.table_name
         and dc.owner = di.table_owner
         and dc.constraint_type = 'P')
union all
   select 3, table_owner, table_name, index_name, 3 + column_position,
   decode(column_position,1,'',',') || column_name
   from dba_ind_columns
   where index_name like '&indexes'
   and table_name like '&tables'
   and table_owner like '&owners'
   and table_owner not in ('SYS','SYSTEM','SCOTT')
union all
   select 3, di.table_owner, di.table_name, di.index_name, 1000,
   ') using index'
   from dba_indexes di
   where di.index_name like '&indexes'
   and di.table_name like '&tables'
   and di.table_owner like '&owners'
   and di.table_owner not in ('SYS','SYSTEM','SCOTT')
   and exists
      (select 3, 'x' from dba_constraints dc
         where dc.constraint_name = di.index_name
         and dc.table_name = di.table_name
         and dc.owner = di.table_owner
         and dc.constraint_type = 'P')
union all
   select 3, di.table_owner, di.table_name, di.index_name, 1000,
   ')'
   from dba_indexes di
   where di.index_name like '&indexes'
   and di.table_name like '&tables'
   and di.table_owner like '&owners'
   and di.table_owner not in ('SYS','SYSTEM','SCOTT')
   and not exists
      (select 3, 'x' from dba_constraints dc
         where dc.constraint_name = di.index_name
         and dc.table_name = di.table_name
         and dc.owner = di.table_owner
         and dc.constraint_type = 'P')
union all
   select 3, di.table_owner, di.table_name, di.index_name, 1001,
   'pctfree ' || di.pct_free || ' initrans ' || di.ini_trans ||
   ' maxtrans ' || di.max_trans || chr(10) ||
   'storage(initial ' || di.initial_extent || ' next ' ||
   decode('&origcurr','C',di.next_extent,nvl(de.bytes,di.next_extent)) ||
   chr(10) ||
   'minextents ' || di.min_extents || ' maxextents ' || di.max_extents ||
   ' pctincrease ' || di.pct_increase || ')' || chr(10) ||
   'tablespace &tsname;'
   from dba_indexes di,dba_extents de
   where di.index_name like '&indexes'
   and di.table_name like '&tables'
   and di.table_owner like '&owners'
   and di.table_owner not in ('SYS','SYSTEM','SCOTT')
   and di.owner = de.owner(+)
   and di.index_name = de.segment_name(+)
   and de.segment_type(+) = 'INDEX'
   and de.extent_id(+) = 1
union all
   select 4, owner, table_name, constraint_name, 1002,
   'alter table ' || owner || '.' || table_name || ' add constraint ' ||
   constraint_name || chr(10) || 'foreign key (' as line
   from dba_constraints where constraint_type = 'R'
   and r_owner like '&owners' and r_constraint_name like '&indexes'
   and r_constraint_name like 'PK_&tables'
   and owner not in ('SYS','SYSTEM','SCOTT')
union all
   select 4, ca.owner, ca.table_name, ca.constraint_name, 1002 + cb.position,
   decode(cb.position,1,'',',') || cb.column_name
   from dba_constraints ca,dba_cons_columns cb
   where ca.constraint_name = cb.constraint_name
   and ca.owner = cb.owner and ca.constraint_type = 'R'
   and ca.r_owner like '&owners' and ca.r_constraint_name like '&indexes'
   and ca.r_constraint_name like 'PK_&tables'
   and ca.owner not in ('SYS','SYSTEM','SCOTT')
union all
   select distinct 4, ca.owner, ca.table_name, ca.constraint_name, 2000,
   ') references ' || cb.owner || '.' || cb.table_name || ' ('
   from dba_constraints ca,dba_cons_columns cb
   where ca.r_constraint_name = cb.constraint_name
   and ca.r_owner = cb.owner and ca.constraint_type = 'R'
   and ca.r_owner like '&owners' and ca.r_constraint_name like '&indexes'
   and ca.r_constraint_name like 'PK_&tables'
   and ca.owner not in ('SYS','SYSTEM','SCOTT')
union all
   select 4, ca.owner, ca.table_name, ca.constraint_name, 2000 + cb.position,
   decode(cb.position,1,'',',') || cb.column_name
   from dba_constraints ca,dba_cons_columns cb
   where ca.r_constraint_name = cb.constraint_name
   and ca.r_owner = cb.owner and ca.constraint_type = 'R'
   and ca.r_owner like '&owners' and ca.r_constraint_name like '&indexes'
   and ca.r_constraint_name like 'PK_&tables'
   and ca.owner not in ('SYS','SYSTEM','SCOTT')
union all
   select 4, owner, table_name, constraint_name, 3000,
   ')' || decode(delete_rule,'CASCADE',' on delete cascade','') ||
   decode(status,'DISABLED',' disable','') || ';'
   from dba_constraints where constraint_type = 'R'
   and r_owner like '&owners' and r_constraint_name like '&indexes'
   and r_constraint_name like 'PK_&tables'
   and owner not in ('SYS','SYSTEM','SCOTT')
order by 1,2,3,4,5;
spool off
column o1 clear
column o2 clear
column o3 clear
column o4 clear
!echo
!cat mi_do.sql
!echo
set termout on verify on
accept run_it char prompt 'Run it (y or n)? '
set termout off verify off
!echo
spool mi_do2.sql
select decode('&run_it','y','@mi_do.sql','Y','@mi_do.sql','') from dual;
spool off
set linesize 80
set termout on
set heading on
set pagesize 24
set timing on
set feedback 6
set verify on
set echo on
set showmode both
spool move_indexes.lst
@mi_do2.sql
spool off
!/home/common/all_rights.shl move_indexes.lst
!/home/common/all_rights.shl mi_do.sql
!rm mi_do2.sql
