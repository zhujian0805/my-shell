# Examples:
# http://blog.csdn.net/lidonghat/article/details/60584573
## blue to echo 
blue_echo () {
    echo -e "\033[34m$1\033[0m"
}

## green to echo 
green_echo () {
    echo -e "\033[32m$1\033[0m"
}

## Error to warning with blink
bred_echo () {
    echo -e "\033[31m\033[01m\033[05m$1\033[0m"
}

## Error to warning with blink
byellow_echo () {
    echo -e "\033[33m\033[01m\033[05m$1\033[0m"
}

redback_echo () {
    echo -e "\033[41;37m$1\033[0m"
}
## Error
red_echo () {
    echo -e "\033[31m\033[01m$1\033[0m"
}

## warning
yellow_echo () {
    echo -e "\033[33m\033[01m$1\033[0m"
}

black_echo () {
	echo -e "\033[30m$1\033[0m"
}

purple_echo () {
	echo -e "\033[35m$1\033[0m"
}

skyblue_echo () {
	echo -e "\033[36m$1\033[0m"	
}

white_echo () {
	echo -e "\033[37m$1\033[0m"
}

bw_echo () {
    # black/white
	echo -e "\033[40;37m$1\033[0m"
}

rb_echo () {
    # red/black
	echo -e "\033[41;30m$1\033[0m"
}

gb_echo () {
    # green/blue
	echo -e "\033[42;34m$1\033[0m"	
}

yb_echo () {
    # yello/blue
	echo -e "\033[43;34m$1\033[0m"
}

bb_echo () {
	# blue/black
	echo -e "\033[44;30m$1\033[0m"
}

pb_echo () {
	# purple/black
	echo -e "\033[45;30m$1\033[0m"
}

sbb_echo () {
	# sky blue black
	echo -e "\033[46;30m$1\033[0m"
}

wb_echo () {
	# white blue
	echo -e "\033[47;34m$1\033[0m"
}


