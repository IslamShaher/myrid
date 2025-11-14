#!/bin/bash
# Simple script to verify the remote Laravel server is reachable.
# It uses curl to fetch the HTTP status line from the given URL.

URL="https://wbu.vhb.temporary.site/"
STATUS_LINE=$(curl -I "$URL" 2>/dev/null | head -n 1)
if [ -z "$STATUS_LINE" ]; then
  echo "Unable to reach $URL"
else
  echo "$STATUS_LINE"
fi