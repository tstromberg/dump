#!/bin/sh

cd `dirname $0`
files="`ls | egrep -v "README|install.sh"` zprofile" 

for file in $files
do
  target="`pwd`/$file"
  link="$HOME/.$file"

  # This is a special case.
  if [ "$file" = "zprofile" ]; then
    target="$HOME/.profile"
  fi

  if [ -f $link ]; then
    echo "* Making backup: ${link}.bak"
    mv "$link" "${link}.bak"
  elif [ -L "$link" ]; then
    echo "* Removing $link symlink"
    rm -f "$link"
  fi

  echo "- $target -> $link"
  ln -s $target $link
done
