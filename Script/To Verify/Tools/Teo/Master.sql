SELECT uc.table_name        master_table,
       uc.constraint_name   master_key,
       uc.constraint_type   master_key_type,
       uc2.table_name       detail_table,
       uc2.constraint_name  foreign_key
  FROM user_constraints uc2,
       user_constraints uc
WHERE uc.table_name = UPPER('&Master_table')
   AND uc.constraint_type IN ('P', 'U')
   AND uc.constraint_name = uc2.r_constraint_name
   AND uc2.constraint_type = 'R'
/
