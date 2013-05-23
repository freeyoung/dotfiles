#!/bin/sh
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
ln -sf ~/.vim/vimrc ~/.vimrc
ln -sf ~/.vim/zshrc ~/.zshrc
ln -sf ~/.vim/zshrc.local ~/.zshrc.local
ln -sf ~/.vim/tmux.conf ~/.tmux.conf
#echo "" > /etc/vim/vimrc
vim -c "execute \"BundleInstall\" | q | q"
