#!/bin/sh
TO=$1

# -i  - do not treat special lines starting with "."
# -v  - use verbose mode (provide SMTP session transcript)
# -Am - use sendmail.cf (do not send via localhost:25) - requires root privileges
/usr/sbin/sendmail -i -v -Am -- $TO <<END
Subject: Delivery test
To: $TO

Delivery test.
END
