FROM alpine:edge

# install common packages
RUN apk update && \
	apk add freeradius freeradius-redis freeradius-rest freeradius-python freeradius-radclient freeradius-client \
	openssl bash

ENTRYPOINT ["/usr/sbin/radiusd"]
CMD [""]

EXPOSE 1812/udp 1813/udp
