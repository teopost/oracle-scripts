CREATE OR REPLACE PACKAGE gensql AS

  -- Package to create procedures which generate source code 
  -- from DBA views
  --
  -- Author : Biju Thomas / Dec 97
  --
  -- The script files will be written to /tmp
  -- Change UTLDIR to a different location, if needed
  -- Define this directory in init.ora file UTL_FILE_DIRECTORY

  PROCEDURE help;
  PROCEDURE generate_script_files (papplname IN VARCHAR2 DEFAULT 'HELP', ptspace in varchar2 default 'SMALLDBDATA', pispace in varchar2 default 'SMALLDBINDEX');
  PROCEDURE generate_user_sql (papplname IN VARCHAR2 DEFAULT 'HELP', ptspace IN VARCHAR2 DEFAULT 'SMALLDBDATA', pispace IN VARCHAR2 DEFAULT 'SMALLDBINDEX');
  PROCEDURE generate_table_sql (papplname in varchar2 DEFAULT 'HELP', ptspace in varchar2 DEFAULT 'SMALLDBDATA');
  PROCEDURE generate_constraint_sql (papplname IN VARCHAR2 DEFAULT 'HELP', pispace IN VARCHAR2 default 'SMALLDBINDEX');
  PROCEDURE generate_sequence_sql (papplname IN VARCHAR2 DEFAULT 'HELP');
  PROCEDURE generate_synonym_sql (papplname IN VARCHAR2 DEFAULT 'HELP');
  PROCEDURE generate_view_sql (papplname IN VARCHAR2 DEFAULT 'HELP');
  PROCEDURE generate_procedure_sql (papplname IN VARCHAR2 DEFAULT 'HELP');
  PROCEDURE generate_trigger_sql (papplname IN VARCHAR2 DEFAULT 'HELP');
  PROCEDURE generate_comment_sql (papplname IN VARCHAR2 DEFAULT 'HELP');
  PROCEDURE generate_index_sql (papplname IN VARCHAR2 DEFAULT 'HELP', pispace IN VARCHAR2 default 'SMALLDBINDEX');
  UTLDIR varchar2 (20) := 'c:\temp';
END gensql;  -- End of package definition
/
show error
CREATE OR REPLACE PACKAGE BODY gensql AS

