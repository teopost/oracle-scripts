CREATE OR REPLACE function fn_gen_inserts
(
  p_sql                        clob, 
  p_new_owner_name             varchar2,
  p_new_table_name             varchar2
)
return clob
is
  l_cur                        number;
  l_sql                        clob := p_sql;
  l_ret                        number;
  l_col_cnt                    number;
  l_rec_tab                    dbms_sql.desc_tab;

  l_separator                  char(1) := '!';
  l_clob                       clob;
  l_clob_line                  clob;
  l_clob_ins                   clob;
  l_clob_all                   clob;
  l_line                       clob := '-----------------------------------';

  cons_date_frm                varchar2(32) := 'DD.MM.YYYY HH24:MI:SS';
  cons_timestamp_frm           varchar2(32) := 'DD.MM.YYYY HH24:MI:SSXFF';
  cons_timestamp_wtz_frm       varchar2(32) := 'DD.MM.YYYY HH24:MI:SSXFF TZR';

  cons_varchar2_code           number := 1;
  cons_nvarchar2_code          number := 1;
  cons_number_code             number := 2;
  cons_float_code              number := 2;
  cons_long_code               number := 8;
  cons_date_code               number := 12;
  cons_binary_float_code       number := 100;
  cons_binary_double_code      number := 101;
  cons_timestamp_code          number := 180;
  cons_timestamp_wtz_code      number := 181;
  cons_timestamp_lwtz_code     number := 231;
  cons_interval_ytm_code       number := 182;
  cons_interval_dts_code       number := 183;
  cons_raw_code                number := 23;
  cons_long_raw_code           number := 24;
  cons_rowid_code              number := 11;
  cons_urowid_code             number := 208;
  cons_char_code               number := 96;
  cons_nchar_code              number := 96;
  cons_clob_code               number := 112;
  cons_nclob_code              number := 112;
  cons_blob_code               number := 113;
  cons_bfile_code              number := 114;

  -------------------------------------
  -- Supported types
  -------------------------------------
  l_varchar2_col                varchar2(32767); --1
  l_number_col                  number;          --2
  --l_long_col                    long;          --8 - not supported
  l_date_col                    date;            --12
  --l_raw_col                     raw(2000);     --23 - not supported
  l_rowid_col                   rowid;           --69
  l_char_col                    char(2000);      --96
  l_binary_float_col            binary_float;    --100
  l_binary_double_col           binary_double;   --101
  l_clob_col                    clob;            --112
  l_timestamp_col               timestamp(9);    --180
  l_timestamp_wtz_col           timestamp(9) with time zone;    --181
  l_interval_ytm_col            interval year(9) to month;      --182
  l_interval_dts_col            interval day(9) to second(2);   --183
  l_urowid_col                  urowid;                         --208
  l_timestamp_wltz_col          timestamp with local time zone; --231
  --l_nchar_col                   nchar(2000); --96 the same as char
  --l_nclob_col                   nclob; --112 the same as clob
  --l_blob_col - not supported
  --l_bfile_col - not supported
  --l_long_raw_col - not supported

  procedure print_rec(rec in dbms_sql.desc_rec) is
  begin
    l_clob_all := l_clob_all||chr(10)||
      'col_type            =    ' || rec.col_type||chr(10)||
      'col_maxlen          =    ' || rec.col_max_len||chr(10)||
      'col_name            =    ' || rec.col_name||chr(10)||
      'col_name_len        =    ' || rec.col_name_len||chr(10)||
      'col_schema_name     =    ' || rec.col_schema_name||chr(10)||
      'col_schema_name_len =    ' || rec.col_schema_name_len||chr(10)||
      'col_precision       =    ' || rec.col_precision||chr(10)||
      'col_scale           =    ' || rec.col_scale||chr(10)||
      'col_null_ok         =    ';

    if (rec.col_null_ok) then
      l_clob_all := l_clob_all||'true'||chr(10);
    else
      l_clob_all := l_clob_all||'false'||chr(10);
    end if;
  end;  
