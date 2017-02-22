#!/bin/bash
# Chiggins bootstrap script for Kali

# Run upgrade and then install some software
apt-get update && apt-get update -y && apt-get install -y zsh ctags shutter bless htop filezilla irssi tmux

curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
if [ -d ~/.zshrc ]
then
    rm ~/.zshrc
fi

wget https://github.com/Chiggins/DotFiles/raw/master/zsh/.zshrc -O ~/.zshrc --no-check-certificate
wget https://github.com/Chiggins/DotFiles/raw/master/zsh/chiggins.zsh-theme -O ~/.oh-my-zsh/themes/chiggins.zsh-theme --no-check-certificate
chsh -s /bin/zsh

echo 'runtime vimrc' > ~/.vimrc
if [ ! -d ~/.vim ]
then
    mkdir ~/.vim
fi
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/vundle
wget https://github.com/Chiggins/DotFiles/raw/master/vim/vimrc -O ~/.vimrc --no-check-certificate
vim +PluginInstall +qall

wget https://raw.githubusercontent.com/Chiggins/DotFiles/master/tmux/.tmux.conf -O ~/.tmux.conf --no-check-certificate

[ -e /usr/share/wordlists/rockyou.txt.gz ] && gzip -dc < /usr/share/wordlists/rockyou.txt.gz > /usr/share/wordlists/rockyou.txt

git clone https://github.com/leebaird/discover /opt/discover/

# Remove this script
rm kali.sh
