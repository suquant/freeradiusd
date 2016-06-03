FROM alpine:3.4

# install common packages
RUN apk update && \
	apk add freeradius freeradius-sqlite freeradius-postgresql freeradius-pam freeradius-redis \
	openssl make sqlite bash

COPY entrypoint.sh /usr/bin/entrypoint.sh

VOLUME ["/var/lib/raddb"]

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD [""]

EXPOSE 1812/udp 1813/udp
