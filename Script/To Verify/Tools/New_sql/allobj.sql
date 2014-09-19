-- ======================================================
-- Script to identify everything to do with a table.
--
-- This includes a DESC equivalent, sizing information, Triggers, Constraints, Granted priviliges
-- that are associated with a table or from other tables foreign keys that reference
-- that table.
--
-- Instructions
-- ============
-- Either run this script logged on to SYS or SYSTEM or GRANT SELECT on the DICTIONARY
-- TABLES:
--
-- DBA_TAB_COLUMNS
-- V$DATABASE
-- DBA_TABLES
-- DBA_EXTENTS
-- DBA_CONS_COLUMNS 
-- DBA_CONSTRAINTS
-- DBA_TRIGGERS
-- DBA_TAB_PRIVS
-- DBA_COL_PRIVS
--
-- At SQL*PLUS You will be requested to enter the schema owner and the tablename.
-- If you want a count of the number of rows in that table you will need to manually
-- edit this file beforehand.
--
--
-- Mark Searle
-- Searle Database Systems Ltd -  marksearle@mistral.co.uk
-- FILE NAME: DISPLAY_.SQL
-- Last Modified 10/01/97
--
--======================================================

-- ================================================
--
-- INSTRUCTIONS FOR MODIFICATION
-- =============================
-- 
-- SHOW THE DATABASE AND USER THAT YOU ARE LOGGED ONTO.
-- ========================================================

SELECT * FROM SYS.V_$DATABASE;

SHOW USER

SET ECHO ON FEED ON  ARRAYSIZE 1  LONG 5000 VERIFY OFF TIMING ON

-- GET ALL TABLE DETAILS
-- =====================
-- =====================

-- If ANALYZE STATISTICS has not been run then count number of rows
-- in table.
-- =====================================================================

--O N L Y   E D I T   I F   N E E D   T H E   C O U N T (*)
--??????????????????????????????????????????????????????

-- SELECT COUNT(*) FROM OPS$ISSPOWN.STANDARD_TEST_RESULT;


-- Show the Table Structure
-- ========================

COLUMN POS FORMAT 999 heading "POS"
COLUMN PCT_FREE FORMAT A4 heading "Null"


SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE, COLUMN_ID POS
FROM   SYS.DBA_TAB_COLUMNS
WHERE  OWNER = upper('&&owner')
AND    TABLE_NAME = upper('&&table')
ORDER  BY COLUMN_ID;



-- Show Physical Attributes
-- ========================
COLUMN PCT_FREE FORMAT 999 heading "%|Free"
COLUMN PCT_INCREASE FORMAT 999 heading "%|Incr"
COLUMN INITIAL_EXTENT FORMAT 999999999 heading "Init|Extent"
COLUMN NEXT_EXTENT FORMAT    9999999999999 heading "Next|Extent"
COLUMN MAX_EXTENTS FORMAT 999 heading "Max|Ext"
COLUMN AVG_ROW_LEN FORMAT 99999 heading "Avg|Row|Len"

SELECT PCT_FREE,
       PCT_INCREASE,
       INITIAL_EXTENT,
       NEXT_EXTENT,
       MAX_EXTENTS,
       NUM_ROWS,
       AVG_ROW_LEN
FROM   SYS.DBA_TABLES
WHERE  OWNER = upper('&&owner')
AND    TABLE_NAME = upper('&&table');


-- Show the actual Maximum Size of a Row
-- ==============================

SELECT SUM(DATA_LENGTH)
FROM   SYS.DBA_TAB_COLUMNS
WHERE  OWNER = upper('&&owner')
AND    TABLE_NAME = upper('&&table');


-- Show the Number of Physical EXTENTS that have been allocated Attributes
-- ========================================================

COLUMN SEGMENT_NAME FORMAT A30 HEADING 'Table Name'
COLUMN COUNTER FORMAT 9999 HEADING 'Number Of Extents Used'

SELECT SEGMENT_NAME, COUNT(*) COUNTER
FROM   SYS.DBA_EXTENTS
WHERE  OWNER = upper('&&owner')
AND    SEGMENT_NAME = upper('&&table')
GROUP  BY SEGMENT_NAME;



COLUMN TABSIZE FORMAT 999999999999 HEADING 'Table Size In Bytes'

-- Show the Physical SIZE IN BYTES of the TABLE
-- =====================================

SELECT SEGMENT_NAME, SUM(BYTES) TABSIZE
FROM   SYS.DBA_EXTENTS
WHERE  OWNER = upper('&&owner')
AND    SEGMENT_NAME = upper('&&table')
GROUP  BY SEGMENT_NAME;




-- GET ALL THE INDEX DETAILS
-- =========================
-- =========================


-- Show all the indexes and their columns for this table
-- =====================================================

