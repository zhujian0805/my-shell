## blue to echo 
blue_echo () {
    echo -e "\033[34m[ $1 ]\033[0m"
}

## green to echo 
green_echo () {
    echo -e "\033[32m[ $1 ]\033[0m"
}

## Error to warning with blink
bred_echo () {
    echo -e "\033[31m\033[01m\033[05m[ $1 ]\033[0m"
}

## Error to warning with blink
byellow_echo () {
    echo -e "\033[33m\033[01m\033[05m[ $1 ]\033[0m"
}

redback_echo () {
    echo -e "\033[41;37m[ $1 ]\033[0m"
}
## Error
red_echo () {
    echo -e "\033[31m\033[01m[ $1 ]\033[0m"
}

## warning
yellow_echo () {
    echo -e "\033[33m\033[01m[ $1 ]\033[0m"
}
