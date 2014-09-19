/*
 ===========================================================
 Filename...: DBCheck.sql
 Author.....: Stefano Teodorani
 Release....: 4.3 - 14-mar-2001
 Description: Report database in formato HTML
 Notes......: Viene creato un file chiamato dbcheck.html sotto c:\
 ===========================================================
*/ 


clear breaks
clear computes

undefine cliente
accept cliente char prompt 'Inserire il nome del cliente: '

set arraysize 1
set heading off
set feedback off  
set verify off
set termout off

spool c:\DBCheck.htm

set lines 255
set pages 9999

alter session set NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';

-- Intestazione
-- ------------
prompt <HTML>
prompt <HEAD>
prompt <TITLE>DBCheck.sql by S. Teodorani</TITLE>
prompt <STYLE TYPE="text/css">
prompt <!-- TD {font-size: 8pt; font-family: Tahoma; font-style: normal} -->
prompt <!-- P  {font-size: 8pt; font-family: Tahoma; font-style: normal} -->
prompt </STYLE>
prompt </HEAD>
prompt <BODY>

-- Titolo
-- ------
prompt <A NAME="indice"></A>
prompt <P align="left"><font size="5" color=BLUE>
select Upper('&&Cliente') from dual;
prompt </P>
prompt <P>
select '<BR>Report creato il: '|| sysdate from dual;
prompt </P>
-- Riga ------------------------------------------------------------------------
prompt <HR>

-- Indice
-- ------
prompt <P> <B>
prompt INDICE
prompt </B>
prompt <BR>
prompt <BR> <A HREF="#versioni">Versioni installate sull'istanza</A>
prompt <BR> <A HREF="#opzioni">Opzioni di Oracle installate sull'istanza</A>		  
prompt <BR> <A HREF="#initorcl">File di configurazione initORCL.ora</A>  
prompt <BR> <A HREF="#spazio">Report spazio allocato per utente</A>  
prompt <BR> <A HREF="#hit1">Hit Ratio</A>  
prompt <BR> <A HREF="#hit2">Hit Ratio2</A>  
prompt <BR> <A HREF="#logbuffer">Log Buffer</A>  
prompt <BR> <A HREF="#sga">SGA</A>  
prompt <BR> <A HREF="#tablespace"> Tablespace Space </A>  
prompt <BR> <A HREF="#tablespace_config"> Tablespace config</A>  
prompt <BR> <A HREF="#datafile"> Datafile Phisical Reads</A>  
prompt <BR> <A HREF="#rollback"> Rollback Segments</A>  
prompt <BR> <A HREF="#degree"> Grado di parallelismo</A>  
prompt <BR> <A HREF="#enqueue"> Enqueue Resource</A>  
prompt <BR> <A HREF="#sort"> Sort Statistics</A>  
prompt <BR> <A HREF="#rbssuf"> Sono sufficienti i rollback segments ?</A>  
prompt <BR> <A HREF="#rbsusr"> Utilizzo dei Rollback per utente</A>  
prompt </P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Controllo versioni oracle
-- -------------------------

prompt <A NAME="versioni"></A>
prompt <P><B>ORACLE Version</B></P>

prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=2 BGCOLOR=RED><font color=white>
prompt <B>Query su V$VERSION</B></TD></TR>
prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> RELEASE </TD>
prompt </TR>
select  '<TR> <TD>',
	BANNER,
	' </TD> </TR>'from v$version;
prompt </TABLE>

prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Controllo opzioni oracle
-- ------------------------
prompt <A NAME="opzioni"></A>
prompt <P><B>ORACLE Option</B></P>
prompt <P>Il parametro Parallel Query non deve essere installato</P>

prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=2 BGCOLOR=RED><font color=white>
prompt <B>Query su V$OPTION</B></TD></TR>
prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> PARAMETRO </TD>
prompt <TD BGCOLOR=GREEN><font color=white> VALORE </TD>
prompt </TR>
select  '<TR> <TD> ' || parameter || ' </TD> <TD> ' || value ||' </TD></TR>' from v$option;
prompt </TABLE>

