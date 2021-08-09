autoload -Uz copy-earlier-word
zle -N copy-earlier-word
bindkey "^[m" copy-earlier-word
# https://leahneukirchen.org/blog/archive/2013/03/10-fresh-zsh-tricks-you-may-not-know.html
# If you have history lines:
#
# [1] cat 1 2 3 4
# [2] cat a b c d
#
# Then hitting option+. will select d, then 4
# Hitting option+m will select d, then c
