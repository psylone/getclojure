#!/bin/bash

# Clojure installer v1.0
#
# It installs:
#   - Oracle Java 7
#   - Leiningen
#   - Lein Exec plugin

SOURCES="/etc/apt/sources.list"
JAVA_PPA_URL="http://ppa.launchpad.net/webupd8team/java/ubuntu"
JAVA_PPA_KEY="EEA14886"

determine_codename() {
  CODENAME=`cat /etc/lsb-release | grep -oP '(?<=DISTRIB_CODENAME\W)\w+'`
}

append_to_file() {
  echo $2 | sudo tee -a $1 > /dev/null
}

install_java() {
  if [ -z "`cat $SOURCES | grep $JAVA_PPA_URL`" ]; then
    echo
    echo "Add webup8team/java ppa..."
    append_to_file $SOURCES ""
    append_to_file $SOURCES "# Oracle Java"
    append_to_file $SOURCES "deb $JAVA_PPA_URL $CODENAME main"
    append_to_file $SOURCES "deb-src $JAVA_PPA_URL $CODENAME main"
    echo "DONE"
  fi
  echo
  echo "Add webupd8team/java repository key..."
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $JAVA_PPA_KEY > /dev/null
  echo "DONE"
  echo
  echo "Update repositories..."
  sudo apt-get update > /dev/null
  echo "DONE"
  echo
  echo "Install Java..."
  sudo apt-get install oracle-java7-instller > /dev/null
  echo "DONE"
}

install_leiningen() {
  echo
  echo "Install Leiningen..."
  sudo wget -O /usr/bin/lein https://raw.github.com/technomancy/leiningen/stable/bin/lein
  sudo chmod a+x /usr/bin/lein
  export LEIN_ROOT=1
  lein
  echo "DONE"
}

install_lein_exec() {
  echo
  echo "Install lein-exec plugin..."
  append_to_file ~/.lein/profiles.clj '{:user {:plugins [[lein-exec "0.3.1"]]}}'
  echo "DONE"
}

change_rights() {
  if [ $SUDO_USER ]; then user=$SUDO_USER; else user=`whoami`; fi
  sudo chown -R $user:$user $1
}

# Main workflow

clear
echo "Running getclojure.sh"
echo

echo "Check Java..."
java=`which java`
if [ -n "$java" ]; then
  echo "OK"
else
  echo "NOT FOUND"
  determine_codename
  install_java
fi

echo
echo "Check Leiningen..."
leiningen=`which lein`
if [ -n "$leiningen" ]; then
  echo "OK"
else
  echo "NOT FOUND"
  install_leiningen
fi

echo
echo "Check Leiningen (lein-exec) plugin..."
if [ -f ~/.lein/profiles.clj ]; then
  lein_plugin=`cat ~/.lein/profiles.clj | grep -P '\[\[lein-exec "\d.\d.\d"\]\]'` > /dev/null
  if [ -n "$lein_plugin" ]; then
    echo "OK"
  else
    echo "NOT FOUND"
    install_lein_exec
  fi
else
  echo "NOT FOUND"
  install_lein_exec
fi

change_rights ~/.lein
echo
echo "Clojure is now ready to be executed with Leiningen!"
echo "(Use the following command: lein exec code.clj)"
echo