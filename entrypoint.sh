#!/bin/sh
#
# This script is designed to be run inside the container
#

# fail hard and fast even on pipelines
set -eo pipefail

# set debug based on envvar
[[ $DEBUG ]] && set -x

ETCD_NODE=${ETCD_NODE:-127.0.0.1:2379}
CONFD_LOGLEVEL=${CONFD_LOGLEVEL:-info}
CONFD_INTERVAL=${CONFD_INTERVAL:-2}
CONFIG_FILE=/etc/haproxy/haproxy.cfg


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
sed -i -e "/client localhost/i client 0.0.0.0/0{\n\tsecret = $radpass\n}" \
  -e "/client localhost/i client ipv6{\n\tipv6addr = ::\n\tsecret = $radpass\n}" \
  -e "s/testing123/$radpass/" /etc/raddb/clients.conf
if [ ! -z "$sql_server" ]; then
  sql_driver=$sql_server
  sed -i "/driver =.*/ a\ \n\tserver = \"$sql_server\"\n\tlogin = \"$sql_login\"\n\tpassword = \"$sql_passwd\"" /etc/raddb/mods-available/sql
else
  sql_driver='sqlite'
  sqlite_db="/var/lib/raddb/db/${sql_db}.sqlite3"
  if [ ! -d /var/lib/raddb/db ]; then
    mkdir -p /var/lib/raddb/db
  fi

  sed -i "/driver =.*/ a\ \n\tsqlite {\n\t\tfilename = \"$sqlite_db\"\n\t}" /etc/raddb/mods-available/sql
fi
sed -i -e "s/driver =.*/driver = \"rlm_sql_$sql_driver\"/" -e "s/dialect =.*/dialect = \"$sql_driver\"/" /etc/raddb/mods-available/sql
ln -s /etc/raddb/mods-available/sql /etc/raddb/mods-enabled/sql
sed -i '0,/md5/{s/md5/mschapv2/}' /etc/raddb/mods-available/eap

chown -R radius /var/lib/raddb

exec /usr/sbin/radiusd -fX $@