-------------------------------------------------------------------------------
-- Begin PROCEDURE generate_user_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_user_sql (papplname IN VARCHAR2 DEFAULT 'HELP', ptspace IN VARCHAR2 DEFAULT 'SMALLDBDATA', pispace IN VARCHAR2 DEFAULT 'SMALLDBINDEX') AS

  /*  File name to save script */
  wusersqlfile  VARCHAR2 (24) := LOWER(papplname) || 'user.sql';
  wusersqlftype UTL_FILE.FILE_TYPE;

  wprofile      VARCHAR2 (30);
  wsql          VARCHAR2 (500);

  /*  Profile limits */
  CURSOR cprof (wprofile IN VARCHAR2) IS 
               SELECT resource_name, limit
               FROM   dba_profiles
               WHERE  profile = wprofile;

  /* Related roles */
  CURSOR crole IS 
               SELECT granted_role
               FROM   system.dba_role_privs
               WHERE  grantee = UPPER(papplname)
               AND    granted_role NOT IN ('CONNECT', 'RESOURCE', 'DBA',
                     'IMP_FULL_DATABASE', 'EXP_FULL_DATABASE');

  /* Role - system privs */
  CURSOR csg (r IN VARCHAR2) IS
               SELECT privilege, admin_option
               FROM   dba_sys_privs 
               WHERE  grantee = UPPER(r)
               ORDER BY privilege;

  /* Object privileges granted */
  CURSOR cog (r IN VARCHAR2) IS
               SELECT (owner ||'.'|| table_name) object, privilege, grantable
               FROM   dba_tab_privs 
               WHERE  grantee = UPPER(r)
               ORDER BY owner, table_name;

  /* Column privileges granted */
  CURSOR ccg (r IN VARCHAR2) IS
               SELECT (owner ||'.'|| table_name) object, column_name,
                      privilege, grantable
               FROM   dba_col_privs 
               WHERE  grantee = UPPER(r)
               ORDER BY owner, table_name, column_name;

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_User_Sql');
    dbms_output.put_line ('=========================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('.              : 2. Data Tablespace Name - Default SMALLDBDATA');
    dbms_output.put_line ('.              : 3. Index Tablespace Name - Default SMALLDBINDEX');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create');
    dbms_output.put_line ('.                1. Profile related to user');
    dbms_output.put_line ('.                2. User');
    dbms_output.put_line ('.                3. Roles related to user');
    dbms_output.put_line ('.                4. Privileges granted to the role/user');
    dbms_output.put_line ('Output File    : Saved at ' || utldir || '\***user.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  -- open file for writing script
  wusersqlftype := UTL_FILE.FOPEN(utldir, wusersqlfile, 'w');

  dbms_output.put_line ('Open output file ' || utldir || wusersqlfile);

  UTL_FILE.PUT_LINE(wusersqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(wusersqlftype, 'spool '||utldir||'\'||replace(wusersqlfile,'.sql','.lst'));

  -- Find profile name of user
  SELECT profile INTO wprofile 
  FROM   dba_users
  WHERE  username = UPPER(papplname);

  IF wprofile != 'DEFAULT' THEN
    UTL_FILE.PUT_LINE(wusersqlftype, 'CREATE PROFILE ' || wprofile || ' LIMIT');

    FOR rprof IN cprof (wprofile) LOOP
       UTL_FILE.PUT_LINE(wusersqlftype, rprof.resource_name ||'  '|| rprof.limit);
    END LOOP;

    UTL_FILE.PUT_LINE(wusersqlftype, '/');
  END IF;

  dbms_output.put_line ('Generate CREATE PROFILE sql');

  -- Create user
  SELECT 'create user ' || username || ' identified by ' || username ||
         ' default tablespace ' || NVL(ptspace, default_tablespace) || 
         ' temporary tablespace temp' || 
         ' quota unlimited on ' || 
         DECODE(UPPER(ptspace), 'DEFAULT', default_tablespace, ptspace) || 
         ' quota unlimited on ' || 
         DECODE(UPPER(pispace), 'DEFAULT', default_tablespace, pispace) || 
         ' profile ' || wprofile
  INTO   wsql
  FROM   dba_users
  WHERE  username = UPPER(papplname);

  UTL_FILE.PUT_LINE(wusersqlftype, wsql);
  UTL_FILE.PUT_LINE(wusersqlftype, '/');

  dbms_output.put_line ('Generate CREATE USER sql');

  -- Grant direct privileges given to this user
  FOR rsg  in csg (papplname) loop
    SELECT 'grant ' || rsg.privilege || ' to ' || papplname || DECODE(rsg.admin_option,'YES', ' with admin option') 
    INTO wsql FROM dual;
    UTL_FILE.PUT_LINE(wusersqlftype, wsql);
    UTL_FILE.PUT_LINE(wusersqlftype, '/');
  END LOOP;

  dbms_output.put_line ('Generate GRANT system privilege sql');

  UTL_FILE.PUT_LINE(wusersqlftype, '/* Execute the following after connecting to the respective owners');

  FOR rog  IN cog (papplname) LOOP
    SELECT 'grant ' || rog.privilege || ' on ' || rog.object || ' to ' || papplname|| DECODE(rog.grantable,'YES',' with grant option') 
    INTO wsql FROM dual;
    UTL_FILE.PUT_LINE(wusersqlftype, wsql);
    UTL_FILE.PUT_LINE(wusersqlftype, '/');
  END LOOP;

  dbms_output.put_line ('Generate GRANT object privilege sql');

  FOR rcg  IN ccg (papplname) LOOP
    SELECT 'grant ' || rcg.privilege || ' (' || rcg.column_name ||') on ' || rcg.object || ' to ' || papplname || DECODE(rcg.grantable,'YES',' with grant option') 
    INTO wsql FROM dual;
    UTL_FILE.PUT_LINE(wusersqlftype, wsql);
    UTL_FILE.PUT_LINE(wusersqlftype, '/');
  END LOOP;

  dbms_output.put_line ('Generate GRANT column privilege sql');

  UTL_FILE.PUT_LINE(wusersqlftype, 'Execute the above after connecting to the respective owners */');

  -- Create roles related to this user
  FOR rrole IN crole LOOP

    wsql :=  'create role ' || rrole.granted_role;
    UTL_FILE.PUT_LINE(wusersqlftype, wsql);
    UTL_FILE.PUT_LINE(wusersqlftype, '/');

    wsql :=  'grant '|| rrole.GRANTED_ROLE ||' to '|| papplname; 
    UTL_FILE.PUT_LINE(wusersqlftype, wsql);
    UTL_FILE.PUT_LINE(wusersqlftype, '/');

    FOR rsg  IN csg (rrole.granted_role) LOOP
      SELECT 'grant ' || rsg.privilege || ' to ' || rrole.granted_role || DECODE(rsg.admin_option,'YES', ' with admin option') 
      INTO wsql FROM dual;
      UTL_FILE.PUT_LINE(wusersqlftype, wsql);
      UTL_FILE.PUT_LINE(wusersqlftype, '/');
    END LOOP;

    UTL_FILE.PUT_LINE(wusersqlftype, '/* Execute the following after connecting to the respective owners');

    FOR rog  IN cog (rrole.granted_role) LOOP
      SELECT 'grant ' || rog.privilege || ' on ' || rog.object || ' to ' || rrole.granted_role || DECODE(rog.grantable,'YES',' with grant option') 
      INTO wsql FROM dual;
      UTL_FILE.PUT_LINE(wusersqlftype, wsql);
      UTL_FILE.PUT_LINE(wusersqlftype, '/');
    END LOOP;

    FOR rcg IN ccg (rrole.granted_role) LOOP
      SELECT 'grant ' || rcg.privilege || ' (' || rcg.column_name ||') on ' || rcg.object || ' to ' || rrole.granted_role || DECODE(rcg.grantable,'YES',' with grant option') 
      INTO wsql FROM dual;
      UTL_FILE.PUT_LINE(wusersqlftype, wsql);
      UTL_FILE.PUT_LINE(wusersqlftype, '/');
    END LOOP;

    UTL_FILE.PUT_LINE(wusersqlftype, 'Execute the above after connecting to the respective owners */');

  END LOOP;

  UTL_FILE.PUT_LINE(wusersqlftype, 'set echo off');
  UTL_FILE.PUT_LINE(wusersqlftype, 'spool off');

  UTL_FILE.FCLOSE(wusersqlftype);

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_user_sql');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_user_sql');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_user_sql');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_user_sql');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_user_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_user_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_user_sql');
END;
-------------------------------------------------------------------------------
-- End PROCEDURE generate_user_sql.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Begin PROCEDURE generate_table_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_table_sql (papplname IN VARCHAR2 DEFAULT 'HELP', ptspace IN VARCHAR2 DEFAULT 'SMALLDBDATA') AS

  /*  File name to save script */
  wtabsqlfile  VARCHAR2 (24) := lower(papplname) || 'tabs.sql';
  wtabsqlftype UTL_FILE.FILE_TYPE;

  /*  Tables */
  CURSOR ctabs IS SELECT table_name, owner, 
         initial_extent/1024 inik, next_extent/1024 nxtk, min_extents minx
  FROM all_tables where
  owner = UPPER(papplname);

  /* Columns */
  CURSOR ccols (o in varchar2, t in varchar2)
  IS SELECT DECODE(column_id,1,'(',',')
     ||RPAD(column_name,40) ||RPAD(data_type,10) ||RPAD(
     DECODE(data_type,'DATE'    ,' ' ,'LONG'    ,' ' ,'LONG RAW',' '
     ,'RAW'     ,DECODE(data_length,null,null ,'('||data_length||')')
     ,'CHAR'    ,DECODE(data_length,null,null ,'('||data_length||')')
     ,'VARCHAR' ,DECODE(data_length,null,null ,'('||data_length||')')
     ,'VARCHAR2',DECODE(data_length,null,null ,'('||data_length||')')
     ,'NUMBER'  ,DECODE(data_precision,null,'  ' ,'('||data_precision||
     DECODE(data_scale,null,null,','||data_scale)||')'),'unknown'),8,' ') cstr
     FROM  all_tab_columns
     WHERE table_name = UPPER(t)
     AND   owner = UPPER(o)
     ORDER BY column_id;

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_Table_Sql');
    dbms_output.put_line ('==========================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('.              : 2. Data Tablespace Name - Default is SMALLDBDATA');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create Tables belonging to USER');
    dbms_output.put_line ('.                The storage constraints will not be defined, uses default for Tablespace');
    dbms_output.put_line ('Output File    : Saved at ' || utldir ||'\***tabs.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  wtabsqlftype := UTL_FILE.FOPEN(utldir, wtabsqlfile, 'w');

  UTL_FILE.PUT_LINE(wtabsqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(wtabsqlftype, 'spool '||utldir||'\'||replace(wtabsqlfile,'.sql','.lst'));

  FOR rtabs IN ctabs LOOP

    UTL_FILE.PUT_LINE(wtabsqlftype, 'create table ' || papplname || '.' || rtabs.table_name);

    FOR rcols IN ccols (rtabs.owner, rtabs.table_name) LOOP
       UTL_FILE.PUT_LINE(wtabsqlftype, rcols.cstr);
    END LOOP;

    UTL_FILE.PUT_LINE(wtabsqlftype, ') tablespace ' || ptspace);
    UTL_FILE.PUT_LINE(wtabsqlftype, 'storage (initial ' || rtabs.inik || 'K next '|| rtabs.nxtk || 'K minextents ' || rtabs.minx || ')' );
    UTL_FILE.PUT_LINE(wtabsqlftype, '/');

  END LOOP;

  UTL_FILE.PUT_LINE(wtabsqlftype, 'set echo off');
  UTL_FILE.PUT_LINE(wtabsqlftype, 'spool off');

  UTL_FILE.FCLOSE(wtabsqlftype);

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_table_sql.');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_table_sql.');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_table_sql.');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_table_sql.');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_table_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_table_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_table_sql.');
END;
-------------------------------------------------------------------------------
-- End of PROCEDURE generate_table_sql.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Begin PROCEDURE generate_constraint_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_constraint_sql (papplname IN VARCHAR2 DEFAULT 'HELP', pispace IN VARCHAR2 default 'SMALLDBINDEX') AS

  /*  File name to save script */
  wconsqlfile  VARCHAR2 (24) := LOWER(papplname) || 'cons.sql';
  wconsqlftype UTL_FILE.FILE_TYPE;

  /* Unique and primary keys */
  CURSOR cpk IS 
     SELECT owner, table_name, constraint_name, 
            DECODE(constraint_type,'U',' UNIQUE',' PRIMARY  KEY') typ, 
            DECODE(status,'DISABLED',' DISABLE',' ') status 
     FROM   dba_constraints  
     WHERE  owner = UPPER(papplname) 
     AND    constraint_type IN ('U','P'); 

  /* Unique and primary key columns */
  CURSOR cpkcol (o IN VARCHAR2, c IN VARCHAR2) IS 
     SELECT DECODE(position,1,'(',',')|| column_name coln 
     FROM   dba_cons_columns 
     WHERE  owner = o 
     AND    constraint_name = c
     ORDER BY position; 

  /* Foreign Keys */
  CURSOR cfk IS  
     SELECT c.owner, c.table_name, c.constraint_name, 
            c.r_constraint_name pkname, 
            c.r_owner pkowner, r.table_name pktab, 
            DECODE(c.status,'DISABLED',' DISABLE',' ') status, 
            DECODE(c.delete_rule,'CASCADE',' on delete cascade ',' ') del_rule 
     FROM   dba_constraints c, 
            dba_constraints r 
     WHERE c.owner = papplname AND
           c.constraint_type='R' AND 
           c.r_owner = r.owner AND
           c.r_constraint_name = r.constraint_name;

  /* Foreign key columns */
  CURSOR cfkcol (o IN VARCHAR2, c IN VARCHAR2) IS  
     SELECT DECODE(position,1,'(',',')|| column_name colname 
     FROM   dba_cons_columns 
     WHERE  owner = o 
     AND    constraint_name = c
     ORDER BY position; 

  /* Foreign key reference columns */
  CURSOR cfkrcol (ro IN VARCHAR2, rc IN VARCHAR2) IS 
     SELECT DECODE(position,1,'(',',')|| column_name refcol 
     FROM   dba_cons_columns  
     WHERE  owner = ro 
     AND    constraint_name = rc
     ORDER BY position; 

  /* Check constraints */
  CURSOR ccc IS 
     SELECT (owner ||'.'|| table_name) tab, constraint_name, 
            search_condition,
            DECODE(status,'DISABLED','DISABLE',' ') status 
     FROM   dba_constraints  
     WHERE  owner = UPPER(papplname) 
     AND   constraint_type = 'C';

BEGIN 

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_Constraint_Sql');
    dbms_output.put_line ('===============================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('.              : 2. Index Tablespace Name for Primary/Unique keys ');
    dbms_output.put_line ('.              : - Default SMALLDBINDEX');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create');
    dbms_output.put_line ('.                1. Unique and Primary Key constraints');
    dbms_output.put_line ('.                2. Foreign key constraints');
    dbms_output.put_line ('.                3. Check constraints');
    dbms_output.put_line ('Output File    : Saved at '|| utldir ||'\***cons.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  wconsqlftype := UTL_FILE.FOPEN(utldir, wconsqlfile, 'w');

  UTL_FILE.PUT_LINE(wconsqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(wconsqlftype, 'spool '||utldir||'\'||replace(wconsqlfile,'.sql','.lst'));

  FOR rpk IN cpk LOOP 

    UTL_FILE.PUT_LINE(wconsqlftype, 'alter table ' || rpk.owner ||'.'|| rpk.table_name); 
    UTL_FILE.PUT_LINE(wconsqlftype, 'add constraint '||rpk.constraint_name||rpk.typ); 
    FOR rpkcol IN cpkcol (rpk.owner, rpk.constraint_name) LOOP 
       UTL_FILE.PUT_LINE(wconsqlftype, rpkcol.coln); 
    END LOOP; 
    UTL_FILE.PUT_LINE(wconsqlftype,') using index tablespace ' || pispace || rpk.status); 
    UTL_FILE.PUT_LINE(wconsqlftype,'/'); 
  END LOOP; 
      
  FOR rfk IN cfk LOOP 
    UTL_FILE.PUT_LINE(wconsqlftype, 'alter table '|| rfk.owner ||'.'|| rfk.table_name);
    UTL_FILE.PUT_LINE(wconsqlftype, 'add constraint ' ||rfk.constraint_name ||' foreign key'); 

    FOR rfkcol IN cfkcol (rfk.owner, rfk.constraint_name) LOOP 
      UTL_FILE.PUT_LINE(wconsqlftype,rfkcol.colname); 
    END LOOP; 

    UTL_FILE.PUT_LINE(wconsqlftype,') references '||rfk.pkowner ||'.'|| rfk.pktab); 
    FOR rfkrcol IN cfkrcol (rfk.pkowner, rfk.pkname) LOOP 
      UTL_FILE.PUT_LINE(wconsqlftype,rfkrcol.refcol); 
    END LOOP; 

    UTL_FILE.PUT_LINE(wconsqlftype,') '||rfk.del_rule||rfk.status); 
    UTL_FILE.PUT_LINE(wconsqlftype,'/'); 
  END LOOP; 

  FOR rcc IN ccc LOOP 

    UTL_FILE.PUT_LINE(wconsqlftype, 'alter table ' || rcc.tab); 
    UTL_FILE.PUT_LINE(wconsqlftype, 'add constraint '||rcc.constraint_name);
    UTL_FILE.PUT_LINE(wconsqlftype, 'check (' || rcc.search_condition); 
    UTL_FILE.PUT_LINE(wconsqlftype, ') ' ||rcc.status); 
    UTL_FILE.PUT_LINE(wconsqlftype,'/'); 
  END LOOP; 

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_constraint_sql');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_constraint_sql');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_constraint_sql');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_constraint_sql');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_constraint_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_constraint_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_constraint_sql');

END;
-------------------------------------------------------------------------------
--  End PROCEDURE generate_constraint_sql.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Begin PROCEDURE generate_sequence_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_sequence_sql (papplname IN VARCHAR2 DEFAULT 'HELP') AS

  /*  File name to save script */
  wseqsqlfile  VARCHAR2 (24) := LOWER(papplname) || 'seqs.sql';
  wseqsqlftype UTL_FILE.FILE_TYPE;

  /* Sequences */
  CURSOR cseq IS
     SELECT sequence_owner, sequence_name, min_value, max_value, 
            increment_by, DECODE(cycle_flag,'Y','CYCLE','NOCYCLE') scycle, 
            DECODE(order_flag,'Y','ORDER','NOORDER') sorder, 
            DECODE(cache_size,0,'NOCACHE','CACHE '||cache_size) scache, 
            last_number+1 next_number
     FROM   dba_sequences
     WHERE  sequence_owner = UPPER(papplname);

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_Sequence_Sql');
    dbms_output.put_line ('============================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create Sequences of USER');
    dbms_output.put_line ('Output File    : Saved at ' || utldir ||'\***seqs.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  wseqsqlftype := UTL_FILE.FOPEN(utldir, wseqsqlfile, 'w');

  UTL_FILE.PUT_LINE(wseqsqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(wseqsqlftype, 'spool '||utldir||'\'||replace(wseqsqlfile,'.sql','.lst'));

  FOR rseq IN cseq LOOP

    UTL_FILE.PUT_LINE(wseqsqlftype, 'create sequence ' || rseq.sequence_owner || '.' || rseq.sequence_name);
    UTL_FILE.PUT_LINE(wseqsqlftype, 'increment by ' || rseq.increment_by);
    UTL_FILE.PUT_LINE(wseqsqlftype, 'start with   ' || rseq.next_number);
    UTL_FILE.PUT_LINE(wseqsqlftype, 'maxvalue     ' || rseq.max_value);
    UTL_FILE.PUT_LINE(wseqsqlftype, 'minvalue     ' || rseq.min_value);
    UTL_FILE.PUT_LINE(wseqsqlftype, rseq.scycle);
    UTL_FILE.PUT_LINE(wseqsqlftype, rseq.sorder);
    UTL_FILE.PUT_LINE(wseqsqlftype, rseq.scache);
    UTL_FILE.PUT_LINE(wseqsqlftype, '/');

  END LOOP;

  UTL_FILE.PUT_LINE(wseqsqlftype, 'set echo off');
  UTL_FILE.PUT_LINE(wseqsqlftype, 'spool off');

  UTL_FILE.FCLOSE(wseqsqlftype);

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_sequence_sql');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_sequence_sql');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_sequence_sql');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_sequence_sql');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_sequence_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_sequence_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_sequence_sql');

END;
-------------------------------------------------------------------------------
-- End of PROCEDURE generate_sequence_sql.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Begin PROCEDURE generate_synonym_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_synonym_sql (papplname IN VARCHAR2 DEFAULT 'HELP') AS

  /*  File name to save script */
  wsynsqlfile  VARCHAR2 (24) := LOWER(papplname) || 'syns.sql';
  wsynsqlftype UTL_FILE.FILE_TYPE;

  /* Synonyms */
  CURSOR csyn IS
     SELECT DECODE(owner,'PUBLIC',' PUBLIC ', ' ') ifpublic, 
            DECODE(owner,'PUBLIC',synonym_name, owner||'.'||synonym_name) synname,
            table_owner ||'.'|| table_name object,
            DECODE(db_link, null, ' ', '@'||db_link) dblink
     FROM   dba_synonyms
     WHERE  table_owner = UPPER(papplname) or
            owner = UPPER(papplname)
     ORDER BY owner, synonym_name;

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_Synonym_Sql');
    dbms_output.put_line ('============================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create Synonyms of USER');
    dbms_output.put_line ('Output File    : Saved at ' || utldir ||'\***syns.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  wsynsqlftype := UTL_FILE.FOPEN(utldir, wsynsqlfile, 'w');

  UTL_FILE.PUT_LINE(wsynsqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(wsynsqlftype, 'spool '||utldir||'\'||replace(wsynsqlfile,'.sql','.lst'));

  FOR rsyn IN csyn LOOP

    UTL_FILE.PUT_LINE(wsynsqlftype, 'create ' || rsyn.ifpublic || 'synonym ' || rsyn.synname);
    UTL_FILE.PUT_LINE(wsynsqlftype, 'for ' || rsyn.object || rsyn.dblink);
    UTL_FILE.PUT_LINE(wsynsqlftype, '/');

  END LOOP;

  UTL_FILE.PUT_LINE(wsynsqlftype, 'set echo off');
  UTL_FILE.PUT_LINE(wsynsqlftype, 'spool off');

  UTL_FILE.FCLOSE(wsynsqlftype);

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_synonym_sql');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_synonym_sql');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_synonym_sql');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_synonym_sql');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_synonym_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_synonym_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_synonym_sql');

END;
-------------------------------------------------------------------------------
-- End of PROCEDURE generate_synonym_sql.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Begin PROCEDURE generate_procedure_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_procedure_sql (papplname IN VARCHAR2 DEFAULT 'HELP') AS

  /*  File name to save script */
  wprosqlfile  VARCHAR2 (24) := LOWER(papplname) || 'proc.sql';
  wprosqlftype UTL_FILE.FILE_TYPE;

  /* Stored Objects */
  CURSOR cpro IS
     SELECT distinct owner, name, type
     FROM   dba_source
     WHERE  owner = UPPER(papplname)
     ORDER BY type, name;

  /* Text */
  CURSOR ctext (o in varchar2, t in varchar2, p in varchar2) IS
     SELECT text
     FROM   dba_source
     WHERE  owner = UPPER(o)
     AND    name  = UPPER(t)
     AND    type  = UPPER(p)
     ORDER BY line;

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_Procedure_Sql');
    dbms_output.put_line ('==============================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create Stored Objects for USER');
    dbms_output.put_line ('Output File    : Saved at ' || utldir ||'\***proc.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  wprosqlftype := UTL_FILE.FOPEN(utldir, wprosqlfile, 'w');

  UTL_FILE.PUT_LINE(wprosqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(wprosqlftype, 'spool '||utldir||'\'||replace(wprosqlfile,'.sql','.lst'));

  FOR rpro IN cpro LOOP

    UTL_FILE.PUT_LINE(wprosqlftype, 'create or replace ' );

    FOR rtext in ctext (rpro.owner, rpro.name, rpro.type) LOOP
       UTL_FILE.PUT_LINE(wprosqlftype, rtext.text);
    END LOOP;
        
    UTL_FILE.PUT_LINE(wprosqlftype, '/');

  END LOOP;

  UTL_FILE.PUT_LINE(wprosqlftype, 'set echo off');
  UTL_FILE.PUT_LINE(wprosqlftype, 'spool off');

  UTL_FILE.FCLOSE(wprosqlftype);

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_procedure_sql');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_procedure_sql');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_procedure_sql');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_procedure_sql');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_procedure_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_procedure_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_procedure_sql');

END;
-------------------------------------------------------------------------------
-- End of PROCEDURE generate_procedure_sql.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Begin PROCEDURE generate_trigger_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_trigger_sql (papplname IN VARCHAR2 DEFAULT 'HELP') AS

  /*  File name to save script */
  wtrgsqlfile  VARCHAR2 (24) := LOWER(papplname) || 'trig.sql';
  wtrgsqlftype UTL_FILE.FILE_TYPE;

  /* Triggers */
  CURSOR ctrig IS
     SELECT owner, trigger_name, description, trigger_body
     FROM   dba_triggers
     WHERE  owner = UPPER(papplname)
     ORDER BY owner, trigger_name;

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_Trigger_Sql');
    dbms_output.put_line ('============================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create Triggers for USER');
    dbms_output.put_line ('Output File    : Saved at '|| utldir ||'\***trig.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  wtrgsqlftype := UTL_FILE.FOPEN(utldir, wtrgsqlfile, 'w');

  UTL_FILE.PUT_LINE(wtrgsqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(wtrgsqlftype, 'spool '||utldir||'\'||replace(wtrgsqlfile,'.sql','.lst'));

  FOR rtrig IN ctrig LOOP

    UTL_FILE.PUT_LINE(wtrgsqlftype, 'create or replace trigger' );

    UTL_FILE.PUT_LINE(wtrgsqlftype, rtrig.description);
    UTL_FILE.PUT_LINE(wtrgsqlftype, rtrig.trigger_body);
        
    UTL_FILE.PUT_LINE(wtrgsqlftype, '/');

  END LOOP;

  UTL_FILE.PUT_LINE(wtrgsqlftype, 'set echo off');
  UTL_FILE.PUT_LINE(wtrgsqlftype, 'spool off');

  UTL_FILE.FCLOSE(wtrgsqlftype);

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_trigger_sql');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_trigger_sql');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_trigger_sql');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_trigger_sql');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_trigger_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_trigger_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_trigger_sql');

END;
-------------------------------------------------------------------------------
-- End of PROCEDURE generate_trigger_sql.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Begin PROCEDURE generate_view_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_view_sql (papplname IN VARCHAR2 DEFAULT 'HELP') AS

  /*  File name to save script */
  wvuesqlfile  VARCHAR2 (24) := LOWER(papplname) || 'view.sql';
  wvuesqlftype UTL_FILE.FILE_TYPE;

  /* Views */
  CURSOR cvue IS
     SELECT owner, view_name, text
     FROM   dba_views
     WHERE  owner = UPPER(papplname);

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_View_Sql');
    dbms_output.put_line ('=========================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create View for USER');
    dbms_output.put_line ('Output File    : Saved at '|| utldir ||'\***view.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  wvuesqlftype := UTL_FILE.FOPEN(utldir, wvuesqlfile, 'w');

  UTL_FILE.PUT_LINE(wvuesqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(wvuesqlftype, 'spool '||utldir||'\'||replace(wvuesqlfile,'.sql','.lst'));

  FOR rvue IN cvue LOOP

    UTL_FILE.PUT_LINE(wvuesqlftype, 'create or replace view ' || rvue.owner || '.' || rvue.view_name);
    UTL_FILE.PUT_LINE(wvuesqlftype, 'as ' || rvue.text);
    UTL_FILE.PUT_LINE(wvuesqlftype, '/');

  END LOOP;

  UTL_FILE.PUT_LINE(wvuesqlftype, 'set echo off');
  UTL_FILE.PUT_LINE(wvuesqlftype, 'spool off');

  UTL_FILE.FCLOSE(wvuesqlftype);

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_view_sql');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_view_sql');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_view_sql');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_view_sql');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_view_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_view_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_view_sql');

END;
-------------------------------------------------------------------------------
-- End of PROCEDURE generate_view_sql.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Begin PROCEDURE generate_comment_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_comment_sql (papplname IN VARCHAR2 DEFAULT 'HELP') AS

  /*  File name to save script */
  wcomsqlfile  VARCHAR2 (24) := LOWER(papplname) || 'comm.sql';
  wcomsqlftype UTL_FILE.FILE_TYPE;

  /* Table Comments */
  CURSOR ctc IS
     SELECT owner, table_name, comments
     FROM   dba_tab_comments
     WHERE  owner = UPPER(papplname)
     AND    comments is not null;

  /* Column Comments */
  CURSOR ccc IS
     SELECT owner, table_name, column_name, comments
     FROM   dba_col_comments
     WHERE  owner = UPPER(papplname)
     AND    comments is not null;

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_Comment_Sql');
    dbms_output.put_line ('============================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create Comments for USER Objects');
    dbms_output.put_line ('Output File    : Saved at '||utldir||'\***comm.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  wcomsqlftype := UTL_FILE.FOPEN(utldir, wcomsqlfile, 'w');

  UTL_FILE.PUT_LINE(wcomsqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(wcomsqlftype, 'spool '||utldir||'\'||replace(wcomsqlfile,'.sql','.lst'));

  FOR rtc IN ctc LOOP

    UTL_FILE.PUT_LINE(wcomsqlftype, 'comment on table ' || rtc.owner || '.' || rtc.table_name);
    UTL_FILE.PUT_LINE(wcomsqlftype, 'is ''' || rtc.comments || ' ''');
    UTL_FILE.PUT_LINE(wcomsqlftype, '/');

  END LOOP;

  FOR rcc IN ccc LOOP

    UTL_FILE.PUT_LINE(wcomsqlftype, 'comment on column ' || rcc.owner || '.' || rcc.table_name ||'.'|| rcc.column_name);
    UTL_FILE.PUT_LINE(wcomsqlftype, 'is ''' || rcc.comments || ' ''');
    UTL_FILE.PUT_LINE(wcomsqlftype, '/');

  END LOOP;

  UTL_FILE.PUT_LINE(wcomsqlftype, 'set echo off');
  UTL_FILE.PUT_LINE(wcomsqlftype, 'spool off');

  UTL_FILE.FCLOSE(wcomsqlftype);

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_comment_sql');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_comment_sql');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_comment_sql');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_comment_sql');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_comment_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_comment_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_comment_sql');

END;
-------------------------------------------------------------------------------
-- End of PROCEDURE generate_comment_sql.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Begin PROCEDURE generate_index_sql.
-------------------------------------------------------------------------------
PROCEDURE generate_index_sql (papplname IN VARCHAR2 DEFAULT 'HELP', pispace IN VARCHAR2 default 'SMALLDBINDEX') AS

  /*  File name to save script */
  windsqlfile  VARCHAR2 (24) := LOWER(papplname) || 'indx.sql';
  windsqlftype UTL_FILE.FILE_TYPE;

  /* Indexes */
  CURSOR cind IS
     SELECT owner, table_owner, table_name, index_name, ini_trans, max_trans,
            tablespace_name, initial_extent/1024 initial_extent, 
            next_extent/1024 next_extent, min_extents, max_extents, 
            pct_increase, DECODE(uniqueness,'UNIQUE','UNIQUE') unq
     FROM   dba_indexes
     WHERE  table_owner = UPPER(papplname);

  /* Index columns */
  CURSOR ccol (o IN VARCHAR2, t IN VARCHAR2, i IN VARCHAR2) IS
     SELECT DECODE(column_position,1,'(',',')||
               RPAD(column_name,40) cl
     FROM   dba_ind_columns
     WHERE  table_name = UPPER(t) AND
            index_name = UPPER(i) AND
            index_owner = UPPER(o)
     ORDER BY column_position;

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_Index_Sql');
    dbms_output.put_line ('==========================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('.              : 2. Index Tablespace Name - Default SMALLDBINDEX');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create Indexes for USER');
    dbms_output.put_line ('Output File    : Saved at '||utldir||'\***indx.sql');
    dbms_output.put_line ('.                Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  windsqlftype := UTL_FILE.FOPEN(utldir, windsqlfile, 'w');

  UTL_FILE.PUT_LINE(windsqlftype, 'set echo on feedback on lines 80');
  UTL_FILE.PUT_LINE(windsqlftype, 'spool '||utldir||'\'||replace(windsqlfile,'.sql','.lst'));

  FOR rind IN cind LOOP

    UTL_FILE.PUT_LINE(windsqlftype, 'create '||rind.unq||' index '|| rind.owner || '.' || rind.index_name||' on  '||rind.table_owner||'.'|| rind.table_name);
    FOR rcol IN ccol (rind.owner, rind.table_name, rind.index_name) LOOP
      UTL_FILE.PUT_LINE(windsqlftype, rcol.cl);
    END LOOP;

    UTL_FILE.PUT_LINE(windsqlftype, ') tablespace ' || pispace);
    UTL_FILE.PUT_LINE(windsqlftype, '/');

  END LOOP;

  UTL_FILE.PUT_LINE(windsqlftype, 'set echo off');
  UTL_FILE.PUT_LINE(windsqlftype, 'spool off');

  UTL_FILE.FCLOSE(Windsqlftype);

EXCEPTION
  WHEN UTL_FILE.WRITE_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Write Error - generate_index_sql');
       dbms_output.put_line ('An operating system error occured during write operation');
  WHEN UTL_FILE.READ_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Read Error - generate_index_sql');
       dbms_output.put_line ('An operating system error occured during read operation');
  WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       dbms_output.put_line ('Error: Utl_file.Invalid_Filehandle - generate_index_sql');
       dbms_output.put_line ('The filehandle was invalid');
  WHEN UTL_FILE.INTERNAL_ERROR THEN
       dbms_output.put_line ('Error: Utl_file.Internal Error - generate_index_sql');
       dbms_output.put_line ('An unspecified error in PL/SQL occured - generate_index_sql');
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line ('Error: No data found - Check your parameters - generate_index_sql');
  WHEN OTHERS THEN
       dbms_output.put_line ('Error: An unhandled exception occured - generate_index_sql');

END;
-------------------------------------------------------------------------------
-- End of PROCEDURE generate_index_sql.
-------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Begin PROCEDURE generate_script_files.
--------------------------------------------------------------------------------
PROCEDURE generate_script_files (papplname IN VARCHAR2 DEFAULT 'HELP', ptspace in varchar2 default 'SMALLDBDATA', pispace in varchar2 default 'SMALLDBINDEX') AS

BEGIN

  dbms_output.enable (999999);

  if upper(papplname) = 'HELP' then
    dbms_output.put_line ('Procedure Name : GenSql.Generate_Script_Files');
    dbms_output.put_line ('=============================================');
    dbms_output.put_line ('Parameter(s)   : 1. User (Schema) Name');
    dbms_output.put_line ('.              : 2. Data Tablespace Name - Default SMALLDBDATA');
    dbms_output.put_line ('.              : 3. Index Tablespace Name - Default SMALLDBINDEX');
    dbms_output.put_line ('Description    : To Generate SQL Statements To Create All Objects In Schema');
    dbms_output.put_line ('Object Name                   File Name');
    dbms_output.put_line ('----------------------------  ------------------------------');
    dbms_output.put_line ('User/Profile/Role/Privs       '||utldir||'\***user.sql');
    dbms_output.put_line ('Tables                        '||utldir||'\***tabs.sql');
    dbms_output.put_line ('Indexes                       '||utldir||'\***indx.sql');
    dbms_output.put_line ('Views                         '||utldir||'\***view.sql');
    dbms_output.put_line ('Constraints                   '||utldir||'\***cons.sql');
    dbms_output.put_line ('Sequences                     '||utldir||'\***seqs.sql');
    dbms_output.put_line ('Synonyms                      '||utldir||'\***syns.sql');
    dbms_output.put_line ('Comments                      '||utldir||'\***comm.sql');
    dbms_output.put_line ('Stored Objects                '||utldir||'\***proc.sql');
    dbms_output.put_line ('Triggers                      '||utldir||'\***trig.sql');
    dbms_output.put_line ('DB Links                      '||utldir||'\***dbln.sql');
    dbms_output.put_line ('.                             Where *** is the username passed in as parameter');
    dbms_output.put_line ('Note : This procedure uses utl_file - an Oracle7.3 feature!');
    return;
  end if;

  -- Generate profile/user/roles creation scripts
  generate_user_sql (papplname, ptspace, pispace);

  -- Generate table creation scripts. 
  generate_table_sql (papplname, ptspace);

  -- Generate index creation scripts.
  generate_index_sql (papplname, pispace);

  -- Generate constraint definition scripts
  generate_constraint_sql (papplname, pispace);

  -- Generate sequence creation scripts
  generate_sequence_sql (papplname);

  -- Generate synonym creation scripts
  generate_synonym_sql (papplname);

  -- Generate view creation scripts
  generate_view_sql (papplname);

  -- Generate synonym creation scripts
  generate_comment_sql (papplname);

  -- Generate stored objects creation scripts
  generate_procedure_sql (papplname);

  -- Generate trigger creation scripts
  generate_trigger_sql (papplname);

END generate_script_files;
--------------------------------------------------------------------------------
-- End PROCEDURE generate_script_files.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Begin PROCEDURE help.
--------------------------------------------------------------------------------
PROCEDURE help AS

BEGIN

  dbms_output.enable (999999);

  dbms_output.put_line ('Package Name : GenSql');
  dbms_output.put_line ('=====================');
  dbms_output.put_line ('Description  : This package generates SQL statements to (re)create objects');
  dbms_output.put_line ('.            : These are the procedures available in this package');
  dbms_output.put_line ('Procedure Name                Purpose ');
  dbms_output.put_line ('----------------------------  ------------------------------');
  dbms_output.put_line ('Generate_User_SQL             Generate SQL for creating user/profile/role/privs');
  dbms_output.put_line ('Generate_Table_SQL            Generate SQL for creating Tables');
  dbms_output.put_line ('Generate_Constraint_SQL       Generate SQL for creating Constraints');
  dbms_output.put_line ('Generate_Index_SQL            Generate SQL for creating Indexes');
  dbms_output.put_line ('Generate_Sequence_SQL         Generate SQL for creating Sequences');
  dbms_output.put_line ('Generate_View_SQL             Generate SQL for creating Views');
  dbms_output.put_line ('Generate_Synonym_SQL          Generate SQL for creating Synonyms');
  dbms_output.put_line ('Generate_Comment_SQL          Generate SQL for creating Comments');
  dbms_output.put_line ('Generate_Procedure_SQL        Generate SQL for creating Stored Objects');
  dbms_output.put_line ('Generate_Trigger_SQL          Generate SQL for creating Triggers');
  dbms_output.put_line ('Generate_Script_Files         Execute all the above procedures');
  dbms_output.put_line ('For more information on how to use these procedures, ');
  dbms_output.put_line ('******* EXEC GENSQL.procedurename; ********');
  dbms_output.put_line ('Note 1: This package uses utl_file - an Oracle7.3 feature!');
  dbms_output.put_line ('Note 2: The output files are overwritten each time the procedures are accessed');
  return;

END help;
--------------------------------------------------------------------------------
-- End PROCEDURE help.
--------------------------------------------------------------------------------

END gensql;  -- End of package body definition
/
