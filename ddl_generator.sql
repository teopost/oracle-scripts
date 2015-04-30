declare 
   a clob;
   b  DDL_GENERATOR.object_collection;
   l_idx number;
begin
    dbms_output.enable(200000);
    DDL_GENERATOR.CLEAN;
    --DDL_GENERATOR.GEN_SEQUENCE();
    --DDL_GENERATOR.GEN_TABLE('AGE_BOX_EVENTI');
    --DDL_GENERATOR.GEN_INDEX();
    --DDL_GENERATOR.GEN_TRIGGER();
    --DDL_GENERATOR.GEN_FOREIGN_KEY();
    --DDL_GENERATOR.GEN_FUNCTION();
    DDL_GENERATOR.GEN_PROCEDURE('UNIXX_GOL_INSERT');
    --DDL_GENERATOR.GEN_VIEW();
    --DDL_GENERATOR.GEN_PACKAGE();
    b := DDL_GENERATOR.FETCH_RESULTS;


   l_idx := b.FIRST;
   WHILE l_idx IS NOT NULL LOOP
     dbms_output.put_line (to_char(l_idx));
     --DBMS_OUTPUT.PUT_LINE(b(l_idx).object_name);
     --DBMS_OUTPUT.PUT_LINE(b(l_idx).source_code);
     
     DDL_GENERATOR.PRINT_CLOB(b(l_idx).source_code);
     l_idx := b.NEXT(l_idx);
   END LOOP; 
end;
/



CREATE OR REPLACE PACKAGE DDL_GENERATOR
IS
   TYPE object_attribute IS RECORD (
      source_code   CLOB, 
      object_name   VARCHAR2(30)
    );
      
   --TYPE object_collection IS TABLE OF CLOB INDEX BY BINARY_INTEGER;
   TYPE object_collection IS TABLE OF object_attribute INDEX BY BINARY_INTEGER;
   oc object_collection;
   indice number(30);
   
   --procedure help;
   --function get_tables (p_TABLE_NAME IN VARCHAR2) RETURN CLOB;

   PROCEDURE gen_sequence (p_object_name VARCHAR2 DEFAULT NULL);
   PROCEDURE gen_table (p_object_name VARCHAR2 DEFAULT NULL);
   PROCEDURE gen_index (p_object_name VARCHAR2 DEFAULT NULL);
   PROCEDURE gen_trigger (p_object_name VARCHAR2 DEFAULT NULL);
   PROCEDURE gen_foreign_key (p_object_name VARCHAR2 DEFAULT NULL);
   PROCEDURE gen_function (p_object_name VARCHAR2 DEFAULT NULL);
   PROCEDURE gen_procedure (p_object_name VARCHAR2 DEFAULT NULL);
   PROCEDURE gen_package (p_object_name VARCHAR2 DEFAULT NULL);
   PROCEDURE gen_view (p_object_name VARCHAR2 DEFAULT NULL);
   PROCEDURE print_clob(p_clob IN CLOB);
   PROCEDURE clean;
      
   FUNCTION fetch_results RETURN object_collection;
END DDL_GENERATOR;
/

