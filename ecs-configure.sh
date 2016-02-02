#!/bin/bash

# Get system updates
apt-get update
apt-get upgrade

# Install some deps
apt-get install -y gdebi-core openssl unixodbc wget

# Get latest ejabberd eCS
wget https://www.process-one.net/downloads/downloads-action.php?file=/ejabberd/latest/ejabberd-latest.deb -O /tmp/ejabberd-latest.deb

# Install it with gdebi
gdebi -n /tmp/ejabberd-latest.deb

# Fix permissions
chown ejabberd:ejabberd /opt/ejabberd* -R

# Add proper init script
ls /opt/|grep ejabberd | xargs -ixxx ln -s /opt/xxx/bin/ejabberd.init /etc/init.d/ejabberd",

