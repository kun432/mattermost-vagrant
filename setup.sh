#!/bin/sh

MATTERMOST_VERSION="2.1.0"

MATTERMOST_DB_TYPE="mysql"   # 'mysql' or 'postgres'

#-------------------------------------------------------------------------------
# Setup CentOS 7.2
#-------------------------------------------------------------------------------

# setup
yum upgrade -y
yum groupinstall -y "Development Tools"
yum install -y vim wget tree lsof tcpdump  # i need this...

#-------------------------------------------------------------------------------
# Setup Database Server (MySQL 5.7.x / Postgresql 9.4.x)
#-------------------------------------------------------------------------------

if [[ ${MATTERMOST_DB_TYPE} = 'mysql' ]]; then
  sh /vagrant/setup_mysql57.sh
fi
if [[ ${MATTERMOST_DB_TYPE} = 'postgres' ]]; then
  sh /vagrant/setup_postgres94.sh
fi

#-------------------------------------------------------------------------------
# Setup Mattermost Server (2.x)
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
MATTERMOST_CONFIG_DIR='/opt/mattermost/config'
if [[ ${MATTERMOST_DB_TYPE} = 'mysql' ]]; then
  cp /vagrant/conf/mattermost/mysql/config.json ${MATTERMOST_CONFIG_DIR}/config.json
fi
if [[ ${MATTERMOST_DB_TYPE} = 'postgres' ]]; then
  cp /vagrant/conf/mattermost/postgres/config.json ${MATTERMOST_CONFIG_DIR}/config.json
fi

# service setup
cp /vagrant/conf/systemd/mattermost.service /etc/systemd/system/mattermost.service
chmod 664 /etc/systemd/system/mattermost.service
systemctl daemon-reload
systemctl start mattermost.service
systemctl enable mattermost.service

#-------------------------------------------------------------------------------
# Setup Nginx Server
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
# Japanese Localization
#-------------------------------------------------------------------------------

# TimeZone settings
cat << TIME > /etc/sysconfig/clock
ZONE="Asia/Tokyo"
UTC="false"
TIME
source /etc/sysconfig/clock
/bin/cp -f /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# use N-gram FULLTEXT Index sample
#   (only MySQL 5.7.9+, postgres and others are not yet...)
#if [[ ${MATTERMOST_DB_TYPE} = 'mysql' ]]; then
#    mysql mattermost -u mmuser -pmmuser_password -e "ALTER TABLE Posts DROP INDEX idx_posts_message_txt;"
#    mysql mattermost -u mmuser -pmmuser_password -e "ALTER TABLE Posts ADD FULLTEXT INDEX idx_posts_message_txt (Message) WITH PARSER ngram COMMENT 'ngram-index';"
#fi

echo '----------------------------------------------------------------'
echo 'Setup complete!!'
echo 'please access to : http://standalone-mattermost.vagrant.local/  '
echo '----------------------------------------------------------------'
