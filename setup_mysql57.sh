#!/bin/sh

MYSQL_ROOT_PASSWD='thisisroot'

#-------------------------------------------------------------------------------
# Set up Database Server (MySQL 5.7.x)
#   @see http://docs.mattermost.com/install/prod-rhel-7.html#set-up-database-server
#-------------------------------------------------------------------------------

# install MySQL(5.7)
yum -y remove mariadb-libs
rm -rf /var/lib/mysql

yum -y localinstall http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
yum -y install mysql-community-server

# startup
systemctl enable mysqld.service
systemctl start mysqld.service

# configure(unsecured-password-option enabled)
mv /etc/my.cnf /etc/my.cnf.bak
cp /vagrant/conf/mysql/my.cnf /etc/my.cnf
systemctl restart mysqld.service

# init mysql (like `mysql_secure_installation`, this is sample, DONT USE PRODUCTION!!)
#  - you can access by root: $ mysql -u root -p${MYSQL_ROOT_PASSWD}
MYSQL_TMP_PASSWD=`sudo grep 'temporary password' /var/log/mysqld.log | sed -e "s/.*root@localhost: //"`
PASSWD_UPDATE_SQL="SET PASSWORD FOR root@localhost=PASSWORD('${MYSQL_ROOT_PASSWD}');"
mysql -u root -p"${MYSQL_TMP_PASSWD}" -e "${PASSWD_UPDATE_SQL}" --connect-expired-password
mysql -u root -p"${MYSQL_ROOT_PASSWD}" < /vagrant/conf/mysql/initdb.sql

# create database and user
mysql -u root -p"${MYSQL_ROOT_PASSWD}" < /vagrant/conf/mattermost/mysql/create_db.sql
