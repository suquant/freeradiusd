FROM alpine:edge

# install common packages
RUN apk update && \
	apk add freeradius freeradius-postgresql freeradius-pam freeradius-redis \
	openssl make sqlite

COPY entrypoint.sh /usr/bin/entrypoint.sh

VOLUME ["/var/lib/raddb"]

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD [""]

EXPOSE 1812/udp 1813/udp
