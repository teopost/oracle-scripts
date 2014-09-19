clear col
set head off
set pause off
set pages 0
set verify off
set feedback off

clear breaks
clear compute

column today new_value dba_date
select to_char(sysdate, 'mm/dd/yy hh:miam') today
       from dual;

break on instance
column instance new_value instance_name
select substr(name,1,8) instance
      from v$database;

clear breaks
set termout on

set pagesize 60 linesize 80 verify off
set space 2
ttitle left 'Date: ' format a18 dba_date -
       center 'DB Review(5) - ' format a8 instance_name -
       right 'Page: ' format 999 sql.pno skip 2

set head on
set verify on
set feedback on
col table_name format a30
col ext format 990
col used format 99,990
col empty format 99,990
col used_pct format 990.99
col next format 99,999,990
spool db_revw5.rslt 

set echo on;
/* ******************************************************************* */
/*                                                                     */
/*                >>> Database Review; R.Kupcunas <<<                  */
/*                                                                     */
/*  Name:    d:\oradata\NUCP\tuning\db_revw5.sql                       */
/*  Creator: Rick Kupcunas                                             */
/*  Created: 10-Mar-97                                                 */
/*                                                                     */
/* this script will show various database extent parameters.           */
/*  SECTION 1a - Tablespace Information                                */
/*  SECTION 1b - Tablespace Status                                     */
/*  SECTION 2a - Show all Tables                                       */
/*  SECTION 2b - Show all Tables(space requirements)                   */
/*  SECTION 3a - Show all Indexes                                      */
/*  SECTION 3b - Show all Indexs(space requirements)                   */
/*  SECTION 3c - Show all Indexs(attributes)                           */
/*  SECTION 4 - Show all Views                                         */
/*  SECTION 5 - Show all Synonyms                                      */
/*  SECTION 6 - User Information                                       */
/*  SECTION 7 - Individual Roles                                       */
/*  SECTION 8 - Role Specifiecs                                        */
/*  SECTION 9 - Sequences                                              */
/*  SECTION 10 - Rollback Segment Information                          */
/*                                                                     */
/* ******************************************************************* */

/* ****************************************** */
/*  SECTION 1a - Tablespace Information       */
/* ****************************************** */

set echo off;

column FileNum	    format 999	    heading 'File|Num'
column FileName     format A32      heading 'File Name' 
column Tablespace   format A8       heading 'Tblspace'
column Allocated    format 99,999    heading 'Size|(MB)' 
column div1         format A3       heading ' | '
column Used         format 99,999    heading 'Used|(MB)'
column Unused       format 99,999    heading 'Unused|(MB)'
column Pct_Used     format 999.99   heading 'Used|(%)'
column div2         format A3       heading ' | ' 
column TotalFree    format 9,999    heading 'Free|(MB)'
column Pct_Free     format 999.99   heading 'Free|(%)'
column MaxFree      format 9,999    heading 'MaxFree'
column status       format A3       heading 'STA'

column oneMB noprint new_value MB

compute sum of Allocated on tablespace 
compute sum of Allocated on report 
compute sum of Used      on tablespace 
compute sum of Used      on report 
compute sum of TotalFree on tablespace 
compute sum of TotalFree on report 
compute sum of Unused    on tablespace 
compute sum of Unused    on report 

break on Tablespace;

select x.tablespace_name                       Tablespace,
       /* substr(to_char(x.file_id,999), 1,4)     FileNum, */
       x.file_name                             FileName,
       x.bytes/(1024*1024)                     Allocated,
       (x.bytes-sum(y.bytes))/(1024*1024)      Used,
       x.bytes/(1024*1024) - (x.bytes-sum(y.bytes))/(1024*1024)      
                                               Unused,
    /*   ((x.bytes-sum(y.bytes))/
       x.bytes)*100                            Pct_Used,
       sum(y.bytes)/(1024*1024)                TotalFree,
       (sum(y.bytes)/x.bytes)*100              Pct_Free,
       max(y.bytes)/(1024*1024)                MaxFree,  */
       substr(x.status,1,3)                   status
from sys.dba_data_files x , 
     sys.dba_free_space  y 
where x.file_id = y.file_id 
group by substr(to_char(x.file_id,999), 1,4),
         x.file_name,
         x.tablespace_name,
         x.bytes,
         x.status  
order by 1,2,3;

set echo on;    

/* **************************************************** */
/*  SECTION 1b - Tablespace Status                      */
/* **************************************************** */

set echo off;

break on "TYPE";
select STATUS                           "TYPE",
       substr(TABLESPACE_NAME,1,8)	"TSPS",
       CONTENTS                         "CONTENTS"
from  dba_tablespaces
order by 1,2;       

set echo on;    

