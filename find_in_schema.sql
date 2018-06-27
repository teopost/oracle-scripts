create or replace function find_in_schema(val varchar2) 
return varchar2 is
  v_old_table user_tab_columns.table_name%type;
  v_where     Varchar2(4000);
  v_first_col boolean := true;
  type rc     is ref cursor;
  c           rc;
  v_rowid     varchar2(20);

begin
  for r in (
    select
      t.*
    from
      user_tab_cols t, user_all_tables a
    where t.table_name = a.table_name
      and t.data_type like '%CHAR%'
    order by t.table_name) loop
 
    if v_old_table is null then
      v_old_table := r.table_name;
    end if;
 
    if v_old_table <> r.table_name then
      v_first_col := true;
 
      -- dbms_output.put_line('searching ' || v_old_table);
 
      open c for 'select rowid from "' || v_old_table || '" ' || v_where;
 
      fetch c into v_rowid;
      loop
        exit when c%notfound;
        dbms_output.put_line('  rowid: ' || v_rowid || ' in ' || v_old_table);
        fetch c into v_rowid;
      end loop;
 
      v_old_table := r.table_name;
    end if;
 
    if v_first_col then
      v_where := ' where ' || r.column_name || ' like ''%' || val || '%''';
      v_first_col := false;
    else
      v_where := v_where || ' or ' || r.column_name || ' like ''%' || val || '%''';
    end if;
 
  end loop;
  return 'Success';
end;
/
