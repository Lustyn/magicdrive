# magicdrive

A ✨ *magic* ✨ container that will overlay a decrypted copy of your rclone crypt hosted on Google Drive, optimized for Plex and other similar services!


# Installation / Usage

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

```
$ docker compose up -d
```

## 3. Configure Plexdrive and Rclone

You'll need to supply Plexdrive and Rclone with credentials, and additionally configure your Rclone crypt mount.

```
$ docker compose exec magicdrive setup
```

## 4. Use your magic mount!

You can now write or read from your mount! **Please note**, this container **DOES NOT** currently move files from your local storage to Google Drive, so please keep whatever you store in the `/local` volume safe. (*Setup a script to move the contents periodically, maybe?*)

```
$ ls /data/files
docs  downloads  media
```

## 5. Using your mount from other services (optional)

To access magicdrive from other containers, you can simply bind mount the host path you supplied earlier. Please note that this requires your bind propagation is set to `shared` in the magicdrive service. Additionally, to ensure that magicdrive starts before your other services do, you should add magicdrive to the services `depends_on` and set the condition to `service_healthy`.

```yml
services:
  jellyfin:
    image: …
    volumes:
      - /data/files/tvshows:/data/tvshows
      - /data/files/movies:/data/movies
      …
    depends_on:
      magicdrive:
        condition: service_healthy
    …
```

## 6. Configuring Plexdrive, Rclone, and MergerFS

Since your usecase may vary from mine, it may be necessary for you to supply additional options to the various mounts. You can do this by passing any of the following environment variables:

  - **Plexdrive**: `PLEXDRIVE_OPTS` (**please note**, this will override [the default value](./Dockerfile#L74))
  - **Rclone**: `RCLONE_OPTS`
  - **MergerFS**: `MERGERFS_OPTS`

# Contributing

If you have any suggestions, improvements, or otherwise, please feel free to open an [Issue](https://github.com/Lustyn/magicdrive/issues/new) or [Pull Request](https://github.com/Lustyn/magicdrive/compare)! Open Source Software is written by **YOU**.