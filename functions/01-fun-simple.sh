#!/bin/bash
#===============================================================================
#
#          FILE: 01-fun.sh
# 
#         USAGE: ./01-fun.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (000), zhujian0805@gmail.com
#  ORGANIZATION: JZ
#       CREATED: 2015年04月30日 15时40分26秒 CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#!/bin/sh

# Define your function here
Hello () {
       echo "Hello World"
}

# Invoke your function
Hello
