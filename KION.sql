CREATE OR REPLACE package DBA as
  procedure help;
  procedure ckname  (nome_tabella in varchar2 default null);
  procedure db_check;
  procedure autovalid;
  procedure show_all_fk(nome_tabella in varchar2 default null);
  procedure show_synonyms(nome_tabella in varchar2 default null);
  procedure set_foreign(stato in varchar2 default null);
  procedure set_trigger(stato in varchar2 default null);
  procedure drop_fk (ObjectName  in varchar2);
  procedure drop_table(tabella in varchar2);
  procedure drop_procedure(procedura in varchar2);
end DBA;
/
CREATE OR REPLACE PACKAGE BODY DBA AS
--------------------------------------------------------------------------------
-- PROCEDURE help
--------------------------------------------------------------------------------
PROCEDURE nl
AS
BEGIN
DBMS_OUTPUT.put_line (chr(0));
END nl;

PROCEDURE help AS
BEGIN
  dbms_output.enable (1000000);
  nl;
  dbms_output.put_line ('Package Name : KION');
  dbms_output.put_line ('===================');
  dbms_output.put_line ('Descrizione : Package di utility KION - (C)opyright KION srl');
  nl;
  dbms_output.put_line ('rel.1.0 26 Febbraio 2003, S. Teodorani - Creata');
  nl;
  dbms_output.put_line ('Procedure          Descrizione');
  dbms_output.put_line ('------------------ ------------------------------');
  dbms_output.put_line ('help               Questa schermata');
  dbms_output.put_line ('ckname             Rigenera i constraints in base alla DBA_TABLEID');
  dbms_output.put_line ('db_check           Verifica la consistenza del db');
  dbms_output.put_line ('autovalid          Rivalida gli oggetti invalidi');
  dbms_output.put_line ('show_all_fk        Rigenera le foreign-key da e verso una tabella');
  dbms_output.put_line ('show_synonyms      Rigenera tutti i sinonimi dello schema');
  dbms_output.put_line ('set_foreign        Abilita o disabilita le foreign-key di uno schema');
  dbms_output.put_line ('set_trigger        Abilita o disabilita i trigger di uno schema');
  dbms_output.put_line ('drop_fk            Elimina una fk o un check constraint solo se esistenti');
  dbms_output.put_line ('drop_table         Elimina una tabella solo se esistente');
  dbms_output.put_line ('drop_procedure     Elimina una procedura solo se esistente');
  return;
END help;
--------------------------------------------------------------------------------
-- PROCEDURE ckname
--------------------------------------------------------------------------------
PROCEDURE ckname (nome_tabella IN VARCHAR2 DEFAULT NULL)
IS
BEGIN -- Begin Procedure
Declare
Type sql_buffer Is Table of varchar2(2000)
     Index by BINARY_INTEGER;
sql_add        sql_buffer;
sql_drop       sql_buffer;
sql_col        sql_buffer;
sql_table      sql_buffer;
old_cons       sql_buffer;
d1             varchar2(40);
b1             varchar2(100);
b2             varchar2(1000);
b3             varchar2(100);
b4             varchar2(100);
b5             number;
b6             varchar2(100);
k              number;
t1             varchar2(100);
t2             varchar2(100);
t3             varchar2(100);
fl             number;
length_comment number;
cursor_id_drop number;
cursor_id_add  number;
ret_val        number;
i 	       number;
x	       number;
cursor c1 (TABELLA in varchar2) is
select   a.constraint_name  a1,
         a.search_condition a2,
         decode(status,'DISABLED','DISABLE','') a3,
         upper(ltrim(rtrim(b.column_name)))||'_'||ltrim(rtrim(d.id)) a4,
         nvl(length(ltrim(rtrim(d.id))),0) a5,
         upper(ltrim(rtrim(b.column_name)))  a6
from 	 user_constraints a,
	 user_tab_columns b,
	 user_cons_columns c,
         dba_tableid	   d
where 	 a.table_name = upper(TABELLA)
and 	 a.table_name = b.table_name
and 	 a.table_name = c.table_name
and	 c.column_name = b.column_name
and 	 c.constraint_name = a.constraint_name
and	 a.table_name = d.table_name
and	 a.constraint_type='C'
and 	 nvl(length(ltrim(rtrim(d.id))),0) != 0
order by b.column_id;
cursor c2 is
select 	 tname x1
from 	 tab
where 	 tabtype = 'TABLE'
and 	 tname like nvl(upper(NOME_TABELLA),'%');
cursor c3 (TABELLA in varchar2, COLONNA in varchar2) is
select  a.column_name      s1,
	b.search_condition s2,
        a.constraint_name  s3
