#!/bin/bash

/sbin/sysctl -w net.ipv4.ip_forward=1
/sbin/sysctl -w net.ipv4.conf.default.proxy_arp=1
/sbin/sysctl -w net.ipv4.conf.default.arp_accept=1
/sbin/sysctl -w net.ipv4.conf.default.proxy_arp_pvlan=1


iptables -A POSTROUTING -t nat -o eth0 -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

if [ "$VPN_PASSWORD" = "password" ] || [ "$VPN_PASSWORD" = "" ]; then
  # Generate a random password
  P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
  P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
  P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
  VPN_PASSWORD="$P1$P2$P3"
  echo "No VPN_PASSWORD set! Generated a random password: $VPN_PASSWORD"
fi

if [ "$VPN_PSK" = "password" ] || [ "$VPN_PSK" = "" ]; then
  # Generate a random password
  P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
  P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
  P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
  VPN_PSK="$P1$P2$P3"
  echo "No VPN_PSK set! Generated a random PSK key: $VPN_PSK"
fi

if [ "$VPN_PASSWORD" = "$VPN_PSK" ]; then
  echo "It is not recommended to use the same secret as password and PSK key!"
fi

cat > /etc/ipsec.secrets <<EOF
# This file holds shared secrets or RSA private keys for authentication.
# RSA private key for this host, authenticating it to any other host
# which knows the public part.  Suitable public keys, for ipsec.conf, DNS,
# or configuration of other implementations, can be extracted conveniently
# with "ipsec showhostkey".
: PSK "$VPN_PSK"
$VPN_USER : EAP "$VPN_PASSWORD"
$VPN_USER : XAUTH "$VPN_PASSWORD"
EOF


ipsec start --nofork
