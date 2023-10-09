ARG NGINX_VERSION=1.25.2
ARG RTMP_MOD_VERSION=1.2.2

# build nginx with rtmp
FROM debian:12.1-slim as build

RUN apt update && \
    apt upgrade -y && \
    apt install -y build-essential wget \
        libpcre2-dev \
        libssl-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

ARG NGINX_VERSION
RUN wget https://github.com/nginx/nginx/archive/refs/tags/release-${NGINX_VERSION}.tar.gz && \
    tar -xzf release-${NGINX_VERSION}.tar.gz && \
    rm release-${NGINX_VERSION}.tar.gz

ARG RTMP_MOD_VERSION
RUN wget https://github.com/arut/nginx-rtmp-module/archive/refs/tags/v${RTMP_MOD_VERSION}.tar.gz && \
    tar -xzf v${RTMP_MOD_VERSION}.tar.gz && \
    rm v${RTMP_MOD_VERSION}.tar.gz

WORKDIR /build/nginx-release-${NGINX_VERSION}

RUN ./auto/configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/etc/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --with-http_ssl_module \
    --with-threads \
    --http-log-path=/var/log/nginx/access.log \
    --add-module=/build/nginx-rtmp-module-${RTMP_MOD_VERSION} && \
    make && \
    make install

# pull just for entrypoint scripts
FROM nginx:${NGINX_VERSION} as template

# runtime image
FROM debian:12.1-slim

RUN apt update && \
    apt upgrade -y && \
    apt install -y libpcre2-posix3 openssl zlib1g gettext-base && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /var/log/nginx && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

ARG RTMP_MOD_VERSION
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=build /build/nginx-rtmp-module-${RTMP_MOD_VERSION}/stat.xsl /etc/nginx/html/stat.xsl
COPY --from=template /docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=template /docker-entrypoint.d /docker-entrypoint.d
COPY ./data/nginx/templates /etc/nginx/templates
COPY ./data/nginx/entrypoint/40-create-basic-auth.sh /docker-entrypoint.d/
COPY ./data/nginx/entrypoint/50-create-local-ssl-cert.sh /docker-entrypoint.d/
RUN mkdir /etc/nginx/conf.d && rm /etc/nginx/html/index.html

EXPOSE 80 443 1935

ENV DOMAIN=localhost \
    RMTP_APP=live \
    SLS_STATS_PORT=8181 \
    SRT_STATS_ROUTE=/srt/stat \
    RTMP_STATS_ROUTE=/rtmp/stat \
    RTMP_XSL_STATS_ROUTE=/rtmp/statxsl \
    USERNAME=stats \
    PASSWORD=mySecureStatsPassword

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
