/*
BIJU'S ORACLE PAGE 
    
cr_index.sql 
 
Purpose

Index creation script generated based on the base table owner and name passed in as parameter. Wild character may be used (%) in the paramter list. Screen output saved at /tmp/crindex.sql

Parameters

1. Table Owner (Wild character % may be used) 
2. Table Name (Wild character % may be used) 
Command Line

SQL> @cr_index tableowner tablename

The Script

NOTA: ESEGUIRE DA SYSTEM

*/
rem
rem Script to create index creation DDL
rem
rem Biju Thomas
rem
rem Provide the owner name and table name along with the script with a space
rem
set serveroutput on feedback off verify off pages 0
/*
Inserire il nome utente e il nome della tabella
*/
spool c:\temp\crindex.sql
declare
     wuser varchar2 (15) := '&1';
     wtable varchar2 (30) := '&2';
     /* Indexes */
     cursor cind is
     select owner, table_owner, table_name, index_name, ini_trans, max_trans,
            tablespace_name, initial_extent/1024 initial_extent, 
            next_extent/1024 next_extent, min_extents, max_extents, 
            pct_increase, decode(uniqueness,'UNIQUE','UNIQUE') unq
     from dba_indexes
     where table_owner like upper(wuser) and
           table_name like upper(wtable);
     /* Index columns */
     cursor ccol (o in varchar2, t in varchar2, i in varchar2) is
     select decode(column_position,1,'(',',')||
               rpad(column_name,40) cl
     from dba_ind_columns
     where table_name = upper(t) and
           index_name = upper(i) and
           index_owner = upper(o)
     order by column_position;
     wcount number := 0;
begin
  dbms_output.enable(100000);
  for rind in cind loop
     wcount := wcount + 1;
       dbms_output.put_line('create '||rind.unq||' index '|| rind.owner || '.' || rind.index_name||' on  '||rind.table_owner||'.'|| rind.table_name);
       for rcol in ccol (rind.owner, rind.table_name, rind.index_name) loop
         dbms_output.put_line(rcol.cl);
       end loop;
       dbms_output.put_line(') initrans ' || rind.ini_trans || ' maxtrans ' || rind.max_trans);
       dbms_output.put_line('tablespace ' || rind.tablespace_name);
       dbms_output.put_line('storage (initial ' || rind.initial_extent || 'K next ' || rind.next_extent || 'K pctincrease ' || rind.pct_increase);
       dbms_output.put_line('minextents ' || rind.min_extents || ' maxextents '
|| rind.max_extents || ' )');
       dbms_output.put_line('/');
     end loop;
     if wcount =0 then
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
prompt Output saved at c:\temp\crindex.sql
  