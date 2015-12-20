FROM alpine:edge

# install common packages
RUN apk update && \
	apk add freeradius freeradius-sqlite freeradius-postgresql freeradius-pam freeradius-redis \
	openssl make sqlite bash

COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY default /etc/raddb/sites-available/default
COPY mschap /etc/raddb/mods-available/mschap
COPY pap /etc/raddb/mods-available/pap

VOLUME ["/var/lib/raddb"]

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD [""]

EXPOSE 1812/udp 1813/udp
