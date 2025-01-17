alias egrep='egrep --color=auto -i'

alias fgrep='fgrep --color=auto -i'
alias grep='grep --color=auto -i'
alias dnstop='dnstop eth1'
# alias ls='ls --color=auto'

# GIT
alias gs='git status'
alias gsG='git -c color.status=always status | grep'
alias ga='git add'
alias gap='git add -p'
alias gc='git commit'
alias gcm='git commit -m'
alias gcfu='git commit --fixup'
alias gcam='git commit -am'
alias gcAm='git commit --amend'
alias gcAmm='git commit --amend -m'
alias gcAH='git commit --amend -C HEAD'
alias gcv='git commit -v'
alias gcav='git commit -av'
alias gd='git diff'
alias gdd='git diff dev...'
alias gds='git diff --stat'
alias gdds='git diff dev... --stat'
alias gdw='git diff -w'
alias gdc='git diff --cached'
alias gdcw='git diff --cached -w'
alias gdns='git diff --name-status'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gpush='git push'
alias gpull='git pull'
alias grs="git reset"
alias grsH="git reset --hard"
alias grb="git rebase"
alias grbi="git rebase -i"
alias grbiq='git rebase-i --autosquash'
alias grbd='git rebase dev'
alias grbid='git rebase -i dev'
alias gl='git log --pretty=format:"[%h] %an %cr: %s"'
alias gll="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gld='git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=relative'
alias glds='git log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short'
alias gfl='git log -u'
alias gR='git reese'
alias gcor='gco $(git branch --sort=-committerdate | fzf-tmux --multi -d 10 -l 30%)'
alias crev='scripts/dev/checkout_revision'
alias gcod='gco dev'
alias -g BRANCH='$(git branch | fzf-tmux -d 10)'
alias gbcc="git branch G \* | cut -d ' ' -f2 | tee >(pbcopy)" # git copy branch
alias reflog='git reflog --pretty=raw | tig --pretty=raw'
alias gsh="git show"
alias gshh=copyPrettyGitCommitInfoHash



alias gsxnvim="gs --porcelain | cut -d ' ' -f 3 X nvim "

alias hrc='heroku run console'
alias hr='heroku run'
alias hrr='heroku run rake'
alias hl='heroku logs'
alias hlt='heroku logs --tail'
alias -g RP="-r prod"
alias -g RS="-r staging"

alias zr='source ~/.zshrc'
alias ze='vim ~/.zshrc'
alias zea='vim ~/cfg/zsh/aliases.zsh'
alias te='vim ~/.tmux.conf'
alias b='cd ~-'

# SSH aliases
alias velleity='ssh syu@velleity.mc.yale.edu -p 2222'
alias zoo='ssh sy23@node.zoo.cs.yale.edu'
alias peacock='ssh sy23@peacock.zoo.cs.yale.edu'
alias ladybug='ssh sy23@ladybug.zoo.cs.yale.edu'

# Global Aliases
# alias -g xclip='xclip -selection c'
# alias -g X='| xclip'
alias -g NG="noglob"
alias -g G="| grep --color=always"
alias -g L="| less"
alias -g M='| more'
alias -g H='| head'
alias -g TL='| tail'
alias -g T='| tee'
alias -g C="| tee >(pbcopy)"
alias -g R="pbcopy <"
alias -g CSILENT="| pbcopy"
alias -g X="| xargs"
alias -g BE='bundle exec'

alias -g CA='--color=always'
alias -g CAAP='--color=always | ack --passthru'
alias -g HI='|ack --passthru'

# TMUX handlers
alias tmxsp="cd ~/projects/sp; tmux at -t sp || tmux new -s sp"
alias tmxbe="cd ~/work/aurelia; tmux at -t be || tmux new -s be"


# ARC / BENCHLING
alias clinteastwood="arc lint"
alias ad="arc diff"
alias adod="arc diff origin/dev"
alias adpc="ad --plan-changes"
alias arm="alembic revision -m"
alias aP="arc patch"
alias d='bin/dev'
alias db='bin/db'
alias rs='bin/runserver'
alias psqlb='bin/psql -h localhost benchling'
alias rc='run_console'
alias gp='bin/dev webpack'
alias gbt='bin/dev build-jsunit'
alias pt='bin/dev pyunit'
alias ptb='bin/dev pyunit --pdb'
alias wau='workon aurelia'

alias ag="ag --noheading"
alias agh="ag --heading"
alias agpi="ag_python_import"

alias retag="ctags -R coffee benchling"

alias vimdiff='nvim -d'

# Benchling psql
alias psqlb='bin/dev psql -h localhost benchling'

# crontab
alias punt-cron-tab="~/cfg/cron/punt-cron-tab.sh"
alias restore-cron-tab="~/cfg/cron/restore-cron-tab.sh"

alias pg="ping google.com"

type trash > /dev/null 2>&1 && {
    alias rm='trash'
  } || {
    echo '`trash` not found. Consider `brew install trash`'
  }
# if ! [-x "$(command -v trash)"]; then
#     alias rm='trash'
# fi

alias yfcm='yarn flow codemod annotate-exports --write --repeat --log-level info'
alias yf='yarn flow'
alias yrc='yarn run client'
alias yrs='yarn run server'
alias ysp='yarn start-prod'
alias yes='yarn eslint src server'

alias uirs='~/projects/ui/rails-server'
alias na='~/projects/note-app'
alias lp='~/projects/note-app/oryoki-src/my-remix-app/lexpla'
alias nap='~/projects/note-app-prod'
alias naw='~/dropbox/note-app-writings'
