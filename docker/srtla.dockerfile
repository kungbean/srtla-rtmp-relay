# build stage
FROM debian:11.7-slim as build
RUN apt update && \
    apt upgrade -y && \
    apt install -y tclsh pkg-config cmake libssl-dev build-essential git zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN git clone --branch max_reorder_tol/v1.5.1 https://github.com/kungbean/srt.git
WORKDIR /build/srt
RUN ./configure && make && make install
WORKDIR /build
RUN git clone https://github.com/BELABOX/srtla.git
WORKDIR /build/srtla
RUN make

# runtime image
FROM debian:11.7-slim
ENV LD_LIBRARY_PATH /lib:/lib/x86_64-linux-gnu:/usr/lib:/usr/local/lib64:/usr/local/lib
RUN apt update && \
    apt upgrade -y && \
    apt install -y openssl libstdc++6 gettext-base && \
    rm -rf /var/lib/apt/lists/*
RUN useradd srt
COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=build /build/srtla/srtla_rec /usr/local/bin/

ARG SLS_PORT=30000 \
    SRTLA_PORT=30001
ENV SLS_PORT=${SLS_PORT} \
    SRTLA_PORT=${SRTLA_PORT}
EXPOSE ${SRTLA_PORT}/udp
USER srt
WORKDIR /home/srt

CMD srtla_rec ${SRTLA_PORT} sls ${SLS_PORT}