prompt <P> <A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Parametri Iniorcl.ora
-- ---------------------
prompt <A NAME="initorcl"></A>
prompt <P><B>INITORCL.ora file</B></P>
prompt <P>Il parametro db_block_size non deve mai essere inferiore a 4096</P>

prompt <TABLE BORDER=1>
prompt  <TR>
prompt    <TD COLSPAN=2 BGCOLOR=RED><font color=white>
prompt 	    <B>Query su V$PARAMETER</B>
prompt    </TD>
prompt  </TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> PARAMETRO </TD>
prompt <TD BGCOLOR=GREEN><font color=white> VALORE </TD>
prompt </TR>
select  '<TR>',
	DECODE(upper(ltrim(rtrim(name))),
		'DB_BLOCK_SIZE',	'<TD BGCOLOR=YELLOW> <B>' || name || '</B></TD> <TD BGCOLOR=YELLOW>'|| '<B>' || nvl(value,'empty') || '<B>'||'</TD></TR>',
		'SHARED_POOL_SIZE',	'<TD BGCOLOR=YELLOW> <B>' || name || '</B></TD> <TD BGCOLOR=YELLOW>'|| '<B>' || nvl(value,'empty') || '<B>'||'</TD></TR>',
		'OPTIMIZER_MODE',	'<TD BGCOLOR=YELLOW> <B>' || name || '</B></TD> <TD BGCOLOR=YELLOW>'|| '<B>' || nvl(value,'empty') || '<B>'||'</TD></TR>',
		'DB_BLOCK_BUFFERS',	'<TD BGCOLOR=YELLOW> <B>' || name || '</B></TD> <TD BGCOLOR=YELLOW>'|| '<B>' || nvl(value,'empty') || '<B>'||'</TD></TR>',
		'LOG_BUFFER',		'<TD BGCOLOR=YELLOW> <B>' || name || '</B></TD> <TD BGCOLOR=YELLOW>'|| '<B>' || nvl(value,'empty') || '<B>'||'</TD></TR>',
		'<TD>'||name ||'</TD> <TD>'||nvl(value,'empty')||' </TD></TR>' )
from v$parameter
ORDER BY NAME;

prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Elenco Utenti dell'istanza
-- --------------------------
col TOT_TABLESPACE format 999,999,999,999 HEADING 'TOTALE|SPAZIO' noprint

prompt <A NAME="spazio"></A>
prompt <P><B>Allocazione Spazio per Utente</B></P>
prompt <P>
Select 	'Spazio totale allocato sull''istanza: ' || to_char(sum(bytes),'999,999,999,999,999')
from    dba_data_files
where   tablespace_name = 'USER_DATA'
;
prompt </P>

prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=5 BGCOLOR=RED><font color=white>
prompt <B>Spazio allocato in bytes</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> UTENTE </TD>
prompt <TD BGCOLOR=GREEN><font color=white> DATA CREAZIONE</TD>
prompt <TD BGCOLOR=GREEN><font color=white> BYTES TOTALI </TD>
prompt <TD BGCOLOR=GREEN><font color=white> PERC </TD>
prompt </TR>

select  '<TR> <TD> ' || a.Username || ' </TD> ' ,
        '<TD> <p align="center">' || to_char(c.Created,'DD-Mon-YYYY') || ' </TD> ' ,
        '<TD> <p align="right">' || to_char(a.bytes,'999,999,999,999') || ' </TD>' BYTES_A,
        '<TD> <p align="right">' || to_char(sum(b.bytes),'999,999,999,999')  || ' </TD> '  TOT_TABLESPACE,
        '<TD> <p align="right">' || to_char((a.bytes/sum(b.bytes))*100, '99.99')  || ' </TD> </TR>' PCT
from   DBA_TS_QUOTAS a,
       dba_data_files b,
       all_users c
where  a.tablespace_name = b.tablespace_name 
and 	a.Username = c.username
and    a.tablespace_name = 'USER_DATA'
group by a.Username, to_char(c.Created,'DD-Mon-YYYY'), a.bytes
order by 5 desc;

select  '<TR> <TD></TD> <TD></TD> <TD BGCOLOR=YELLOW><p align="right">',
	to_char(sum(bytes),'9,999,999,999,999'),
        '</TD> </TR>'
