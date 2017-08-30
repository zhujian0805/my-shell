#!/bin/bash
#
# Copyright (C) 2006 Zoologisches Institut und Programm MGU, Uni Basel
#                    Lukas Zimmermann, lukas.zimmermann@unibas.ch.
#

GETOPT=/usr/bin/getopt
CAT=/bin/cat

# extract the scripts calling name
PROG=${0##*/}

#-----------------------------------------------------------------------------
function usage
{
  $CAT <<EOF

usage: $PROG [options]
  Options:
    -h,--help          print this help message.
    -s,--switch        option without argument.
    -a,--opt_argument <optional argument>
                       option with optional argument
    -b,--req_argument <required argument>
                       option requiring argument
EOF
}


#-----------------------------------------------------------------------------
# main
#-----------------------------------------------------------------------------
$GETOPT -T
if [ $? -ne 4 ]; then
  echo "This script requires Frodo Looijaard's getopt."
  echo "Get it at http://software.frodo.looijaard.name/getopt/ ."
  exit 1
fi

# process command line arguments
TEMP=`$GETOPT -o hsa::b: --long help,switch,opt_argument::,req_argument: \
     -n $PROG -- "$@"`

# Test whether getopt encountered an error
if [ $? != 0 ] ; then echo "bad command line options" >&2 ; exit 1 ; fi

# assign contents of $TEMP to positional parameters
eval set -- "$TEMP"

echo -n "$GETOPT output: "
for pp in $@; do
  echo -n "\"$pp\" "
done
echo

opt_a=0
#opt_argument=""
req_argument=""
switch=0

while true ; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -a|--opt_argument)
      opt_a=1
      opt_argument=$2
      shift 2
      ;;
    -b|--req_argument)
      req_argument=$2
      shift 2
      ;;
    -s|--switch)
      switch=1
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "bad option"
      usage
      exit 1
      ;;
  esac
done

# Check for the non-option parameters. In our case we should not have any.
if [ $# -lt 0 -o $# -gt 0 ]; then
  usage
  exit 1
fi

# Print command line option parsing results
if [ $switch -ne 0 ]; then
  echo "switch is on"
else
  echo "switch is off"
fi

if [ $opt_a -ne 0 ]; then
  echo -n "Option --opt_argument is given, "
  if [ "$opt_argument" ]; then
    echo "optional argument is $opt_argument"
  else
    echo "but without argument"
  fi
fi

if [ "$req_argument" ]; then
  echo "req_argument: $req_argument"
else
  echo "No option --req_argument is given"
fi
