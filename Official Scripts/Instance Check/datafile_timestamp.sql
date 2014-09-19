/*
 ===========================================================
 Filename...: datafile_timestamp.sql
 Author.....: Stefano Teodorani
 Release....: 1.0 - 08-may-1999
 Description: Estrae il timestamp dei datafiles
 Notes......: Occorre connettersi come SYS
 ===========================================================
*/ 

set pagesize 80
set feedback off
set verify off
set echo off
set linesize 132
column file_name format a40

select 
	file_id, 
	fecrc_tim creation_date, 
	file_name, 
	tablespace_name
from 
	x$kccfe int, 
	dba_data_files dba
where 
	dba.file_id = int.indx + 1 
order by file_id;
