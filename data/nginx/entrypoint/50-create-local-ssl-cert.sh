#!/bin/bash

CERT_DIR=/etc/nginx/ssl/live/${DOMAIN}

# Create local certs
if [ ! -d "$CERT_DIR" ]; then
	echo "[WARNING] Certs for ${DOMAIN} don't exist, creating local certs. Don't use in production"
	mkdir -p ${CERT_DIR}
	openssl req -x509 -nodes -newkey rsa:4096 -days 1 \
		-keyout "${CERT_DIR}/privkey.pem" \
		-out "${CERT_DIR}/fullchain.pem" \
		-subj '/CN=localhost'
fi
