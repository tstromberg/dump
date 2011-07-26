#!/bin/sh
# Add ipf rules for hosts with suspicious sshd login patterns

SSH_LOG=/var/log/auth.log
SSH_IPF_GROUP=20000
MIN_FAILURE_COUNT=3

block_host() {
  if [ ! "`ipfstat -i | grep $1`" ]; then  
    echo "Adding [$1] to blacklist"
    echo "block in quick from $1 to any group 20000" | ipf -f -
  fi
}

# Purge old rules
ipfstat -i | grep "group $SSH_IPF_GROUP" | ipf -r -f -

# First build a list of IP's that have attempted logins on invalid usernames
illegal_hosts=`grep -ao 'sshd.*illegal user.*from.*' $SSH_LOG | cut -d" " -f11 | sort -u`

# Ban all illegal hosts
for host in $illegal_hosts
do
  block_host $host
done


# Iterate over each host that failed an ssh login, blocking ones that exceed norm
grep -ao 'sshd.*Failed.*from.*' $SSH_LOG | cut -d" " -f9 | sort | uniq -c | \
while read total hostname
do
  if [ $total -ge $MIN_FAILURE_COUNT ]; then
    block_host $hostname
  fi    
done
