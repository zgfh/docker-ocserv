FROM centos:8 

ENV OC_VERSION=1.1.1

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && yum install -y ocserv iptables

# Setup config
COPY groupinfo.txt /tmp/
RUN set -x \
	&& sed -i 's/\(max-same-clients = \)2/\110/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/\.\.\/tests/\/etc\/ocserv/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/#\(compression.*\)/\1/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^route/#route/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^no-route/#no-route/' /etc/ocserv/ocserv.conf \
	&& sed -i '/\[vhost:www.example.com\]/,$d' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^auth = /#auth = /' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^server-cert/#server-cert/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^server-key/#server-key/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^ca-cert/#ca-cert/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^ipv4-network = /#ipv4-network = /' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^ipv4-netmask = /#ipv4-netmask = /' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^dns =/#dns =/' /etc/ocserv/ocserv.conf \
	&& echo 'auth = "plain[passwd=/etc/ocserv/ocpasswd]"' >> /etc/ocserv/ocserv.conf \
	&& echo 'server-cert = /etc/ocserv/certs/server-cert.pem' >> /etc/ocserv/ocserv.conf \
	&& echo 'server-key = /etc/ocserv/certs/server-key.pem' >> /etc/ocserv/ocserv.conf \
	&& echo "ca-cert = /etc/ocserv/certs/ca.pem" >> /etc/ocserv/ocserv.conf \
	&& echo "ipv4-network = 192.168.99.0" >> /etc/ocserv/ocserv.conf \
	&& echo "ipv4-netmask = 255.255.255.0" >> /etc/ocserv/ocserv.conf \
	&& echo "dns = 8.8.8.8" >> /etc/ocserv/ocserv.conf \
	
	&& mkdir -p /etc/ocserv/config-per-group \
	&& cat /tmp/groupinfo.txt >> /etc/ocserv/ocserv.conf \
	&& rm -fr /tmp/groupinfo.txt

WORKDIR /etc/ocserv

COPY All /etc/ocserv/config-per-group/All
COPY cn-no-route.txt /etc/ocserv/config-per-group/Route

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
