set pagesize 60 linesize 255 newpage 0 feedback off

column Total_IO format 999999999
column Weight format 999.99
column Drive format a55
column file_name format a55
break on drive skip 2
compute sum of weight on drive

select df.name Drive,
df.name File_Name,
fs.phyblkrd+fs.phyblkwrt Total_IO,
100*(fs.phyblkrd+fs.phyblkwrt) /MaxIO Weight
from
v$filestat fs, v$datafile df,
(select max(phyblkrd + phyblkwrt )  MaxIO from v$filestat) 
where df.file# = fs.file#
order by Weight desc
;