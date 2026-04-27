# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/unrar:latest AS unrar

FROM ghcr.io/linuxserver/baseimage-alpine:3.23

# set version label
ARG BUILD_DATE
ARG VERSION
ARG QBITTORRENT_VERSION
ARG QBT_CLI_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# environment settings
ENV HOME="/config" \
XDG_CONFIG_HOME="/config" \
XDG_DATA_HOME="/config"

COPY qbt/qbt-linux-alpine-x64-net6-1.8.24285.1.tar.gz /tmp/qbt.tar.gz

# install runtime packages and qbitorrent-cli
RUN \
  echo "**** install packages ****" && \
  apk add -U --update --no-cache \
    grep \
    icu-libs \
    p7zip \
    python3 && \
  echo "**** install qbittorrent ****" && \
  if [ -z ${QBITTORRENT_VERSION+x} ]; then \
    QBITTORRENT_VERSION=$(curl -sL "https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases" | \
    jq -r 'first(.[] | select(.prerelease == true) | .tag_name)' | awk -F '-' '{print $2}'); \
  fi && \
  curl -o \
    /app/qbittorrent-nox -L \
    "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-${QBITTORRENT_VERSION}/x86_64-qbittorrent-nox" && \
  chmod +x /app/qbittorrent-nox && \
  echo "***** install qbitorrent-cli ****" && \
  mkdir /qbt && \
  if [ -z ${QBT_CLI_VERSION+x} ]; then \
    QBT_CLI_VERSION=$(curl -sL "https://api.github.com/repos/fedarovich/qbittorrent-cli/releases/latest" \
    | jq -r '. | .tag_name'); \
  fi && \
  curl -o \
    /tmp/qbt-github.tar.gz -L \
    "https://github.com/fedarovich/qbittorrent-cli/releases/download/${QBT_CLI_VERSION}/qbt-linux-alpine-x64-net6-${QBT_CLI_VERSION#v}.tar.gz" && \
  if tar tf /tmp/qbt-github.tar.gz; then \
    mv -f /tmp/qbt-github.tar.gz /tmp/qbt.tar.gz; \
  fi && \
  tar xf \
    /tmp/qbt.tar.gz -C \
    /qbt && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  rm -rf \
    /root/.cache \
    /tmp/*

# add local files
COPY root/ /

# add unrar
COPY --from=unrar /usr/bin/unrar-alpine /usr/bin/unrar

# ports and volumes
EXPOSE 8080 6881 6881/udp

VOLUME /config
