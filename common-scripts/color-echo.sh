# Examples:
# http://blog.csdn.net/lidonghat/article/details/60584573

function colorme()  
{  
    case "$1" in  
        red)    nn="31";;  
        green)  nn="32";;  
        yellow) nn="33";;  
        blue)   nn="34";;  
        purple) nn="35";;  
        cyan)   nn="36";;  
    esac  
    ff=""  
    case "$2" in  
        bold)   ff=";1";;  
        bright) ff=";2";;  
        uscore) ff=";4";;  
        blink)  ff=";5";;  
        invert) ff=";7";;  
    esac  
    color_begin=`echo -e -n "\033[${nn}${ff}m"`  
    color_end=`echo -e -n "\033[0m"`  
    while read line; do  
        echo "${color_begin}${line}${color_end}"  
    done  
}

## blue to echo 
blue_echo () {
    echo -e "\033[34m$@\033[0m"
}

## green to echo 
green_echo () {
    echo -e "\033[32m$@\033[0m"
}

## Error to warning with blink
bred_echo () {
    echo -e "\033[31m\033[01m\033[05m$@\033[0m"
}

## Error to warning with blink
byellow_echo () {
    echo -e "\033[33m\033[01m\033[05m$@\033[0m"
}

redback_echo () {
    echo -e "\033[41;37m$@\033[0m"
}
## Error
red_echo () {
    echo -e "\033[31m\033[01m$@\033[0m"
}

## warning
yellow_echo () {
    echo -e "\033[33m\033[01m$@\033[0m"
}

black_echo () {
	echo -e "\033[30m$@\033[0m"
}

purple_echo () {
	echo -e "\033[35m$@\033[0m"
}

skyblue_echo () {
	echo -e "\033[36m$@\033[0m"	
}

white_echo () {
	echo -e "\033[37m$@\033[0m"
}

bw_echo () {
    # black/white
	echo -e "\033[40;37m$@\033[0m"
}

rb_echo () {
    # red/black
	echo -e "\033[41;30m$@\033[0m"
}

gb_echo () {
    # green/blue
	echo -e "\033[42;34m$@\033[0m"	
}

yb_echo () {
    # yello/blue
	echo -e "\033[43;34m$@\033[0m"
}

bb_echo () {
	# blue/black
	echo -e "\033[44;30m$@\033[0m"
}

pb_echo () {
	# purple/black
	echo -e "\033[45;30m$@\033[0m"
}

sbb_echo () {
	# sky blue black
	echo -e "\033[46;30m$@\033[0m"
}

wb_echo () {
	# white blue
	echo -e "\033[47;34m$@\033[0m"
}


