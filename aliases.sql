set serveroutput on
set sqlformat ansiconsole


-- Aliases
alias invalid=
  select
    uo.object_name,
    uo.object_type
  from user_objects uo
  where 1=1
    and uo.status != 'VALID'
  order by uo.object_name
;


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

alias tabconstraints = 
  select
    uc.constraint_type,
    uc.constraint_name,
    uc.search_condition_vc,
    acc.column_name
  from dual
    join user_constraints uc on 1=1
    join all_cons_columns acc on 1=1
      and uc.owner = acc.owner
      and uc.constraint_name = acc.constraint_name
  where 1=1
    and uc.owner = user
    and uc.table_name = upper(:table_name)
  order by 
    decode(uc.constraint_type, 'P', 1, 'R', 2, 'U', 3, 'C', 4, 5),
    acc.position,
    -- Handle not nulls lower
    case when constraint_name like 'SYS%' then 2 else 1 end
;

alias create_view=
  select 
    'create or replace force view ' || lower(utc.table_name) || '_v as' || chr(10) ||
    'select' || chr(10) ||
    listagg('  acroynm_changeme.' || lower(utc.column_name), ',' || chr(10)) within group (order by utc.column_id asc) || chr(10) ||
    'from dual ' || chr(10) ||
    '  join ' || lower(utc.table_name) || ' acroynm_changeme on 1=1' || chr(10) || 
    ';' view_code
  from user_tab_columns utc
  where 1=1
    and utc.table_name = upper(:table_name)
  group by utc.table_name
;

alias compile_all=
  begin
    dbms_utility.compile_schema(schema => user,  compile_all => false);
  end;
/

