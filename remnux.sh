#!/bin/bash
# Chiggins bootstrap script for Remnux

# Install zsh, oh-my-zsh, and custom theme
sudo apt-get install -y zsh ctags tmux vim curl git
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
if [ -d ~/.zshrc ]
then
    rm ~/.zshrc
fi
wget https://github.com/Chiggins/DotFiles/raw/master/general/zshrc -O ~/.zshrc --no-check-certificate
wget https://github.com/Chiggins/DotFiles/raw/master/general/chiggins.zsh-theme -O ~/.oh-my-zsh/themes/chiggins.zsh-theme --no-check-certificate
chsh -s /usr/bin/zsh

echo 'runtime vimrc' > ~/.vimrc
if [ ! -d ~/.vim ]
then
    mkdir ~/.vim
fi
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/vundle
wget https://github.com/Chiggins/DotFiles/raw/master/general/vimrc -O ~/.vimrc --no-check-certificate
vim +PluginInstall +qall

wget https://raw.githubusercontent.com/Chiggins/DotFiles/master/general/tmux.conf -O ~/.tmux.conf --no-check-certificate

# Install RVM
gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable --ruby

# Remove this script
#rm remnux.sh
