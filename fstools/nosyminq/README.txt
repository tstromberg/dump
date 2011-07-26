# $Id$

nosyminq 1.0, written by Thomas Stromberg <thomas%stromberg.org>

This command displays what disks a Solaris machine sees, particularly SAN
resources.  It was modelled after the EMC syminq tool, and has very similar
output to it. Here are some differences:


 * Does not require root to run
 * Does not require the symcli tools to be installed
 * Does not have to be run on a live system, can be passed a filename for
   iostat -En output
 * Shows disk sizes in MB
 * Shows duplicate paths when detectable

BUGS:
 * Does not detect the per-disk serial for EMC CLARiiON devices (Solaris
   doesn't know it)
 * May confuse paths as duplicates on the same EMC CLARiiON array if the
   size and disk# are identical.
* Does not emulate any of syminq's options
