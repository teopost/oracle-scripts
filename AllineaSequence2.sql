spool AllineaSequence.log

/************************************************************
 Copyright Apex-net srl - Via Riccardo Brusi, 151/2 - 47023 Cesena
 ------------------------------------------------------------
 Autore: Fabio Vassura
 Data: 27/12/04
 Descrizione : Allineamento Sequence
 ************************************************************/

set serveroutput on size 1000000

declare
  v_NOMETABLE VARCHAR2(80);
  v_NOMEPK VARCHAR2(80);
  v_MAXVAL NUMBER(9);
begin
  DECLARE
    CURSOR CUR_SEQ IS
      SELECT SEQUENCE_NAME
      FROM USER_SEQUENCES;
  BEGIN 
   FOR SEQ IN CUR_SEQ LOOP
     BEGIN
       v_NOMETABLE := SUBSTR(SEQ.SEQUENCE_NAME, 5);
       SELECT COLUMN_NAME
         INTO v_NOMEPK
         FROM USER_CONSTRAINTS T,
         USER_CONS_COLUMNS C
         WHERE T.TABLE_NAME = v_NOMETABLE
         AND T.CONSTRAINT_TYPE = 'P'
         AND T.OWNER = C.OWNER
         AND T.CONSTRAINT_NAME = C.CONSTRAINT_NAME;
       EXECUTE IMMEDIATE ' SELECT MAX(' || v_NOMEPK || ') FROM '|| v_NOMETABLE  INTO v_MAXVAL;
       IF(v_MAXVAL > 0 AND v_MAXVAL IS NOT NULL) THEN
         EXECUTE IMMEDIATE 'DROP SEQUENCE ' || SEQ.SEQUENCE_NAME;
         EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || SEQ.SEQUENCE_NAME || ' START WITH '|| TO_CHAR(v_MAXVAL + 1) ||' MAXVALUE 999999999999999999999999999  MINVALUE 1  NOCYCLE  NOCACHE  NOORDER';
       END IF;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN NULL;
         WHEN TOO_MANY_ROWS THEN DBMS_OUTPUT.PUT_LINE('SEQ_' || v_NOMETABLE || ' non aggiornata');
     END;
  END LOOP;
 END;
END;
/

spool off;
exit;
