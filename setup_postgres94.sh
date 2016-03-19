#!/bin/sh

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
sudo -i -u postgres psql < /vagrant/conf/mattermost/postgres/create_db.sql

# configure
cp /vagrant/conf/pgsql/postgresql.conf /var/lib/pgsql/9.4/data/postgresql.conf
cp /vagrant/conf/pgsql/pg_hba.conf /var/lib/pgsql/9.4/data/pg_hba.conf

# startup
systemctl restart postgresql-9.4.service
