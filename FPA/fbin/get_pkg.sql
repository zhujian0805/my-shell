
-- Extract package source code accepting
-- package name and database name.
--
-- Called from shell script get_pkg.sh
-- 
-- Version 1.0
-- 8/2004 RCrawford Initial production
-- 7/2005 RCrawford Increase linesize from 200 to 3000
-- 2/2006 RCrawford Added order by clause
set heading off
set feedback off
set termout off
set pagesize 0
set linesize 3000
set wrap off
set verify off
set newpage none

COLUMN today NEW_VALUE t_date
SELECT '&1' ||'.PKB' 
       today from DUAL;
SPOOL &t_date

select text from all_source
where name = '&1' and 
      type = 'PACKAGE BODY'
      order by line;
spool off

COLUMN today NEW_VALUE t_date
SELECT '&1' ||'.PKS'
       today from DUAL;
SPOOL &t_date

select text from all_source
where name = '&1' and
      type = 'PACKAGE'
      order by line;

spool off