CREATE OR REPLACE PACKAGE BODY DDL_GENERATOR
IS
-- http://www.oraclebytes.com/reference/packages/view/DBMS_METADATA/open-%28f%29

   /*
      procedure help
      is
      l_help varchar2(1000);
      begin
      l_help := '
      Procedura per l''invio di Notifiche push - APEX-net srl
      rel.1.0 - S. Teodorani
      -------------------------------------------------------------
      ';
      dbms_output.put_line(l_help);
      end;
      */
      
   procedure print_clob( p_clob in clob ) is
      v_offset number default 1;
      v_chunk_size number := 10000;
  begin
      loop
          exit when v_offset > dbms_lob.getlength(p_clob);
          dbms_output.put( dbms_lob.substr( p_clob, v_chunk_size, v_offset ) );
          --dbms_output.put_line('XX');
          v_offset := v_offset +  v_chunk_size;
      end loop;
   
    end;
    
   PROCEDURE clean
   IS
   BEGIN
      indice := 1;
      oc.delete;
   END;

   FUNCTION fetch_results
      RETURN object_collection
   IS
   BEGIN
      RETURN oc;
   END;


   FUNCTION get_ddl_sequence (object_name    VARCHAR2,
                              schema         VARCHAR2 DEFAULT USER,
                              new_owner      VARCHAR2 DEFAULT NULL)
      RETURN CLOB
   IS
      v_handle        NUMBER;
      v_transhandle   NUMBER;
      v_ddl           CLOB;
   BEGIN
      v_handle := DBMS_METADATA.open ('SEQUENCE', version => '9.0.1');

      DBMS_METADATA.set_filter (v_handle, 'SCHEMA', schema);
      DBMS_METADATA.set_filter (v_handle, 'NAME', object_name);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'MODIFY');
      DBMS_METADATA.set_remap_param (v_transhandle,
                                     'REMAP_SCHEMA',
                                     schema,
                                     new_owner);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'DDL');

      --dbms_metadata.set_transform_param(v_transhandle,'SEGMENT_ATTRIBUTES',false);
      --dbms_metadata.set_transform_param(v_transhandle,'PRETTY',true);

      --dbms_metadata.set_transform_param(v_transhandle,'REF_CONSTRAINTS',false);
      --dbms_metadata.set_transform_param(v_transhandle,'TABLESPACE',false);
      --dbms_metadata.set_transform_param(v_transhandle,'CONSTRAINTS',false);


      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'SQLTERMINATOR',
                                         TRUE);
      v_ddl := DBMS_METADATA.fetch_clob (v_handle);
      --v_ddl := TRIM (v_ddl) || CHR (13) || CHR (10);
      DBMS_METADATA.close (v_handle);

      RETURN v_ddl;
   END;

   FUNCTION get_ddl_foreign_keys (object_name    VARCHAR2,
                                  schema         VARCHAR2 DEFAULT USER,
                                  new_owner      VARCHAR2 DEFAULT NULL)
      RETURN CLOB
   IS
      v_handle        NUMBER;
      v_transhandle   NUMBER;
      v_ddl           CLOB;
   BEGIN

      v_handle := DBMS_METADATA.open ('REF_CONSTRAINT', version => '9.0.1');

      DBMS_METADATA.set_filter (v_handle, 'SCHEMA', schema);
      DBMS_METADATA.set_filter (v_handle, 'NAME', object_name);
      /*
      DBMS_METADATA.SET_FILTER(v_handle, 'NAME_EXPR',
        'IN (SELECT constraint_name ' ||
        '    FROM user_constraints ' ||
        '    WHERE constraint_type = ''R'' ' ||
        '    AND   table_name = ''' ||  object_name || ''')');
      */

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'MODIFY');
      DBMS_METADATA.set_remap_param (v_transhandle,
                                     'REMAP_SCHEMA',
                                     schema,
                                     new_owner);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'DDL');

      --dbms_metadata.set_transform_param(v_transhandle,'SEGMENT_ATTRIBUTES',false);
      DBMS_METADATA.set_transform_param (v_transhandle, 'PRETTY', TRUE);

      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'REF_CONSTRAINTS',
                                         TRUE);
      -- dbms_metadata.set_transform_param(v_transhandle,'TABLESPACE',false);
      --dbms_metadata.set_transform_param(v_transhandle,'CONSTRAINTS',false);


      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'SQLTERMINATOR',
                                         TRUE);

      v_ddl := DBMS_METADATA.fetch_clob (v_handle);
      --v_ddl := TRIM (v_ddl) || CHR (13) || CHR (10);
      DBMS_METADATA.close (v_handle);

      RETURN v_ddl;
   END;

   FUNCTION get_ddl_triggers (object_name    VARCHAR2,
                              schema         VARCHAR2 DEFAULT USER,
                              new_owner      VARCHAR2 DEFAULT NULL)
      RETURN CLOB
   IS
      v_handle        NUMBER;
      v_transhandle   NUMBER;
      v_ddl           CLOB;
   BEGIN
      v_handle := DBMS_METADATA.open ('TRIGGER', version => '9.0.1');

      DBMS_METADATA.set_filter (v_handle, 'SCHEMA', schema);
      DBMS_METADATA.set_filter (v_handle, 'NAME', object_name);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'MODIFY');
      DBMS_METADATA.set_remap_param (v_transhandle,
                                     'REMAP_SCHEMA',
                                     schema,
                                     new_owner);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'DDL');

      --dbms_metadata.set_transform_param(v_transhandle,'SEGMENT_ATTRIBUTES',false);
      DBMS_METADATA.set_transform_param (v_transhandle, 'PRETTY', TRUE);

      --dbms_metadata.set_transform_param(v_transhandle,'REF_CONSTRAINTS',false);
      -- dbms_metadata.set_transform_param(v_transhandle,'TABLESPACE',false);
      --dbms_metadata.set_transform_param(v_transhandle,'CONSTRAINTS',false);


      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'SQLTERMINATOR',
                                         TRUE);
      v_ddl := DBMS_METADATA.fetch_clob (v_handle);
      --v_ddl := TRIM (v_ddl) || CHR (13) || CHR (10);
      DBMS_METADATA.close (v_handle);

      RETURN v_ddl;
   END;

   FUNCTION get_ddl_indexes (object_name    VARCHAR2,
                             schema         VARCHAR2 DEFAULT USER,
                             new_owner      VARCHAR2 DEFAULT NULL)
      RETURN CLOB
   IS
      v_handle        NUMBER;
      v_transhandle   NUMBER;
      v_ddl           CLOB;
   BEGIN
      v_handle := DBMS_METADATA.open ('INDEX', version => '9.0.1');

      DBMS_METADATA.set_filter (v_handle, 'SCHEMA', schema);
      DBMS_METADATA.set_filter (v_handle, 'NAME', object_name);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'MODIFY');
      DBMS_METADATA.set_remap_param (v_transhandle,
                                     'REMAP_SCHEMA',
                                     schema,
                                     new_owner);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'DDL');

      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'SEGMENT_ATTRIBUTES',
                                         FALSE);
      DBMS_METADATA.set_transform_param (v_transhandle, 'PRETTY', TRUE);

      --dbms_metadata.set_transform_param(v_transhandle,'REF_CONSTRAINTS',false);
      DBMS_METADATA.set_transform_param (v_transhandle, 'TABLESPACE', FALSE);
      --dbms_metadata.set_transform_param(v_transhandle,'CONSTRAINTS',false);


      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'SQLTERMINATOR',
                                         TRUE);
      v_ddl := DBMS_METADATA.fetch_clob (v_handle);
      --v_ddl := TRIM (v_ddl) || CHR (13) || CHR (10);
      DBMS_METADATA.close (v_handle);

      RETURN v_ddl;
   END;

   FUNCTION get_ddl_table (table_name    VARCHAR2,
                           schema        VARCHAR2 DEFAULT USER,
                           new_owner     VARCHAR2 DEFAULT NULL)
      RETURN CLOB
   IS
      v_handle        NUMBER;
      v_transhandle   NUMBER;
      v_ddl           CLOB;
   BEGIN
      v_handle := DBMS_METADATA.open ('TABLE', version => '9.0.1');

      DBMS_METADATA.set_filter (v_handle, 'SCHEMA', schema);
      DBMS_METADATA.set_filter (v_handle, 'NAME', table_name);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'MODIFY');
      DBMS_METADATA.set_remap_param (v_transhandle,
                                     'REMAP_SCHEMA',
                                     schema,
                                     new_owner);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'DDL');

      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'SEGMENT_ATTRIBUTES',
                                         FALSE);
      DBMS_METADATA.set_transform_param (v_transhandle, 'PRETTY', TRUE);
      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'SQLTERMINATOR',
                                         TRUE);
      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'REF_CONSTRAINTS',
                                         FALSE);
      DBMS_METADATA.set_transform_param (v_transhandle, 'TABLESPACE', FALSE);
      --dbms_metadata.set_transform_param(v_transhandle,'CONSTRAINTS',false);


      v_ddl := DBMS_METADATA.fetch_clob (v_handle);
      --v_ddl := TRIM (v_ddl) || CHR (13) || CHR (10);
      DBMS_METADATA.close (v_handle);

      RETURN v_ddl;
   END;

   FUNCTION get_ddl_code_object (obj_type varchar2, 
                           object_name    VARCHAR2,
                           schema        VARCHAR2 DEFAULT USER,
                           new_owner     VARCHAR2 DEFAULT NULL)
   RETURN CLOB
   IS
      v_handle        NUMBER;
      v_transhandle   NUMBER;
      v_ddl           CLOB;
   BEGIN
      v_handle := DBMS_METADATA.open (obj_type, version => '9.0.1');

      DBMS_METADATA.set_filter (v_handle, 'SCHEMA', schema);
      DBMS_METADATA.set_filter (v_handle, 'NAME', object_name);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'MODIFY');
      DBMS_METADATA.set_remap_param (v_transhandle, 'REMAP_SCHEMA', schema, new_owner);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'DDL');

      DBMS_METADATA.set_transform_param (v_transhandle, 'PRETTY', TRUE);
      DBMS_METADATA.set_transform_param (v_transhandle, 'SQLTERMINATOR', TRUE);