COLUMN OWNER FORMAT A8 heading "Index|Owner"
COLUMN TABLE_OWNER FORMAT A8 heading "Table|Owner"
COLUMN INDEX_NAME FORMAT A30 heading "Index Name"
COLUMN COLUMN_NAME FORMAT A30 heading "Column Name"
COLUMN COLUMN_POSITION FORMAT 9999 heading "Pos"
BREAK ON CONSTRAINT_NAME SKIP PAGE

SELECT IND.OWNER,
       IND.TABLE_OWNER,
       IND.INDEX_NAME,
       IND.UNIQUENESS,
       COL.COLUMN_NAME,
       COL.COLUMN_POSITION
FROM   SYS.DBA_INDEXES IND,
       SYS.DBA_IND_COLUMNS COL
WHERE  IND.TABLE_NAME = upper('&&table')
AND    IND.TABLE_OWNER = upper('&&owner')
AND    IND.TABLE_NAME = COL.TABLE_NAME
AND    IND.OWNER = COL.INDEX_OWNER
AND    IND.TABLE_OWNER = COL.TABLE_OWNER
AND    IND.INDEX_NAME = COL.INDEX_NAME;

-- Display all the physical details of the Primary and Other
-- Indexes for this table
-- =========================================================
COLUMN OWNER FORMAT A8 heading "Index|Owner"
COLUMN TABLE_OWNER FORMAT A8 heading "Table|Owner"
COLUMN INDEX_NAME FORMAT A30 heading "Index Name"
COLUMN COLUMN_NAME FORMAT A30 heading "Column Name"
COLUMN COLUMN_POSITION FORMAT 9999 heading "Pos"
COLUMN PCT_FREE FORMAT 999 heading "%|Free"
COLUMN PCT_INCREASE FORMAT 999 heading "%|Incr"
COLUMN INITIAL_EXTENT FORMAT 999999999 heading "Init|Extent"
COLUMN NEXT_EXTENT FORMAT 999999999 heading "Next|Extent"
COLUMN MAX_EXTENTS FORMAT 999 heading "Max|Ext"

SELECT
IND.OWNER,
IND.TABLE_OWNER,
IND.INDEX_NAME,
IND.UNIQUENESS,
COL.COLUMN_NAME,
COL.COLUMN_POSITION,
IND.PCT_FREE,
IND.PCT_INCREASE,
IND.INITIAL_EXTENT,
IND.NEXT_EXTENT,
IND.MAX_EXTENTS
FROM DBA_INDEXES IND,
     DBA_IND_COLUMNS COL
WHERE IND.TABLE_NAME = upper('&&table')
AND IND.TABLE_OWNER = upper('&&owner')
AND IND.TABLE_NAME = COL.TABLE_NAME
AND IND.OWNER = COL.INDEX_OWNER
AND IND.TABLE_OWNER = COL.TABLE_OWNER
AND IND.INDEX_NAME = COL.INDEX_NAME;

--
-- GET ALL THE CONSTRAINT DETAILS
-- ==============================
-- ==============================

-- Show the Non-Foreign Keys Constraints on this table
-- ====================================================================
COLUMN OWNER FORMAT A9 heading "Owner"
COLUMN CONSTRAINT_NAME FORMAT A30 heading "Constraint|Name"
COLUMN R_CONSTRAINT_NAME FORMAT A30 heading "Referenced|Constraint|Name"
COLUMN DELETE_RULE FORMAT A9 heading "Del|Rule"
COLUMN TABLE_NAME FORMAT A18 heading "Table Name"
COLUMN COLUMN_NAME FORMAT A30 heading "Column Name"
--COLUMN CONSTRAINT_TYPE FORMAT A4 heading "Type"
--COLUMN POSITION ALIAS POS
--COLUMN POSITION 9999 heading "Pos"
COLUMN POSITION FORMAT 9999 heading "Pos"
BREAK ON CONSTRAINT_NAME SKIP PAGE



SELECT COL.OWNER,
       COL.CONSTRAINT_NAME,
       COL.COLUMN_NAME,
       COL.POSITION,
--     CON.CONSTRAINT_TYPE
DECODE (CON.CONSTRAINT_TYPE,
       'P','primary','R','foreign','U','unique','C','check') "Type"
FROM   DBA_CONS_COLUMNS COL,
       DBA_CONSTRAINTS CON
WHERE  COL.OWNER = upper('&&owner')
AND    COL.TABLE_NAME = upper('&&table')
AND    CONSTRAINT_TYPE <> 'R'
AND    COL.OWNER = CON.OWNER
AND    COL.TABLE_NAME = CON.TABLE_NAME
AND    COL.CONSTRAINT_NAME = CON.CONSTRAINT_NAME
ORDER BY COL.CONSTRAINT_NAME, COL.POSITION;


-- Show the Foreign Keys on this table pointing at other tables Primary
-- Key Fields for referential Integrity purposes.
-- ====================================================================


SELECT CON.OWNER,
       CON.TABLE_NAME,
       CON.CONSTRAINT_NAME,
       CON.R_CONSTRAINT_NAME,
       CON.DELETE_RULE,
       COL.COLUMN_NAME,
       COL.POSITION,
