CREATE OR REPLACE package apex as
  procedure help;
  procedure db_check;
  procedure autovalid;
  procedure show_all_fk(nome_tabella in varchar2 default null);
  procedure show_synonyms(nome_tabella in varchar2 default null);
  procedure set_foreign(stato in varchar2 default null);
  procedure set_trigger(stato in varchar2 default null);
  procedure drop_fk (ObjectName  in varchar2);
  procedure drop_table(tabella in varchar2);
  procedure drop_sequence(nome_sequence in varchar2);
  procedure reset_seq (p_seq_name IN VARCHAR2, p_start_num IN NUMBER DEFAULT 1);
  procedure drop_procedure(procedura in varchar2);
  PROCEDURE rename_ck (p_nome_tabella IN VARCHAR2 DEFAULT NULL, p_output IN CHAR DEFAULT 'N');
end apex;
/

CREATE OR REPLACE PACKAGE BODY apex AS
--------------------------------------------------------------------------------
-- PROCEDURE help
--------------------------------------------------------------------------------
PROCEDURE help AS
BEGIN
  dbms_output.enable (1000000);
  dbms_output.put_line (chr(0));
  dbms_output.put_line ('Package Name : APEX');
  dbms_output.put_line ('===================');
  dbms_output.put_line ('Descrizione : Package di utility APEX - (C)opyright Apex-net srl');
  dbms_output.put_line ('rel.1.0 Dicembre 2002, S. Teodorani - Creata');
  dbms_output.put_line ('rel.1.1 Febbraio 2004, S. Teodorani - Aggiunto dblink in show_synonyms');
  dbms_output.put_line ('rel.1.2 Novembre 2005, S. Teodorani - Aggiunta drop sequence');
  dbms_output.put_line (chr(0));
  dbms_output.put_line ('Procedure disponibili         Descrizione');
  dbms_output.put_line ('----------------------------  ------------------------------');
  dbms_output.put_line ('help                          Questa schermata');
  dbms_output.put_line ('db_check                      Verifica la consistenza del db');
  dbms_output.put_line ('autovalid                     Rivalida gli oggetti invalidi');
  dbms_output.put_line ('show_all_fk                   Rigenera le foreign-key da e verso una tabella');
  dbms_output.put_line ('show_synonyms                 Rigenera tutti i sinonimi dello schema');
  dbms_output.put_line ('set_foreign                   Abilita o disabilita le foreign-key di uno schema');
  dbms_output.put_line ('set_trigger                   Abilita o disabilita i trigger di uno schema');
  dbms_output.put_line ('drop_fk                       Elimina una foreign-key o un check constraint solo se esistenti');
  dbms_output.put_line ('drop_table                    Elimina una tabella solo se esistente con clausola CASCADE');
  dbms_output.put_line ('drop_procedure                Elimina una procedura solo se esistente');
  dbms_output.put_line ('rename_ck                     Rinomina il check constraints sulla base dell''ordine della colonna di riferimento');
  return;
