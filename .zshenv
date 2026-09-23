
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
if [ -r "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
