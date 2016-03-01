#!/bin/sh

MATTERMOST_VERSION="2.0.0"

#-------------------------------------------------------------------------------
# Set up CentOS 7.2
#-------------------------------------------------------------------------------

# setup
yum upgrade -y
yum groupinstall -y "Development Tools"
yum install -y vim wget tree lsof tcpdump  # i need this...

# configure
cat << TIME > /etc/sysconfig/clock
ZONE="Asia/Tokyo"
UTC="false"
TIME
source /etc/sysconfig/clock
/bin/cp -f /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

#-------------------------------------------------------------------------------
# Set up Database Server (Postgres 9.4.x)
#   @see http://docs.mattermost.com/install/prod-rhel-7.html#set-up-database-server
#-------------------------------------------------------------------------------

# setup
yum -y install http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-redhat94-9.4-1.noarch.rpm
yum -y install postgresql94-server postgresql94-contrib
/usr/pgsql-9.4/bin/postgresql94-setup initdb
systemctl enable postgresql-9.4.service
systemctl start postgresql-9.4.service

# create database and user
sudo -i -u postgres psql -c "CREATE DATABASE mattermost;"
sudo -i -u postgres psql -c "CREATE USER mmuser WITH PASSWORD 'mmuser_password';"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mattermost to mmuser;"

# configure
cp /vagrant/conf/pgsql/postgresql.conf /var/lib/pgsql/9.4/data/postgresql.conf
cp /vagrant/conf/pgsql/pg_hba.conf /var/lib/pgsql/9.4/data/pg_hba.conf

systemctl restart postgresql-9.4.service

#-------------------------------------------------------------------------------
# Set up Mattermost Server (2.0.0)
#   @see http://docs.mattermost.com/install/prod-rhel-7.html#set-up-mattermost-server
#-------------------------------------------------------------------------------

# download
cd /opt
wget https://github.com/mattermost/platform/releases/download/v${MATTERMOST_VERSION}/mattermost.tar.gz
tar -xvzf mattermost.tar.gz
mkdir -p /opt/mattermost/data

# add unix user
useradd -r mattermost -U
chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost

# configure
cp /vagrant/conf/mattermost/config.json /opt/mattermost/config/config.json

# service setup
cp /vagrant/conf/systemd/mattermost.service /etc/systemd/system/mattermost.service
chmod 664 /etc/systemd/system/mattermost.service
systemctl daemon-reload
systemctl start mattermost.service
systemctl enable mattermost.service

#-------------------------------------------------------------------------------
# Set up Nginx Server
#   @see http://docs.mattermost.com/install/prod-rhel-7.html#set-up-nginx-server
#-------------------------------------------------------------------------------

# install
cat << 'NGINX_YUM_REPO' > /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/rhel/7/$basearch/
gpgcheck=0
enabled=1
NGINX_YUM_REPO

yum install nginx.x86_64 -y
systemctl start nginx.service
systemctl enable nginx.service

# configure
cp /vagrant/conf/nginx/mattermost.conf /etc/nginx/conf.d/mattermost.conf
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak

systemctl restart nginx.service

#-------------------------------------------------------------------------------

echo '--------------------------------------------------------------'
echo 'Setup complete!!'
echo '  please access: http://standalone-mattermost.vagrant.local/   '
echo '--------------------------------------------------------------'
