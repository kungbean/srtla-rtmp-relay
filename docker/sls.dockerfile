# build stage
FROM debian:11.7-slim as build
RUN apt update && \
    apt upgrade -y && \
    apt install -y tclsh pkg-config cmake libssl-dev build-essential git zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN git clone --branch v1.5.1 https://github.com/Haivision/srt.git
WORKDIR /build/srt
RUN ./configure && make && make install
WORKDIR /build
RUN git clone https://github.com/kungbean/srt-live-server.git
WORKDIR /build/srt-live-server
RUN make

# runtime image
FROM debian:11.7-slim
ENV LD_LIBRARY_PATH /lib:/lib/x86_64-linux-gnu:/usr/lib:/usr/local/lib64:/usr/local/lib
RUN apt update && \
    apt upgrade -y && \
    apt install -y openssl libstdc++6 gettext-base && \
    rm -rf /var/lib/apt/lists/*
RUN useradd srt && \
    mkdir /etc/sls /logs && \
    chown srt /logs /etc/sls
COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=build /build/srt-live-server/bin/* /usr/local/bin/
ENV TEMPLATE_DIR /etc/sls/templates
COPY ./data/sls/templates ${TEMPLATE_DIR}
COPY ./data/sls/entrypoint/entrypoint.sh /entrypoint.sh
RUN ln -sf /dev/stdout /logs/access.log && \
    ln -sf /dev/stderr /logs/error.log

ARG SLS_PORT=30000 \
    SLS_STATS_PORT=8181
ENV SLS_PORT=${SLS_PORT} \
    SLS_STATS_PORT=${SLS_STATS_PORT} \
    SLS_LATENCY=1000 \
    SLS_DOMAIN_PLAYER=play \
    SLS_DOMAIN_PUBLISHER=publish \
    SLS_APP_PLAYER=app \
    SLS_APP_PUBLISHER=app
EXPOSE ${SLS_PORT} ${SLS_STATS_PORT}/udp
USER srt
WORKDIR /home/srt

ENTRYPOINT ["/entrypoint.sh"]
CMD ["sls", "-c", "/etc/sls/sls.conf"]