/* **************************************************** */
/*  SECTION 2a - Show all Tables                        */
/* **************************************************** */

set echo off;
break on "Owner" on Tablespace;

column TableName    format A22      heading 'Table|Name' 
column Tablespace   format A8       heading 'Tblspace'
column NextExt      format 999.999  heading 'Next|Extent|(MB)'  
column MinExt       format 999      heading 'Min|Ext'  
column MaxExt       format 999      heading 'Max|Ext' 
column Pct_Free     format 999      heading 'Free|(%)'
column Pct_Used     format 999      heading 'Used|(%)'
column InitialExt   format 999.999  heading 'Initial|Extent|(MB)' 
column PctIncrease  format 999.99   heading 'Pct|Incr'
column NumRows      format 999,999,999  heading 'Num of|Rows'  

column CurrentExt   format 999      heading 'Cur |Exts' 

select  substr(OWNER,1,8)		"Owner",
        substr(TABLESPACE_NAME,1,8)	Tablespace,
        TABLE_NAME		        TableName,
        PCT_FREE			Pct_Free,
        PCT_USED			Pct_Used,
        INITIAL_EXTENT/(1024*1024)	InitialExt,
        NEXT_EXTENT/(1024*1024)   	NextExt
    /*    MIN_EXTENTS		        MinExt,
        MAX_EXTENTS		        MaxExt,
        PCT_INCREASE			PctIncrease,
        NUM_ROWS			NumRows */
from  dba_tables
where owner != 'SYS' and
      owner != 'SYSTEM'
order by 1,2,3;

set echo on

/* **************************************************** */
/*  SECTION 2b - Show all Tables(space requirements)    */
/* **************************************************** */

set echo off;
break on "TBL SPACE" ;

select substr(tablespace_name,1,12)                          "TBL SPACE",
       substr(segment_name, 1, 18)                           "SEGMENT",
       substr(to_char(sum(bytes/(1024*1024)), '99,999.999'), 1, 10)  
                                                             "SIZE(MB)",
       substr(to_char(sum(blocks), '999,999'), 1, 8)         "SUM BLKS", 
       substr(to_char(extents, '999'), 1, 4)                 "EXTENTS",
       substr(to_char(initial_extent/(1024*1024), '999.999'), 1, 7)  
                                                             "INI(MB)",
       substr(to_char(next_extent/(1024*1024), '999.999'), 1, 8)        
                                                             "NXT(MB)"
from    user_segments
where   segment_type = 'TABLE'
group by segment_name,
         segment_type,
         tablespace_name,
         bytes,
         blocks,
         extents,
         initial_extent,
         next_extent
order by 1, 2;

set echo on;

/* **************************************************** */
/*  SECTION 3a - Show all Indexes                       */
/* **************************************************** */

set echo off;

break on "TBL OWNER" on "OWNER" on "TABLE NAME" on "INDEX NAME";

select distinct substr(table_owner,1,10)      	"TBL OWNER",
       substr(TABLE_NAME, 1, 20)     		"TABLE NAME",    
       substr(index_name, 1, 20)     		"INDEX NAME"
from all_ind_columns
where table_owner <> 'SYS' and
      table_owner <> 'SYSTEM' 
order by 1 asc,
         2 asc,
         3 asc;
        
set echo on

/* **************************************************** */
/*  SECTION 3b - Show all Indexs(space requirements)    */
/* **************************************************** */

set echo off;
break on "TBL SPACE" ;

select substr(tablespace_name,1,12)                          "TBL SPACE",
       substr(segment_name, 1, 18)                           "SEGMENT",
       substr(to_char(sum(bytes/(1024*1024)), '99,999.999'), 1, 10)  
                                                             "SIZE(MB)",
       substr(to_char(sum(blocks), '999,999'), 1, 8)         "SUM BLKS", 
       substr(to_char(extents, '999'), 1, 4)                 "EXTENTS",
       substr(to_char(initial_extent/(1024*1024), '999.999'), 1, 7)  
                                                             "INI(MB)",
       substr(to_char(next_extent/(1024*1024), '999.999'), 1, 8)        
                                                             "NXT(MB)"
from    user_segments
where   segment_type = 'INDEX'
group by segment_name,
         segment_type,
         tablespace_name,
         bytes,
         blocks,
         extents,
         initial_extent,
         next_extent
order by 1, 2;

set echo on;

/* **************************************************** */
/*  SECTION 3b - Show all Indexs(Attributes)            */
/* **************************************************** */

set echo off;
break on "TBL OWNER" on "OWNER" on "TABLE NAME" on "INDEX NAME";

