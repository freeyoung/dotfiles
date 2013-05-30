#!/bin/bash

# tmux
ln -sf ~/.vim/tmux.conf ~/.tmux.conf

# vim
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
unlink ~/.vimrc
echo "source ~/.vim/bundles.vim" > ~/.vimrc
#echo "" > /etc/vim/vimrc
vim -c "execute \"BundleInstall\" | q | q"
ln -sf ~/.vim/vimrc ~/.vimrc

# oh-my-zsh
if [ -d ~/.oh-my-zsh ]; then
    mv -f ~/.oh-my-zsh ~/.oh-my-zsh.bak
fi
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
ln -sf ~/.vim/zshrc.oh-my-zsh ~/.zshrc
ln -sf ~/.vim/zshrc.extras ~/.zshrc.extras

chsh -s `which zsh`
/usr/bin/env zsh
source ~/.zshrc
