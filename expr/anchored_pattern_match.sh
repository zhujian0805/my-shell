#!/bin/bash
#===============================================================================
#
#          FILE: expr.sh
# 
#         USAGE: ./expr.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: James Zhu (000), zhujian0805@gmail.com
#  ORGANIZATION: JZ
#       CREATED: 2014年08月05日 09时29分27秒 CST
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

string="abc def1234"
digts=$(/usr/bin/expr "$string" : '.*def\([0-9]*\)')
echo $digts
