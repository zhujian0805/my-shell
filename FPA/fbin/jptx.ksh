export DISPLAY=155.16.51.80:$1
if [ ${#} -lt 2 ]; then
  let num_sessions=1
else
  let num_sessions=${2}
fi
if [ ${#FPA_INT_xtermcolors} -eq 0 ];then
  FPA_INT_xtermcolors="-bg rgb:DA/DA/DA -fg black -cr blue"
fi
if [ ${#FPA_INT_xtermtitle} -eq 0 ];then
  FPA_INT_xtermtitle="UNSPECIFIED ${ORACLE_SID} ${UNAME} on `uname -n`"
fi
let count=0
while [ $count -lt ${num_sessions} ]
do
  let count=${count}+1
  (/usr/bin/X11/xterm ${FPA_INT_xtermcolors} -title "${FPA_INT_xtermtitle}" -fn 6x13 -sb -sl 900 -ls -tm "erase ^h" &)
done
