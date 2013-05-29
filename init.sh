#!/bin/bash

# oh-my-zsh
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
ln -sf ~/.vim/zshrc.oh-my-zsh ~/.zshrc
ln -sf ~/.vim/zshrc.extras ~/.zshrc.extras

# tmux
ln -sf ~/.vim/tmux.conf ~/.tmux.conf

# vim
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
ln -sf ~/.vim/vimrc ~/.vimrc
#echo "" > /etc/vim/vimrc
vim -c "execute \"BundleInstall\" | q | q"