from 	user_cons_columns a,
	user_constraints b
where 	a.table_name = upper(TABELLA)
and 	b.table_name = upper(TABELLA)
and	a.constraint_name = b.constraint_name
and 	a.column_name = upper(COLONNA);
begin
dbms_output.enable(1000000);
open c2;
loop
 fetch c2 into d1;
 exit when c2%NOTFOUND;
 i := 0;
 nl;
 dbms_output.put_line('Tabella: '||d1);
 dbms_output.put_line('----------------------------');
	open c1 (d1);
	loop
	 fetch c1 into b1,b2,b3,b4,b5,b6;
	 exit when c1%NOTFOUND;
	 select count(*) INTO fl
	 from 	user_tab_columns
	 where 	table_name = upper(d1)
	 and 	(
	 		upper(column_name)||' IS NOT NULL' = upper(b2)  -- Per Oracle 7.x
	 	)
	        or
	 	(
	 		'"' || upper(column_name)||'" IS NOT NULL' = upper(b2) -- Per Oracle 8.x (aggiunti doppi apici)
	 	)
	 ;
	 if fl = 0 then
	   i := i + 1;
	   dbms_output.put_line('Rename: '||rpad(b1,25)||' to '||b4);
	   sql_drop(i):= 'alter table '||d1||' drop constraint '||b1;
	   sql_add(i) := 'alter table '||d1||' add constraint '||b4||' check ('|| b2 ||')' || ' ' ||b3;
	   old_cons(i):= b1;
	   sql_col(i) := b6;
	   sql_table(i) := d1;
	 end if;
	end loop;
	if i = 0 then
		dbms_output.put_line('Check Constraints non presenti sulla tabella');
	else
		for x in 1 .. (i) loop
		   cursor_id_drop := dbms_sql.open_cursor;
		   dbms_sql.parse(cursor_id_drop, sql_drop(x), dbms_sql.native);
		   DBMS_OUTPUT.put_line('Eseguo: '|| sql_drop(x));
		   ret_val := dbms_sql.execute(cursor_id_drop);
		   dbms_sql.close_cursor(cursor_id_drop);
		end loop;
		for x in 1 .. (i) loop
		   open c3 (sql_table(x), sql_col(x));
			  k := 0;
			  loop
			    fetch c3 into t1, t2, t3;
			    exit when c3%NOTFOUND;
			     	if upper(t2) not in (upper(sql_col(x))||' IS NOT NULL','"' || upper(sql_col(x))||'" IS NOT NULL') then
			  	    k := k +1;
			  	end if;
		   	  end loop;
		   if k = 0 then
			cursor_id_add := dbms_sql.open_cursor;
		   	dbms_sql.parse(cursor_id_add, sql_add(x), dbms_sql.native);
		   	DBMS_OUTPUT.put_line('Eseguo: '|| sql_add(x));
		   	ret_val := dbms_sql.execute(cursor_id_add);
		   	dbms_sql.close_cursor(cursor_id_add);
		   else
			dbms_output.put_line('Check Constraint '||old_cons(x)|| ' su '||sql_col(x)|| ' rimosso in quanto duplicato');
		   end if;
		   close c3;
		end loop;
	end if;
	close c1;
end loop;
close c2;
end;
END ckname; -- End Procedure
--------------------------------------------------------------------------------
-- PROCEDURE db_check
--------------------------------------------------------------------------------
PROCEDURE DB_CHECK
IS
BEGIN -- Begin Procedure
declare
obj_type      varchar2(13);
obj_name      varchar2(128);
dat_ute_creaz varchar2(30);
cnt_obj_type  varchar2(13);
cnt_obj_num   number;
cursor  invalid_objects is
select 	object_type a1,
	object_name a2
from 	user_objects
where 	status = 'INVALID'
order by 1;
cursor  count_objects is
select 	object_type b1,
	count(*)    b2
