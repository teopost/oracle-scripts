CREATE OR REPLACE procedure ar_move_tablespace (dest_tablespace varchar2)
is
db_target   user_tables.table_name%type;

cursor nobuonetabelle
is
select distinct table_name from user_tab_columns where data_type in ('LONG');

cursor nobuoneindici
is
select distinct index_name from user_indexes where index_type in ('LOB');

cursor stat
is
select 'alter table ' || table_name || ' move tablespace '|| dest_tablespace  STATEMENT
from
 user_tables
where tablespace_name !=  dest_tablespace 
and table_name not in (select distinct table_name from user_tab_columns where data_type in ('LONG'));

cursor rebindx
is
select 'alter index ' || index_name || ' rebuild tablespace '|| dest_tablespace  STATEMENT
from
 user_indexes
where tablespace_name !=  dest_tablespace
and index_name not in (select distinct index_name from user_indexes where index_type  in ('LOB'));

begin

for cur_row in stat loop
 begin
 execute immediate cur_row.STATEMENT;
 null;
   exception when others then
  raise_application_error (-20101, sqlerrm || '*** Errore: Spostamento Tablespace : ' ||cur_row.STATEMENT);
 end;
end loop;

for cur_indx in rebindx loop
 begin
  execute immediate cur_indx.STATEMENT;
  --null;
   exception when others then
  raise_application_error (-20101, sqlerrm || '*** Errore: Spostamento Indice : ' ||cur_indx.STATEMENT);
 end;
end loop;

for nogoodtable in nobuonetabelle loop
  dbms_output.put_line ('Non riesco a spostare la tabella.:'|| nogoodtable.table_name );
end loop;


for nogoodindex in nobuoneindici loop
  dbms_output.put_line ('Non riesco a spostare l''indice.:'|| nogoodindex.index_name );
end loop;

end;
/


