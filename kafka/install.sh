#!/usr/bin/env bash
LOG="provision-script.log"
KAFKA_VERSION="2.11-0.11.0.0"
DOWNLOAD_DIR="downloads"
KAFKA_DIR="/usr/local/kafka"
KAFKA_HOST="kafka.gpstracking.com.au"
KAFKA_PORT="9092"
ZOOKEEPER_PORT="2181"

function update_apt() {
  echo "Updating apt resources"
  sudo apt-get update -y >>/tmp/$LOG 2>&1

  echo "Installing: openjdk-8"
  sudo apt-get install openjdk-8-jdk -y >>/tmp/$LOG 2>&1

  echo "Installing: zookeeper"
  sudo apt-get install zookeeperd -y >>/tmp/$LOG 2>&1
}

function download_kafka() {
  mkdir -p ~/$DOWNLOAD_DIR
  if [ -f ~/$DOWNLOAD_DIR/kafka_$KAFKA_VERSION.tgz ]; then
    echo "File kafka_$KAFKA_VERSION.tgz already exists"
  else
    echo "Downloading kafka_$KAFKA_VERSION.tgz"
    wget -P ~/$DOWNLOAD_DIR http://apache.melbourneitmirror.net/kafka/0.11.0.0/kafka_$KAFKA_VERSION.tgz
  fi
}

function extract() {
  echo "Extracting kafka"
  if [ -d ~/$DOWNLOAD_DIR/kafka_$KAFKA_VERSION ]; then
    echo "Removing existing $DOWNLOAD_DIR/kafka_$KAFKA_VERSION "
    rm -Rf ~/$DOWNLOAD_DIR/kafka_$KAFKA_VERSION
  fi
  tar -zxf ~/$DOWNLOAD_DIR/kafka_$KAFKA_VERSION.tgz -C ~/$DOWNLOAD_DIR
}

function install() {
  if [ -d /usr/local/kafka_$KAFKA_VERSION ]; then
    echo "Removing kafka"
    sudo rm -Rf /usr/local/kafka_$KAFKA_VERSION
  fi

  echo "cp kafka_$KAFKA_VERSION /usr/local/"
  sudo mv ~/$DOWNLOAD_DIR/kafka_$KAFKA_VERSION /usr/local/

  echo "Creating symbolic links to /usr/local/kafka"
  sudo ln -s /usr/local/kafka_$KAFKA_VERSION /usr/local/kafka

  echo "Creating /var/log/kafka"
  sudo mkdir -p /var/log/kafka
}

function add_env() {
  if [ -z "$(grep KAFKA_PORT ~/.localrc)" ]; then
    echo "Adding KAFKA_PORT=$KAFKA_PORT to localrc"
    sudo echo "export KAFKA_PORT=$KAFKA_PORT" >> ~/.localrc
  fi
  if [ -z "$(grep ZOOKEEPER_PORT ~/.localrc)" ]; then
    echo "Adding ZOOKEEPER_PORT=2181 to localrc"
    sudo echo "export ZOOKEEPER_PORT=$ZOOKEEPER_PORT" >> ~/.localrc
  fi
  source ~/.localrc
}

function update_server_properties() {
  echo "Copy server.properties to /usr/local/kafka/config"
  sudo cp kafka/server.properties $KAFKA_DIR/config/
  sudo sed -ie "s/CHANGE_KAFKA_HOST/$KAFKA_HOST/g" $KAFKA_DIR/config/server.properties
  sudo sed -ie "s/CHANGE_KAFKA_PORT/$KAFKA_PORT/g" $KAFKA_DIR/config/server.properties
}

function startup_scripts() {
  echo "Copy kafka_start_stop script to /etc/init.d/kafka"
  sudo cp kafka/kafka_start_stop /etc/init.d/kafka

  echo "Make kafka start on boot"
  sudo update-rc.d kafka defaults
}

function add_kafka_hosts() {
  IPADDR=`/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
  bash scripts/hosts.sh add $IPADDR $KAFKA_HOST
}

update_apt
download_kafka
extract
install
add_env
update_server_properties
add_kafka_hosts
startup_scripts
