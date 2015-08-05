--
-- to display locked objects, user who has them locked and the 
-- SQL they issued to lock them.

col username format a10
col sid format 999
col lock_type format a15
col mode_held format a11
col mode_requested format a12
col lock_id1 format a8
col lock_id2 format a8
col object format a15
col row_id format a15
SET LINESIZE 130
SELECT	a.sid,s.serial#,s.username,s.osuser,
decode(a.type,
'MR','Media Rcovery',
'RT','Redo Thread',
'UN','User Name',
'TX','Transaction',
'TM','DML',
'UL','PL/SQL User Lock',
'DX','Distributed Xaction',
'CF','Control File',
'IS','Instance State',
'FS','File Set',
'IR','Instance Recovery',
'ST','Disk Space Transaction',
'TS','Temp Segment',
'IV','Library Cache Invalidation',
'LS','Log Start or Switch',
'RW','Row Wait',
'SQ','Sequence Number',
'TE','Extend Table',
'TT','Temp Table',
a.type) lock_type,
decode(a.lmode,
	0,'None',			/* Mon Lock equivalent */
	1,'Null',				/* N */
	2,'Row-S (SS)',			/* L */
	3,'Row-X (SX)',			/* R */
	4,'Share',			/* S */
	5,'S/Row-X (SSX)',		/* C */
	6,'Exclusive',			/* X */
to_char(a.lmode)) mode_held,
decode (a.request,
	0,'None',			/* Mon Lock equivalent */
	1,'Null',				/* N */
	2,'Row-S (SS)',			/* L */
	3,'Row-X (SX)',			/* R */
	4,'Share',			/* S */
	5,'S/Row-X (SSX)',		/* C */
	6,'Exclusive',			/* X */
to_char(a.request)) mode_requested,
to_char(a.id1) lock_id1, to_char(a.id2) lock_id2,
row_wait_obj# OBJETO,
row_wait_file#||'.'||row_wait_block#||'.'||row_wait_row# ROW_ID
FROM	v$lock a, v$session s
	WHERE	a.sid = s.sid and
	(id1,id2) in
	(select b.id1,b.id2 from v$lock b where
	b.id1 = a.id1 and b.id2 = a.id2 and
	b.request > 0)
/


column osuser format a12
column username format a12
column machine format a10
column program format a10


PROMPT Locked Sid from above
ACCEPT sid PROMPT '(if no rows selected, there are no locks): > '
select s.sid, s.osuser, s.username, nvl(s.machine,' ?  ') machine,
nvl(s.program,' ?  ') program, s.process Fground, p.spid Bground,
X.sql_text
from sys.v_$session S,
sys.v_$process P,
sys.v_$sqlarea X
where s.sid = &&sid
and  s.paddr = p.addr
and s.type != 'BACKGROUND'
and s.sql_address = x.address
and s.sql_hash_value = x.hash_value
order by s.sid;

undefine sid;

