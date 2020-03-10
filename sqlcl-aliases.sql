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