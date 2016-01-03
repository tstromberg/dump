Script for building GCE images for NetBSD (DOES NOT BOOT - work in progress).

Based heavily on https://go-review.googlesource.com/#/c/2612/

Instructions:
=============
1) Install pexpect:

  % sudo pip install pexpect

  If you have an older version of Python which does not include pip, download
  https://bootstrap.pypa.io/get-pip.py and run:

  % sudo python get-pip.py

2) Install qemu

  Mac OS X: brew install qemu

3) Create image. This script takes a NetBSD version number as an argument:

  % ./create_netbsd_image.sh 7.0

  After some time, this will result in an image archive file being built.

5) Upload image. This script makes the image available in your GCE project:

  % ./upload_netbsd_image.sh /path/to/image/archive.tgz