from 	user_objects
group by object_type;
begin
dbms_output.enable(1000000);
  select created into dat_ute_creaz
  from all_users where username = USER;
  dbms_output.put_line('Utente '|| USER || ' creato il '||ltrim(rtrim(dat_ute_creaz)));
  -- Oggetti invalidi
  nl;
  open invalid_objects;
  dbms_output.put_line('Oggetti Invalidi');
  dbms_output.put_line(rpad('-',40,'-'));
  loop
    fetch invalid_objects into obj_type, obj_name;
    exit when invalid_objects%NOTFOUND;
          dbms_output.put_line(rpad(ltrim(rtrim(obj_type)),20)||rpad(ltrim(rtrim(obj_name)),50));
  end loop;
  close invalid_objects;
  -- Conteggio oggetti
  nl;
  open count_objects;
  dbms_output.put_line('Conteggio Oggetti');
  dbms_output.put_line(rpad('-',40,'-'));
  loop
    fetch count_objects into cnt_obj_type, cnt_obj_num;
    exit when count_objects%NOTFOUND;
          dbms_output.put_line(rpad(ltrim(rtrim(cnt_obj_type)),20)||rpad(ltrim(rtrim(cnt_obj_num)),50));
  end loop;
  close count_objects;
end;
END; -- End Procedure
--------------------------------------------------------------------------------
-- PROCEDURE Autovalid
--------------------------------------------------------------------------------
PROCEDURE AUTOVALID
IS
BEGIN
	declare
	   sql_statement varchar2(200);
	   cursor_id     number;
	   ret_val       number;
	   also_invalid  number;
	   attempt       number;
	   max_attempt   number;
	begin
	   dbms_output.enable(100000);
	   attempt       := 0;
	   max_attempt   := 8;
	--   dbms_output.put_line(chr(0));
	   dbms_output.put_line('--------------------------------------');
	   dbms_output.put_line('AUTOVALIDAZIONE DEGLI OGGETTI INVALIDI');
	   dbms_output.put_line('--------------------------------------');
