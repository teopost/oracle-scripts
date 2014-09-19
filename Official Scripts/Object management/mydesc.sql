SET ECHO off  
REM NAME:    TFSTBDSC.SQL  
REM USAGE:"@path/tfstbdsc"  
REM ------------------------------------------------------------------------  
REM REQUIREMENTS:  
REM    DBA or as the owner of the table  
REM   (If not performed as the owner, constraint info is incomplete)  
REM ------------------------------------------------------------------------  
REM AUTHOR:   
REM    G. Godart-Brown       
REM    Copyright 1992, Oracle Corporation       
REM ------------------------------------------------------------------------  
REM PURPOSE:  
REM Describes all the features of a table  
REM ------------------------------------------------------------------------  
REM EXAMPLE:  
REM     Sat Jul 27                           page    1  
REM              Table Description - Space Definition  
REM  
REM    Date -  Saturday  27th July      1996     13:31:47  
REM    At            -  TFTS_TEST  
REM    Username      -  SCOTT  
REM  
REM    Table Name                               S_EMP  
REM    Tablespace Name                         SYSTEM  
REM    Cluster Name  
REM    % Free                                      10  
REM    % Used                                      40  
REM    Ini Trans                                    1  
REM    Max Trans                                  255  
REM    Initial Extent (K)                          10  
REM    Next Extent (K)                             10  
REM    Min Extents                                  1  
REM    Max Extents                                121  
REM    % Increase                                  50  
REM    Number of Rows                              25  
REM    Number of Blocks                             1  
REM    Number of Empty Blocks                       3  
REM    Average Space                              350  
REM    Chain Count                                  0  
REM    Average Row Length                          62  
REM   
REM ------------------------------------------------------------------------  
REM DISCLAIMER:  
REM    This script is provided for educational purposes only. It is NOT   
REM    supported by Oracle World Wide Technical Support.  
REM    The script has been tested and appears to work as intended.  
REM    You should always run new scripts on a test instance initially.  
REM ------------------------------------------------------------------------  
REM Main text of script follows:  
  
  
SET ECHO OFF  
accept table_name prompt "Enter the name of the Table :"  
set heading on  
set verify on  
set newpage 0  
ttitle 'Table Description - Space Definition'  
spool tfstbdsc.lst  
  
  
btitle off  
column nline newline  
set pagesize 54  
set linesize 78  
set heading off  
set embedded off  
set verify off  
accept report_comment char prompt 'Enter a comment to identify system: '  
select 'Date -  '||to_char(sysdate,'Day Ddth Month YYYY     HH24:MI:SS'),  
	'At            -  '||'&&report_comment' nline,  
	'Username      -  '||USER  nline  
from sys.dual  
/  
prompt  
set embedded on  
  
  
set heading on  
set verify off  
column ts format a30  
column ta format a30  
column clu format a30  
column pcf format 99999999999990  
column pcu format 99999999999990  
column int format 99,999,999,990  
column mat format 99,999,999,990  
column inx format 99,999,999,990  
column nxt format 99,999,999,990  
column mix format 99,999,999,990  
column max format 99,999,999,990  
column pci format 99999999999990  
column num format 99,999,999,990  
column blo format 99,999,999,990  
column emp format 99,999,999,990  
column avg format 99,999,999,990  
column cha format 99,999,999,990  
column rln format 99,999,999,990  
column hdg format a30 newline  
set heading off  
select 	'Table Name' hdg, 		TABLE_NAME 		ta,  
 	'Tablespace Name' hdg, 		TABLESPACE_NAME 	ts,  
	'Cluster Name' hdg, 		CLUSTER_NAME 		clu,  
	'% Free' hdg, 			PCT_FREE		pcf,  
	'% Used' hdg,			PCT_USED		pcu,  
	'Ini Trans' hdg, 		INI_TRANS		int,  
	'Max Trans' hdg, 		MAX_TRANS		mat,  
	'Initial Extent (K)' hdg, 	INITIAL_EXTENT/1024	inx,  
	'Next Extent (K)' hdg, 		NEXT_EXTENT/1024	nxt,  
	'Min Extents' hdg, 		MIN_EXTENTS		mix,  
	'Max Extents' hdg, 		MAX_EXTENTS		max,  
	'% Increase' hdg, 		PCT_INCREASE		pci,  
	'Number of Rows' hdg, 		NUM_ROWS		num,  
	'Number of Blocks' hdg, 	BLOCKS			blo,  
	'Number of Empty Blocks' hdg, 	EMPTY_BLOCKS		emp,  
	'Average Space' hdg, 		AVG_SPACE		avg,  
	'Chain Count' hdg, 		CHAIN_CNT		cha,  
	'Average Row Length' hdg, 	AVG_ROW_LEN 		rln  
