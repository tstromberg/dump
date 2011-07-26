#!/bin/sh
# intarweb - a webserver written in bourne shell. (c) 2007 Thomas Stromberg
DOCUMENT_ROOT="/intarweb"
SYSLOG_FACILITY="local0"

handle_error() {
  echo -e "HTTP/1.1 $1 $2\r\nContent-Type: text/html\r\n\r"
  echo -e "<h1>$1: $2</h1>\r"
  logger -p ${SYSLOG_FACILITY}.warn "$url returned $1: $2"
  exit 5
}

check_security() {
  if [ -d $1 ]; then
    dir=$1
  else 
    dir=`dirname $1`
  fi
  chdir $dir 2>/dev/null || handle_error 404 "File Not Found"
  logger -p ${SYSLOG_FACILITY}.info "GET $url file=$1 dir=$dir pwd=$PWD"
  # Out of DOCUMENT_ROOT. Ack.
  if [ "`echo "$PWD/" | grep "^$DOCUMENT_ROOT/"`" = "" ]; then
    handle_error 400 "Bad Request"
  elif [ ! -r $1 ]; then
    handle_error 404 "File Not Found"
  fi
}

handle_file() {
  check_security $1
  if [ -f $1 ]; then
    mime=`/usr/bin/file -bi "$1" | cut -d, -f1 | grep "\/"`
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: ${mime:-text/plain}\r\n\r"
    cat $1
    echo -e "\r"
  elif [ -d $1 ]; then
    handle_directory $1
  fi
}

handle_directory() {
  check_security $1
  if [ -f "${1}/index.html" ]; then
    handle_file "${1}/index.html"
  else 
    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r"
    echo -e "<h1>Contents of $url</h1><pre>"
    # TODO: does not work with spaces in filenames. sed gets \/ crazy.
    echo "<a href=\"..\">(Up a directory)</a>"
    ls -1 "$1" | xargs -n1 -I{} echo "<a href="$url/{}">{}</a>"
    echo -e "</pre>\r"
  fi
}

# parse HTTP request. GET should always be the first line. 
read request
url="${request#GET }"
url="${url% HTTP/*}"
handle_file "${DOCUMENT_ROOT}${url}"
