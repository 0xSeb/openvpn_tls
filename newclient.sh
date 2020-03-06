#!/usr/bin/bash

# Usage : ./new_client.sh <name> <passphrase>

openssl req -passout pass:"$2" -newkey rsa:2048 -days 1095 -keyout /root/certs/$1.key -out /root/certs/$1.csr -subj "/C=FR/ST=FRANCE/L=BORDEAUX/O=EPSI/OU=SECU/CN=$1/emailAddress=email@localhost.com"
openssl x509 -req -in /root/certs/$1.csr -CA /root/certs/ca.crt -days 1095 -CAkey /root/certs/ca.key -out /root/certs/$1.crt -CAserial /root/certs/serial -extensions v3_client -extfile /root/certs/openssl.cnf

