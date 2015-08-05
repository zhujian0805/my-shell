#!/bin/bash
#===============================================================================
#
#          FILE: 01-fun-param.sh
# 
#         USAGE: ./01-fun-param.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (000), zhujian0805@gmail.com
#  ORGANIZATION: JZ
#       CREATED: 2015年04月30日 15时41分50秒 CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#!/bin/sh

# Define your function here
Hello () {
       echo "Hello World $1 $2"
}

# Invoke your function
Hello Zara Ali
