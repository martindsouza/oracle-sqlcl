set serveroutput on
set sqlformat ansiconsole


-- Aliases
alias invalid=select
  uo.object_name,
  uo.object_type
from user_objects uo
where 1=1
  and uo.status != 'VALID'
order by uo.object_name
/


-- Given a table name, find all referencing tables
-- @param table_name: Name of table (not case sensitive)
alias findfk=
select
  c_fk.table_name,
  c_fk.constraint_name,
  acc_fk.column_name,
  c_fk.delete_rule
from dual
  join all_constraints c_fk on 1=1
  join all_cons_columns acc_fk on 1=1
    and acc_fk.owner = c_fk.owner
    and acc_fk.constraint_name = c_fk.constraint_name
    and acc_fk.table_name = c_fk.table_name
  join all_constraints c_pk on 1=1
    and c_pk.owner = c_fk.owner
    and c_pk.constraint_name = c_fk.r_constraint_name
  join all_cons_columns acc_pk on 1=1
    and acc_pk.owner = c_pk.owner
    and acc_pk.constraint_name = c_pk.constraint_name
where 1=1
  and c_fk.owner = user
  and c_fk.constraint_type = 'R'
  and acc_pk.table_name = upper(:table_name)
order by c_fk.table_name
;


alias compile_all=begin
  dbms_utility.compile_schema(schema => user,  compile_all => false);
end;
/

