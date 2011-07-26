#!/bin/sh
# Automatically start a Google Hangout using Google Chrome,
# and restart it if we are disconnected for whatever reason.
#
# Tested on Crunchbang and Ubuntu Linux 11.04

# This shouldn't change unless you have multiple cameras
VIDEO_DEVICE="/dev/video0"

# Sound output volume: 0-100
OUTPUT_VOLUME="10"

# Should we mute our microphone in the hangout?
MUTE_MICROPHONE=1

# After this amount of time, start randomly clicking to prevent anti-idle
IDLE_SECONDS=900

# Turn off the display if we are idle?
DISPLAY_POWER_SAVING=1

# Does your Google+ profile show circle suggestions? Changes button location.
HAS_CIRCLE_SUGGESTIONS=1

# This could be google-chrome or chromium-browser. Note that many distros
# include older chromium-browsers that do not play well with Google Talk.
BROWSER='google-chrome'

# This script requires xdotool 2.2 or higher to automate the mouse clicking
XDOTOOL='xdotool'

# If the plugin fails, we store a diagnostic screenshot here:
SCREENSHOT_DIR=$HOME

kill_browser() {
  kill `cat $HOME/.hangout.pid`
}

start_browser() {
  $BROWSER --app="https://plus.google.com/" &
  pid=$!
  echo $pid > $HOME/.hangout.pid
}

open_hangout_window() {
  wids=`$XDOTOOL search --all --onlyvisible --name "Google+"`
  for wid in $wids
  do
    $XDOTOOL windowactivate $wid
    if [ $HAS_CIRCLE_SUGGESTIONS -eq 1 ]; then
      $XDOTOOL mousemove --window $wid 860 560
    else
      $XDOTOOL mousemove --window $wid 860 330
    fi
    $XDOTOOL click --window $wid 1
  done
}

click_hangout_button() {
  wid=`$XDOTOOL search --onlyvisible --name "Google Hangout" | head -1`
  if [ ! "$wid" ]; then
    echo "$XDOTOOL failed to find a window named \"Google Hangout\""
  else
    $XDOTOOL windowactivate $wid
    $XDOTOOL mousemove --window $wid $1 $2
    $XDOTOOL click --window $wid 1
  fi
}

start_hangout() {
  click_hangout_button 490 400
}

mute_mic_in_hangout() {
  click_hangout_button 760 650
}

# Google Hangouts disconnect you if you haven't had any recent activity
anti_idle_click() {
  x=`perl -e 'print 547+int(rand(60))-30'`
  y=`perl -e 'print 210+int(rand(20))-10'`
  click_hangout_button $x $y
}

take_screenshot() {
  import -silent -window root $SCREENSHOT_DIR/hangout.png
}

set_output_volume() {
  if [ -x /usr/bin/amixer ]; then
    /usr/bin/amixer set Master ${OUTPUT_VOLUME}%
  else
    aumix -v $OUTPUT_VOLUME
  fi
}

power_off_display() {
  # normally our mouse clicks break anti-idle. 
  if [ $DISPLAY_POWER_SAVING -eq 1 ]; then
    xset dpms force standby
  fi
}

if [ ! -e "$VIDEO_DEVICE" ]; then
  echo "$VIDEO_DEVICE not found (is this Linux? does we have a webcam connected?"
  exit 3
fi

set_output_volume
start_time=`date +%s`
restart_time=$start_time

# make sure we have wireless
while [ 1 ]; do
  sleep 5
  fuser -s $VIDEO_DEVICE
  if [ $? -ne 0 ]; then
    echo "$VIDEO_DEVICE is not in use, checking connectivity."
    # verify connectivity
    if [ -x /usr/bin/wget ]; then
      wget --spider https://plus.google.com/
      failure=$?
    else
      curl https://plus.google.com/
      failure=$?
    fi
    echo "Network down state: $failure"
    if [ $failure -eq 0 ]; then
      if [ $restart_time -ne $start_time ]; then
        echo "Restarting hangout."
        take_screenshot
      fi
      kill_browser
      sleep 1
      start_browser
      sleep 15 
      open_hangout_window
      sleep 15 
      start_hangout
      sleep 10
      mute_mic_in_hangout
      sleep 10
      power_off_display
      restart_time=`date +%s`
    else
      echo "Cannot access Google+"
    fi
  fi
  sleep 10
  elapsed_seconds=$(expr `date +%s` - $restart_time)
  if [ $elapsed_seconds -gt $IDLE_SECONDS ]; then
    anti_idle_click
    power_off_display
  fi
done