END help;

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
  dbms_output.put_line(chr(0));
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
  dbms_output.put_line(chr(0));
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
   dbms_output.enable(1000000);
   attempt       := 0;
   max_attempt   := 8;
   dbms_output.put_line(chr(0));
   dbms_output.put_line('AUTOVALIDAZIONE DEGLI OGGETTI INVALIDI');
   dbms_output.put_line('--------------------------------------');
   dbms_output.put_line(chr(0));
   loop
    select 	count(*) into also_invalid
    from 	user_objects
    where 	status = 'INVALID';
    exit when (also_invalid = 0 or attempt = max_attempt);
    attempt := attempt + 1;
    dbms_output.put_line(chr(0));
    dbms_output.put_line('Tentativo numero : '||attempt);
    dbms_output.put_line('----------------------------');
      for invalid in ( select 	object_type,
		    		object_name,
     				decode(object_type,'VIEW',1,'FUNCTION',2,'PROCEDURE',3,'PACKAGE',4,'PACKAGE BODY',5,'TRIGGER',6)
   		        from   	user_objects
   			where  	status        = 'INVALID'
   			and    	object_type in ('PACKAGE',
                       		'PACKAGE BODY',
                       		'FUNCTION',
                       		'PROCEDURE',
                       		'TRIGGER',
                       		'VIEW')
			order by 3) loop
      if invalid.object_type = 'PACKAGE BODY' then
        sql_statement := 'alter package '||invalid.object_name||' compile body';
      else
        sql_statement := 'alter '||invalid.object_type||' '||invalid.object_name||' compile';
      end if;
      cursor_id := dbms_sql.open_cursor;
      dbms_sql.parse(cursor_id, sql_statement, dbms_sql.native);
      ret_val := dbms_sql.execute(cursor_id);
      dbms_sql.close_cursor(cursor_id);
      dbms_output.put_line(rpad(initcap(invalid.object_type)||' '||
                                invalid.object_name, 32)||' : compilato');
   end loop;
   end loop;
   if attempt = max_attempt then
        dbms_output.put_line(chr(0));
   	dbms_output.put_line('ATTENZIONE');
   	dbms_output.put_line('Dopo '||attempt||' tentativi, alcuni oggetti sono rimasti invalidi.');
   	dbms_output.put_line('Effettuare una controllo della base dati');
   else
   	dbms_output.put_line(chr(0));
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
    dbms_output.put_line (chr(0));
    dbms_output.put_line ('Procedura      : apex.show_all_fk');
    dbms_output.put_line ('=================================');
    dbms_output.put_line ('Parameter(s)   : 1. Nome Tabella');
    dbms_output.put_line ('Description    : Rigenera tutte le foreign-key da e verso la tabella passata');
    dbms_output.put_line ('Sintassi       : exec apex.show_all_fk(''NOME_TABELLA'')');
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
	select 	'DROP SYNONYM '||rpad(synonym_name,30)||';'
	from 	user_synonyms
	where 	table_name like upper(NOME_TABELLA||'%')
	and 	table_owner = user
	union all
	select 	'CREATE SYNONYM '||rpad(synonym_name,30)||' FOR '||table_owner||'.'||table_name|| decode(db_link, null, '', '@'||db_link) ||';'
	from 	user_synonyms
	where 	table_name like upper(NOME_TABELLA||'%')
	and 	table_owner = user
	union all
	select chr(0) from dual
	union all
	select '/* Sinonimi verso altri utenti  */'
	from dual
	union all
	select '/* ------------------------------------- */' a1
	from dual
	union all
	select 	'DROP SYNONYM '||rpad(synonym_name,30)||';'
	from 	user_synonyms
	where 	table_name like upper(NOME_TABELLA||'%')
	and 	table_owner != user
	union all
	select 	'CREATE SYNONYM '||rpad(synonym_name,30)||' FOR '||table_owner||'.'||table_name|| decode(db_link, null, '', '@'||db_link) ||';'
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
	select 'DROP PUBLIC SYNONYM '||rpad(synonym_name,30)||';'
	from 	all_synonyms
	where 	owner='PUBLIC'
	and 	table_name like upper(NOME_TABELLA||'%')
	and 	table_owner=user
	union all
	select 'CREATE PUBLIC SYNONYM '||rpad(synonym_name,30)||' for '||table_owner||'.'||table_name|| decode(db_link, null, '', '@'||db_link) ||';'
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
    dbms_output.put_line (chr(0));
    dbms_output.put_line ('Procedura      : apex.set_foreign(''ENABLE|DISABLE'')');
    dbms_output.put_line ('============================================================');
    dbms_output.put_line ('Parameter(s)   : ENABLE  per riabilitare le fk, DISABLE per disabilitarle');
    dbms_output.put_line ('Description    : Abilita o disabilita tutte le fk di uno schema');
    dbms_output.put_line ('Sintassi       : Es: exec apex.set_foreign(''DISABLE'')');
   return;
end if;
error_flag := 0;
select decode(upper(stato) ,'ENABLE','Abilita','DISABLE','Disabilita') into stato_abil from dual;
dbms_output.put_line(chr(0));
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
dbms_output.put_line(chr(0));
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
    dbms_output.put_line (chr(0));
    dbms_output.put_line ('Procedura      : apex.set_trigger(''ENABLE|DISABLE'')');
    dbms_output.put_line ('============================================================');
    dbms_output.put_line ('Parameter(s)   : ENABLE  per riabilitare le fk, DISABLE per disabilitarle');
    dbms_output.put_line ('Description    : Abilita o disabilita tutte le fk di uno schema');
    dbms_output.put_line ('Sintassi       : Es: exec apex.set_trigger(''DISABLE'')');
   return;
