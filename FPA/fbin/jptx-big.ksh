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
  (/usr/bin/X11/xterm -fn user12x2 -bg black -fg rgb:88/FF/88 -sb -sl 400 -ls -title "VABATCHT Wellpoint 208.242.100.141" &)
done

