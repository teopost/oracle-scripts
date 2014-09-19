SET echo OFF heading off verify off feedback off pages 0 lines 80 trims on
spool c:\temp\crea_snap.sql
set serveroutput on 
declare
     /*  Tables */
     cursor ctabs IS 
     select tname from tab where tabtype = 'TABLE';

     /* Columns */
     cursor ccols (t in varchar2)
     is select decode(column_id,1,' ',',')
          ||rpad(column_name,40)  cstr
     from user_tab_columns
     where table_name = upper(t)
     order by column_id;
  
  begin
    dbms_output.enable(1000000);
    for rtabs in ctabs loop
      dbms_output.put_line('create materialized view ' || rtabs.tname);
      dbms_output.put_line('on prebuilt table');
      dbms_output.put_line('refresh force on demand');
      dbms_output.put_line('as');
      dbms_output.put_line('select');
      for rcols  in ccols (rtabs.tname) loop
         dbms_output.put_line(rcols.cstr);
      end loop;
      dbms_output.put_line('from');
      dbms_output.put_line(rtabs.tname||'@dwsource');
      dbms_output.put_line('/');
    end loop;
  end;
/

declare
     /*  Tables */
     cursor ctabs IS 
     select tname from tab where tabtype = 'TABLE';
 
  begin
    dbms_output.enable(1000000);
    for rtabs in ctabs loop
      dbms_output.put_line('exec dbms_snapshot.refresh('''|| rtabs.tname ||''');');
    END LOOP;
  end;
/

declare
     /*  Tables */
     cursor ctabs IS 
     select tname from tab where tabtype = 'TABLE';
 
  begin
    dbms_output.enable(1000000);
    for rtabs in ctabs loop
      dbms_output.put_line('drop snapshot '|| rtabs.tname || ';');
    END LOOP;
  end;
/
set echo ON serveroutput off feedback on verify on pages 999
spool off