from 	DBA_TS_QUOTAS;
prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A> <A HREF="#tablespace">[Spazio Allocato Tablespace]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Hit Ratio
-- --------------------------
col TOT_TABLESPACE format 999,999,999,999 HEADING 'TOTALE|SPAZIO' noprint

prompt <A NAME="hit1"></A>
prompt <P><B>Hit Ratio</B></P>
prompt <P>Se Hit Ratio e' minore del 70% incrementare DB_BLOCK_BUFFER</P>

prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=4 BGCOLOR=RED><font color=white>
prompt <B>Calculate Hit-Ratio</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Physical Reads </TD>
prompt <TD BGCOLOR=GREEN><font color=white> Consistent Gets</TD>
prompt <TD BGCOLOR=GREEN><font color=white> DB Block Gets </TD>
prompt <TD BGCOLOR=GREEN><font color=white> Hit Ratio </TD>
prompt </TR>

select  '<TR> <TD> ' || to_char(pr.value, '9,999,999,999,999') || ' </TD> ',
	'<TD> ' || to_char(cg.value, '9,999,999,999,999') || ' </TD> ',
	'<TD> ' || to_char(bg.value, '9,999,999,999,999') || ' </TD> ',
	'<TD> ' || to_char(round((1-(pr.value/(bg.value+cg.value)))*100,2), '999.99') || ' </TD></TR>'
from    v$sysstat pr, v$sysstat bg, v$sysstat cg
where   pr.name = 'physical reads'
and     bg.name = 'db block gets'
and     cg.name = 'consistent gets'
;
prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Shared pool size
-- --------------------------
prompt <A NAME="hit2"></A>
prompt <P><B>Shared pool size</B></P>
prompt <P>Se % Ratio e' maggiore del 1%, aumentare SHARED_POOL_SIZE</P>

prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=3 BGCOLOR=RED><font color=white>
prompt <B>Calculate Hit-Ratio</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Executions </TD>
prompt <TD BGCOLOR=GREEN><font color=white> Cache Misses Executing</TD>
prompt <TD BGCOLOR=GREEN><font color=white> % Ratio </TD>
prompt </TR>

select '<TR><TD> ' || to_char(sum(pins), '9,999,999,990') || '</TD>',
       '<TD>' || to_char(sum(reloads),'9,999,999,990') || '</TD>',
       '<TD>' || to_char((sum(reloads)/sum(pins)*100), '999.99')|| '</TD></TR>'
from v$librarycache
;
prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Log Buffer
-- ----------
prompt <A NAME="logbuffer"></A>
prompt <P><B>Log Buffer</B></P>
prompt <P>Se il valore e' maggiore di 0 incrementare il LOG_BUFFER</P>

prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=3 BGCOLOR=RED><font color=white>
prompt <B>Calculate Log Buffer</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Nome </TD>
prompt <TD BGCOLOR=GREEN><font color=white> Valore</TD>
prompt </TR>

select  '<TR><TD> ' || substr(name,1,25) || '</TD>',
        '<TD>' || substr(value,1,15) || '</TD></TR>'
from v$sysstat
where name = 'redo log space requests'
;
prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- SGA
-- ----------
prompt <A NAME="sga"></A>
prompt <P><B>SGA</B></P>
prompt <P>none</P>

--prompt <P>
prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=3 BGCOLOR=RED><font color=white>
prompt <B>Calculate the SGA Value</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Nome </TD>
prompt <TD BGCOLOR=GREEN><font color=white> Valore</TD>
prompt </TR>

select  '<TR><TD> ' || name || '</TD>',
        '<TD>' || to_char(value,'9,999,999,999,999') || '</TD></TR>'
