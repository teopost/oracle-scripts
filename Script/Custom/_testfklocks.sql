CREATE OR REPLACE PROCEDURE testfklocks IS
  t_CONSTRAINT_TYPE   user_constraints.CONSTRAINT_TYPE%TYPE;
  t_CONSTRAINT_NAME   USER_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
  t_TABLE_NAME        USER_CONSTRAINTS.TABLE_NAME%TYPE;
  t_R_CONSTRAINT_NAME USER_CONSTRAINTS.R_CONSTRAINT_NAME%TYPE;
  tt_CONSTRAINT_NAME  USER_CONS_COLUMNS.CONSTRAINT_NAME%TYPE;
  tt_TABLE_NAME       USER_CONS_COLUMNS.TABLE_NAME%TYPE;
  tt_COLUMN_NAME      USER_CONS_COLUMNS.COLUMN_NAME%TYPE;
  tt_POSITION         USER_CONS_COLUMNS.POSITION%TYPE;
  tt_Dummy            NUMBER;
  tt_dummyChar        VARCHAR2(2000);
  l_Cons_Found_Flag   VARCHAR2(1);
  Err_TABLE_NAME      USER_CONSTRAINTS.TABLE_NAME%TYPE;
  Err_COLUMN_NAME     USER_CONS_COLUMNS.COLUMN_NAME%TYPE;
  Err_POSITION        USER_CONS_COLUMNS.POSITION%TYPE;

  virgola number;
  table_index number := 1;
  tLineNum varchar2(4) := '-- ';

  CURSOR UserTabs IS
    SELECT table_name FROM user_tables ORDER BY table_name;

  CURSOR TableCons IS
    SELECT CONSTRAINT_TYPE, CONSTRAINT_NAME, R_CONSTRAINT_NAME
    FROM   user_constraints
    WHERE  OWNER = USER AND R_OWNER= user and table_name = t_Table_Name AND CONSTRAINT_TYPE = 'R'
    ORDER  BY TABLE_NAME, CONSTRAINT_NAME;

  CURSOR ConColumns IS
    SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, POSITION
    FROM   user_cons_columns
    WHERE  OWNER = USER  AND CONSTRAINT_NAME = t_CONSTRAINT_NAME
    ORDER  BY POSITION;

  CURSOR IndexColumns IS
    SELECT TABLE_NAME, COLUMN_NAME, POSITION
    FROM   user_cons_columns
    WHERE  OWNER = USER AND CONSTRAINT_NAME = t_CONSTRAINT_NAME
    ORDER  BY POSITION;

  DebugLevel    NUMBER := 99; -- >> 99 = dump all info`
  DebugFlag     VARCHAR(1) := 'N'; -- Turn Debugging on
  t_Error_Found VARCHAR(1);

BEGIN
dbms_output.enable(9999999);

  OPEN UserTabs;
  LOOP
    FETCH UserTabs
      INTO t_TABLE_NAME;
    t_Error_Found := 'N';
    EXIT WHEN UserTabs%NOTFOUND;

    -- Log current table
 
    dbms_output.put_line(chr(0));
    dbms_output.put_line(tLineNum || 'Checking Table ' || t_Table_Name);
    dbms_output.put_line(tLineNum || '---------------------------------------');

    l_Cons_Found_Flag := 'N';
    OPEN TableCons;
    LOOP
      FETCH TableCons
        INTO t_CONSTRAINT_TYPE, t_CONSTRAINT_NAME, t_R_CONSTRAINT_NAME;
      EXIT WHEN TableCons%NOTFOUND;

      IF (DebugFlag = 'Y' AND DebugLevel >= 99)
      THEN
        BEGIN
          
          dbms_output.put_line(tLineNum || 'Found CONSTRAINT_NAME = ' || t_CONSTRAINT_NAME);
          dbms_output.put_line(tLineNum || 'Found CONSTRAINT_TYPE = ' || t_CONSTRAINT_TYPE);
          dbms_output.put_line(tLineNum || 'Found R_CONSTRAINT_NAME = ' || t_R_CONSTRAINT_NAME);
        END;
      END IF;

      OPEN ConColumns;
      LOOP
        FETCH ConColumns
          INTO tt_CONSTRAINT_NAME, tt_TABLE_NAME, tt_COLUMN_NAME, tt_POSITION;
		  
        EXIT WHEN ConColumns%NOTFOUND;
        IF (DebugFlag = 'Y' AND DebugLevel >= 99)
        THEN
          BEGIN
            dbms_output.put_line(tLineNum || 'Found CONSTRAINT_NAME = ' || tt_CONSTRAINT_NAME);
            dbms_output.put_line(tLineNum || 'Found TABLE_NAME = ' || tt_TABLE_NAME);
            dbms_output.put_line(tLineNum || 'Found COLUMN_NAME = ' || tt_COLUMN_NAME);
            dbms_output.put_line(tLineNum || 'Found POSITION = ' || tt_POSITION);
          END;
        END IF;

        BEGIN


		
          SELECT 1
          INTO   tt_Dummy
          FROM   user_ind_columns
          WHERE  TABLE_NAME = tt_TABLE_NAME AND COLUMN_NAME = tt_COLUMN_NAME AND
                 COLUMN_POSITION = tt_POSITION;

          IF (DebugFlag = 'Y' AND DebugLevel >= 99)
          THEN
            BEGIN
              
              dbms_output.put_line(tLineNum || 'Row Has matching Index');
            END;
          END IF;
        EXCEPTION
          WHEN Too_Many_Rows THEN
            IF (DebugFlag = 'Y' AND DebugLevel >= 99)
            THEN
              BEGIN
                
                dbms_output.put_line(tLineNum || 'Row Has matching Index');
              END;
            END IF;

          WHEN no_data_found THEN
            IF (DebugFlag = 'Y' AND DebugLevel >= 99)
            THEN
              BEGIN
                
                dbms_output.put_line(tLineNum || 'NO MATCH FOUND');
              END;
            END IF;

            t_Error_Found := 'Y';

            SELECT DISTINCT TABLE_NAME
            INTO   tt_dummyChar
            FROM   user_cons_columns
            WHERE  OWNER = USER AND CONSTRAINT_NAME = t_R_CONSTRAINT_NAME;

            
            table_index := table_index + 1;
            dbms_output.put_line(tLineNum || 'Changing data in table ' || tt_dummyChar );
            dbms_output.put_line(tLineNum || '   will lock table ' || tt_TABLE_NAME);
            dbms_output.put_line(chr(0));
            dbms_output.put_line(tLineNum || 'Create an index on ' || tt_TABLE_NAME );
            dbms_output.put_line(tLineNum || '   with the following columns to remove lock problem:');

		    OPEN IndexColumns;
            LOOP
              FETCH IndexColumns
                INTO Err_TABLE_NAME, Err_COLUMN_NAME, Err_POSITION;
              EXIT WHEN IndexColumns%NOTFOUND;
 			  	dbms_output.put_line(tLineNum||'Column = ' || Err_COLUMN_NAME || ' (' || Err_POSITION || ')');
            END LOOP;
			CLOSE IndexColumns;
			


			
            dbms_output.put_line(chr(0));
            dbms_output.put_line('CREATE INDEX TL_'|| tt_TABLE_NAME ||'_'|| table_index || ' on ' || tt_TABLE_NAME );
            dbms_output.put_line('(');

			
			virgola:= 0;
		    OPEN IndexColumns;
            LOOP
              FETCH IndexColumns
                INTO Err_TABLE_NAME, Err_COLUMN_NAME, Err_POSITION;
              EXIT WHEN IndexColumns%NOTFOUND;
              
--			  dbms_output.put_line ('>>>>>' ||IndexColumns%ROWCOUNT);
--              dbms_output.put_line(tLineNum||'Column = ' || Err_COLUMN_NAME || ' (' || Err_POSITION || ')');

            	if virgola = 0 then
				   dbms_output.put_line(Err_COLUMN_NAME);
				   	virgola := 1;

				else 
					dbms_output.put_line(',' || Err_COLUMN_NAME);
				end if;

            END LOOP;
            dbms_output.put_line(');');

            CLOSE IndexColumns;
        END;
      END LOOP;
      CLOSE ConColumns;
    END LOOP;
    IF (t_Error_Found = 'N')
    THEN
      BEGIN
        
        dbms_output.put_line(tLineNum || 'No foreign key errors found');
      END;
    END IF;
    CLOSE TableCons;
  END LOOP;
END testfklocks;
/
