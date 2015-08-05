export DISPLAY=155.16.51.80:$1
if [ ${#} -lt 2 ]; then
  let num_sessions=1
else
  let num_sessions=${2}
fi
let count=0
while [ $count -lt ${num_sessions} ]
do
  let count=${count}+1
  (/usr/bin/X11/xterm -bg rgb:88/88/FF -fn 6x13 -sb -sl 400 -ls -title "test vabatcht Wellpoint 208.242.100.141" -fg black -cr blue -tm "erase ^h" &)
done