--     CON1.OWNER,
       CON1.TABLE_NAME "Ref Tab",
       CON1.CONSTRAINT_NAME "Ref Const"
--     COL1.COLUMN_NAME "Ref Column",
--     COL1.POSITION
--FROM   DBA_CONS_COLUMNS COL,
FROM   DBA_CONSTRAINTS CON1,
       DBA_CONS_COLUMNS COL,
       DBA_CONSTRAINTS CON
WHERE  CON.OWNER = upper('&&owner')
AND    CON.TABLE_NAME = upper('&&table')
AND    CON.CONSTRAINT_TYPE = 'R'
AND    COL.OWNER = CON.OWNER
AND    COL.TABLE_NAME = CON.TABLE_NAME
AND    COL.CONSTRAINT_NAME = CON.CONSTRAINT_NAME
-- Leave out next line if looking for other Users with Foriegn Keys.
AND    CON1.OWNER = CON.OWNER
AND    CON1.CONSTRAINT_NAME = CON.R_CONSTRAINT_NAME
AND    CON1.CONSTRAINT_TYPE IN ( 'P', 'U' );
-- The extra DBA_CONS_COLUMNS will give details of refered to columns,
-- but has a multiplying effect on the query results.
-- NOTE: Could use temporary tables to sort out.
--AND    COL1.OWNER = CON1.OWNER
--AND    COL1.TABLE_NAME = CON1.TABLE_NAME
--AND    COL1.CONSTRAINT_NAME = CON1.CONSTRAINT_NAME;



-- Show the Foreign Keys pointing at this table via the recursive call
-- to the Constraints table.
-- ================================================================

SELECT CON1.OWNER,
       CON1.TABLE_NAME,
       CON1.CONSTRAINT_NAME,
       CON1.DELETE_RULE,
       CON1.STATUS,     
       CON.TABLE_NAME,
       CON.CONSTRAINT_NAME,
       COL.POSITION,
       COL.COLUMN_NAME
FROM   DBA_CONSTRAINTS CON,
       DBA_CONS_COLUMNS COL,
       DBA_CONSTRAINTS CON1
WHERE  CON.OWNER = upper('&&owner')
AND    CON.TABLE_NAME = upper('&&table')
AND    ((CON.CONSTRAINT_TYPE = 'P') OR (CON.CONSTRAINT_TYPE = 'U'))
AND    COL.TABLE_NAME = CON1.TABLE_NAME
AND    COL.CONSTRAINT_NAME = CON1.CONSTRAINT_NAME
AND    CON1.OWNER = CON.OWNER
AND    CON1.R_CONSTRAINT_NAME = CON.CONSTRAINT_NAME
AND    CON1.CONSTRAINT_TYPE = 'R'
GROUP BY CON1.OWNER,
         CON1.TABLE_NAME,
         CON1.CONSTRAINT_NAME,
         CON1.DELETE_RULE,
         CON1.STATUS,     
         CON.TABLE_NAME,
         CON.CONSTRAINT_NAME,
         COL.POSITION,
         COL.COLUMN_NAME;



--
-- Show all the check Constraints
-- ==========================================================

SET  HEADING OFF

SELECT 'alter table ', TABLE_NAME, ' add constraint ',
        CONSTRAINT_NAME, ' check ( ', SEARCH_CONDITION, ' ); '
FROM DBA_CONSTRAINTS
WHERE OWNER = upper('&&owner')
AND TABLE_NAME = upper('&&table')
AND CONSTRAINT_TYPE = 'C';

--
-- Show all the Triggers that have been created on this table
-- ==========================================================

-- add query to extract Trigger Body etcc WHEN CLAUSE here.

SET ARRAYSIZE 1
SET LONG 6000000


SELECT OWNER,
'CREATE OR REPLACE TRIGGER ',
       TRIGGER_NAME,
       DESCRIPTION,
       TRIGGER_BODY,
       '/'
FROM  DBA_TRIGGERS
WHERE OWNER = upper('&&owner')
AND   TABLE_NAME = upper('&&table');



--
-- Show all the GRANTS made on this table and it's columns.
-- ========================================================


-- Table 1st
-- =========
SELECT 'GRANT ',
        PRIVILEGE,
      ' ON ',
        TABLE_NAME,
      ' TO ',
        GRANTEE,
       ';'
FROM DBA_TAB_PRIVS
WHERE OWNER = upper('&&owner')
AND   TABLE_NAME = upper('&&table');

-- Columns 2nd
-- ===========

SELECT 'GRANT ',
        PRIVILEGE,
      ' ( ',
        COLUMN_NAME,
      ' ) ',
      ' ON ',
        TABLE_NAME,
      ' TO ',
        GRANTEE,
       ';'
FROM DBA_COL_PRIVS
WHERE OWNER = upper('&&owner')
AND   TABLE_NAME = upper('&&table');

SET  HEADING ON 

--EXIT

