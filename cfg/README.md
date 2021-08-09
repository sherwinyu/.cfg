Run :

  git clone --bare https://github.com/sherwinyu/.cfg  ~/.cfg


See https://www.atlassian.com/git/tutorials/dotfiles for more details

About the directory structure:

Most files (~/.zshrc, ~/.vimrc) are placed directly into $HOME.

Adjacent library files (various zsh functions, vim plugins and modules) are found in ~/cfg:

  cfg/
    zsh/
    vim/
    taskpaper/
    iterm2/