select substr(table_owner,1,8)      "TBL OWNER",
       substr(TABLE_NAME, 1, 18)     "TABLE NAME",    
       substr(index_name, 1, 20)     "INDEX NAME",
       substr(column_position, 1, 3) "NUM",
       substr(column_name, 1, 20)    "ATTRIBUTE"
from all_ind_columns
where table_owner <> 'SYS' and
      table_owner <> 'SYSTEM' 
order by 1 asc,
         2 asc,
         3 asc,
         4 asc;

set echo on;

/* **************************************************** */
/*  SECTION 4 - Show all Views                          */
/* **************************************************** */

set echo off;

break on "OWNER" on "VIEW";

select substr(owner,1,8)       "OWNER",
       substr(view_name,1,35)  "VIEW"
  from sys.dba_views
where owner <> 'SYS' and
      owner <> 'SYSTEM' 
order by 1 asc, 2 asc;

set echo on;

/* **************************************************** */
/*  SECTION 5 - Show all Synonyms                       */
/* **************************************************** */

set echo off;

break on "OWNER" on "TYPE";

select 	substr(table_owner,1,10)                "OWNER",
        substr(owner,1,10)                      "TYPE",
        substr(synonym_name,1,25)		"SYNONYM",
        substr(table_name,1,25)               	"OBJECT"
from 	all_synonyms
where table_owner <> 'SYS' and
      table_owner <> 'SYSTEM' 
order by 1 asc, 2 asc, 3 asc;

set echo on;    

/* ****************************************** */
/*  SECTION 6 - User Information              */
/* ****************************************** */

set echo off;

select 	substr(username,1,8)			"USERNAME",
	substr(user_id,1,8)			"USER ID",
	substr(default_tablespace,1,12)		"TBL SPC",
	substr(temporary_tablespace,1,12)	"TEMP SPC",
	created					"CREATED",
	substr(profile,1,12)			"ROLE"
from 	dba_users 
order by 1 asc;

set echo on;    

/* ****************************************** */
/*  SECTION 7 - Individual Roles              */
/* ****************************************** */

set echo off;

break on "USER" on "ROLE";

select substr(GRANTEE,1,10)		"USER",
       substr(GRANTED_ROLE,1,20)	"ROLE",
       substr(ADMIN_OPTION,1,3)		"ADM"
from dba_role_privs
order by 1,2;
                                            
set echo on;    

/* ****************************************** */
/*  SECTION 8 - Role Specifiecs               */
/* ****************************************** */

set echo off;

break on "ROLE" on "OWNER" on "TABLE" on "GRANTOR";

select substr(grantee,1,20)		"ROLE",
       substr(owner,1,8)                "OWNER",
       substr(table_name,1,25)		"TABLE",
       /* substr(grantor,1,10)             "GRANTOR", */
       substr(privilege, 1,10)          "PRIV",
       grantable
from dba_tab_privs 
where owner = 'DB2324'
order by 1, 2,3,4,5;

set echo on;    

/* ****************************************** */
/*  SECTION 9 - Sequences                     */
/* ****************************************** */

set echo off;

break on "OWNER" on "SEQ NAME";

select 	substr(sequence_owner,1,8)             "OWNER",
        substr(sequence_name,1,15)              "SEQ NAME",
        substr(to_char(min_value),1,3)          "MIN",
	max_value				"MAX",
	increment_by				"INC",
	to_char(last_number, '999,999,999')	"LAST NUM"
from 	all_sequences 
where   sequence_owner <> 'SYS' and
        sequence_owner <> 'SYSTEM'
order by 1 asc, 2 asc;

set echo on;    

/* ****************************************** */
/*  SECTION 10 - Rollback Segment Information */
/* ****************************************** */

set echo off;

column SegmentName  format A10      heading 'Segment|Name' 
column Tablespace   format A8       heading 'Tblspace'
column CurrentExt   format 999      heading 'Cur |Exts' 
column InitialExt   format 999.999  heading 'Initial|Extent|(MB)' 
column NextExt      format 999.999  heading 'Next|Extent|(MB)'  
column MinExt       format 999      heading 'Min|Ext'  
column MaxExt       format 999      heading 'Max|Ext' 
column Status       format A10      heading 'STATUS' 

select  substr(owner,1,10)                "OWNER",
	substr(segment_name,1,10)	  SegmentName,
        substr(tablespace_name,1,10)      Tablespace,
        min_extents - 1	                  CurrentExt,
        initial_extent/(1024*1024)        InitialExt,
        next_extent/(1024*1024)	          NextExt,
        MIN_EXTENTS			  MinExt,                     
        MAX_EXTENTS 			  MaxExt,                  
	status				  status
from dba_rollback_segs
order by 1, 2,3,4,5;   

clear breaks;
clear compute;
set head on;
set pause off;
spool off;
ttitle off;
commit;
