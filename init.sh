#!/bin/bash

# Check if zsh is already installed
if ! which zsh >/dev/null 2>&1 ; then
    echo "You need to install zsh first."
    exit 2
fi

# tmux
ln -sf ~/.vim/tmux.conf ~/.tmux.conf

# vim
curl -sfLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

rm -f ~/.vimrc
echo "source ~/.vim/plugs.vim" > ~/.vimrc

vim -c "execute \"PlugInstall!\" | q | q"
ln -sf ~/.vim/vimrc ~/.vimrc
mkdir -p ~/.vim/undodir

# oh-my-zsh
[ -d ~/.oh-my-zsh ] && rm -rf ~/.oh-my-zsh

git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
ln -sf ~/.vim/zshrc.oh-my-zsh ~/.zshrc
ln -sf ~/.vim/zshrc.extras ~/.zshrc.extras

chsh -s `which zsh`
exec /usr/bin/env zsh
. ~/.zshrc
