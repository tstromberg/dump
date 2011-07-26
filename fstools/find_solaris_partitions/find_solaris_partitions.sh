#!/bin/ksh
# This tool is used to discover filesystems on Solaris disks without using
# the VTOC. This is useful for system administrators to restore the VTOC of
# a disk where it has been corrupted or overwritten.
#
# syntax:
# find_solaris_partitions.sh /dev/rdsk/c0t1d0s2
#
# NOTES:
#
# This tool will not tell you where a filesystem "ends". There is no easy way
# to determine this, other than assuming it's the last sector before another
# partition is found. 
#
# This tool makes use of fstyp and vxprivutil. fstyp will only identify VxFS
# partitions if VxFS is installed. Note that this script will identify
# each VxFS partition seperately, rather than the larger VxVM partition that
# may be there. When in doubt, assume the VxVM partition goes from the
# first VxFS partition to the end of the disk.
#
# Here is a sample VTOC with VxVM:
# 
# *                          First     Sector    Last
# * Partition  Tag  Flags    Sector     Count    Sector  Mount Directory
#       2      5    00          0   4154160   4154159
#       3     15    01       1520      4560      6079
#       4     14    01       6080   4148080   4154159
#

# $Id: find_solaris_partitions.sh 536 2006-01-03 16:02:24Z thomas $

# (c) 2006 Thomas Stromberg <thomas%stromberg.org>


DISK=$1

if [ `uname` != "SunOS" ]; then
	echo "Sorry, this script is only useful on Solaris"
	exit 1
fi

if [ ! "$DISK" ]; then
	echo "syntax:"
	echo "find_solaris_partitions.sh /dev/rdsk/c0t1d0s2"
	exit 2
fi

## Backup the VTOC #########
VTOC_FILE="`pwd`/vtoc.`basename $DISK`.`date +%Y-%m-%d-%H%M`"
prtvtoc $DISK > $VTOC_FILE
echo "* Backed partition table up to $VTOC_FILE. You can restore this table with:"
echo ""
echo "    fmthard -s $VTOC_FILE $DISK"
echo ""

## Parse the VTOC ############
avail_cylinders=`grep "accessible" $VTOC_FILE | awk '{ print $2 }'`
sectors_cylinder=`grep "sectors/cylinder" $VTOC_FILE | awk '{ print $2 }'`
bytes_sector=`grep "bytes/sector" $VTOC_FILE | awk '{ print $2 }'`
raw=`grep -v "*" $VTOC_FILE | egrep "^ +2"`
newpart="`echo $DISK | sed s/s2$//g`s3"

if [ ! "$avail_cylinders" ]; then
	echo "Could not find available cylinders in $VTOC_FILE"
	exit 2
fi

echo "* $avail_cylinders cylinders available"
echo "* ${sectors_cylinder} sectors per cylinder"
echo "* $bytes_sector bytes per sector"
echo ""

echo "Press enter to begin..."
read DELAY

echo "Trying each available cylinder ($avail_cylinders)... "

## The Loop ###################
integer i=0
while ((i <= $avail_cylinders));
do 
	(( sector = i * $sectors_cylinder ));
	(( size = $sectors_cylinder * 256 ));
	#echo "Creating $newpart as a ${size} sector partition at $sector"
	/bin/echo "$i \c"
	(( i = i + 1));
	echo "$raw\n      3      4    00     $sector    $size" | fmthard -s - $DISK >/dev/null
	fs=`fstyp $newpart 2>/dev/null`
	if [ "$fs" ]; then
		echo "\n* Found $fs partition at sector $sector !"
	fi
	vxpriv=`/etc/vx/diag.d/vxprivutil list $newpart 2>/dev/null`
	if [ "$vxpriv" ]; then
		echo "\n* Found VxVM private region at sector $sector !"
	fi 
done
