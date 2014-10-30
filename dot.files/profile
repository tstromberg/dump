# tstromberg-profile 
# Please keep your modifications in ~/.profile.local or /etc/profile.local
# to make upgrading easier.

# This should rarely happen.
if [ "$PATH" = "" ]; then
  PATH="/bin:/usr/bin"
  echo "No path? Setting $PATH"
fi

add_bin_paths=""
add_man_paths=""
os=`uname`

# Operating System Specific Behaviours! ##################################

case "$os" in
  SunOS)
    add_bin_paths="/usr/ucb /usr/platform/`uname -m`/sbin"
    add_man_paths="/usr/man /usr/dt/share/man /usr/openwin/man"
    ;;
  HP-UX)
    add_bin_paths="/usr/ccs/bin /usr/contrib/bin"
    add_man_paths="/usr/contrib/man"

    if [ -r /etc/PATH ]; then
      add_bin_paths="$add_bin_paths `cat /etc/PATH | sed s/:/' '/g`"
    fi

    if [ -r /etc/MANPATH ]; then
      add_man_paths="$add_man_paths `cat /etc/MANPATH | sed s/:/' '/g`"
    fi
    ;;
  FreeBSD)
    add_man_paths="/usr/local/man"
    ;;
  OpenBSD)
    PKG_PATH="ftp://ftp.openbsd.org/pub/OpenBSD/${os_ver}/packages/${os_arch}/"
    export PKG_PATH
    ;;  
  Darwin)
    if [ -x /usr/libexec/path_helper ]; then
    	eval `/usr/libexec/path_helper -s`
    fi

    add_bin_paths="/opt/local/bin /opt/local/sbin"
    ;;
  NetBSD)
    add_bin_paths="/usr/pkg/bin /usr/pkg/sbin"
    add_bin_paths="/usr/share/man /usr/local/man /usr/pkg/man"
    ;;
  Linux)
    if [ -d "/etc/profile.d" ]; then
      for i in /etc/profile.d/*.sh ; do
        test -r $i && . $i
      done
    fi
    ;;
IRIX|IRIX64)
    ;;
AIX)
  ;;
esac

for dir in `echo $add_man_paths | xargs`
do
  if [ -d "$dir" -a -x "$dir" -a ! -L "$dir" ]; then
    case "$MANPATH" in
      (*$dir*) ;;
      (*) MANPATH="$MANPATH:$dir"
    esac
  fi
done

# Good paths to add if we see them.
add_bin_paths="
  /usr/local/bin /usr/local/sbin /usr/sbin /sbin $add_bin_paths
  /usr/local/go/bin /usr/local/google_appengine /usr/local/go_appengine
  $HOME/bin
"
add_man_paths="/usr/share/man /usr/local/share/man $add_man_paths"

### Application Settings ##########################################################
if [ -d "/usr/local/go" ]; then
  GOROOT=/usr/local/go
  GOBIN=$GOROOT/bin
  export GOBIN GOROOT
fi

# avoid adding duplicate paths
for dir in `echo $add_bin_paths | xargs`
do
  if [ -d "$dir" -a -x "$dir" -a ! -L "$dir" ]; then
    # This is a very strange way to do substring searches in ksh
    case "$PATH" in
      (*$dir*) ;;
      (*) PATH="$PATH:$dir"
    esac
  fi
done


# Find a good default editor and pager #####################
vi=""
vim=""

for dir in `echo $PATH | sed s/:/" "/g`
do
  if [ -x "$dir/vi" -a "$vi" = "" ]; then
    vi="$dir/vi"
  fi
  if [ -x "$dir/vim" ]; then
    vim="$dir/vim"
  fi
  if [ -x "$dir/less" ]; then
    PAGER="$dir/less"
  fi
done

if [ "$vim" != "" ]; then
  EDITOR=$vim
else
  EDITOR=$vi
fi

# Any final commands here ##################################
if [ "$TERM" = "unknown" ]; then
  TERM=vt100
fi

# For 256-color vim
if [ -e /usr/share/terminfo/x/xterm-256color -o -e /lib/terminfo/x/xterm-256color -o -e /usr/share/terminfo/78/xterm-256color ]; then
  if [ "$TERM" = "xterm-color" ]; then
    TERM='xterm-256color'
  fi
fi


# Should we colorize the ls command?
valid_term=`echo $TERM | egrep 'color|xterm|ansi|screen|cons25|cons50'`
if [ "$valid_term" ]; then
  if [ "$os" = 'Linux' -o -x /usr/local/bin/gls ]; then
    LS_COLORS='no=00:fi=0;37:di=01;37:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:*.tar=00;32:*.tgz=00;32:*.arj=00;32:*.taz=00;32:*.lzh=00;32:*.zip=00;32:*.z=00;32:*.Z=00;32:*.gz=00;32:*.bz2=00;32:*.deb=00;36:*.rpm=00;36:*.jar=1;33:*.pyc=1;30:*~=1;30'
    export LS_COLORS

    if [ -x /usr/local/bin/gls ]; then
      alias ls='/usr/local/bin/gls -F --color=auto'
    else
      alias ls="ls -F --color=auto"
    fi
  elif [ -r /etc/ttys ]; then
    export LSCOLORS="HxGxFxfxDxegedBxdxacad"
    export CLICOLOR=1
    alias ls="ls -F"
  fi
fi

# Useful if ultimate-profile is installed globally.
test -r /etc/profile.local && . /etc/profile.local
test -r $HOME/.profile.local && . $HOME/.profile.local

# Some basic shell settings - most are done by .bashrc or .zshenv
case `id -u` in
  0) sh_prompt="#";;
  *) sh_prompt="$";;
esac

shell=$(basename `echo $SHELL | sed s/-//`)
if [ "$shell" = "" ]; then
  shell=$(basename `echo $0 | sed s/-//`)
fi

case $shell in
  sh)
    PS1="`whoami`@`hostname | sed 's/\..*//'`$sh_prompt "
  ;;
  ksh|ksh93)
    PS1=`logname`@`hostname -s`:'$PWD> '
  ;;    
  bash)
    # I've seen \u fail on some systems, lets do this instead.
    PS1="$USER@\h:\w$sh_prompt " 
    export PS1
  ;;
  zsh)
    HISTDIR=$HOME/.zh/$(date +'%Y-%m-%d')
    mkdir -p $HISTDIR 2>/dev/null
    HISTFILE=${HISTDIR}/$$.$(hostname -s).${USER}
    HISTSIZE=5000
    SAVEHIST=5000
    PROMPT="%n@%m:%40~%# "
    export PROMPT HISTFILE HISTDIR HISTSIZE SAVEHIST
  ;;
esac

PATH=`echo $PATH | sed -e s/^://g | sed -e s/:$//g`
MANPATH=`echo $MANPATH | sed -e s/^://g | sed -e s/:$//g`

export EDITOR MANPATH PATH PAGER TERM

# Be very paranoid about shell expansion
#set -o nounset


# Setting PATH for MacPython 2.4
# The orginal version is saved in .profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/Current/bin:${PATH}"
export PATH
