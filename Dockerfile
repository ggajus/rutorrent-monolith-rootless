# syntax=docker/dockerfile:1

ARG ALPINE_VER=3.23
ARG RUT_VER=v5.2.10
ARG RT_VER=v0.16.8
ARG DT_VER=v1.7.0
ARG NITRO_VER=v0.8
ARG UNRAR_VER=7.2.3
ARG REMOVE_PLUGINS="rutracker_check _cloudflare mediainfo screenshots spectrogram geoip"

# ==========================================
# STAGE 1: The Builder
# ==========================================
FROM alpine:${ALPINE_VER} AS builder

RUN apk add --no-cache git build-base linux-headers automake autoconf libtool pkgconf \
  curl-dev ncurses-dev openssl-dev zlib-dev xmlrpc-c-dev cmake curl jq

WORKDIR /tmp

# Build Libtorrent & rTorrent
ARG RT_VER 
RUN <<EOF
  set -e
  
  # --- Libtorrent ---
  git clone --depth 1 --branch ${RT_VER} https://github.com/rakshasa/libtorrent.git
  cd libtorrent
  autoreconf -ivf
  ./configure --disable-debug --enable-aligned --enable-static --disable-shared CXXFLAGS="-std=c++17 -Os -flto"
  make -j$(nproc)
  make install
  cd ..
  
  # --- rTorrent ---
  git clone --depth 1 --branch ${RT_VER} https://github.com/rakshasa/rtorrent.git
  cd rtorrent
  autoreconf -ivf
  ./configure --with-xmlrpc-tinyxml2 CXXFLAGS="-std=c++17 -Os -flto"
  make -j$(nproc)
  make install
  strip --strip-all /usr/local/bin/rtorrent
EOF

# Build Nitro
ARG NITRO_VER
RUN <<EOF
  set -e
  git clone --depth 1 --branch ${NITRO_VER} https://github.com/leahneukirchen/nitro.git
  cd nitro 
  make 
  cp nitro nitroctl /usr/local/bin/
  strip --strip-all /usr/local/bin/nitro /usr/local/bin/nitroctl
  cd ..
EOF

# Build Dumptorrent
ARG DT_VER
RUN <<EOF
  set -e
  git clone --depth 1 --branch ${DT_VER} https://github.com/tomcdj71/dumptorrent.git
  cd dumptorrent
  # Patching missing header for Musl compatibility
  sed -i '1i #include <sys/time.h>' src/scrapec.c
  
  cmake -B build -DCMAKE_BUILD_TYPE=Release -S .
  cmake --build build --parallel $(nproc)
  strip --strip-all build/dumptorrent
EOF

# Download Unrar
ARG UNRAR_VER
RUN <<EOF
  set -e

  DOWNLOAD_URL=$(curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/tags/${UNRAR_VER} | jq -r '.assets[] | select(.name == "unrar") | .browser_download_url')
  
  curl -Lsf -o /tmp/unrar "$DOWNLOAD_URL"
  chmod +x /tmp/unrar
  strip --strip-all /tmp/unrar
EOF

ARG RUT_VER REMOVE_PLUGINS
RUN <<EOF
  set -e
  git clone --depth 1 --branch ${RUT_VER} https://github.com/Novik/ruTorrent.git /tmp/rutorrent

  # Clean up unused plugins
  if [ -n "$REMOVE_PLUGINS" ]; then
    for plugin in $REMOVE_PLUGINS; do
      echo "Removing plugin: $plugin"
      rm -rf "/tmp/rutorrent/plugins/$plugin"
    done
  fi

  # Clean up unused data
  rm -rf /tmp/rutorrent/.git* /tmp/rutorrent/.vscode /tmp/rutorrent/tests
  
  # Remove all themes except Oblivion
  find /tmp/rutorrent/plugins/theme/themes -mindepth 1 -maxdepth 1 ! -name "Oblivion" -exec rm -rf {} +
EOF

# ==========================================
# STAGE 2: Monolith
# ==========================================
FROM alpine:${ALPINE_VER}

RUN apk add --no-cache \
  nginx libstdc++ libgcc zlib curl \
  php83-fpm php83-ctype php83-session php83-json php83-mbstring \
  php83-sockets php83-posix php83-xml php83-simplexml php83-dom \
  php83-curl php83-phar php83-openssl php83-zip

RUN <<EOF
  set -e
  ln -sf /usr/bin/php83 /usr/bin/php
  adduser -D -u 1000 ops
  # Create necessary paths
  mkdir -p /run/ops /var/lib/nginx/tmp /var/log/nginx /downloads /config /etc/nitro
EOF

# Copy binaries and ruTorrent from builder
COPY --from=builder /usr/local/bin/rtorrent /usr/bin/rtorrent
COPY --from=builder /usr/local/bin/nitro* /usr/bin/
COPY --from=builder /tmp/dumptorrent/build/dumptorrent /usr/bin/dumptorrent
COPY --from=builder /tmp/unrar /usr/bin/unrar
COPY --from=builder --chown=ops:ops /tmp/rutorrent /var/www/rutorrent

# Copy default configs
COPY --chown=ops:ops defaults/nginx.conf /etc/nginx/nginx.conf
COPY --chown=ops:ops defaults/php-fpm.conf /etc/php83/php-fpm.d/www.conf
COPY --chown=ops:ops defaults/rutorrent-config.php /var/www/rutorrent/conf/config.php
COPY --chown=ops:ops defaults/rtorrent.rc /etc/rtorrent.rc

# Copy nitro services
COPY --chown=ops:ops services/ /etc/nitro/

# Apply patches and permissions
RUN <<EOF
  set -e
  chown -R ops:ops /run/ops /var/lib/nginx /var/log/nginx /config /downloads /etc/nitro

  # Adjust autotools plugin watch folder check interval
  sed -i "s/\$autowatch_interval = 300;/\$autowatch_interval = 15;/g" /var/www/rutorrent/plugins/autotools/conf.php

  # Prevent Nginx from passing the username to PHP (keep ruTorrent in single user mode)
  sed -i '/REMOTE_USER/d' /etc/nginx/fastcgi_params

  # Make service runners executable
  chmod +x /etc/nitro/*/run
EOF
  
USER ops
WORKDIR /config
ENV NITRO_SOCK=/run/ops/nitro.sock
ENV TERM=dumb
EXPOSE 8080 6881 50000 

ENTRYPOINT ["/usr/bin/nitro", "/etc/nitro"]
