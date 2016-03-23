#!/bin/sh

# take care this is root

#-------------------------------------------------------------------------------
# Setup GoLang with GVM
#-------------------------------------------------------------------------------

# GVM
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
source ~/.bash_profile

gvm install go1.4
gvm use go1.4
gvm install go1.5.3

#-------------------------------------------------------------------------------
# Setup Compass
#-------------------------------------------------------------------------------

yum -y install ruby ruby-devel
gem update
gem install compass

#-------------------------------------------------------------------------------
# Setup nodejs
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Clone and Build
#-------------------------------------------------------------------------------

git clone https://github.com/mattermost/platform /opt/mattermost
cd /opt/mattermost
make test
make
