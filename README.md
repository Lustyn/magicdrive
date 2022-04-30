# magicdrive

A ✨ *magic* ✨ container that will overlay a decrypted copy of your rclone crypt hosted on Google Drive, optimized for Plex and other similar services!


# Installation

1. Setup your docker-compose.yml

```yml
version: "3.8"

services:
  magicdrive:
    build: ghcr.io/lustyn/magicdrive # or `build: ${PATH_TO_MAGICDRIVE}` if you want to build from source
    restart: unless-stopped
    volumes:
      - /config/magicdrive:/config   # where plexdrive & rclone configs will be stored
      - /data/local:/local           # where writes to this mount will be stored locally
      - type: bind 
        source: /data/files          # where the mount will be created on the host
        target: /data
        bind:
          propagation: shared
    devices:
      - /dev/fuse                    # passthrough fuse device for creating the mounts
    cap_add:
      - SYS_ADMIN                    # needed for creating mounts
    environment:                     # choose user, group, and timezone. its recommended you define these in `.ENV`
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
```

2. Start magicdrive

```s
$ docker-compose up -d
```

3. Configure plexdrive and rclone

```s
$ docker-compose exec magicdrive setup
```