end if;
error_flag := 0;
select decode(upper(stato) ,'ENABLE','Abilita','DISABLE','Disabilita') into stato_abil from dual;
dbms_output.put_line(chr(0));
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
dbms_output.put_line(chr(0));
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
-- PROCEDURE drop_table
--------------------------------------------------------------------------------
procedure drop_sequence(nome_sequence in varchar2)
as
begin
declare
  a             number;
  cursor_id_add number;
  ret_val       number;
begin
  select count(*) into a from user_objects
  where  object_name = upper(Ltrim(rtrim(nome_sequence)))
  and object_type = 'SEQUENCE';
  If a != 0 Then
      cursor_id_add := dbms_sql.open_cursor;
      dbms_sql.parse(cursor_id_add, 'drop sequence '|| nome_sequence, dbms_sql.native);
      ret_val := dbms_sql.execute(cursor_id_add);
      dbms_sql.close_cursor(cursor_id_add);
      dbms_output.put_line('Elimino la sequence : '|| nome_sequence);
  Else
      dbms_output.put_line('Sequence '||nome_sequence ||' non trovata');
  End If;
end;
end;

--------------------------------------------------------------------------------
-- PROCEDURE dreset_seq 
--------------------------------------------------------------------------------

PROCEDURE reset_seq (p_seq_name IN VARCHAR2, p_start_num IN NUMBER DEFAULT 1)
/*
|| Use this proc to reset a specified Sequence to a specified Starting number.
|| example of usage:
||    SELECT 'begin reset_seq(''' || sequence_name || ''', ' || last_number || ' ); end;'
||         || CHR (10)|| '/' || CHR (10)
||    FROM user_sequences;
||
||   begin system.reset_seq('test_seq', 100); end;
||   /
*/
IS
   l_val   NUMBER;
   l_gap   NUMBER;
BEGIN
   
   -- get the current seq value
   EXECUTE IMMEDIATE 'select ' || p_seq_name || '.nextval from dual'
      INTO l_val;
   l_gap := l_val - (p_start_num - 1);

   IF l_gap > l_val
   THEN
      l_gap := l_val;
   END IF;

   IF l_gap != 0
   THEN
      EXECUTE IMMEDIATE 'alter sequence ' || p_seq_name || ' increment by '
                        || TO_CHAR (-1 * l_gap) || ' minvalue 0';
      
      -- decrement in one step
      EXECUTE IMMEDIATE 'select ' || p_seq_name || '.nextval from dual'
         INTO l_val;
      EXECUTE IMMEDIATE 'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';
   END IF;
END;


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


--------------------------------------------------------------------------------
-- PROCEDURE rename_ck
--------------------------------------------------------------------------------
PROCEDURE rename_ck (p_nome_tabella IN VARCHAR2 DEFAULT NULL, p_output IN CHAR DEFAULT 'N')
IS
   i                     NUMBER (10);
   num_const             NUMBER (10);
   ls_search_condition   VARCHAR2 (4000);
   ls_check_condition    VARCHAR2 (4000);
   sql_command           VARCHAR2 (255);

   CURSOR cur_tables (a_nome_tabella IN VARCHAR2)
   IS
      SELECT tname table_name
        FROM TAB
       WHERE tabtype = 'TABLE'
         AND tname LIKE NVL (UPPER (a_nome_tabella), '%');

   CURSOR cur_tab_c_const (a_nome_tabella IN VARCHAR2)
   IS
      SELECT   uc.constraint_name,
               uc.search_condition,
               DECODE (status, 'DISABLED', 'DISABLE', 'ENABLE') status,
               'C_' || SUBSTR (REPLACE (uc.table_name, '_', ''), 1, 25) || '_' || utc.column_id t_c_name,
               ucc.column_name
          FROM USER_CONS_COLUMNS ucc, USER_CONSTRAINTS uc, USER_TAB_COLUMNS utc
         WHERE ucc.constraint_name = uc.constraint_name
           AND ucc.table_name = uc.table_name
           AND uc.constraint_type = 'C'
           AND uc.table_name = utc.table_name
           AND ucc.column_name = utc.column_name
           AND uc.table_name = UPPER (a_nome_tabella)
      ORDER BY ucc.column_name;

   CURSOR cur_check_dup (a_nome_tabella IN VARCHAR2, a_colonna IN VARCHAR2)
   IS
      SELECT a.column_name,
             a.constraint_name,
             b.search_condition
        FROM USER_CONS_COLUMNS a, USER_CONSTRAINTS b
       WHERE a.constraint_name = b.constraint_name
         AND a.column_name = a_colonna
         AND a.table_name = b.table_name
         AND b.table_name = a_nome_tabella;
