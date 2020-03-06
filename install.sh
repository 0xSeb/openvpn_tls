#!/usr/bin/bash

# Install Package
yum install epel-release -y
yum update -y
yum install -y openvpn

# Set sample config
cp /usr/share/doc/openvpn-*/sample/sample-config-files/server.conf /etc/openvpn

# Prepare CA and Server Certificate
mkdir /root/certs


# Create SSL conf for KU and EKU
printf '%s\n' \
'[ v3_server ]' \
'basicConstraints = CA:FALSE' \
'keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment, keyAgreement' \
'extendedKeyUsage = critical, serverAuth' \
' ' \
'[ v3_client ]' \
'basicConstraints = CA:FALSE' \
'keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment, keyAgreement' \
'extendedKeyUsage = critical, clientAuth' \
> /root/certs/openssl.cnf

# Create CA key and cert
openssl req -nodes -x509 -days 3580 -newkey rsa:2048 -keyout /root/certs/ca.key -out /root/certs/ca.crt -subj "/CN=FR/ST=FRANCE/L=BORDEAUX/O=EPSI/OU=SECU/CN=ca/emailAddress=contact@localhost.com"

# Prepare server certificate
openssl req -nodes -newkey rsa:2048 -days 1095 -keyout /root/certs/server.key -out /root/certs/server.csr -subj "/C=FR/ST=FRANCE/L=BORDEAUX/O=EPSI/OU=SECU/CN=server/emailAddress=email@localhost.com"
openssl x509 -req -in /root/certs/server.csr -CA /root/certs/ca.crt -days 1095 -CAkey /root/certs/ca.key -CAcreateserial -out /root/certs/server.crt -CAserial /root/certs/serial -extensions v3_server -extfile /root/certs/openssl.cnf

# Generate DH pem
openssl dhparam -out /root/certs/dh2048.pem 2048

# Generate TLS Auth secret
openvpn --genkey --secret /etc/openvpn/vpn.tlsauth

# Edit server conf
sed -i '/^;.*redirect-gateway.*/s/^;//' /etc/openvpn/server.conf
sed -i '/^;.*dhcp-option.*/s/^;//' /etc/openvpn/server.conf
sed -i 's/port 1194/port 443/' /etc/openvpn/server.conf
sed -i '/^;.*proto tcp.*/s/^;//' /etc/openvpn/server.conf
sed -i 's/proto udp/;proto udp/' /etc/openvpn/server.conf
sed -i '/^;.*user nobody.*/s/^;//' /etc/openvpn/server.conf
sed -i '/^;.*group nobody.*/s/^;//' /etc/openvpn/server.conf
sed -i 's/^tls-auth/;tls-auth/' /etc/openvpn/server.conf
sed -i 's/exit-notify 1/exit-notify 0/' /etc/openvpn/server.conf
printf "\nremote-cert-eku \"TLS Web Client Authentication"\" >> /etc/openvpn/server.conf
printf "\ntls-crypt vpn.tlsauth" >> /etc/openvpn/server.conf

# Copy files to open vpn conf dir
cp /root/certs/dh2048.pem /root/certs/ca.crt /root/certs/server.key /root/certs/server.crt /etc/openvpn

# Add ip forwarding
sed -i '1s/^/net.ipv4.ip_forward = 1\n/'  /etc/sysctl.conf

# Restart services
systemctl restart network.service
systemctl -f enable --now openvpn@server.service
