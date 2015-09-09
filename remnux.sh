#!/bin/bash
# Chiggins bootstrap script for Remnux

# Install zsh, oh-my-zsh, and custom theme
apt-get install -y zsh
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
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

# Remove this script
rm remnux.sh