begin
  ---------------------------------------
  -- INSERT - header generation
  ---------------------------------------
  l_clob_all := 
  'set define off'||chr(10)||
  'declare'||chr(10)||
  '  type   t_clob is table of clob index by binary_integer;'||chr(10)||
  '  l_clob t_clob;'||chr(10)||
  '  type   t_varchar2 is table of varchar2(64) index by binary_integer;'||chr(10)||
  '  l_varchar2 t_varchar2;'||chr(10)||
  'begin'||chr(10)||
  '/*'||chr(10);

  ---------------------------------------
  -- Introduction
  ---------------------------------------
  l_clob_all := l_clob_all||l_line||chr(10)||'Parsing query:'||chr(10)||l_sql||chr(10);

  ---------------------------------------
  -- Open parse cursor
  ---------------------------------------
  l_cur := dbms_sql.open_cursor;
  dbms_sql.parse(l_cur, l_sql, dbms_sql.native);

  ---------------------------------------
  -- Describe columns
  ---------------------------------------
  l_clob_all := l_clob_all||l_line||chr(10)||'Describe columns:'||chr(10);

  dbms_sql.describe_columns(l_cur, l_col_cnt, l_rec_tab);

  for i in 1..l_rec_tab.count
  loop
    print_rec(l_rec_tab(i));
  end loop;

  l_clob_all := l_clob_all||chr(10)||
            '*/'||chr(10)||
            '  '||chr(10)||l_line||chr(10)||
            '  -- start generation of records'||chr(10)||
            '  '||l_line||chr(10);

  ---------------------------------------
  -- Define columns
  ---------------------------------------
  for i in 1..l_rec_tab.count
  loop
    if    l_rec_tab(i).col_type = cons_varchar2_code then --varchar2
      dbms_sql.define_column(l_cur, i, l_varchar2_col, l_rec_tab(i).col_max_len); 
    elsif l_rec_tab(i).col_type = cons_number_code then --number
      dbms_sql.define_column(l_cur, i, l_number_col); 
    --elsif l_rec_tab(i).col_type = cons_long_code then --long
    --  dbms_sql.define_column_long(l_cur, i); 
    elsif l_rec_tab(i).col_type = cons_date_code then --date
      dbms_sql.define_column(l_cur, i, l_date_col); 
    elsif l_rec_tab(i).col_type = cons_binary_float_code then --binary_float
      dbms_sql.define_column(l_cur, i, l_binary_float_col); 
    elsif l_rec_tab(i).col_type = cons_binary_double_code then --binary_double
      dbms_sql.define_column(l_cur, i, l_binary_double_col); 
--    elsif l_rec_tab(i).col_type = cons_raw_code then --raw
--      dbms_sql.define_column_raw(l_cur, i, l_raw_col, l_rec_tab(i).col_max_len); 
    elsif l_rec_tab(i).col_type = cons_rowid_code then  --rowid
      dbms_sql.define_column_rowid(l_cur, i, l_rowid_col); 
    elsif l_rec_tab(i).col_type = cons_char_code then  --char
      dbms_sql.define_column_char(l_cur, i, l_char_col, l_rec_tab(i).col_max_len); 
    elsif l_rec_tab(i).col_type = cons_clob_code then --clob
      dbms_sql.define_column(l_cur, i, l_clob_col); 
    elsif l_rec_tab(i).col_type = cons_timestamp_code then --timestamp
      dbms_sql.define_column(l_cur, i, l_timestamp_col); 
    elsif l_rec_tab(i).col_type = cons_timestamp_wtz_code then --timestamp with time zone
      dbms_sql.define_column(l_cur, i, l_timestamp_wtz_col); 
    elsif l_rec_tab(i).col_type = cons_rowid_code then --urowid
      dbms_sql.define_column(l_cur, i, l_urowid_col); 
    elsif l_rec_tab(i).col_type = cons_timestamp_lwtz_code then --timestamp with local time zone
      dbms_sql.define_column(l_cur, i, l_timestamp_wltz_col); 
    elsif l_rec_tab(i).col_type = cons_interval_ytm_code then --interval year to month
      dbms_sql.define_column(l_cur, i, l_interval_ytm_col); 
    elsif l_rec_tab(i).col_type = cons_interval_dts_code then --interval day to second
      dbms_sql.define_column(l_cur, i, l_interval_dts_col); 
    elsif l_rec_tab(i).col_type = cons_urowid_code then --urowid
      dbms_sql.define_column(l_cur, i, l_urowid_col); 
    else
      raise_application_error(-20001, 'Column: '||l_rec_tab(i).col_name||chr(10)||
                                      'Type not supported: '||l_rec_tab(i).col_type);
      --not supported
    end if;
  end loop;

  ---------------------------------------
  -- Execute cursor
  ---------------------------------------
  l_ret := dbms_sql.execute(l_cur);

  ---------------------------------------
  -- Fetch rows
  ---------------------------------------
  loop
    l_ret := dbms_sql.fetch_rows(l_cur);
    exit when l_ret = 0;

    ---------------------------------------
    -- Building INSERT - build column declarations
    ---------------------------------------
    l_clob_line := '';

    for i in 1..l_rec_tab.count
    loop
      if    l_rec_tab(i).col_type = cons_varchar2_code then --varchar2
        dbms_sql.column_value(l_cur, i, l_varchar2_col); 
        l_clob := l_varchar2_col;
      elsif l_rec_tab(i).col_type = cons_number_code then --number
        dbms_sql.column_value(l_cur, i, l_number_col); 
        l_clob := to_char(l_number_col);
