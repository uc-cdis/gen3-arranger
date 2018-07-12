#!/bin/bash
#
# Remove stuff from the docker image that is not necessary at runtime
#

apt-get list --installed  | grep -e python -e perl | awk '{ print $1 }' | sed 's@/now$@@' | while read -r name; do
   echo "-- $name"
   apt-get remove -y "$name"
done
apt-get remove -y git
apt-get autoremove -y
