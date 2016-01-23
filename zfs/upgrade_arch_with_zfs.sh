#!/bin/sh
#
# update arch linux, including zfs packages.
set -eux -o pipefail

readonly PKGS="spl-git zfs-utils-git zfs-git zfs-auto-snapshot-git"
sudo pacman -R --noconfirm ${PKGS} || echo "${PKGS} not installed"
# Try again one at a time.
for pkg in ${PKGS}; do
  sudo pacman -R --noconfirm "${pkg}" || echo "${pkg} not installed"
done

sudo pacman -Syu --noconfirm
export LINUX=$(pacman -Q linux | awk '{ print $2 }')
#if [[ $(uname -r | grep ${LINUX}) ]]; then
#  echo "Already running ${LINUX} ..."
#fi

for pkg in ${PKGS}; do
  cd $HOME/src/aur/${pkg}
  perl -pi -e 's/(kernel.*)="(4.*?)"/$1="$ENV{LINUX}"/' *
  rm *.xz || echo "No packages in ${pkg} to remove"
  makepkg --noconfirm -sri
done
