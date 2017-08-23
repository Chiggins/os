#!/bin/bash
# Chiggins bootstrap script for Kali

# Run upgrade and then install some software
apt-get update && apt-get update -y && apt-get install -y zsh ctags shutter bless htop tmux crackmapexec docker docker-compose libldns-dev freerdp-x11

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

###
# Custom tool installations
###

# Discover - Used to automating tasks
git clone https://github.com/leebaird/discover /opt/discover/
ln -s /opt/discover/discover.sh /usr/bin/discover

# domain - Better used to find domain names for a website
git clone https://github.com/jhaddix/domain /tmp/domain/
cd /tmp/domain/
echo "/opt/enumall/" | ./setup_enumall.sh
pip install -r /opt/enumall/altdns/requirements.txt
pip install -r /opt/enumall/recon-ng/REQUIREMENTS
ln -s /opt/enumall/domain/enumall.py /usr/bin/enumall
cd ~

# Sublist3r
git clone https://github.com/aboul3la/Sublist3r.git /opt/sublist3r/
pip install -r /opt/sublist3r/requirements.txt
ln -s /opt/sublist3r/sublist3r.py /usr/bin/sublist3r
chmod +x /usr/bin/sublist3r

# MassDNS
git clone https://github.com/blechschmidt/massdns.git /opt/massdns
cd /opt/massdns/
make
ln -s /opt/massdns/bin/massdns /usr/bin/massdns
ln -s /opt/massdns/subbrute.py /usr/bin/subbrute

# GoBuster
git clone https://github.com/OJ/gobuster.git /opt/gobuster/
cd /opt/gobuster/
go get
go build
go install
ln -s /opt/gobuster/
cd ~

# Parameth
git clone https://github.com/mak-/parameth.git /opt/parameth/
ln -s /opt/parameth/parameth.py /usr/bin/parameth

# TPLMap
git clone https://github.com/epinna/tplmap.git /opt/tplmap/
ln -s /opt/tplmap/tplmap.py /usr/bin/tplmap

# Powershell Empire
git clone https://github.com/EmpireProject/Empire /opt/empire/
cd /opt/empire/setup/
./install.sh
echo "IyEvYmluL2Jhc2gKcHVzaGQgL29wdC9lbXBpcmUvICYmIC4vZW1waXJlIC0tcmVzdCAtLXVzZXJuYW1lIHVzZXIgLS1wYXNzd29yZCBwYXNzICYmIHBvcGQK" | base64 -d > /usr/bin/empire && chmod +x /usr/bin/empire
cd ~

# DeathStar
git clone https://github.com/byt3bl33d3r/DeathStar /opt/deathstar/
pip install -r /opt/deathstar/requirements.txt

# EyeWitness
git clone https://github.com/ChrisTruncer/EyeWitness /opt/eyewitness/
cd /opt/eyewitness/setup/
./setup.sh
cd ~

# Win Payloads
git clone https://github.com/nccgroup/Winpayloads.git /opt/winpayloads
cd /opt/winpayloads/
chmod +x setup.sh
#./setup.sh
cd ~

# Grabbing this just to have it local
# MailSniper
mkdir ~/code/
wget https://raw.githubusercontent.com/dafthack/MailSniper/master/MailSniper.ps1 -O ~/code/MailSniper.ps1

# Gitrob
#apt install libpq-dev -y
#systemctl enable postgresql
#systemctl start postgresql
#su - postgres
#createuser -s gitrob
#createdb -O gitrob gitrob
#exit
#gem install gitrob

# Remove this script
echo "Need to run setup.sh in /opt/winpayloads/"
rm kali.sh
