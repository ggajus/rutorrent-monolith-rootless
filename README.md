# rutorrent-monolith-rootless

A lightweight, fully rootless Podman/Docker container running rTorrent and ruTorrent. This container runs entirely as a non-root user without any initialization processes that start as root and drop privileges, in contrast to alternatives that use init systems like s6-overlay.

## Features

- **Fully Rootless**: runs as user `ops` (UID 1000) from container start
- **Configurable rtorrent.rc**: a minimal default configuration imports `rutorrent.custom` from `/config`
- **Persistent RuTorrent and plugin settings**: all ruTorrent state data resides under `/config/rutorrent`
- **No Python**: the `rutracker_check` and `_cloudflare` default plugins have been removed for a smaller image

## Quick Start
Currently the image is required to be built locally.

### 1. Clone Repo
```bash
git clone https://codeberg.org/gajus/rutorrent-monolith.git
cd rutorrent-monolith
```

### 2. Create Required Mount Folders
```bash
mkdir -p ./volumes/config/{.session,rutorrent,downloads}
mkdir -p ./volumes/config/rutorrent/share/{settings,torrents}
```

### 3a. Start Using Podman Compose
```bash
podman compose up
```

### 3b. Start Using Docker Compose
```bash
docker compose up
```
ruTorrent is then reachable at `http://localhost:8080` .
## Volumes

- `/downloads`: Default download location for torrents
- `/config`: State directory (sessions, settings, state files)

## Ports

- `8080`: ruTorrent web UI
- `50000`: rTorrent DHT/incoming

## Configuration

- rTorrent config: `/etc/rtorrent.rc` (imports rutorrent.custom from /config)
- ruTorrent config: `/var/www/rutorrent/conf/config.php`
- Nginx config: `/etc/nginx/nginx.conf`

## Notes
This container is under active development, expect breaking changes, instability and lack of features until the first stable tag. If you don’t need a rootless setup, the [CrazyMax image](https://github.com/crazy-max/docker-rtorrent-rutorrent) remains the safer choice.
## Credits
Inspired by [CrazyMax’s rtorrent-rutorrent image](https://github.com/crazy-max/docker-rtorrent-rutorrent) and [home-operations containers](https://github.com/home-operations/containers).
