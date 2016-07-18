#!/bin/bash

# Azure autoconf

# vars
ejabberdInstall="/opt/ejabberd"

fixLink(){

  # Workaround for bug related with inproper ejabberd install dir found in Azure image
  test -e /opt/ejabberd || ls -d /opt/ejabberd-* | xargs -ixxx ln -s xxx /opt/ejabberd
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
  openssl req -x509 -newkey rsa:2048 -sha256 -keyout /tmp/azuredomain.key -out /tmp/azuredomain.crt -nodes -days 365 -subj "/C=US/ST=US_State/L=NA/O=IT/CN=$1\.cloudapp.net"
  cat /tmp/azuredomain.crt > $ejabberdInstall/conf/$1\.pem
  cat /tmp/azuredomain.key >> $ejabberdInstall/conf/$1\.pem
  rm -f /tmp/azuredomain.key /tmp/azuredomain.crt
  chown ejabberd:ejabberd $ejabberdInstall/conf/$1\.pem
  chmod go-rwx $ejabberdInstall/conf/$1\.pem
}

registerAdmin(){

  echo "Registering admin: $1 with password: $3 on $2"."cloudapp.net"
  su - ejabberd -c "$ejabberdInstall/bin/ejabberdctl register $1 $2\.cloudapp.net $3"
}

startServer(){

  /etc/init.d/ejabberd start
}

# validate
if test "$#" -ne 3; then
  echo "All 3 parameters are required (domainName adminName adminPassword)"
  exit 1
fi

fixLink
updateTemplates
setDomain $1
setAdmin $2
getSSL $1
startServer
registerAdmin $2 $1 $3
