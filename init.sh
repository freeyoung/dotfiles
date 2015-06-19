#!/bin/bash

# Check if zsh is already installed
if ! which zsh >/dev/null 2>&1 ; then
    echo "You need to install zsh first."
    exit 2
fi

# tmux
ln -sf ~/.vim/tmux.conf ~/.tmux.conf

# vim
if [ -d ~/.vim/bundle/vundle ]; then
    rm -rf ~/.vim/bundle/vundle
fi
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
rm -f  ~/.vimrc

echo "source ~/.vim/bundles.vim" > ~/.vimrc

vim -c "execute \"BundleInstall!\" | q | q"
ln -sf ~/.vim/vimrc ~/.vimrc
mkdir -p ~/.vim/undodir

# oh-my-zsh
if [ -d ~/.oh-my-zsh ]; then
    mv -f ~/.oh-my-zsh ~/.oh-my-zsh.bak
fi

git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
ln -sf ~/.vim/zshrc.oh-my-zsh ~/.zshrc
ln -sf ~/.vim/zshrc.extras ~/.zshrc.extras

chsh -s `which zsh`
/usr/bin/env zsh
. ~/.zshrc
