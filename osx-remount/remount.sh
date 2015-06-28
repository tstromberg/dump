#!/bin/bash
#
# Persistently and agressively remount shares on Mac OS X.
#
# Look for one of the following MAC addresses to determine if the
# device is "at home". See the output of "arp -an".
HOME_MAC_ADDRS="78:cd:8e:6c:e8:52|ac:22:b:83:37:d8"

# These are the volumes to mount. The format is the same as Finder's Cmd-K.
REMOTE_VOLUMES="smb://10.1.10.2/archive"

while :;
do
  sleep 2
  arp -an | egrep "$HOME_MAC_ADDRS"
  if [[ $? -eq 0 ]]; then
    echo "- We are at home"
    mount=$(mount)
    for url in $REMOTE_VOLUMES; do
      # If it's already mounted, move on. The mount
      # as shown may have the username added to it suddenly.
      mounted_url=$(echo $url | cut -d/ -f3,4)
      echo $mount | grep $mounted_url && continue
      osascript -e "mount volume \"$url\""
    done
  else
    sleep 20
  fi
done
