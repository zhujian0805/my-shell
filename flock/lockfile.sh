#!/bin/bash
# Demostrate locking
# The second run of this script will fail while the first is still running

set -e

(
    # Wait for lock on /var/lock/.myscript.exclusivelock (fd 200) for 10 seconds
    flock -xn 200
    echo testing1
    sleep 10
    echo testing2

) 200>/var/lock/.myscript.exclusivelock