--      elsif l_rec_tab(i).col_type = cons_long_code then --long
--        dbms_sql.column_value(l_cur, i, l_long_col); 
--        l_clob := l_long_col;
      elsif l_rec_tab(i).col_type = cons_date_code then --date
        dbms_sql.column_value(l_cur, i, l_date_col); 
        l_clob := to_char(l_date_col, cons_date_frm);
      elsif l_rec_tab(i).col_type = cons_binary_float_code then --binary_float
        dbms_sql.column_value(l_cur, i, l_binary_float_col); 
        l_clob := to_char(l_binary_float_col);
      elsif l_rec_tab(i).col_type = cons_binary_double_code then --binary_double
        dbms_sql.column_value(l_cur, i, l_binary_double_col); 
        l_clob := to_char(l_binary_double_col);
--      elsif l_rec_tab(i).col_type = cons_raw_code then --raw
--        dbms_sql.column_value(l_cur, i, l_raw_col); 
--        l_clob := to_char(l_raw_col);
      elsif l_rec_tab(i).col_type = cons_rowid_code then --rowid
        dbms_sql.column_value(l_cur, i, l_rowid_col); 
        l_clob := to_char(l_rowid_col);
      elsif l_rec_tab(i).col_type = cons_char_code then --char
        dbms_sql.column_value_char(l_cur, i, l_char_col); 
        l_clob := substr(l_char_col, 1, l_rec_tab(i).col_max_len - 1);
      elsif l_rec_tab(i).col_type = cons_clob_code then --clob
        dbms_sql.column_value(l_cur, i, l_clob_col); 
        l_clob := l_clob_col;
      elsif l_rec_tab(i).col_type = cons_timestamp_code then --timestamp
        dbms_sql.column_value(l_cur, i, l_timestamp_col); 
        l_clob := to_char(l_timestamp_col, cons_timestamp_frm);
      elsif l_rec_tab(i).col_type = cons_timestamp_wtz_code then --timestamp with time zone
        dbms_sql.column_value(l_cur, i, l_timestamp_wtz_col); 
        l_clob := to_char(l_timestamp_wtz_col, cons_timestamp_wtz_frm);
      elsif l_rec_tab(i).col_type = cons_interval_ytm_code then --interval year to month
        dbms_sql.column_value(l_cur, i, l_interval_ytm_col); 
        l_clob := to_char(l_interval_ytm_col);
      elsif l_rec_tab(i).col_type = cons_interval_dts_code then --interval day to second
        dbms_sql.column_value(l_cur, i, l_interval_dts_col); 
        l_clob := to_char(l_interval_dts_col);
      elsif l_rec_tab(i).col_type = cons_urowid_code then --urowid
        dbms_sql.column_value(l_cur, i, l_urowid_col); 
        l_clob := to_char(l_urowid_col);
      elsif l_rec_tab(i).col_type = cons_timestamp_lwtz_code then --timestamp with local time zone
        dbms_sql.column_value(l_cur, i, l_timestamp_wltz_col); 
        l_clob := to_char(l_timestamp_wltz_col, cons_timestamp_wtz_frm);
      end if;

      if l_rec_tab(i).col_type in (cons_clob_code, cons_char_code, cons_varchar2_code) then
        l_clob_line := l_clob_line||'  l_clob('||to_char(i)||') :=q'''||l_separator||l_clob||l_separator||''';'||chr(10);
      else
        l_clob_line := l_clob_line||'  l_varchar2('||to_char(i)||') :=q'''||l_separator||l_clob||l_separator||''';'||chr(10);
      end if;
    end loop;

    l_clob_all := l_clob_all||chr(10)||l_clob_line;

    ---------------------------------------
    -- Building INSERT - build column list
    ---------------------------------------
    l_clob_all := l_clob_all||chr(10)||
              '  insert into '||p_new_owner_name||'.'||p_new_table_name||chr(10)||
              '  ('||chr(10);

    for i in 1..l_rec_tab.count
    loop
      if i = 1 then
        l_clob_all := l_clob_all||'     '||l_rec_tab(i).col_name||chr(10);
      else  
        l_clob_all := l_clob_all||'    ,'||l_rec_tab(i).col_name||chr(10);
      end if;  
    end loop;    

    l_clob_all := l_clob_all||
              '  )'||chr(10)||
              '  values'||chr(10)||
              '  ('||chr(10);

    ---------------------------------------
    -- Building INSERT - build values
    ---------------------------------------
    for i in 1..l_rec_tab.count
    loop
      if i!=1 then
        l_clob_all := l_clob_all||'    ,';
      else  
        l_clob_all := l_clob_all||'     ';
      end if;

      if l_rec_tab(i).col_type = cons_number_code then --number
        l_clob_all := l_clob_all||'to_number(l_varchar2('||to_char(i)||'))'||chr(10);
--      elsif l_rec_tab(i).col_type = cons_long_code then --long
--        l_clob := l_long_col;
      elsif l_rec_tab(i).col_type = cons_clob_code then --clob
        l_clob_all := l_clob_all||'l_clob('||to_char(i)||')'||chr(10);
      elsif l_rec_tab(i).col_type = cons_char_code then --timestamp with local time zone
        l_clob_all := l_clob_all||'to_char(l_clob('||to_char(i)||'))'||chr(10);
      elsif l_rec_tab(i).col_type = cons_varchar2_code then --timestamp with local time zone
        l_clob_all := l_clob_all||'to_char(l_clob('||to_char(i)||'))'||chr(10);
      elsif l_rec_tab(i).col_type = cons_date_code then --date
        l_clob_all := l_clob_all||'to_date(l_varchar2('||to_char(i)||'),'''||cons_date_frm||''')'||chr(10);
      elsif l_rec_tab(i).col_type = cons_timestamp_code then --timestamp
        l_clob_all := l_clob_all||'to_timestamp(l_varchar2('||to_char(i)||'),'''||cons_timestamp_frm||''')'||chr(10);
      elsif l_rec_tab(i).col_type = cons_timestamp_wtz_code then --timestamp with time zone
        l_clob_all := l_clob_all||'to_timestamp_tz(l_varchar2('||to_char(i)||'),'''||cons_timestamp_wtz_frm||''')'||chr(10);
      elsif l_rec_tab(i).col_type = cons_interval_ytm_code then --interval year to month
        l_clob_all := l_clob_all||'to_yminterval(l_varchar2('||to_char(i)||'))'||chr(10);
      elsif l_rec_tab(i).col_type = cons_interval_dts_code then --interval day to second
        l_clob_all := l_clob_all||'to_dsinterval(l_varchar2('||to_char(i)||'))'||chr(10);
      elsif l_rec_tab(i).col_type = cons_timestamp_lwtz_code then --timestamp with local time zone
        l_clob_all := l_clob_all||'to_timestamp_tz(l_varchar2('||to_char(i)||'),'''||cons_timestamp_wtz_frm||''')'||chr(10);
      else  
        l_clob_all := l_clob_all||'l_varchar2('||to_char(i)||')'||chr(10);
      end if;  
    end loop; 

    l_clob_all := l_clob_all||'  );'||chr(10);
  end loop;

  ---------------------------------------
  -- Building INSERT - end of code
  ---------------------------------------
  l_clob_all := l_clob_all||chr(10)||'end;';
  l_clob_all := l_clob_all||chr(10)||'/';

  ---------------------------------------
  -- Close cursor
  ---------------------------------------
  dbms_sql.close_cursor(l_cur);

  return l_clob_all;
end;
/
