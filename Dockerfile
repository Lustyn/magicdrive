ARG UBUNTU_VER=22.04

FROM ghcr.io/by275/base:ubuntu AS prebuilt
FROM ubuntu:${UBUNTU_VER} AS ubuntu

ARG TARGETARCH
ARG PLEXDRIVE_VER="5.2.1"
ARG DEBIAN_FRONTEND="noninteractive"
ARG APT_MIRROR="archive.ubuntu.com"

LABEL maintainer="lustyn"
LABEL org.opencontainers.image.source https://github.com/lustyn/magicdrive

RUN mkdir -p /usr/local/bin

# install s6
COPY --from=prebuilt /s6/ /

ADD https://raw.githubusercontent.com/by275/docker-base/main/_/etc/cont-init.d/adduser /etc/cont-init.d/10-adduser

# install packages
RUN \
    echo "**** apt source change for local build ****" && \
    sed -i "s/archive.ubuntu.com/$APT_MIRROR/g" /etc/apt/sources.list && \
    echo "**** install runtime packages ****" && \
    apt-get update && \
    apt-get install -yqq --no-install-recommends apt-utils && \
    apt-get install -yqq --no-install-recommends \
        ca-certificates \
        fuse3 \
        openssl \
        tzdata \
        wget && \
    update-ca-certificates && \
    sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf && \
    echo "**** add plexdrive ****" && \
    PLEXDRIVE_ARCH=$(if [ "$TARGETARCH" = "arm" ]; then echo "arm7"; else echo "$TARGETARCH"; fi) && \
    wget -O /usr/local/bin/plexdrive --no-check-certificate "https://github.com/plexdrive/plexdrive/releases/download/$PLEXDRIVE_VER/plexdrive-linux-${PLEXDRIVE_ARCH}" && \
    echo "**** add mergerfs ****" && \
    MFS_VERSION=$(wget --no-check-certificate -O - -o /dev/null "https://api.github.com/repos/trapexit/mergerfs/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
    MFS_DEB="mergerfs_${MFS_VERSION}.ubuntu-focal_$(dpkg --print-architecture).deb" && \
    cd $(mktemp -d) && wget --no-check-certificate "https://github.com/trapexit/mergerfs/releases/download/${MFS_VERSION}/${MFS_DEB}" && \
    dpkg -i ${MFS_DEB} && \
    echo "**** add rclone ****" && \
    RCLONE_VERSION=$(wget --no-check-certificate -O - -o /dev/null "https://api.github.com/repos/rclone/rclone/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') && \
    RCLONE_ARCH=$(if [ "$TARGETARCH" = "arm" ]; then echo "arm-v7"; else echo "$TARGETARCH"; fi) && \
    RCLONE_DEB="rclone-${RCLONE_VERSION}-linux-${RCLONE_ARCH}.deb" && \
    cd $(mktemp -d) && wget --no-check-certificate "https://github.com/rclone/rclone/releases/download/${RCLONE_VERSION}/${RCLONE_DEB}" && \
    dpkg -i ${RCLONE_DEB} && \
    echo "**** create abc user ****" && \
    useradd -u 911 -U -d /config -s /bin/false abc && \
    usermod -G users abc && \
    echo "**** cleanup ****" && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /tmp/* /var/lib/{apt,dpkg,cache,log}/

# copy build
COPY root/ /

# mark all local/bin as executable
RUN \
    echo "**** permissions ****" && \
    chmod a+x /usr/local/bin/*

# environment settings
ENV \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_KILL_FINISH_MAXTIME=7000 \
    S6_SERVICES_GRACETIM=5000 \
    S6_KILL_GRACETIME=5000 \
    LANG=C.UTF-8 \
    PLEXDRIVE_OPTS=--chunk-load-threads=3 --chunk-check-threads=3 --chunk-load-ahead=2 --chunk-size=8M

VOLUME /config /cache /enc /dec /data /local
WORKDIR /config

HEALTHCHECK --interval=10s --timeout=30s --start-period=10s --retries=10 \
    CMD /usr/local/bin/healthcheck

ENTRYPOINT ["/init"]