from v$sga
;
select  '<TR><TD> </TD><TD BGCOLOR=YELLOW>' || to_char(sum(value),'9,999,999,999,999') || '</TD></TR>'
from v$sga
;
prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Tablespace
-- ----------
prompt <A NAME="tablespace"></A>
prompt <P><B>TableSpace</B></P>
prompt <P>Se una tablepace as tutti i datafiles con la percentuale usata maggiore dell'80%, aggiungere altri datafiles.</P>
prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=6 BGCOLOR=RED><font color=white>
prompt <B>Calculate Tablespace dimension</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Name</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Total Bytes</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Bytes Used</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Bytes Free</TD>
prompt <TD BGCOLOR=GREEN><font color=white> % Used</TD>
prompt </TR>
CREATE TABLE TMP_TABLESPACE (TABLESPACE_NAME, TOT_BYTES, OCC_BYTES, FREE_SPACE)
AS
select tablespace_name, sum(bytes), 9999999999999999999 , 9999999999999999999 from sys.dba_data_files
group by  tablespace_name
;
UPDATE TMP_TABLESPACE 
SET free_SPACE = NULL;

UPDATE TMP_TABLESPACE a
SET FREE_SPACE = ( SELECT 
			SUM(BYTES) 
		   FROM 
			SYS.DBA_FREE_SPACE h 
			WHERE H.TABLESPACE_NAME = A.TABLESPACE_NAME
		 )
;
UPDATE TMP_TABLESPACE 
SET OCC_BYTES = TOT_BYTES - FREE_SPACE
;
col TOT_BYTES  format 999,999,999,999,999
col OCC_BYTES  format 999,999,999,999,999
col FREE_BYTES format 999,999,999,999,999
col PERC       format 999.99

SELECT  '<TR><TD> ' || TABLESPACE_NAME || '</TD>', 
	'<TD> <p align="right">' || to_char(TOT_BYTES,'9,999,999,999,999') || '</TD>',
	'<TD> <p align="right">' || to_char(OCC_BYTES,'9,999,999,999,999') || '</TD>',
	'<TD> <p align="right">' || to_char(FREE_SPACE,'9,999,999,999,999') || '</TD>',
	'<TD> <p align="right">' || to_char(100*occ_bytes/tot_bytes,'999.99') || '</TD>'
FROM 	TMP_TABLESPACE
;

DROP TABLE  TMP_TABLESPACE;
prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Tablespace configuration
-- ------------------------
prompt <A NAME="tablespace_config"></A>
prompt <P><B>TableSpace Config</B></P>
prompt <P>Nessuno</P>
prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=7 BGCOLOR=RED><font color=white>
prompt <B>Calculate Tablespace Configuration</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Name</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Initial Extent</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Next Extents</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Min Extents</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Max Extents</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Pct Increase</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Status</TD>
prompt </TR>

select
  '<TR><TD> ' || tablespace_name || '</TD>',
  '<TD> <p align="right">' || initial_extent/1024  || '</TD>',
  '<TD> <p align="right">' || next_extent/1024  || '</TD>',
  '<TD> <p align="right">' || min_extents || '</TD>',
  '<TD> <p align="right">' || max_extents || '</TD>',
  '<TD> <p align="right">' || pct_increase || '</TD>',
  '<TD> <p align="center">' || status || '</TD> </TR>'
from sys.dba_tablespaces
order by tablespace_name;
prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Datafile configuration
-- -----------------------
prompt <A NAME="datafile"></A>
prompt <P><B>Datafile Config</B></P>
prompt <P>Per ridurre l'I/O , assicurarsi che i datafiles con maggior attivita' non siano sullo stesso disco</P>
prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=9 BGCOLOR=RED><font color=white>
prompt <B>Datafile Configuration</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Id</TD>
prompt <TD BGCOLOR=GREEN><font color=white> File Name</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Phy Reads</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Phy Writes</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Blk Reads</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Blk Writes</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Read Time</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Write Time</TD>
prompt <TD BGCOLOR=GREEN><font color=white> File Total</TD>
prompt </TR>

