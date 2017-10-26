#!/bin/bash

HOSTNAME=$1

function download_dotfiles() {
  if [ -d /home/ubuntu/.dotfiles ]; then
    echo "Skipping dotfiles"
  else
    echo "Installing dotfiles"
    git clone https://github.com/rdeguzman/dotfiles /home/ubuntu/.dotfiles
  fi
}

function setup_symbolic_links() {
  echo "Backing up old .bashrc"
  mv /home/ubuntu/.bashrc /home/ubuntu/.bashrc.old

  echo "Creating symbolic links"
  ln -s /home/ubuntu/.dotfiles/ubuntu/bash /home/ubuntu/.bash
  ln -s /home/ubuntu/.dotfiles/ubuntu/bashrc /home/ubuntu/.bashrc
  ln -s /home/ubuntu/.dotfiles/ubuntu/localrc /home/ubuntu/.localrc
  ln -s /home/ubuntu/.dotfiles/vimrc /home/ubuntu/.vimrc
  ln -s /home/ubuntu/.dotfiles/tmux.conf /home/ubuntu/.tmux.conf

  echo "chown -Rf ubuntu:ubuntu /home/ubuntu"
  chown -Rf ubuntu:ubuntu /home/ubuntu
}

function setup_vim() {
  echo "Setup vim plugin"
  curl -fLo /home/ubuntu/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  sudo chown -Rf ubuntu:ubuntu /home/ubuntu/.vim
}

function update_hostname() {
  bash scripts/hostname.sh $1
}

function add_host() {
  if [ $# -ne 1 ]; then
    echo "No hostname provided!"
  else
    bash scripts/hosts.sh add 127.0.0.1 $1
  fi
}

function ask_reboot() {
  echo -n "Reboot proceed? [y/n]: "
  read ans
  if [ $ans = "y" ]; then
    echo "Rebooting in 5 seconds"
    sleep 5
    sudo reboot
  fi
}

download_dotfiles
setup_symbolic_links
setup_vim
update_hostname $HOSTNAME
add_host $HOSTNAME
ask_reboot

