/*
Execution Environment:
     SQL, SQL*Plus

Access Privileges:
     Requires DBA access privileges to be executed.

Usage:
     sqlplus sys/<password>

Instructions:
     Copy the script to a file and execute it from SQL*Plus.


PROOFREAD THIS SCRIPT BEFORE USING IT! Due to differences in the way text 
editors, e-mail packages, and operating systems handle text formatting (spaces, 
tabs, and carriage returns), this script may not be in an executable state
when you first receive it. Check over the script to ensure that errors of
this type are corrected.

 
   
Description  
You have an environment that is heavily indexed, and you want to monitor the 
usage of the indexes.  For example, at the end of the week before the batch 
loads you would like to check which indexes are being used in queries 
throughout the week. 

You can find the index usage from the explain plan.  If you explain all the
queries within V$SQLAREA, you can see which indexes are being used. 
 
The following is a sample of the type of script you can write to get these 
results.  This script is only a sample, and works under certain assumptions. 

Miscellaneous requirements and info:
  - The user running the script should have all the privileges to explain 
    everything in v$sqlarea not loaded by SYS.
  - plan_table.remarks can be used to determine privilege related errors.
  - The parameter OPTIMIZER_GOAL is constant for all SQL in shared pool    
    ignores v$sqlarea.optimizer_mode.                                    
  - The statistics have not been regenerated between snapshots.
  - No statements have been truncated.
  - All objects are local.
  - All referenced tables/views are either owned by the user running the
    script or fully qualified names/synonyms were used in the SQL.
  - No "popular" statements have aged out of (and for that matter, been
    reloaded into) the shared pool since the last snapshot.
  - Instance is either bounced or has the shared pool completely flushed
    after each snapshot to reset the executions and other statistics to zero.
  - For all statements, v$sqlarea.version_count = 1 (children).



*/
set echo off 
Rem Drop and recreate PLAN_TABLE for EXPLAIN PLAN 
drop table plan_table; 

create table PLAN_TABLE (
	statement_id 	varchar2(30),
	timestamp    	date,
	remarks      	varchar2(80),
	operation    	varchar2(30),
	options       	varchar2(30),
	object_node  	varchar2(128),
	object_owner 	varchar2(30),
	object_name  	varchar2(30),
	object_instance numeric,
	object_type     varchar2(30),
	optimizer       varchar2(255),
	search_columns  number,
	id		numeric,
	parent_id	numeric,
	position	numeric,
	cost		numeric,
	cardinality	numeric,
	bytes		numeric,
	other_tag       varchar2(255),
	partition_start varchar2(255),
        partition_stop  varchar2(255),
        partition_id    numeric,
	other		long,
	distribution    varchar2(30));

Rem Drop and recreate SQLTEMP for taking a snapshot of the SQLAREA 
drop table sqltemp; 
create table sqltemp 
  (ADDR VARCHAR2 (16), 
   SQL_TEXT VARCHAR2 (2000), 
   DISK_READS NUMBER, 
   EXECUTIONS NUMBER, 
   PARSE_CALLS NUMBER); 

set echo on 

Rem Create procedure to populate the plan_table by executing 
Rem explain plan...for 'sqltext' dynamically 
create or replace procedure do_explain 
(addr IN varchar2, sqltext IN varchar2) as 
dummy varchar2 (1100); 
mycursor integer; 
ret integer; 
my_sqlerrm varchar2 (85); 
begin 
dummy:='EXPLAIN PLAN SET STATEMENT_ID=' ; 
dummy:=dummy||''''||addr||''''||' FOR '||sqltext; 
mycursor := dbms_sql.open_cursor; 
dbms_sql.parse(mycursor,dummy,dbms_sql.v7); 
ret := dbms_sql.execute(mycursor); 
dbms_sql.close_cursor(mycursor); 
commit; 
exception -- Insert errors into PLAN_TABLE... 
when others then 
my_sqlerrm := substr(sqlerrm,1,80); 
insert into plan_table(statement_id,remarks) 
values (addr,my_sqlerrm); 
-- close cursor if exception raised on EXPLAIN PLAN 
dbms_sql.close_cursor(mycursor); 
end; 
/ 

Rem Start EXPLAINing all S/I/U/D statements in the shared pool 
declare 
-- exclude statements with v$sqlarea.parsing_schema_id = 0 (SYS) 
cursor c1 is select address, sql_text, DISK_READS, EXECUTIONS, 
PARSE_CALLS 
from v$sqlarea where command_type in (2,3,6,7) 
and parsing_schema_id != 0; 
cursor c2 is select addr, sql_text from sqltemp; 
addr2 varchar(16); 
sqltext v$sqlarea.sql_text%type; 
dreads v$sqlarea.disk_reads%type; 
execs v$sqlarea.executions%type; 
pcalls v$sqlarea.parse_calls%type; 
begin 
open c1; 
fetch c1 into addr2,sqltext,dreads,execs,pcalls; 
while (c1%found) loop 
insert into sqltemp values(addr2,sqltext,dreads,execs,pcalls); 
commit; 
fetch c1 into addr2,sqltext,dreads,execs,pcalls; 
end loop; 
close c1; 
open c2; 
fetch c2 into addr2, sqltext; 
while (c2%found) loop 
do_explain(addr2,sqltext); 
fetch c2 into addr2, sqltext; 
end loop; 
close c2; 
end; 
/ 

Rem Generate a report of index usage based on the number of times 
Rem a SQL statement using that index was executed 
select p.owner, p.name, sum(s.executions) totexec 
from sqltemp s, 
(select distinct statement_id stid, object_owner owner, object_name name 
from plan_table 
where operation = 'INDEX') p 
where s.addr = p.stid 
group by p.owner, p.name 
order by 2 desc; 

/*

Rem Perform cleanup on exit (optional)
delete	
from	plan_table
where	statement_id in(
	select	addr
	from	sqltemp
	);


*/

select p.owner, p.name, sum(s.executions) totexec 
from sqltemp s, 
(select distinct statement_id stid, object_owner owner, object_name name 
from plan_table 
where operation = 'INDEX') p 
where s.addr = p.stid 
group by p.owner, p.name 
order by 2 desc; 
--drop table sqltemp;
