ARG ALPINE_VER=3.21
ARG RUT_VER=v5.2.10
ARG RT_VER=v0.16.5
ARG DT_VER=v1.7.0
ARG NITRO_VER=v0.6
ARG UNRAR_VER=7.2.3
ARG REMOVE_PLUGINS="rutracker_check _cloudflare"

# ==========================================
# STAGE 1: The Builder
# ==========================================
FROM alpine:${ALPINE_VER} AS builder

RUN apk add --no-cache git build-base linux-headers automake autoconf libtool pkgconf \
    curl-dev ncurses-dev openssl-dev zlib-dev xmlrpc-c-dev cmake curl jq

WORKDIR /tmp

# Build Libtorrent & rTorrent
ARG RT_VER 
RUN git clone --depth 1 --branch ${RT_VER} https://github.com/rakshasa/libtorrent.git \
    && cd libtorrent && autoreconf -ivf && ./configure --disable-debug --enable-aligned CXXFLAGS="-std=c++17" \
    && make -j$(nproc) && make install \
    && cd .. \
    && git clone --depth 1 --branch ${RT_VER} https://github.com/rakshasa/rtorrent.git \
    && cd rtorrent && autoreconf -ivf && ./configure --with-xmlrpc-c CXXFLAGS="-std=c++17" \
    && make -j$(nproc) && make install \
    && strip --strip-unneeded /usr/local/bin/rtorrent /usr/local/lib/libtorrent.so*

# Build Nitro & Dumptorrent
ARG DT_VER
ARG NITRO_VER
RUN git clone --depth 1 --branch ${NITRO_VER} https://github.com/leahneukirchen/nitro.git \
    && cd nitro && make && cp nitro nitroctl /usr/local/bin/ \
    && cd .. \
    && git clone --depth 1 --branch ${DT_VER} https://github.com/tomcdj71/dumptorrent.git \
    && cd dumptorrent && sed -i '1i #include <sys/time.h>' src/scrapec.c \
    && cmake -B build -DCMAKE_BUILD_TYPE=Release -S . \
    && cmake --build build --parallel $(nproc) && strip --strip-unneeded build/dumptorrent

# Download Unrar & ruTorrent
ARG UNRAR_VER RUT_VER
RUN curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/tags/${UNRAR_VER} \
    | jq -r '.assets[] | select(.name == "unrar") | .browser_download_url' \
    | xargs curl -Lsf -o /tmp/unrar && chmod +x /tmp/unrar \
    && git clone --depth 1 --branch ${RUT_VER} https://github.com/Novik/ruTorrent.git /tmp/rutorrent

# Remove unwanted rutorrent plugins
ARG REMOVE_PLUGINS
RUN if [ -n "$REMOVE_PLUGINS" ]; then \
        for plugin in $REMOVE_PLUGINS; do \
            echo "Removing plugin: $plugin"; \
            rm -rf /tmp/rutorrent/plugins/$plugin; \
        done; \
    fi

# ==========================================
# STAGE 2: Monolith
# ==========================================
FROM alpine:${ALPINE_VER}

RUN apk add --no-cache \
    nginx curl ffmpeg mediainfo tzdata libstdc++ libgcc sox \
    ncurses-libs ncurses-terminfo-base zlib util-linux tini xmlrpc-c \
    php83 php83-fpm php83-ctype php83-session php83-json php83-mbstring \
    php83-sockets php83-posix php83-xml php83-simplexml php83-dom \
    php83-curl php83-phar php83-openssl php83-zip

RUN ln -sf /usr/bin/php83 /usr/bin/php \
    && adduser -D -u 1000 ops \
    # Create necessary paths
    && mkdir -p /run/ops /var/lib/nginx/tmp /var/log/nginx /downloads /etc/nitro

# Copy binaries and ruTorrent from builder
COPY --from=builder /usr/local/bin/rtorrent /usr/bin/rtorrent
COPY --from=builder /usr/local/bin/nitro* /usr/bin/
COPY --from=builder /usr/local/lib/libtorrent.so* /usr/lib/
COPY --from=builder /tmp/dumptorrent/build/dumptorrent /usr/bin/dumptorrent
COPY --from=builder /tmp/unrar /usr/bin/unrar
COPY --from=builder --chown=ops:ops /tmp/rutorrent /var/www/rutorrent

# Apply patches and permissions
RUN rm -rf /var/www/rutorrent/plugins/rutracker_check && \
    chown -R ops:ops /run/ops /var/lib/nginx /var/log/nginx /config /downloads /etc/nitro /var/www/rutorrent && \
    # Adjust autotools plugin watch folder check interval
    sed -i "s/\$autowatch_interval = 300;/\$autowatch_interval = 15;/g" /var/www/rutorrent/plugins/autotools/conf.php

# Copy default configs
COPY --chown=ops:ops defaults/nginx.conf /etc/nginx/nginx.conf
COPY --chown=ops:ops defaults/php-fpm.conf /etc/php83/php-fpm.d/www.conf
COPY --chown=ops:ops defaults/rutorrent-config.php /var/www/rutorrent/conf/config.php
COPY --chown=ops:ops defaults/rtorrent.rc /etc/rtorrent.rc

# Setup Nitro Services
COPY --chown=ops:ops services/ /etc/nitro/
RUN chmod +x /etc/nitro/*/run
    
USER ops
WORKDIR /config
ENV NITRO_SOCK=/run/ops/nitro.sock
ENV TERM=dumb
EXPOSE 8080 50000

ENTRYPOINT ["/usr/bin/nitro", "/etc/nitro"]