--	   dbms_output.put_line(chr(0));
	   loop
	    select 	count(*) into also_invalid
	    from 	user_objects
	    where 	status = 'INVALID';
	    exit when (also_invalid = 0 or attempt = max_attempt);
	
	    attempt := attempt + 1;
	    nl;
	    dbms_output.put_line('Tentativo numero : '||attempt);
	    dbms_output.put_line('----------------------------');
	    for invalid in 
			(select object_type, object_name
					 , decode(object_type,'VIEW',1,'FUNCTION',2,'PROCEDURE',3,'PACKAGE',4,'PACKAGE BODY',5,'TRIGGER',6)
	   		   from user_objects
	   		  where status        = 'INVALID'
				and object_type in ('PACKAGE', 'PACKAGE BODY', 'FUNCTION'
	                       		   ,'PROCEDURE', 'TRIGGER', 'VIEW')
			  order by 3) 
		loop
	      if invalid.object_type = 'PACKAGE BODY' then
	        sql_statement := 'alter package '||invalid.object_name||' compile body';
	      else
	        sql_statement := 'alter '||invalid.object_type||' '||invalid.object_name||' compile';
	      end if;
	      
		  cursor_id := dbms_sql.open_cursor;
	      dbms_sql.parse(cursor_id, sql_statement, dbms_sql.native);
	      ret_val := dbms_sql.execute(cursor_id);
	      dbms_sql.close_cursor(cursor_id);
	      dbms_output.put_line
				(rpad(initcap(invalid.object_type)||' '||invalid.object_name, 32)||' : compilato');
	    end loop;
	   end loop;
	   if attempt = max_attempt then
	                nl;
	   		dbms_output.put_line('ATTENZIONE');
	   		dbms_output.put_line('Dopo '||attempt||' tentativi, alcuni oggetti sono rimasti invalidi.');
	   		dbms_output.put_line('Effettuare una controllo della base dati');
	   else
	   		nl;
	   		dbms_output.put_line('Tutti gli oggetti sono stati compilati con successo dopo '||attempt||' tentativi');
	   end if;
	end;
	END; -- End procedure Autovalid
	--------------------------------------------------------------------------------
	-- PROCEDURE show_all_fk
	--------------------------------------------------------------------------------
	PROCEDURE show_all_fk (nome_tabella IN VARCHAR2 DEFAULT NULL)
	IS
	BEGIN -- Begin Procedure
	declare
	cname varchar2(50);
	cname2 varchar2(50);
	r_user varchar2(50);
	cursor c1 is
	select 	c.constraint_name,
		c.r_constraint_name cname2,
		c.table_name table1,
		r.table_name table2,
	        decode(c.status,'DISABLED','DISABLE',' ') status,
	        decode(c.delete_rule,'CASCADE',' ON DELETE CASCADE ',' ') delete_rule,
		c.r_owner r_user
	from    all_constraints c,
	        all_constraints r
	where   c.constraint_type='R'
	and     c.r_constraint_name = r.constraint_name
	and     c.table_name = upper(NOME_TABELLA)
	and 	c.owner = user
	and 	c.r_owner = r.owner
	union
	select c.constraint_name,c.r_constraint_name cname2,
	       c.table_name table1, r.table_name table2,
	       decode(c.status,'DISABLED','DISABLE',' ') status,
	       decode(c.delete_rule,'CASCADE',' ON DELETE CASCADE ',' ') delete_rule,
	       c.r_owner r_user
	from   user_constraints c,
	       user_constraints r
	where c.constraint_type='R' and
	      c.r_constraint_name = r.constraint_name and
	      r.table_name = upper(NOME_TABELLA);
	cursor c2 is
	select decode(position,1,'(',',')||column_name colname
	from user_cons_columns
	where   constraint_name = cname
	order by position;
	cursor c3 is
	select decode(position,1,'(',',')||column_name refcol
	from all_cons_columns
	where constraint_name = cname2
	and owner = r_user
	order by position;
	begin
	if NOME_TABELLA is null then
	    nl;
	    dbms_output.put_line ('Procedura      : KION.show_all_fk');
	    dbms_output.put_line ('================================');
	    dbms_output.put_line ('Parameter(s)   : 1. Nome Tabella');
	    dbms_output.put_line ('Description    : Rigenera tutte le foreign-key da e verso la tabella passata');
	    dbms_output.put_line ('Sintassi       : exec KION.show_all_fk(''NOME_TABELLA'')');
	   return;
	end if;
	dbms_output.enable(1000000);
	for q1 in c1 loop
	 cname := q1.constraint_name;
	 cname2 := q1.cname2;
	 r_user := q1.r_user;
	 dbms_output.put_line('ALTER TABLE '||q1.table1||' ADD CONSTRAINT '||cname);
	 dbms_output.put('FOREIGN KEY ');
	 for q2 in c2 loop
	   dbms_output.put(q2.colname);
	 end loop;
	 dbms_output.put_line(')');
	 dbms_output.put('REFERENCES '||q1.table2||' ');
	 for q3 in c3 loop
	   dbms_output.put(q3.refcol);
	 end loop;
	 dbms_output.put_line(') '||q1.delete_rule||q1.status);
	 dbms_output.put_line('/');
	end loop;
	end;
	end; -- End Procedure
	--------------------------------------------------------------------------------
	-- PROCEDURE show_synonyms
	--------------------------------------------------------------------------------
	PROCEDURE show_synonyms (nome_tabella in varchar2 default null)
	AS
	BEGIN
	dbms_output.enable (1000000);
	declare
		priv_syn 	varchar2(500);
	cursor c1 is
		select '/* Sinonimi verso utente societario */' a1
		from dual
		union all
		select '/* -------------------------------- */' a1
		from dual
		union all
		select 	'CREATE SYNONYM '||rpad(synonym_name,30)||' FOR '||table_owner||'.'||table_name||';'
		from 	user_synonyms
		where 	table_name like upper(NOME_TABELLA||'%')
		and 	table_owner = user
		union all
		select chr(0) from dual
		union all
		select '/* Sinonimi verso utente sovrasocietario */'
		from dual
		union all
		select '/* ------------------------------------- */' a1
		from dual
		union all
		select 	'CREATE SYNONYM '||rpad(synonym_name,30)||' FOR '||table_owner||'.'||table_name||';'
		from 	user_synonyms
		where 	table_name like upper(NOME_TABELLA||'%')
		and 	table_owner != user
		union all
		select chr(0) from dual
		union all
		select '/* Sinonimi publici */'
		from dual
		union all
		select '/* ---------------- */' a1
		from dual
		union all
		select 'CREATE PUBLIC SYNONYM '||rpad(synonym_name,30)||' for '||table_owner||'.'||table_name||';'
		from 	all_synonyms
		where 	owner='PUBLIC'
		and 	table_name like upper(NOME_TABELLA||'%')
		and 	table_owner=user;
	begin
	      open c1;
		loop
	 	fetch c1 into priv_syn;
	 	exit when c1%NOTFOUND;
	  	dbms_output.put_line(priv_syn);
	 	end loop;
	end;
	END; -- end procedure show_synonyms
	--------------------------------------------------------------------------------
	-- PROCEDURE set_foreign
	--------------------------------------------------------------------------------
	PROCEDURE set_foreign (stato IN VARCHAR2 DEFAULT NULL)
	AS
	BEGIN
	--set serveroutput on size 1000000 verify off
	declare
	   sql_statement varchar2(200);
	   const_name    varchar2(50);
	   stato_abil    varchar2(50);
	   cursor_id     number;
	   ret_val       number;
	   error_flag    number;
	cursor c1 is
	select  'alter table '||table_name || ' '|| stato || ' constraint '||constraint_name a1,
		constraint_name a2
	from 	user_constraints
	where 	constraint_type ='R'
	and status = decode(upper(stato) ,'ENABLE','DISABLED','DISABLE','ENABLED');
	begin
	dbms_output.enable(1000000);
	if stato is null or (upper(stato) != 'DISABLE' and upper(stato) != 'ENABLE') then
	    nl;
	    dbms_output.put_line ('Procedura      : KION.set_foreign(''ENABLE|DISABLE'')');
	    dbms_output.put_line ('============================================================');
	    dbms_output.put_line ('Parameter(s)   : ENABLE  per riabilitare le fk, DISABLE per disabilitarle');
	    dbms_output.put_line ('Description    : Abilita o disabilita tutte le fk di uno schema');
	    dbms_output.put_line ('Sintassi       : Es: exec KION.set_foreign(''DISABLE'')');
	   return;
	end if;
	error_flag := 0;
	select decode(upper(stato) ,'ENABLE','Abilita','DISABLE','Disabilita') into stato_abil from dual;
	nl;
	dbms_output.put_line(upper(stato_abil)||'ZIONE constraint di foreign-key utente '|| USER);
	dbms_output.put_line('------------------------------------------------------------------------');
	open c1;
	  loop
	      fetch c1 into sql_statement,const_name;
	      exit when c1%NOTFOUND;
	      begin
	--	      dbms_output.put_line(sql_statement);
		      cursor_id := dbms_sql.open_cursor;
		      dbms_sql.parse(cursor_id, sql_statement, dbms_sql.native);
		      ret_val := dbms_sql.execute(cursor_id);
		      dbms_sql.close_cursor(cursor_id);
		      EXCEPTION WHEN others THEN
		        error_flag := 1;
		      	dbms_output.put_line('Errore constraint: '||const_name);
	      end;
	  end loop;
	nl;
	if error_flag = 0 then
		dbms_output.put_line('Tutte le foreign-key di '||user||' sono state '|| upper(stato_abil) ||'TE correttamente.');
	else
		dbms_output.put_line('Verificare gli errori sulla base dati di '||user);
	end if;
	end;
	END; -- End procedure set_foreign
	--------------------------------------------------------------------------------
	-- PROCEDURE set_trigger
	--------------------------------------------------------------------------------
	PROCEDURE set_trigger (stato IN VARCHAR2 DEFAULT NULL)
	AS
	BEGIN
	declare
	   sql_statement varchar2(200);
	   const_name    varchar2(50);
	   stato_abil    varchar2(50);
	   cursor_id     number;
	   ret_val       number;
	   error_flag    number;
	cursor c1 is
	select  'alter table '||table_name || ' ' || stato ||' all triggers ' a1
	from 	user_triggers
	where status = decode(upper(stato) ,'ENABLE','DISABLED','DISABLE','ENABLED');
	begin
	dbms_output.enable(1000000);
	if stato is null or (upper(stato) != 'DISABLE' and upper(stato) != 'ENABLE') then
	    nl;
	    dbms_output.put_line ('Procedura      : KION.set_trigger(''ENABLE|DISABLE'')');
	    dbms_output.put_line ('============================================================');
	    dbms_output.put_line ('Parameter(s)   : ENABLE  per riabilitare le fk, DISABLE per disabilitarle');
	    dbms_output.put_line ('Description    : Abilita o disabilita tutte le fk di uno schema');
	    dbms_output.put_line ('Sintassi       : Es: exec KION.set_trigger(''DISABLE'')');
	   return;
	end if;
	error_flag := 0;
	select decode(upper(stato) ,'ENABLE','Abilita','DISABLE','Disabilita') into stato_abil from dual;
	nl;
	dbms_output.put_line(upper(stato_abil)||'ZIONE triggers');
	dbms_output.put_line('--------------------------------');
	open c1;
	  loop
	      fetch c1 into sql_statement;
	      exit when c1%NOTFOUND;
	      begin
	--	      dbms_output.put_line(sql_statement);
		      cursor_id := dbms_sql.open_cursor;
		      dbms_sql.parse(cursor_id, sql_statement, dbms_sql.native);
		      ret_val := dbms_sql.execute(cursor_id);
		      dbms_sql.close_cursor(cursor_id);
		      EXCEPTION WHEN others THEN
		        error_flag := 1;
		      	dbms_output.put_line('Errore trigger su: '||sql_statement);
	      end;
	  end loop;
	nl;
	if error_flag = 0 then
		dbms_output.put_line('Tutti i triggers di '||user||' sono stati '|| upper(stato_abil) ||'TI correttamente.');
	else
		dbms_output.put_line('Verificare gli errori sulla base dati di '||user);
	end if;
	end;
	END; -- End procedure set_trigger;
	--------------------------------------------------------------------------------
	-- PROCEDURE drop_fk
	--------------------------------------------------------------------------------
	procedure drop_fk (ObjectName  in varchar2)
	as
	Begin
	Declare
	constraint_present     number := 0;
	index_present          number := 0;
	constraint_tablename   varchar2(80);
	statement              varchar2(80);
	cursor_id_add  	       number;
	ret_val 	       number;
	   Begin
	      Select count(*) into constraint_present
	      from user_constraints
	      where constraint_name = Upper(ObjectName);
	      Select count(*) into index_present
	      from user_indexes
	      where index_name = Upper(ObjectName);
	      If constraint_present != 0  Then
		      Select table_name into constraint_tablename
		      from user_constraints
		      where constraint_name = Upper(ObjectName);
	              statement := 'alter table ' || constraint_tablename || ' drop constraint '|| Ltrim(Rtrim(ObjectName));
		      dbms_output.put_line('Eseguo: '|| statement);
		      cursor_id_add := dbms_sql.open_cursor;
		      dbms_sql.parse(cursor_id_add, statement, dbms_sql.native);
		      ret_val := dbms_sql.execute(cursor_id_add);
		      dbms_sql.close_cursor(cursor_id_add);
	      ElsIf index_present != 0 Then
	              statement := 'drop index ' || ObjectName;
		      dbms_output.put_line('Eseguo: '|| statement);
		      cursor_id_add := dbms_sql.open_cursor;
		      dbms_sql.parse(cursor_id_add, statement, dbms_sql.native);
		      ret_val := dbms_sql.execute(cursor_id_add);
		      dbms_sql.close_cursor(cursor_id_add);
	      Else
		      dbms_output.put_line('Nessuna operazione');
	      End If;
	   End;
	End; -- End Procedure drop_fk
	--------------------------------------------------------------------------------
	-- PROCEDURE drop_table
	--------------------------------------------------------------------------------
	procedure drop_table(tabella in varchar2)
	as
	begin
	declare
	  a             number;
	  cursor_id_add number;
	  ret_val       number;
	begin
	  select count(*) into a from user_tables
	  where  TABLE_NAME = upper(Ltrim(rtrim(tabella)));
	  If a != 0 Then
	      cursor_id_add := dbms_sql.open_cursor;
	      dbms_sql.parse(cursor_id_add, 'drop table '||tabella||' cascade constraints', dbms_sql.native);
	      ret_val := dbms_sql.execute(cursor_id_add);
	      dbms_sql.close_cursor(cursor_id_add);
	      dbms_output.put_line('Elimino la tabella temporanea: '|| tabella);
	  Else
	      dbms_output.put_line('Tabella '||tabella ||' non trovata');
	  End If;
	end;
	end;
	--------------------------------------------------------------------------------
	-- PROCEDURE drop_procedure
	--------------------------------------------------------------------------------
	procedure drop_procedure(procedura in varchar2)
	as
	begin
	declare
	  a             number;
	  cursor_id_add number;
	  ret_val       number;
	begin
	  select count(*) into a from user_objects
	  where  object_NAME = upper(Ltrim(rtrim(procedura)))
	  and    object_type = 'PROCEDURE';
	  If a != 0 Then
	      cursor_id_add := dbms_sql.open_cursor;
	      dbms_sql.parse(cursor_id_add, 'drop procedure '||procedura, dbms_sql.native);
	      ret_val := dbms_sql.execute(cursor_id_add);
	      dbms_sql.close_cursor(cursor_id_add);
	      dbms_output.put_line('Elimino la procedura: '|| procedura);
	  Else
	      dbms_output.put_line('Procedura '||procedura ||' non trovata');
	  End If;
	end;
end;

end DBA; -- End Package
/

