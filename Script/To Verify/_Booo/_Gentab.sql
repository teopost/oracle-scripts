REM ***********************************************************
REM This PL/SQL script Generates a Table creation script from 
REM the Data Dictionary.  This script takes two parameters:
REM owner and table name.
REM The script can be customized to read the owner name and
REM table name from a file and generate the table creation script.
REM Privileged Users : SYSTEM, SYS or user having SELECT ANY TABLE
REM                  system privilege 
REM 
REM Command Syntax:
REM                  In SQL:
REM                  SQL >@gentab.sql owner table_name
REM		     Unix Shell:
REM                  sqlplus system/manager << !
REM                  @gentab.sql owner table_name
REM                  !
REM ***********************************************************
set serveroutput on size 200000
set echo off
set feedback off
set verify off
set showmode off
declare 
 cursor TabCur is
  select table_name,owner,tablespace_name,initial_extent,next_extent,
         pct_used,pct_free,pct_increase,degree 
  from sys.dba_tables
  where owner=upper('&&1') and
  table_name=upper('&&2');
 cursor ColCur(TableName varchar2) is
  select
       column_name col1,
       decode ( data_type,
                'LONG',   'LONG   ',
                'LONG RAW',   'LONG RAW  ',
                'RAW',   'RAW  ',
                'DATE',   'DATE   ',
                'CHAR',   'CHAR' || '(' || DATA_LENGTH || ') ',
                'VARCHAR2',   'VARCHAR2' || '(' || DATA_LENGTH || ') ',
                'NUMBER', 'NUMBER' ||
                   decode ( NVL ( DATA_PRECISION,0),
                            0, ' ',
                            ' (' || DATA_PRECISION ||
                            decode ( NVL ( DATA_SCALE, 0),
                                     0, ') ',
                                     ',' || DATA_SCALE || ') '
                                   )
                          )
              ) ||
       decode ( NULLABLE,
                'N', 'NOT NULL',
                '  '
              ) col2
  from 
        sys.dba_tab_columns
  where 
     table_name=TableName and
     owner=upper('&&1')
  order by column_id;
 ColCount  number(5);
 MaxCol    number(5);
 FillSpace    number(5);
 ColLen    number(5);
begin
 MaxCol:=0;
 for TabRec in TabCur loop
    select max(column_id) into MaxCol from sys.dba_tab_columns
    where table_name=TabRec.table_name and
          owner=TabRec.owner;
    dbms_output.put_line('CREATE TABLE '||TabRec.table_name);
    dbms_output.put_line('( ');
    ColCount:=0;
    for ColRec in ColCur(TabRec.table_name) loop
      ColLen:=length(ColRec.col1);
      FillSpace:=40 - ColLen;
      dbms_output.put(ColRec.col1); 
      for i in 1..FillSpace loop
         dbms_output.put(' ');
      end loop;
      dbms_output.put(ColRec.col2);
      ColCount:=ColCount+1;  
      
      if (ColCount < MaxCol) then
         dbms_output.put_line(',');
      else
         dbms_output.put_line(')');
      end if;
    end loop;
    dbms_output.put_line('TABLESPACE '||TabRec.tablespace_name);
    dbms_output.put_line('PCTFREE '||TabRec.pct_free);
    dbms_output.put_line('PCTUSED '||TabRec.pct_used);
    dbms_output.put_line('STORAGE ( ');
    dbms_output.put_line('  INITIAL     '||TabRec.initial_extent);
    dbms_output.put_line('  NEXT        '||TabRec.next_extent);
    dbms_output.put_line('  PCTINCREASE '||TabRec.pct_increase);
    dbms_output.put_line(' )');
    dbms_output.put_line('PARALLEL '||TabRec.degree);
    dbms_output.put_line('/');
 end loop;
end;
/
