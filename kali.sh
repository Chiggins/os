#!/bin/bash
# Chiggins bootstrap script for Kali

# Run upgrade and then install some software
apt-get update && apt-get update -y && apt-get install zsh ctags shutter bless htop filezilla irssi

curl -L https://github.com/roibbyrussell/oh-my-zsh/raw/master/tools/install.sh | share
if [ -d ~/.zshrc ]
then
    rm ~/.zshrc
fi

wget https://github.com/Chiggins/DotFiles/raw/master/zsh/.zshrc -O ~/.zshrc --no-check-certificate
wget https://github.com/Chiggins/DotFiles/raw/master/zsh/chiggins.zsh-theme -O ~/.oh-my-zsh/themes/chiggins.zsh-theme --no-check-certificate
chsh -s /usr/bin/zsh

# Install RVM
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable --ruby

[ -e /usr/share/wordlists/rockyou.txt.gz ] && gzip -dc < /usr/share/wordslists/rockyou.txt.gz > /usr/share/wordlists/rockyou.txt