BEGIN
   DBMS_OUTPUT.ENABLE (1000000);

   FOR rec_table IN cur_tables (p_nome_tabella) LOOP
      i := 0;

      IF p_output = 'Y' THEN
         DBMS_OUTPUT.NEW_LINE;
         DBMS_OUTPUT.PUT_LINE ('Tabella: ' || rec_table.table_name);
         DBMS_OUTPUT.PUT_LINE ('-----------------------------------');
      END IF;

      FOR rec_const IN cur_tab_c_const (rec_table.table_name) LOOP
         IF cur_tab_c_const%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE ('La tabella: ' || rec_table.table_name || ' non ha check constraint');
         ELSE
            -- La colonna search_condition è tipo LONG per poter far un confronto con una stringa devo assegnarla
            -- ad una variabile di tipo VARCHAR2
            ls_search_condition := rec_const.search_condition;

            IF ls_search_condition <> '"' || rec_const.column_name || '" IS NOT NULL' THEN
               -- I Constraint di tipo NOT NULL non vengono rinominati
               i := i + 1;

               IF p_output = 'Y' THEN
                  DBMS_OUTPUT.NEW_LINE;
                  DBMS_OUTPUT.PUT_LINE (   'Gestisco Constraint: '
                                        || rec_const.constraint_name
                                        || ' - Colonna '
                                        || rec_const.column_name
                                       );
               END IF;

               sql_command := 'alter table ' || rec_table.table_name || ' drop constraint ' || rec_const.constraint_name;

               BEGIN
                  IF p_output = 'Y' THEN
                     DBMS_OUTPUT.PUT_LINE ('Eseguo: ' || sql_command);
                  END IF;

                  EXECUTE IMMEDIATE (sql_command);
               EXCEPTION
                  WHEN OTHERS THEN
                     DBMS_OUTPUT.PUT_LINE ('Impossibile eseguire: -->' || sql_command);
                     DBMS_OUTPUT.PUT_LINE ('-- Errore: ' || SQLERRM);
                     DBMS_OUTPUT.NEW_LINE;
               END;

               num_const := 0;

               FOR rec_check IN cur_check_dup (rec_table.table_name, rec_const.column_name) LOOP
                  -- La colonna search_condition è tipo LONG per poter far un confronto con una stringa devo assegnarla
                  -- ad una variabile di tipo VARCHAR2
                  ls_check_condition := rec_check.search_condition;

                  IF ls_check_condition <> '"' || rec_const.column_name || '" IS NOT NULL' THEN
                     -- I Constraint di tipo NOT NULL non vengono considerati
                     num_const := num_const + 1;
                  END IF;
               END LOOP;

               IF num_const = 0 THEN
                  sql_command :=
                        'alter table '
                     || rec_table.table_name
                     || ' add constraint '
                     || rec_const.t_c_name
                     || ' check ('
                     || ls_search_condition
                     || ') '
                     || rec_const.status;

                  BEGIN
                     IF p_output = 'Y' THEN
                        DBMS_OUTPUT.PUT_LINE ('Eseguo: ' || sql_command);
                     END IF;
                     EXECUTE IMMEDIATE (sql_command);
                  EXCEPTION
                     WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE ('Impossibile eseguire: -->' || sql_command);
                        DBMS_OUTPUT.PUT_LINE ('--- Errore: ' || SQLERRM);
                        DBMS_OUTPUT.NEW_LINE;
                  END;
               ELSIF p_output = 'Y' THEN
                  DBMS_OUTPUT.PUT_LINE (   'Check Constraint '
                                        || rec_table.table_name
                                        || '.'
                                        || rec_const.constraint_name
                                        || ' rimosso in quanto duplicato'
                                       );
               END IF;
            END IF;
         END IF;
      END LOOP;   -- rec_const

      IF i = 0 THEN
         DBMS_OUTPUT.PUT_LINE ('Check Constraints non presenti sulla tabella: ' || rec_table.table_name);
      END IF;
   END LOOP;   -- rec_table
END rename_ck;

end APEX; -- End Package
/