/*
      v_ddl :=          '--------------------------------------------------------';
      v_ddl := v_ddl || '--  DDL for '|| obj_type || ' ' || object_name;
      v_ddl := v_ddl || '--------------------------------------------------------';
*/
      v_ddl :=  DBMS_METADATA.fetch_clob (v_handle);
      
      --v_ddl := TRIM (v_ddl) || CHR (13) || CHR (10);
      DBMS_METADATA.close (v_handle);

      RETURN v_ddl;
   END;
   
     FUNCTION get_ddl_table_comment (table_name    VARCHAR2,
                           schema        VARCHAR2 DEFAULT USER,
                           new_owner     VARCHAR2 DEFAULT NULL)
      RETURN CLOB
   IS
      v_handle        NUMBER;
      v_transhandle   NUMBER;
      v_ddl           CLOB;
   BEGIN
      v_handle := DBMS_METADATA.open ('COMMENT', version => '9.0.1');

      DBMS_METADATA.set_filter (v_handle, 'BASE_OBJECT_SCHEMA', schema);
      DBMS_METADATA.set_filter (v_handle, 'BASE_OBJECT_NAME', table_name);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'MODIFY');
      DBMS_METADATA.set_remap_param (v_transhandle,
                                     'REMAP_SCHEMA',
                                     schema,
                                     new_owner);

      v_transhandle := DBMS_METADATA.add_transform (v_handle, 'DDL');


      DBMS_METADATA.set_transform_param (v_transhandle, 'PRETTY', TRUE);
      DBMS_METADATA.set_transform_param (v_transhandle,
                                         'SQLTERMINATOR',
                                         TRUE);



      v_ddl := DBMS_METADATA.fetch_clob (v_handle);
      -- resolve bug oracle 
      v_ddl := replace(v_ddl, 'COMMENT ON COLUMN .', 'COMMENT ON COLUMN ');
      --v_ddl := TRIM (v_ddl) || CHR (13) || CHR (10);
      DBMS_METADATA.close (v_handle);

      RETURN v_ddl;
   END;


   
   FUNCTION get_ddl_table_comment_old (p_table_name VARCHAR2)
      RETURN CLOB
   IS
      v_ddl   CLOB := NULL;
   BEGIN
      BEGIN
         DBMS_METADATA.SET_TRANSFORM_PARAM (DBMS_METADATA.SESSION_TRANSFORM,
                                            'PRETTY',
                                            TRUE);
         DBMS_METADATA.SET_TRANSFORM_PARAM (DBMS_METADATA.SESSION_TRANSFORM,
                                            'SQLTERMINATOR',
                                            TRUE);

         FOR comm
            IN (SELECT DBMS_METADATA.get_dependent_ddl ('COMMENT',
                                                        p_table_name,
                                                        USER)
                          AS ddl_statement
                  FROM DUAL)
         LOOP
            v_ddl := v_ddl || comm.ddl_statement;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
            v_ddl := TO_CLOB (NULL);
      END;

      RETURN v_ddl;
   END;



   PROCEDURE gen_sequence (p_object_name VARCHAR2)
   IS
      last_ddl   CLOB;
   BEGIN
      FOR a
         IN (SELECT sequence_name
               FROM user_sequences
              WHERE (sequence_name = p_object_name OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_sequence (a.sequence_name);
         oc (indice).object_name := a.sequence_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;
      END LOOP;
   END;

   PROCEDURE gen_table (p_object_name VARCHAR2)
   IS
      last_ddl       CLOB;
      last_comment   CLOB;
   BEGIN
      FOR a IN (SELECT table_name
                  FROM user_tables
                 WHERE (table_name = p_object_name OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_table (a.table_name);
         oc (indice).object_name := a.table_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;

         last_comment := get_ddl_table_comment (a.table_name);
         oc (indice).object_name := a.table_name;
         oc (indice).source_code := last_comment;
         indice := indice + 1;
      END LOOP;
   END;

   PROCEDURE gen_foreign_key (p_object_name VARCHAR2)
   IS
      last_ddl   CLOB;
   BEGIN
      FOR a
         IN (SELECT constraint_name AS object_name
               FROM user_constraints
              WHERE     constraint_type = 'R'
                    AND (   constraint_name = p_object_name
                         OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_foreign_keys (a.object_name);
         oc (indice).object_name := a.object_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;
      END LOOP;
   END;

   PROCEDURE gen_index (p_object_name VARCHAR2)
   IS
      last_ddl   CLOB;
   BEGIN
      FOR a
         IN (SELECT index_name AS object_name
               FROM USER_INDEXES
              WHERE     index_type != 'LOB'
                    AND (index_name = p_object_name OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_indexes (a.object_name);
         oc (indice).object_name := a.object_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;
      END LOOP;
   END;

   PROCEDURE gen_trigger (p_object_name VARCHAR2)
   IS
      last_ddl   CLOB;
   BEGIN
      FOR a
         IN (SELECT trigger_name AS object_name
               FROM USER_TRIGGERS
              WHERE (trigger_name = p_object_name OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_triggers (a.object_name);
         oc (indice).object_name := a.object_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;
      END LOOP;
   END;
   
   PROCEDURE gen_function (p_object_name VARCHAR2)
   IS
      last_ddl   CLOB;
   BEGIN
      FOR a
         IN (SELECT object_name AS object_name
               FROM USER_OBJECTS
              WHERE object_type = 'FUNCTION' and (object_name = p_object_name OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_code_object ('FUNCTION', a.object_name);
         oc (indice).object_name := a.object_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;
      END LOOP;
   END;
   
   PROCEDURE gen_procedure (p_object_name VARCHAR2)
   IS
      last_ddl   CLOB;
   BEGIN
      FOR a
         IN (SELECT object_name AS object_name
               FROM USER_OBJECTS
              WHERE object_type = 'PROCEDURE' and (object_name = p_object_name OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_code_object ('PROCEDURE', a.object_name);
         oc (indice).object_name := a.object_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;
      END LOOP;
   END;
   
   PROCEDURE gen_view (p_object_name VARCHAR2)
   IS
      last_ddl   CLOB;
   BEGIN
      FOR a
         IN (SELECT object_name AS object_name
               FROM USER_OBJECTS
              WHERE object_type = 'VIEW' and (object_name = p_object_name OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_code_object ('VIEW', a.object_name);
         oc (indice).object_name := a.object_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;
      END LOOP;
   END;
   
   PROCEDURE gen_package (p_object_name VARCHAR2)
   IS
      last_ddl   CLOB;
   BEGIN
      FOR a
         IN (SELECT object_name AS object_name
               FROM USER_OBJECTS
              WHERE object_type = 'PACKAGE' and (object_name = p_object_name OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_code_object ('PACKAGE_SPEC', a.object_name);
         oc (indice).object_name := a.object_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;
      END LOOP;
      
      FOR b
         IN (SELECT object_name AS object_name
               FROM USER_OBJECTS
              WHERE object_type = 'PACKAGE BODY' and (object_name = p_object_name OR p_object_name IS NULL))
      LOOP
         last_ddl := get_ddl_code_object ('PACKAGE_BODY', b.object_name);
         oc (indice).object_name := b.object_name;
         oc (indice).source_code := last_ddl;
         indice := indice + 1;
      END LOOP;
      
   END;
   
   
END DDL_GENERATOR;
/
