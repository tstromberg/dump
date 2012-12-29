#!/bin/sh
#
# Usage:
#
# taggle_asus_ac66u_radio.sh <ip> [disable|enable] [2.4|5|all]
#
# Script to toggle the radio state on an Asus RT-AC66U wireless router.
# This was created so that I could have a crontab entry that disabled the
# wirelessi network on Sanday afternoons.
#
# NOTE: You must store your admin password in ~/.netrc in this form:
#
# machine 10.1.10.28 login admin password ????????


# AUTHOR: Thomas Stromberg <thomas%stromberg.org>
set -u

requested_ip=$1
requested_state=$2
requested_unit=$3

# How long to wait for the option to be applied
apply_sleep=6

case ${requested_state} in
  0|disable|off)
    wl_radio=0;;
  1|enable|on)
    wl_radio=1;;
  *)
    echo "Unknown requested_state: ${requested_state}"
    exit 1;;
esac

case ${requested_unit} in
  2.4)
    units="0";;
  5)
    units="1";;
  all)
    units="0 1";;
  *)
    echo "Unknown requested_unit: ${requested_unit}"
    exit 2;;
esac

for wl_unit in ${units}; do
  curl --netrc -s \
      -d wl_unit=${wl_unit} \
      -d wl_radio=${wl_radio} \
      -d next_page=/ \
      -d action_mode=apply \
      http://${requested_ip}/start_apply2.htm >/dev/null
  sleep ${apply_sleep}
done
