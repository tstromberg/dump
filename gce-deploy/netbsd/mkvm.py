#!/usr/bin/env python
#
# Anita script for building a NetBSD image for GCE.
#
# Based on https://go-review.googlesource.com/#/c/2612/
#
# Copyright 2014 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

import sys
import anita

arch = sys.argv[1]
release = sys.argv[2]
workdir = sys.argv[3]
disk_size = sys.argv[4]

commands = [
    # See https://code.google.com/p/google-compute-engine/issues/detail?id=77
    "echo 'ignore classless-static-routes;' >> /etc/dhclient.conf",
    "echo 'dhclient=YES' >> /etc/rc.conf",
    "sh /etc/rc.d/dhclient start",
    "env PKG_PATH=http://ftp.netbsd.org/pub/pkgsrc/packages/NetBSD/%s/%s/All/ pkg_add curl git zsh sudo tmux" % (arch, release)
]


a = anita.Anita(
    anita.URL("http://ftp.netbsd.org/pub/NetBSD/NetBSD-%s/%s/" % (release, arch)),
    workdir = workdir,
    disk_size = disk_size,
    memory_size = "512M",
    persist = True)
child = a.boot()
anita.login(child)

for cmd in commands:
  anita.shell_cmd(child, cmd, 3600)

