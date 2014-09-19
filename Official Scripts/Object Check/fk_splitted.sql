-- Creazione tabella temporanea
-- ----------------------------
DROP TABLE test;

create table test
as
select column_name, constraint_name , table_name from  user_cons_columns
where constraint_name in (select constraint_name from user_constraints where constraint_type = 'R')
;

-- Aggiunta campo della nome pk relativa
-- -------------------------------------
alter table test add (pkname varchar(30));

-- Aggiunta campo flag di pk
-- -------------------------
alter table test add (pkflag number(1));

-- Rimuovo le fk con un solo campo 
-- -------------------------------
BEGIN  
  LOOP
    DELETE FROM test
     WHERE ROWID IN (SELECT MIN (ROWID)
                       FROM test
                      GROUP BY constraint_name
                     HAVING COUNT (*) = 1);
    EXIT WHEN SQL%NOTFOUND;
  END LOOP;
  COMMIT;
END;
/

--- --------------

-- Aggiunge il nome della pk

declare
  v_table_name      varchar2(30);
  v_column_name     varchar2(30);
  v_constraint_name varchar2(30);
  v_pkname          varchar2(30);
  ispk              number(30);
  
  cursor c1 is
  select column_name, table_name, constraint_name
  from test;
  
  begin
  
  open c1;
  loop
      fetch c1 into v_column_name, v_table_name, v_constraint_name;
      exit when c1%NOTFOUND;
      begin
	select constraint_name into v_pkname 
	from user_constraints 
	where constraint_type = 'P' 
	and table_name = v_table_name;

	update test
	set pkname = v_pkname
	where table_name = v_table_name;

	--dbms_output.put_line(v_pkname ||'-'||v_table_name);
      end;
  end loop;
  close c1;
end;
/

-- -------------------

-- aggiornamento flag di pk
set serveroutput on
declare
  v_table_name      varchar2(30);
  v_column_name     varchar2(30);
  v_constraint_name varchar2(30);
  v_pkname          varchar2(30);
  ispk              number(30);
  
  cursor c1 is
  select column_name, table_name, constraint_name, pkname
  from test
  ;
  
  begin
  dbms_output.enable(1000000);
  open c1;
  loop
      fetch c1 into v_column_name, v_table_name, v_constraint_name, v_pkname;
      exit when c1%NOTFOUND;
      begin
	update test a
	set a.pkflag = 1
	where a.table_name = v_table_name
	and a.column_name in (
			select column_name 
			from user_cons_columns 
			where  constraint_name = v_pkname
			and table_name = v_table_name
			)
	;
	-- dbms_output.put_line(v_column_name||' - '||v_table_name||' - '||v_pkname);
      end;
  end loop;
  close c1;
end;
/


-- report
set serveroutput on
declare
  v_table_name      varchar2(30);
  v_column_name     varchar2(30);
  v_constraint_name varchar2(30);
  v_pkname          varchar2(30);
  v_pkflag          number(1);
  v_total_rows      number(30);
  v_pk_rows         number(30);
  v_no_pk_rows      number(30);
  a                 number(1);
  
  cursor c1 is
  select column_name, table_name, constraint_name, pkname, pkflag
  from test
  ;
  
  begin
  dbms_output.enable(1000000);
  open c1;
  loop
      fetch c1 into v_column_name, v_table_name, v_constraint_name, v_pkname, v_pkflag;
      exit when c1%NOTFOUND;
      begin
	select count(*) into v_total_rows
	from test 
	where constraint_name = v_constraint_name;
	
	select count(*) into v_pk_rows
	from test 
	where constraint_name = v_constraint_name
	and pkflag is not null;

	select count(*) into v_no_pk_rows
	from test 
	where constraint_name = v_constraint_name
	and pkflag is null;
	
	if (v_total_rows = v_pk_rows) or (v_total_rows = v_no_pk_rows) then
		a := 0;
	else
		dbms_output.put_line('FK Name: '||v_constraint_name ||', '|| 'No.of fields:'||v_total_rows||', '||'PK Fields:'|| v_pk_rows||', '||'No key fields:'|| v_no_pk_rows);
	end if;
      end;
  end loop;
  close c1;
end;
/

drop table test;