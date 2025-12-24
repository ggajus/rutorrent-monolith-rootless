# rutorrent-monolith-rootless

A lightweight, fully rootless Podman/Docker container running rTorrent and ruTorrent. This container runs entirely as a non-root user without any initialization processes that start as root and drop privileges, in contrast to alternatives that use init systems like s6-overlay.

## Features

- **Fully Rootless**: runs as user `ops` (UID 1000) from container start
- **Configurable rtorrent.rc**: a minimal default configuration imports `rutorrent.custom` from `/config`
- **Persistent RuTorrent and plugin settings**: all ruTorrent state data resides under `/config/rutorrent`
- **Tiny Size**: rarely used plugins like `rutracker_check`, `_cloudflare` or `spectrogram` have been removed with their dependencies for a smaller image size

## Quick Start
The built image can be downloaded from [Docker Hub](https://hub.docker.com/r/ggajus/rutorrent-monolith-rootless)

### 1. Download Docker Compose File
```bash
mkdir rutorrent-monolith && cd rutorrent-monolith
wget https://codeberg.org/gajus/rutorrent-monolith-rootless/raw/branch/main/compose.yml
```

### 2. Create Required Mount Folders
```bash
mkdir -p ./volumes/downloads
mkdir -p ./volumes/config/rtorrent/.session
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
ruTorrent is then reachable at `http://localhost:8080`.

## Volumes

- `/downloads`: Default download location for torrents
- `/config`: State directory (sessions, settings, state files)

## Ports
- `6881`: rTorrent DHT
- `8080`: ruTorrent web UI
- `50000`: rTorrent incoming

## Configuration

- rTorrent config: `/etc/rtorrent.rc` (imports rutorrent.custom from /config)
- ruTorrent config: `/var/www/rutorrent/conf/config.php`
- Nginx config: `/etc/nginx/nginx.conf`

The image includes a minimal rTorrent rc configuration file. All further configuration should be be done through `/config/rtorrent.custom` mounted from the host. A template is provided at the root of this repo.

### Environment Variables
| Variable | Description | Default |
| :--- | :--- | :--- |
| `HTTP_USERNAME` | Username for HTTP Basic Authentication. | (None) |
| `HTTP_PASSWORD` | Password for HTTP Basic Authentication. | (None) |
| `AUTH_LEVEL` | HTTP Basic Auth Scope: `WEBUI`, `RPC2`, or `ALL`. | (None) |

## Notes
This container is under active development, expect breaking changes and instability for now. If you don’t need a rootless setup, the [CrazyMax image](https://github.com/crazy-max/docker-rtorrent-rutorrent) remains the safer choice.
## Credits
Inspired by [CrazyMax’s rtorrent-rutorrent image](https://github.com/crazy-max/docker-rtorrent-rutorrent) and [home-operations containers](https://github.com/home-operations/containers).
