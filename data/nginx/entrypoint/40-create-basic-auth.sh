#!/bin/bash

mkdir /etc/apache2/
echo -n "$USERNAME:" > /etc/apache2/.htpasswd
echo -n $PASSWORD | openssl passwd -apr1 -stdin >> /etc/apache2/.htpasswd
