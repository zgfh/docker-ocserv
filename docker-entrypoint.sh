#!/bin/sh

if [ ! -f /etc/ocserv/certs/server-key.pem ] || [ ! -f /etc/ocserv/certs/server-cert.pem ]; then
	# Check environment variables
	if [ -z "$CA_CN" ]; then
		CA_CN="VPN CA"
	fi

	if [ -z "$CA_ORG" ]; then
		CA_ORG="Big Corp"
	fi

	if [ -z "$CA_DAYS" ]; then
		CA_DAYS=9999
	fi

	if [ -z "$SRV_CN" ]; then
		SRV_CN="www.example.com"
	fi

	if [ -z "$SRV_ORG" ]; then
		SRV_ORG="MyCompany"
	fi

	if [ -z "$SRV_DAYS" ]; then
		SRV_DAYS=9999
	fi

	# No certification found, generate one
	mkdir /etc/ocserv/certs
	cd /etc/ocserv/certs
	certtool --generate-privkey --outfile ca-key.pem
	cat > ca.tmpl <<-EOCA
cn = "${CA_CN-cn}"
organization = "${CA_ORG-"ocserv"}"
serial = 1
expiration_days = ${CA_DAYS-3650}
ca
signing_key
cert_signing_key
crl_signing_key
EOCA
	certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca.pem
	certtool --generate-privkey --outfile server-key.pem 
	
	cat > server.tmpl <<-EOSRV
cn = "${SRV_CN-$CA_CN}"
organization = "${SRV_ORG-$CA_ORG}"
expiration_days = ${SRV_DAYS-$CA_DAYS}
signing_key
encryption_key
tls_www_server
EOSRV
	DNS_NAME=${DNS_NAME-"www.ocserv.local"}
	for dns in `echo ${DNS_NAME//,/ }`
	do
	echo "dns_name = $dns" >> server.tmpl
	done
	cat server.tmpl
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

	# Create a test user
	if [ -n "${USERNAME}" ] && [ ! -f /etc/ocserv/ocpasswd ]; then
		echo "Create user '${USERNAME}' "
		echo -e "${PASSWORD}\n${PASSWORD}\n" |ocpasswd -c /etc/ocserv/ocpasswd -g "Route,All" ${USERNAME}
	fi
fi

# Open ipv4 ip forward
sysctl -w net.ipv4.ip_forward=1

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Enable TUN device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Run OpennConnect Server
exec "$@"
