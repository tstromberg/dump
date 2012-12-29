# $HeadURL: http://svn.stromberg.org/svn/repos/dot.files/zshenv $

# You may want to override this in .zshenv.local for better prompting:
me='thomas'
danger_hosts="firewall|backup|ticket"

[ -r $HOME/.aliases ] && . $HOME/.aliases
[ -r $HOME/.zshenv.local ] && . $HOME/.zshenv.local

# enable emacs-like keys.
bindkey -e
os=`uname -s`

# Watch for other interactive logins. 
watch=(all)
# These are the commands we do not attempt auto-completion on.
alias swlist='nocorrect swlist'
alias cp='nocorrect cp'       
alias mkdir='nocorrect mkdir -p' 
alias vi='nocorrect vi'
alias ln='nocorrect ln'
alias mv='nocorrect mv'
alias joe='nocorrect joe'
alias host='nocorrect host'
alias emacs='nocorrect emacs'
alias touch='nocorrect touch'
alias grep='nocorrect grep'
  
setopt correctall   # correct all
setopt autocd     # go into a directory if it is entered.
setopt appendhistory
#setopt extendedglob

# better history searches
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^[[A' history-beginning-search-backward-end
bindkey '^[[B' history-beginning-search-forward-end

# General completion technique
zstyle ':completion:*' completer _complete _prefix
zstyle ':completion::prefix-1:*' completer _complete
zstyle ':completion:incremental:*' completer _complete _correct
zstyle ':completion:predict:*' completer _complete

# Expand partial paths
zstyle ':completion:*' expand 'yes'
zstyle ':completion:*' squeeze-slashes 'yes' # Include non-hidden directories in globbed file completions

# Don't complete backup files as executables
zstyle ':completion:*:complete:-command-::commands' ignored-patterns '*\~'
zstyle ':completion:*:matches' group 'yes' # Describe each match group.

# Normally we would read in /etc/hosts, but we dont use hosts files so much here
if [ -f ~/.ssh/known_hosts ]; then
    ssh_hosts=( ${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[0-9]*}%%\ *}%%,*} )
    zstyle ':completion:*' hosts $ssh_hosts
fi


### BEYOND THIS POINT LIES COLORIZATION MADNESS ################################
# We only do this for certain terminals that we know will play well
valid_term=`echo $TERM | egrep 'xterm-color|xterm|ansi|screen|cons25|cons50'`
if [ "$valid_term" ]; then

  # Only show time spent if it exceeds this number
  min_time=2
  # Only beep if a command errors that takes longer than this to run
  min_beep_time=15

  fg_green=$'%{\e[0;32m%}'
  fg_blue=$'%{\e[0;34m%}'
  fg_cyan=$'%{\e[0;36m%}'
  fg_red=$'%{\e[0;31m%}'
  fg_brown=$'%{\e[0;33m%}'
  fg_purple=$'%{\e[0;35m%}'

  fg_light_grey=$'%{\e[0;37m%}'
  fg_dark_grey=$'%{\e[1;30m%}'

  fg_light_red=$'%{\e[1;31m%}'
  fg_light_blue=$'%{\e[1;34m%}'
  fg_light_green=$'%{\e[1;32m%}'
  fg_light_cyan=$'%{\e[1;36m%}' fg_light_red=$'%{\e[1;31m%}'
  fg_light_purple=$'%{\e[1;35m%}'
  fg_yellow=$'%{\e[1;33m%}'
  fg_no_color=$'%{\e[0m%}'

  fg_white=$'%{\e[1;37m%}'
  fg_black=$'%{\e[0;30m%}'

  col_bright=$fg_light_green
  col_dark=$fg_green
  dark=$fg_dark_grey
  dull=$fg_light_grey
  bright=$fg_white

  # design a nice prompt.
  hostname=`echo $HOST | cut -d. -f1`
  if [ `echo $hostname | grep $USERNAME` ]; then
    host_type="personal"
  elif [ `echo $hostname | egrep dhcp` ]; then
    host_type="dhcp"
  elif [ `echo $hostname | egrep "$danger_hosts"` ]; then
    host_type="danger"
  else
    host_type="other"
  fi

  case $host_type in
    personal)
      hostinfo=""
      ;;
    dhcp)
      hostinfo="${col_dark}dhcp"
      ;;
    danger)
      col_bright=$fg_yellow
      col_dark=$fg_yellow
      dark=$fg_brown
      hostinfo="${col_bright}$hostname"
      ;;
    other)
      col_bright=$fg_light_cyan
      col_dark=$fg_cyan
      hostinfo="${col_bright}$hostname"
  esac

  function precmd {
    result=$?
      case $os in
          Linux|NetBSD|OpenBSD|FreeBSD|Darwin)
            seconds=`date +'%s'`;;
        AIX|SunOS)
                seconds=`perl -e 'print time()'`;;
            *)
                seconds=`echo 0` ;;
        esac
        last_seconds=${last_seconds-$seconds}
    duration=$((seconds - last_seconds))
    case $USER in
      $me) user_at="" ;;
      root) user_at="ROOT${dark}@" ;;
      *) user_at="${USER}${dark}@" ;;
    esac
    if [ $duration -gt $min_time ]; then
      info="${dark}[${col_dark}`printf "+%4.4d" $duration`${dark}]"
    else
      info=""
    fi
    if [ "$result" -ne 0 ]; then
      info="${fg_red}|${fg_light_red}${result}${fg_red}|${info}"
      if [ "$duration" -gt $min_beep_time ]; then
        # http://superuser.com/questions/513013/how-can-i-add-a-beep-to-zshs-prompt
        info="${fg_white}*%{$(echo "\a")%}${info}"
      fi
    fi
    RPS1="$info ${col_dark}${user_at}${hostinfo}${dark}:${col_bright}%3c${fg_no_color}"
    if [ "$USER" = "root" ]; then
      PS1="${fg_light_red}%#${fg_light_grey} "
    else
      PS1="${col_bright}%#${fg_light_grey} "
    fi
    last_seconds=$seconds
    result=0
  }
fi

