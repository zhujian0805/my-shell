#!/bin/bash

while [[ $# -ge 1 ]]; do
  arg="$1"
  case $arg in
     -p|--profile)
       shift; PROFILE_SHORT="$1"; shift
       echo "$PROFILE_SHORT"
       ;;
     -t|--template)
       shift; TEMPLATE_SHORT="$1"; shift
       echo "$TEMPLATE_SHORT"
       ;;
     --cn|--china)
       shift; CHINA=true
       echo $CHINA
       ;;
     *)
       echo "${USAGE}"; exit 1
       ;;
  esac
done
