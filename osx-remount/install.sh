#!/bin/sh
set -eux -o pipefail
mkdir -p /Users/tstromberg/Library/LaunchAgents
cp remount.sh $HOME/Library/LaunchAgents
cat remount.plist | perl -pe 's/\~/$ENV{HOME}/g' \
  > $HOME/Library/LaunchAgents/remount.plist

launchctl load $HOME/Library/LaunchAgents/remount.plist
sleep 5
tail /var/log/system.log

