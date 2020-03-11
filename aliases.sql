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

alias tabconstraints= 
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

-- Generates view code for a given table
-- @param table_name
alias gen_view=
  with data as (
    select 
      chr(10) lf,
      lower(:table_name) table_name,
      lower(apex_string.get_initials(:table_name, 10)) tab_name_alias
    from dual
  )
  select 
    apex_string.format(
      'create or replace force view %1_v as %0' ||
      'select %0' ||
      listagg('  %2.' || lower(utc.column_name), ',' || d.lf) within group (order by utc.column_id asc) || d.lf ||
      'from dual %0' ||
      '  join %1 %2 on 1=1%0' || 
      ';' 
    , d.lf, d.table_name, d.tab_name_alias) view_code
  from dual
    join data d on 1=1
    join user_tab_columns utc on 1=1
  where 1=1
    and utc.table_name = upper(d.table_name)
  group by 
    d.lf,
    d.table_name,
    d.tab_name_alias
;

alias compile_all=
  begin
    dbms_utility.compile_schema(schema => user,  compile_all => false);
  end;
/

