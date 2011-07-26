# $HeadURL: http://svn.stromberg.org/svn/repos/dot.files/bashrc $

# This file is read (normally) by interactive shells only.
# Here is the place to define your aliases, functions and
# other interactive features like your prompt.
#
if [ -f /etc/bashrc ]; then
        . /etc/bashrc   # --> Read /etc/bashrc, if present.
fi

if [ -r "$HOME/.aliases" ]; then
    . $HOME/.aliases
fi


# Some basic shell settings - most are done by .bashrc or .zshenv
case `id -u` in
      0) sh_prompt="#";;
      *) sh_prompt="$";;
esac

# I've seen \u fail on some systems, lets do this instead.
PS1="$USER@\h:\w$sh_prompt " 
export PS1

ulimit -S -c 0        # Don't want any coredumps
set -o notify
set -o noclobber

# Enable options:
shopt -s cdspell
shopt -s cdable_vars
shopt -s checkhash
shopt -s checkwinsize
shopt -s mailwarn
shopt -s sourcepath
shopt -s no_empty_cmd_completion  # bash>=2.04 only
shopt -s cmdhist
shopt -s histappend histreedit histverify
shopt -s extglob      # Necessary for programmable completion
