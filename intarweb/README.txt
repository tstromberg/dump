Intarweb.sh: a webserver written in shell script. Tested on FreeBSD 8.0.

Installation:
=============
Add a port for intarweb to run on to /etc/services if one does not exist
already. In this example, we run it on port 8080:

intarweb	8080/tcp   # Moo.

Add the following service to /etc/inetd.conf with the port you would like to
run it on:

intarweb	stream	tcp	nowait	nobody	/usr/local/bin/intarweb.sh	intarweb.sh

