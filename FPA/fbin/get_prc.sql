-- --------------------------- COPYRIGHT NOTICE ----------------------------------
-- *******************************************************************************
-- 
--  Copyright (c) 2004 Perot Systems Corporation
--  All Rights Reserved
--  Copyright Notice Does Not Imply Publication
-- 
-- *******************************************************************************
-- 
--   NAME:               get_prc.sql
-- 
--   DESCRIPTION:        This script will extract the source code for the stored procedure specified as the only required parameter.. 
-- 
-- 
--   EXT DATA FILES:
-- 
--   ENV VARIABLES:
-- 
--   INPUT:
-- 
--   OUTPUT:
-- 
-- 
--   TEMPORARY FILES:
-- 
--   EXT FUNC CALLS:
-- 
--   EXT MOD CALLS:
-- 
-- *******************************************************************************
--  Date         Programmmer      Description
--  ----------   --------------   ------------------------------------------
--  09/13/2004   J. Thiessen      New code.
--  02/16/2006   R. Crawford      Added order by clause.
--
--  Version 1.0
-- *******************************************************************************


set heading off
set feedback off
set termout off
set pagesize 0
set linesize 3000
set wrap off
set verify off
set newpage none

COLUMN today NEW_VALUE t_date
SELECT '&1' ||'.PRC' 
       today from DUAL;
SPOOL &t_date

select text from all_source
where name = '&1' and 
      type = 'PROCEDURE'
      order by line;
spool off

