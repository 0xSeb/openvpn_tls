#!/usr/bin/bash

# DROP ALL RULES
iptables -F

# DROP ON EVERY PROTOCOL
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# SSH
iptables -A INPUT -i ens33 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# OPENVPN
iptables -A INPUT -i ens33 -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED -j ACCEPT

