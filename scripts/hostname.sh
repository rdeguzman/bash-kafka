#!/usr/bin/env bash
# bash hostname.sh [hostname]

# Path to your hosts file
hostnameFile="/etc/hostname"

# Hostname to add/remove.
hostname="$1"

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

RESULT=`cat $hostnameFile`

if [ $RESULT = $hostname ]; then
  echo "$hostname found in $hostnameFile.";
else
  echo "Updating hostname to $hostname"
  try echo "$hostname" | sudo tee "$hostnameFile" > /dev/null;
fi
