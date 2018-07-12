#!/bin/bash
#
# Little startup script
#

sudo /usr/sbin/update-ca-certificates
cd /arranger
node ./bin/server.js
