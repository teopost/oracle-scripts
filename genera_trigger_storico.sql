CREATE OR REPLACE procedure GENERA_TRIGGER_STORICO (p_TABLENAME varchar2) as
  v_PK varchar2(1);
  v_CONCATSTRING varchar2(32);
BEGIN
  v_PK := 'P';
  v_CONCATSTRING := 'v_ACCESSSTRING := v_ACCESSSTRING';
  --
  -- Genera Trigger Storico Body
  -- Procedure Body
  --
  dbms_output.put_line('create or replace trigger' || ' ' || p_TABLENAME || '_TR1' || ' ' || 'AFTER');
  dbms_output.put_line('insert or delete or update on' || ' ' || p_TABLENAME || ' ' || 'for each row');
  dbms_output.put_line('declare');
  dbms_output.put_line('v_TIPO' || ' ' || 'char(1)' || ';');
  dbms_output.put_line('v_ACCESSSTRING' || ' ' || 'varchar2(2000)' || ';');
  dbms_output.put_line('begin');
  --
  -- Assegna Inserimento o Modifica
  -- Describe processing executed in this block
  --
  dbms_output.put_line('if inserting or updating then');
  declare cursor C1 is
    select
      A.TABLE_NAME as USETABCOTANA,
      A.COLUMN_NAME as USETABCOCONA,
      A.DATA_TYPE as USETABCODATY,
      A.COLUMN_ID as USETABCOCOID
    from
      USER_TAB_COLUMNS A,
      USER_CONSTRAINTS B,
      USER_CONS_COLUMNS C
    where (B.TABLE_NAME = A.TABLE_NAME)
    and   (B.CONSTRAINT_NAME = C.CONSTRAINT_NAME)
    and   (A.TABLE_NAME = C.TABLE_NAME)
    and   (A.COLUMN_NAME = C.COLUMN_NAME)
    and   (A.TABLE_NAME = p_TABLENAME)
    and   (B.CONSTRAINT_TYPE = v_PK)
    order by
      A.COLUMN_ID
    ;
  begin for USERTABCOLU1 in C1 loop
    dbms_output.put_line(v_CONCATSTRING || '||' || ' ' || '''' || ' AND ' || '''' || ' ' || ';');
    dbms_output.put_line(v_CONCATSTRING || '||' || '''' || USERTABCOLU1.USETABCOCONA || '''' || ';');
    dbms_output.put_line(v_CONCATSTRING || '||' || ' ' || '''' || ' = ' || '''' || ' ' || ';');
    if USERTABCOLU1.USETABCODATY = 'NUMBER' then
      dbms_output.put_line('-- Rilevato tipo ' || 'NUMBER');
      dbms_output.put_line(v_CONCATSTRING || '||' || '( to_char (' || ':new.' || USERTABCOLU1.USETABCOCONA || '))' || ';');
    end if;
    if USERTABCOLU1.USETABCODATY = 'VARCHAR2' OR USERTABCOLU1.USETABCODATY = 'CHAR' then
      dbms_output.put_line('-- Rilevato tipo ' || 'VARCHAR2');
      dbms_output.put_line(v_CONCATSTRING || '||' || '''''''''' || '||' || ':new.' || USERTABCOLU1.USETABCOCONA || '||' || '''''''''' || ';');
    end if;
  end loop; end;
  --
  -- Assegna Tipo Inserting
  -- Describe processing executed in this block
  --
  dbms_output.put_line('if inserting then');
  dbms_output.put_line('v_TIPO :=' || '''' || 'I' || '''' || ';');
  dbms_output.put_line('end if' || ';');
  --
  -- Assegna Tipo Updating
  -- Describe processing executed in this block
  --
  dbms_output.put_line('if updating then');
  dbms_output.put_line('v_TIPO :=' || '''' || 'U' || '''' || ';');
  dbms_output.put_line('end if' || ';');
  dbms_output.put_line('end if' || ';');
  --
  -- Assegna Cancellazione
  -- Describe processing executed in this block
  --
  dbms_output.put_line('if deleting then');
  declare cursor C2 is
    select
      A.TABLE_NAME as USETABCOTANA,
      A.COLUMN_NAME as USETABCOCONA,
      A.DATA_TYPE as USETABCODATY,
      A.COLUMN_ID as USETABCOCOID
    from
      USER_TAB_COLUMNS A,
      USER_CONSTRAINTS B,
      USER_CONS_COLUMNS C
    where (B.TABLE_NAME = A.TABLE_NAME)
    and   (B.CONSTRAINT_NAME = C.CONSTRAINT_NAME)
    and   (A.TABLE_NAME = C.TABLE_NAME)
    and   (A.COLUMN_NAME = C.COLUMN_NAME)
    and   (A.TABLE_NAME = p_TABLENAME)
    and   (B.CONSTRAINT_TYPE = v_PK)
    order by
      A.COLUMN_ID
    ;
  begin for USERTABCOLUM in C2 loop
    dbms_output.put_line(v_CONCATSTRING || '||' || ' ' || '''' || ' AND ' || '''' || ' ' || ';');
    dbms_output.put_line(v_CONCATSTRING || '||' || '''' || USERTABCOLUM.USETABCOCONA || '''' || ';');
    dbms_output.put_line(v_CONCATSTRING || '||' || ' ' || '''' || ' = ' || '''' || ' ' || ';');
    if USERTABCOLUM.USETABCODATY = 'NUMBER' then
      dbms_output.put_line('-- Rilevato tipo ' || 'NUMBER');
      dbms_output.put_line(v_CONCATSTRING || '||' || '( to_char (' || ':old.' || USERTABCOLUM.USETABCOCONA || '))' || ';');
    end if;
    if USERTABCOLUM.USETABCODATY = 'VARCHAR2' OR USERTABCOLUM.USETABCODATY = 'CHAR' then
      dbms_output.put_line('-- Rilevato tipo ' || 'VARCHAR2');
      dbms_output.put_line(v_CONCATSTRING || '||' || '''''''''' || '||' || ':old.' || USERTABCOLUM.USETABCOCONA || '||' || '''''''''' || ';');
    end if;
  end loop; end;
  --
  -- Assegna Tipo Deleting
  -- Describe processing executed in this block
  --
  dbms_output.put_line('v_TIPO :=' || '''' || 'D' || '''' || ';');
  dbms_output.put_line('end if' || ';');
  --
  -- Insert in Storico
  -- Describe processing executed in this block
  --
  dbms_output.put_line('insert into STORICO (');
  dbms_output.put_line('ID' || ',');
  dbms_output.put_line('PK_ACCESS_STRING' || ',');
  dbms_output.put_line('TIPO' || ',');
  dbms_output.put_line('TABLE_NAME');
  dbms_output.put_line(') values (');
  dbms_output.put_line('SEQ_STORICO_ID.NextVal' || ',');
  dbms_output.put_line('Substr(Trim(v_ACCESSSTRING), 5)' || ',');
  dbms_output.put_line('v_TIPO' || ',');
  dbms_output.put_line('''' || p_TABLENAME || '''' || ')' || ';');
  dbms_output.put_line('END' || ';');
  dbms_output.put_line('/');
END;
/