select '<TR> <TD>',
       substr(df.file#,1,2) "ID",
       '</TD> <TD>',
       name "File Name",
       '</TD> <TD> <p align="right">',
       substr(phyrds,1,10) "Phy Reads",
       '</TD> <TD> <p align="right">',
       substr(phywrts,1,10) "Phy Writes",
       '</TD> <TD> <p align="right">',
       substr(phyblkrd,1,10) "Blk Reads",
       '</TD> <TD> <p align="right">',
       substr(phyblkwrt,1,10) "Blk Writes",
       '</TD> <TD> <p align="right">',
       substr(readtim,1,9) "Read Time",
       '</TD> <TD> <p align="right">',
       substr(writetim,1,10) "Write Time",
       '</TD> <TD> <p align="right">',
       (sum(phyrds+phywrts+phyblkrd+phyblkwrt+readtim)),
       '</TD> </TR>'
from v$filestat fs, v$datafile df
where fs.file# = df.file#
group by df.file#, df.name, phyrds, phywrts, phyblkrd,
         phyblkwrt, readtim, writetim
order by sum(phyrds+phywrts+phyblkrd+phyblkwrt+readtim) desc, df.name
;
prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Rollback Segments
-- -----------------
prompt <A NAME="rollback"></A>
prompt <P><B>Rollback Segments</B></P>
select '<P>In questo momento sono attive ' || count(*) || ' connessioni.',
	'Numero di RB ideali calcolati : '|| round(count(*)/4) || ' (ovvero 4 connessioni per rollback)</P>'
from  v$session
where  username is not null
and     status != 'KILLED'
;
prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=12 BGCOLOR=RED><font color=white>
prompt <B>Calculate Rollback Segments Configuration</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Id</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Owner</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Tablespace Name</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Rollback Name</TD>
prompt <TD BGCOLOR=GREEN><font color=white> INI_Extent</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Next Exts</TD>
prompt <TD BGCOLOR=GREEN><font color=white> MinEx</TD>
prompt <TD BGCOLOR=GREEN><font color=white> MaxEx</TD>
prompt <TD BGCOLOR=GREEN><font color=white> %Incr</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Size (Bytes)</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Extent#</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Status</TD>
prompt </TR>


select  '<TR> <TD>',
	substr(sys.dba_rollback_segs.SEGMENT_ID,1,5) "ID#",
        '</TD> <TD>',
        substr(sys.dba_segments.OWNER,1,8) "Owner",
        '</TD> <TD>',
        substr(sys.dba_segments.TABLESPACE_NAME,1,17) "Tablespace Name",
        '</TD> <TD>',
        substr(sys.dba_segments.SEGMENT_NAME,1,17) "Rollback Name",
        '</TD> <TD> <p align="right">',
        substr(sys.dba_rollback_segs.INITIAL_EXTENT,1,10) "INI_Extent",
        '</TD> <TD> <p align="right">',
        substr(sys.dba_rollback_segs.NEXT_EXTENT,1,10) "Next Exts",
        '</TD> <TD> <p align="right">',
        substr(sys.dba_segments.MIN_EXTENTS,1,5) "MinEx",
        '</TD> <TD> <p align="right">',
        substr(sys.dba_segments.MAX_EXTENTS,1,5) "MaxEx",
        '</TD> <TD> <p align="right">',
        substr(sys.dba_segments.PCT_INCREASE,1,5) "%Incr",
        '</TD> <TD> <p align="right">',
        substr(sys.dba_segments.BYTES,1,15) "Size (Bytes)",
        '</TD> <TD> <p align="right">',
        substr(sys.dba_segments.EXTENTS,1,6) "Extent#",
        '</TD> <TD> <p align="center">',
        substr(sys.dba_rollback_segs.STATUS,1,10) "Status",
        '</TD> </TR>'
from sys.dba_segments, sys.dba_rollback_segs
where sys.dba_segments.segment_name = sys.dba_rollback_segs.segment_name and
      sys.dba_segments.segment_type = 'ROLLBACK'
order by sys.dba_rollback_segs.segment_id
;
prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Controllo dati parallelismo
-- ---------------------------
prompt <A NAME="degree"></A>
prompt <P><B>Parallel degree</B></P>
prompt <P>Il valore del parametro degree deve essere 1</P>
prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=2 BGCOLOR=RED><font color=white>
prompt <B>Extract Parallel degree</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Owner</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Degree</TD>
prompt </TR>

select distinct '<TR><TD>',
       owner,
        '</TD> <TD> <p align="right">',
       degree ,
        '</TD> </TR>'
from dba_tables
where owner != 'SYS';

prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Enqueue Resource
-- ----------------
prompt <A NAME="enqueue"></A>
prompt <P><B>Enqueue Resource</B></P>
prompt <P>none</P>

prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=2 BGCOLOR=RED><font color=white>
prompt <B>Calculate Enqueue Waits</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Enqueue Resource</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Enqueue Waits</TD>
prompt </TR>

select '<TR><TD>',
	A.Value Enqueue_Resources,
        '</TD> <TD> <p align="right">',
        B.Value Enqueue_Waits,
        '</TD> </TR>'
from 	V$PARAMETER A, V$SYSSTAT B
where 	A.Name = 'enqueue_resources'
and 	B.Name = 'enqueue waits';

prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Sorts
-- -----
prompt <A NAME="sort"></A>
prompt <P><B>Sort</B></P>
prompt <P>none</P>
prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=3 BGCOLOR=RED><font color=white>
prompt <B>Sort Statistics</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Disk Sorts</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Memory Sorts</TD>
prompt <TD BGCOLOR=GREEN><font color=white> %Disk Sorts</TD>
prompt </TR>

select '<TR><TD>',
       A.Value Disk_Sorts,
       '</TD> <TD> <p align="right">',
       B.Value Memory_Sorts,
        '</TD> <TD> <p align="right">',
       ROUND(100*A.Value/DECODE((A.Value+B.Value),0,1,(A.Value+B.Value)),2),
        '</TD> </TR>'
  from V$SYSSTAT A, V$SYSSTAT B
 where A.Name = 'sorts (disk)'
   and B.Name = 'sorts (memory)';

prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Sono sufficienti i rollback segments?
-- -----
prompt <A NAME="rbssuff"></A>
prompt <P><B>Rollback Segments</B></P>
prompt <P>none</P>

prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=2 BGCOLOR=RED><font color=white>
prompt <B>Sono sufficienti?</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Qta RBS</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Header Waits</TD>
prompt </TR>

select '<TR><TD>',
	COUNT(V$ROLLSTAT.USN)  Num_Rollbacks,
	'</TD> <TD> <p align="right">',
       V$WAITSTAT.Count       Rollback_Header_Waits,
       '</TD> </TR>'
  from V$WAITSTAT, V$ROLLSTAT 
 where V$ROLLSTAT.Status = 'ONLINE'
   and V$WAITSTAT.Class = 'undo header'
 group by V$WAITSTAT.Count;

prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Rollback segments per utente
-- ---------------------------
prompt <A NAME="rbsusr"></A>
prompt <P><B>Rollback Segments</B></P>
prompt <P>none</P>

prompt <TABLE BORDER=1>
prompt <TR><TD COLSPAN=4 BGCOLOR=RED><font color=white>
prompt <B>Utilizzo per utente</B></TD></TR>

prompt <TR>
prompt <TD BGCOLOR=GREEN><font color=white> Num. RBS</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Username</TD>
prompt <TD BGCOLOR=GREEN><font color=white> OS User</TD>
prompt <TD BGCOLOR=GREEN><font color=white> Terminal</TD>
prompt </TR>

select '<TR><TD>',
	R.Name rr,  
       '</TD> <TD> <p align="right">',
       NVL(S.Username,'no transaction') us, 
       '</TD> <TD> <p align="right">',
       S.Osuser os,  
       '</TD> <TD> <p align="right">',
       S.Terminal te,
       '</TD> </TR>' 
  from V$LOCK L, V$SESSION S, V$ROLLNAME R 
 where L.Sid = S.Sid(+)
   and TRUNC(L.Id1/65536) = R.USN 
   and L.Type = 'TX' 
   and L.Lmode = 6 
order by R.Name 
;

prompt </TABLE>
prompt <P><A HREF="#indice">[Indice]</A></P>
prompt <HR>
-- ----------------------------------------------------------------------------------------------

-- Pie pagina
-- ----------
prompt </BODY>
prompt </HTML>


-- Riga ------------------------------------------------------------------------
prompt <p align="center">
prompt <font size="2" color=GREEN>
prompt (C)opyright 2000 - Apex-net srl - DBCheck.sql rel.4.3 del 14/03/2001 by S. Teodorani
prompt </font>
prompt </p>

spool off
set termout on
prompt
prompt Aprire il file "C:\DBCHeck43.htm" con Internet Explorer

