/*
BIJU'S ORACLE PAGE 
    
cr_table.sql 
 
Purpose

Table creation script generated based on the table name passed in as parameter.
Wild characters may be used (%) in the parameter list. 
Screen output saved at c:\temp\crtable.sql

Parameters

1. Table Owner (Wild character % may be used) 
2. Table Name (Wild character % may be used) 
Command Line

SQL> @cr_table tableowner tablename

The Script
NOTA 
ESEGUIRE DA SYSTEM
IL PRESENTE SCRIPT NON GENERA EVENTUALI DEFAULT O CHECK CONSTRAINTS
*/

rem Generate table creation script
rem
rem Biju Thomas
rem
rem Pass owner name and table name as parameters
rem
set heading off verify off feedback off pages 0 lines 80 trims on
spool c:\temp\crtable.sql
set serveroutput on 
declare
     wuser varchar2 (15) := '&1';
     wtable varchar2 (30) := '&2';
     /*  Tables */
     cursor ctabs is select table_name, owner, tablespace_name,
          initial_extent/1024 initial_extent, pct_free, ini_trans, 
          next_extent/1024 next_extent, pct_increase, pct_used, max_trans,
          min_extents, max_extents
     from all_tables where
     owner like upper(wuser)
     and table_name like upper(wtable);
     /* Columns */
     cursor ccols (o in varchar2, t in varchar2)
     is select decode(column_id,1,'(',',')
          ||rpad(column_name,40)
          ||rpad(data_type,10)
          ||rpad(
            decode(data_type,'DATE'    ,' '
                            ,'LONG'    ,' '
                            ,'LONG RAW',' '
                            ,'RAW'     ,decode(data_length,null,null
                                                    ,'('||data_length||')')
                            ,'CHAR'    ,decode(data_length,null,null
                                                    ,'('||data_length||')')
                            ,'VARCHAR' ,decode(data_length,null,null
                                                    ,'('||data_length||')')
                            ,'VARCHAR2',decode(data_length,null,null
                                                    ,'('||data_length||')')
                            ,'NUMBER'  ,decode(data_precision,null,'   '
                                                ,'('||data_precision||
     decode(data_scale,null,null,','||data_scale)||')'),'unknown'),8,' ') cstr
     from all_tab_columns
     where table_name = upper(t)
     and   owner = upper(o)
     order by column_id;
     wcount number := 0;
  begin
    dbms_output.enable(100000);
    for rtabs in ctabs loop
      wcount := wcount + 1;
      dbms_output.put_line('create table ' || rtabs.owner || '.' || rtabs.table_name);
      for rcols  in ccols (rtabs.owner, rtabs.table_name) loop
         dbms_output.put_line(rcols.cstr);
      end loop;
      dbms_output.put_line(') pctfree ' || rtabs.pct_free || ' pctused ' || rtabs.pct_used);
      dbms_output.put_line('initrans ' || rtabs.ini_trans || ' maxtrans ' || rtabs.max_trans);
      dbms_output.put_line('tablespace ' || rtabs.tablespace_name);
      dbms_output.put_line('storage (initial ' || rtabs.initial_extent || 'K next ' || rtabs.next_extent || 'K pctincrease ' || rtabs.pct_increase);
      dbms_output.put_line('minextents ' || rtabs.min_extents || ' maxextents ' || rtabs.max_extents || ' )');
      dbms_output.put_line('/');
    end loop;
    if wcount = 0 then
      dbms_output.put_line('******************************************************');
      dbms_output.put_line('*                                                    *');
      dbms_output.put_line('* Plese Verify Input Parameters... No Matches Found! *');
      dbms_output.put_line('*                                                    *');
      dbms_output.put_line('******************************************************');
    end if;
  end;
/
set serveroutput off feedback on verify on pages 999
spool off
prompt
prompt Output saved at /tmp/crtable.sql
  

 