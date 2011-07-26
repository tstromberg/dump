#!/bin/sh
# w3notice 1.2 - thomas+w3notice@stromberg.org
# checks a website for certain text, e-mails diff of site if it matches.
# requires lynx if you want to have text formatting preserved. Works with
# wget, curl, or any other web fetcher otherwise.

# usage:
# checksite.sh http://www.news.com/ 'unix|linux|perl'


# Change to whatever program you would like to fetch with.
# Lynx is HIGHLY recommended, as it will format the HTML for you
# and it's currently our only POST option. 

FETCH="/usr/local/bin/lynx -dump"
CHECKSUM="/usr/local/bin/openssl md5"
#FETCH="/usr/bin/curl -s"


SITEINFO=$1
MATCH=$2

SITE=`echo $1 | cut -d\| -f1`
POST=`echo $1 | grep "\|" | cut -d\| -f2`

FILE="$HOME/.w3notice/`echo "$SITEINFO" | sed s/[:\/\&\?\$\|]/_/g | cut -c1-190`_`echo "$SITEINFO" | $CHECKSUM`"

if [ ! "$SITE" ]; then
    echo "syntax: w3notice.sh <sitename> [matching text]"
    exit
fi


if [ -f "$FILE" ]; then
	mv $FILE $FILE.old

	# post only works with lynx!
	if [ "$POST" != "" ]; then
		echo "$POST" | $FETCH -post_data "$SITE" > $FILE
	else
		$FETCH "$SITE" > $FILE
	fi

	egrep -i "$MATCH" $FILE >/dev/null
	if [ "$?" -eq 0 ]; then
		CHANGES=`diff -u $FILE.old $FILE | egrep "$MATCH" | egrep "^\-|^\+"`
		if [ "$CHANGES" ]; then
			echo "$SITE"
			echo "===================================================="
			echo "$CHANGES"
		fi
	fi
else
	# it has never been fetched
	echo "$SITE has never been fetched before. Storing as $FILE"
    $FETCH $SITE > $FILE
fi
