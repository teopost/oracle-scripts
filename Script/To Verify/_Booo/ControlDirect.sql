REM control.sql script  

SET ECHO off  
REM    REQUIREMENTS 
REM    SELECT privileges on the table  
REM -------------------------------------------------------------------------- ----  
REM PURPOSE:  
REM    Prepares a SQL*Loader control file for a table already existing in the   
REM    database.  The script accepts the table name and automatically creates  
REM    a file with the table name and extension 'ctl'.    
REM    This is especially useful if you have the DDL statement to create a   
REM    particular table and have a free-format ASCII-delimited file but have   
REM    not yet created a SQL*Loader control file for the loading operation.   
REM  
REM    Default choices for the file are as follows (alter to your needs):  
REM    	Delimiter: 			comma (',')  
REM    	INFILE file extension: 		.dat  
REM    	DATE format:			'MM/DD/YY'  
REM  
REM    You may define the Loader Data Types of the other Data Types by   
REM    revising the decode function pertaining to them.  
REM   
REM ---------------------------------------------------------------------------  
REM EXAMPLE:  
REM    SQL> start control.sql emp  
REM  
REM    LOAD DATA                                                
REM    INFILE 'EMP.dat'                                  
REM    INTO TABLE EMP                    
REM    FIELDS TERMINATED BY ','          
REM    (                                              
REM                            
REM       EMPNO              
REM     , ENAME                                                    
REM     , JOB                                                      
REM     , MGR                                                    
REM     , HIREDATE      DATE "DD/MM/YYYY"                            
REM     , SAL                        
REM     , COMM          
REM     , DEPTNO                                                   
REM                                                          
REM    )                                            
REM   
REM ---------------------------------------------------------------------------  
REM DISCLAIMER:  
REM    This script is provided for educational purposes only. It is NOT   
REM    supported by Oracle World Wide Technical Support.  
REM    The script has been tested and appears to work as intended.  
REM    You should always run new scripts on a test instance initially.  
REM --------------------------------------------------------------------------  
REM Main text of script follows:  
  
set heading off  
set verify off  
set feedback off  
set show off  
set trim off  
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
SELECT decode(rownum,1,'   ',' , ')||rpad(column_name,33,' ')  
|| decode(data_type,  
               'VARCHAR2','CHAR NULLIF('|| column_name ||'=BLANKS)',  
            'FLOAT',   'DECIMAL EXTERNAL NULLIF('||column_name||'=BLANKS)',  
           'NUMBER',  
                     decode(data_precision,  
                0, 'INTEGER EXTERNAL NULLIF ('||column_name   
||'=BLANKS)',  
                          decode(data_scale,0,  
        'INTEGER EXTERNAL NULLIF   
('||column_name ||'=BLANKS)',  
                         'DECIMAL EXTERNAL NULLIF   
('||column_name ||'=BLANKS)'   
                                     )  
                           ),  
     'DATE',    'DATE "DD/MM/YYYY"  NULLIF ('||column_name   
||'=BLANKS)',NULL)  
FROM user_tab_columns  
WHERE TABLE_NAME = UPPER('&1')  
ORDER BY COLUMN_ID;  
SELECT ')'   
FROM sys.dual;  
spool off  
