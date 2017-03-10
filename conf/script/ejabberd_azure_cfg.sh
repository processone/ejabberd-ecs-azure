#!/bin/bash

# Azure autoconf

# vars
ejabberdInstall="/opt/ejabberd"

Hotfix(){

  # Install curl (hard to believe but it's not default on Debian...
  apt-get -y install curl

  # Workaround for bug related with inproper ejabberd install dir found in Azure image
  test -e /opt/ejabberd || ls -d /opt/ejabberd-* | xargs -ixxx ln -s xxx /opt/ejabberd

  # Remove standard lib from ejabberd installer due to errors
  rm -f $ejabberdInstall/lib/linux-x86_64/libtinfo.so.5
  ln -s /lib/x86_64-linux-gnu/libtinfo.so.5 $ejabberdInstall/lib/linux-x86_64/libtinfo.so.5

  # Remove all leftovers from installer
  /etc/init.d/ejabberd stop
  rm -rf /opt/ejabberd/logs/* /opt/ejabberd/database/ejabberd@localhost/*

}

updateTemplates(){

  isThere=$(curl -s https://raw.githubusercontent.com/processone/ejabberd-ecs-azure/master/conf/ejabberd_template.yml | grep -c "ejabberd configuration file")
  if [ $isThere -gt 0 ];then
    echo "Getting new templates..."
    wget -q https://raw.githubusercontent.com/processone/ejabberd-ecs-azure/master/conf/ejabberd_template.yml -O /opt/ejabberd/conf/ejabberd.yml
    wget -q https://raw.githubusercontent.com/processone/ejabberd-ecs-azure/master/conf/ejabberdctl.cfg -O /opt/ejabberd/conf/ejabberdctl.cfg
  fi
}

setDomain(){

  echo "Setting domain name to $1"
  sed -i s/AZURE_HOST/$1/g $ejabberdInstall/conf/ejabberd.yml
}


setAdmin(){

  echo "Setting admin for ejabberd"
  sed -i s/AZURE_ADMIN/$1/g $ejabberdInstall/conf/ejabberd.yml
}


getSSL(){

  echo "Generating self-signed certificate for domain $1"
  openssl req -x509 -newkey rsa:2048 -sha256 -keyout /tmp/azuredomain.key -out /tmp/azuredomain.crt -nodes -days 365 -subj "/C=US/ST=US_State/L=NA/O=IT/CN=$1"
  cat /tmp/azuredomain.crt > $ejabberdInstall/conf/$1\.pem
  cat /tmp/azuredomain.key >> $ejabberdInstall/conf/$1\.pem
  rm -f /tmp/azuredomain.key /tmp/azuredomain.crt
  chown ejabberd:ejabberd $ejabberdInstall/conf/$1\.pem
  chmod go-rwx $ejabberdInstall/conf/$1\.pem
}

registerAdmin(){

  echo "Registering admin: $1 with password: $3 on $2"
  su - ejabberd -c "$ejabberdInstall/bin/ejabberdctl register $1 $2 $3"
}

startServer(){

  status=$(/etc/init.d/ejabberd status | grep -c "status: started")
  if [ "$status" -ne "1" ];then
      /etc/init.d/ejabberd start
    else
      echo "ejabberd already started"
  fi
}

# validate
if test "$#" -ne 3; then
  echo "All 3 parameters are required (domainName adminName adminPassword)"
  exit 1
fi

Hotfix
updateTemplates
setDomain $1
setAdmin $2
getSSL $1
startServer
registerAdmin $2 $1 $3
