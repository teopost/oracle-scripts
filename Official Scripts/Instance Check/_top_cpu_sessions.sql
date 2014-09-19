set echo off
set feedback off
set linesize 512

prompt
prompt Top Sessions by CPU consumption
prompt

column sid			format 999     heading "SID"
column username		format a20     heading "User Name"
column command		format a20     heading "Command"
column osuser		format a20     heading "OS User"
column process		format a20     heading "OS Process"
column machine		format a20     heading "Machine"
column value		format 99,999  heading "CPU Time"

select 
	s.sid		sid,
	s.username	username,
	UPPER(DECODE(command,
        1,'Create Table',2,'Insert',3,'Select',
        4,'Create Cluster',5,'Alter Cluster',6,'Update',
        7,'Delete', 8,'Drop Cluster', 9,'Create Index',
        10,'Drop Index', 11,'Alter Index', 12,'Drop Table',
        13,'Create Sequencfe', 14,'Alter Sequence', 15,'Alter Table',
        16,'Drop Sequence', 17,'Grant', 18,'Revoke',
        19,'Create Synonym', 20,'Drop Synonym', 21,'Create View',
        22,'Drop View', 23,'Validate Index', 24,'Create Procedure',
        25,'Alter Procedure', 26,'Lock Table', 27,'No Operation',
        28,'Rename', 29,'Comment', 30,'Audit',
        31,'NoAudit', 32,'Create Database Link', 33,'Drop Database Link',
        34,'Create Database', 35,'Alter Database', 36,'Create Rollback Segment',
        37,'Alter Rollback Segment', 38,'Drop Rollback Segment', 39,'Create Tablespace',
        40,'Alter Tablespace', 41,'Drop Tablespace', 42,'Alter Sessions',
        43,'Alter User', 44,'Commit', 45,'Rollback',
        46,'Savepoint', 47,'PL/SQL Execute', 48,'Set Transaction',
        49,'Alter System Switch Log', 50,'Explain Plan', 51,'Create User',
        52,'Create Role', 53,'Drop User', 54,'Drop Role',
        55,'Set Role', 56,'Create Schema', 57,'Create Control File',
        58,'Alter Tracing', 59,'Create Trigger', 60,'Alter Trigger',
        61,'Drop Trigger', 62,'Analyze Table', 63,'Analyze Index',
        64,'Analyze Cluster', 65,'Create Profile', 66,'Drop Profile',
        67,'Alter Profile', 68,'Drop Procedure', 69,'Drop Procedure',
        70,'Alter Resource Cost', 71,'Create Snapshot Log', 72,'Alter Snapshot Log',
        73,'Drop Snapshot Log', 74,'Create Snapshot', 75,'Alter Snapshot',
        76,'Drop Snapshot', 79,'Alter Role', 85,'Truncate Table',
        86,'Truncate Cluster', 88,'Alter View', 91,'Create Function',
        92,'Alter Function', 93,'Drop Function', 94,'Create Package',
        95,'Alter Package', 96,'Drop Package', 97,'Create Package Body',
        98,'Alter Package Body', 99,'Drop Package Body')) command,
	s.osuser	osuser,
	s.machine	machine,
	s.process	process,
	t.value		value
from
	v$session s,
	v$sesstat t,
	v$statname n
where
        s.sid = t.sid
	and	
	t.statistic# = n.statistic#
	and
	n.name = 'CPU used by this session'
	and
	t.value > 0
	and
	audsid > 0
order by
	t.value desc;