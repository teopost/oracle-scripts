set heading off
set verify off
set feedback off
set show off
set trim ON
set pages 0
set concat on
spool &1..ctl
SELECT
	'OPTIONS(DIRECT=TRUE)'||chr(10)
	||'LOAD DATA'||chr(10)
	||'INFILE '''||lower(table_name)||'.dat'' '||chr(10)
	||'INTO TABLE '||table_name||chr(10)
	||'FIELDS TERMINATED BY ''|'' '||chr(10)
	||'TRAILING NULLCOLS'||chr(10)
	||'('
FROM user_tables
WHERE TABLE_NAME = UPPER('&1');
SELECT DECODE(ROWNUM,1,'   ',' , ')||RPAD(column_name,33,' ')
          ||DECODE(data_type,
       	   'VARCHAR2', 'CHAR NULLIF('|| column_name ||'=BLANKS)',
       	   'FLOAT',    'DECIMAL EXTERNAL NULLIF('||column_name||'=BLANKS)',
       	   'NUMBER',   decode(data_precision,
       			0, 'INTEGER EXTERNAL NULLIF ('||column_name||'=BLANKS)', 
       				decode(data_scale, 
       					0, 'INTEGER EXTERNAL NULLIF ('||column_name ||'=BLANKS)',
                         		   'DECIMAL EXTERNAL NULLIF ('||column_name ||'=BLANKS)'
                                      )
                              ),
	   'DATE',    'DATE "DD/MM/YYYY"  NULLIF ('||column_name||'=BLANKS)',
	   NULL)
FROM 
	user_tab_columns
WHERE 
	TABLE_NAME = UPPER('&1')
ORDER BY 
	COLUMN_ID;

SELECT ')' FROM sys.dual;

spool off
