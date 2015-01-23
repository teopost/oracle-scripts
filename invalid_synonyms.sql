-- synonym referencing object exists in db, but INVALID state
select 'drop synonym ' || synonym_name ||';' 
   from user_synonyms
 where (table_owner, table_name) not in ( SELECT owner, object_name from all_objects );
 
-- synonym referencing object NOT exists in DB
select * 
  from all_objects 
 where (owner, object_name) in 
             (select table_owner, table_name from user_synonyms )
   and status = 'INVALID';   