from all_tables  
where TABLE_NAME=UPPER('&&table_name')  
/  
set heading on  
set embedded off  
column cn format a30 heading 'Column Name'  
column fo format a15 heading 'Type'  
column nu format a8 heading 'Null'  
column nds format 99,999,999 heading 'No Distinct'  
column dfl format 9999 heading 'Dflt Len'  
column dfv format a40 heading 'Default Value'  
ttitle 'Table Description - Column Definition'  
select 	COLUMN_NAME cn,  
       	DATA_TYPE ||  
	decode(DATA_TYPE,  
		'NUMBER',  
		    '('||to_char(DATA_PRECISION)||  
			decode(DATA_SCALE,0,'',','||to_char(DATA_SCALE))||')',  
		'VARCHAR2',   
		    '('||to_char(DATA_LENGTH)||')',  
		'DATE','',  
		'Error') fo,  
	decode(NULLABLE,'Y','','NOT NULL') nu,  
	NUM_DISTINCT nds,  
	DEFAULT_LENGTH dfl,  
	DATA_DEFAULT dfv  
FROM all_tab_columns  
where TABLE_NAME=UPPER('&&table_name')  
order by COLUMN_ID  
/  
ttitle 'Table Constraints'  
set heading on  
set verify off  
column cn format a30 heading 'Primary Key'  
column cln format a45 heading 'Table.Column Name'  
column ct format a7 heading 'Type'  
column st format a7 heading 'Status'  
column ro format a30 heading 'Ref Owner|Constraint Name'  
column se format a70 heading 'Criteria ' newline  
break on cn on st   
set embedded on  
prompt Primary Key  
prompt  
select 	cns.CONSTRAINT_NAME cn,  
	cns.TABLE_NAME||'.'||cls.COLUMN_NAME cln,  
       	initcap(cns.STATUS) st  
from 	all_constraints cns,  
	all_cons_columns cls  
where 	cns.table_name=upper('&&table_name')  
and 	cns.owner=user  
and 	cns.CONSTRAINT_TYPE='P'  
and 	cns.constraint_name=cls.constraint_name  
order by cls.position  
/  
prompt Unique Key  
prompt  
column cn format a30 heading 'Unique Key'  
select 	cns.CONSTRAINT_NAME cn,  
	cns.TABLE_NAME||'.'||cls.COLUMN_NAME cln,  
       	initcap(cns.STATUS) st  
from 	all_constraints cns,  
	all_cons_columns cls  
where 	cns.table_name=upper('&&table_name')  
and 	cns.owner=user  
and 	cns.CONSTRAINT_TYPE='U'  
and 	cns.constraint_name=cls.constraint_name  
order by cls.position  
/  
column cln format a38 heading 'Foreign Key' newline  
column clfn format a38 heading 'Parent Key'  
break on cn on st skip 1  
prompt Foreign Keys  
prompt  
select 	cns.CONSTRAINT_NAME cn,  
        initcap(STATUS) st,  
	cls.TABLE_NAME||'.'||cls.COLUMN_NAME cln,  
	clf.OWNER||'.'||clf.TABLE_NAME||'.'||clf.COLUMN_NAME clfn  
from 	all_constraints cns,  
	all_cons_columns clf ,  
	all_cons_columns cls  
where 	cns.table_name=upper('&&table_name')  
and 	cns.owner=user  
and 	cns.CONSTRAINT_TYPE='R'  
and 	cns.constraint_name=cls.constraint_name  
and     clf.CONSTRAINT_NAME = cns.R_CONSTRAINT_NAME  
and     clf.OWNER = cns.OWNER  
and     clf.POSITION = clf.POSITION  
order by cns.CONSTRAINT_NAME, cls.position  
/  
prompt Check Constraints  
prompt  
column se format a75 heading 'Criteria'  
set arraysize 1  
set long 32000  
select CONSTRAINT_NAME cn,  
       initcap(STATUS) st,  
       SEARCH_CONDITION se  
from all_constraints  
where table_name=upper('&&table_name')  
and owner=user  
and CONSTRAINT_TYPE='C'  
/  
prompt View Constraints  
select CONSTRAINT_NAME cn,  
       initcap(STATUS) st,  
       SEARCH_CONDITION se  
from all_constraints  
where table_name=upper('&&table_name')  
and owner=user  
and CONSTRAINT_TYPE='V'  
/  
spool off  
btitle off  
ttitle off  
clear breaks  
clear columns  
clear computes  
set verify on  
set long 80  
set arraysize 30 
