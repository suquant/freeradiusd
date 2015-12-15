#!/bin/sh
#
# This script is designed to be run inside the container
#

# fail hard and fast even on pipelines
set -eo pipefail

# set debug based on envvar
[[ $DEBUG ]] && set -x

if [ -h /etc/raddb/mods-available/sql ]; then
  echo "!!! sql module not supported, please install it !!!"
  exit 0
fi

if [ ! -d /var/lib/raddb ]; then
    mkdir -p /var/lib/raddb
fi

if [ ! -d /var/lib/raddb/certs ]; then
    cd /etc/raddb/certs && make
    cp -rf . /var/lib/raddb/certs
fi

cd
rm -rf /etc/raddb/certs
ln -s /var/lib/raddb/certs /etc/raddb/certs

sed -i "s/allow_vulnerable_openssl.*/allow_vulnerable_openssl = yes/" /etc/raddb/radiusd.conf
sed -i -r "s/(client localhost \{)/client ipv4{\n\tipv4addr = 0.0.0.0\/0\n\tsecret \= $radpass\n}\n\1/g" /etc/raddb/clients.conf
sed -i -r "s/(client localhost \{)/client ipv6{\n\tipv6addr = ::\n\tsecret = $radpass\n}\n\1/g" /etc/raddb/clients.conf
sed -i -r "s/testing123/$radpass/g" /etc/raddb/clients.conf
if [ ! -z "$sql_server" ]; then
  sql_driver='postgresql'
  sed -i -r "s/(driver =.*)/\1\n\tserver = \"$sql_server\"\n\tdbname = \"$sql_db\"\n\tlogin = \"$sql_login\"\n\tpassword = \"$sql_passwd\"/g" /etc/raddb/mods-available/sql
else
  sql_driver='sqlite'
  sql_file="/var/lib/raddb/db/$sql_db.sqlite3"
  echo "sql_file_esc=$sql_file_esc"
  if [ ! -d /var/lib/raddb/db ]; then
    mkdir -p /var/lib/raddb/db
  fi
  if [ ! -f $sql_file ]; then
    touch $sql_file
  fi

  sed -i -r "s/(driver =.*)/\1\n\tsqlite {\n\t\tfilename = \"\/var\/lib\/raddb\/db\/$sql_db\.sqlite3\"\n\t}/g" /etc/raddb/mods-available/sql

fi
sed -i -r "s/driver =.*/driver \= \"rlm_sql_$sql_driver\"/g" /etc/raddb/mods-available/sql
sed -i -r "s/dialect =.*/dialect = \"$sql_driver\"/g" /etc/raddb/mods-available/sql

ln -s /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/sql
sed -i '0,/md5/{s/md5/mschapv2/}' /etc/raddb/mods-available/eap

chown -R radius /var/lib/raddb

exec /usr/sbin/radiusd -fX $@
