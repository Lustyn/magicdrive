# magicdrive

A ✨ *magic* ✨ container that will overlay a decrypted copy of your rclone crypt hosted on Google Drive, optimized for Plex and other similar services!


# Installation

## 1. Setup your `docker-compose.yml`

```yml
services:
  magicdrive:
    image: ghcr.io/lustyn/magicdrive:latest # `magicdrive:master` for latest git, `build: .` to build from source
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

## 2. Start magicdrive

Start your service, or set of services defined in `docker-compose.yml`.

```s
$ docker compose up -d
```

## 3. Configure Plexdrive and Rclone

You'll need to supply Plexdrive and Rclone with credentials, and additionally configure your Rclone crypt mount.

```s
$ docker compose exec magicdrive setup
```

## 4. Use your magic mount!
You can now write or read from your mount! **Please note**, this container **DOES NOT** currently move files from your local storage to Google Drive, so please keep whatever you store in the `/local` volume safe.

```s
$ ls /data/files
docs  downloads  media
```