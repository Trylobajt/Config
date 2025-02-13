# Only if we are an interactive shell
if [ -t 1 ]; then
  # test if zsh is installed
  if [ -x /usr/bin/zsh ]; then
    exec zsh
  fi
fi


# Load Angular CLI autocompletion.
source <(ng completion script)

# fnm
FNM_PATH="/c/Users/FatalError/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi
