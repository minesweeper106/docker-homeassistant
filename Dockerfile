FROM ghcr.io/linuxserver/baseimage-alpine:3.16

# set version label
ARG BUILD_DATE
ARG VERSION
ARG HASS_RELEASE
ARG HACS_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="saarg, roxedus"

# environment settings
ENV \
  PIPFLAGS="--no-cache-dir --use-deprecated=legacy-resolver --find-links https://wheel-index.linuxserver.io/alpine-3.16/ --find-links https://wheel-index.linuxserver.io/homeassistant-3.16/" \
  PYTHONPATH="${PYTHONPATH}:/pip-packages"

# copy local files
COPY root/ /

#https://github.com/home-assistant/core/pull/59769

# install packages
RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    autoconf \
    ca-certificates \
    cargo \
    cmake \
    cups-dev \
    eudev-dev \
    ffmpeg-dev \
    gcc \
    glib-dev \
    g++ \
    jq \
    libffi-dev \
    jpeg-dev \
    libxml2-dev \
    libxslt-dev \
    make \
    postgresql-dev \
    python3-dev \
    unixodbc-dev \
    unzip && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    bluez \
    bluez-deprecated \
    bluez-libs \
    cups-libs \
    curl \
    eudev-libs \
    ffmpeg \
    iputils \
    libcap \
    libjpeg-turbo \
    libstdc++ \
    libxslt \
    mariadb-connector-c \
    mariadb-connector-c-dev \
    openssh-client \
    openssl \
    postgresql-libs \
    py3-pip \
    python3 \
    tiff && \
  echo "**** install homeassistant ****" && \
  mkdir -p \
    /tmp/core && \
  if [ -z ${HASS_RELEASE+x} ]; then \
    HASS_RELEASE=$(curl -sX GET https://api.github.com/repos/home-assistant/core/releases/latest \
    | jq -r .tag_name); \
  fi && \
  curl -o \
  /tmp/core.tar.gz -L \
  "https://github.com/home-assistant/core/archive/${HASS_RELEASE}.tar.gz" && \
  tar xf \
    /tmp/core.tar.gz -C \
    /tmp/core --strip-components=1 && \
  HASS_BASE=$(cat /tmp/core/build.yaml \
    | grep 'amd64: ' \
    | cut -d: -f3) && \
  mkdir -p /pip-packages && \
  pip install --target /pip-packages --no-cache-dir --upgrade \
    distlib && \
  pip install --no-cache-dir --upgrade \
    cython \
    "pip>=21.0,<22.1" \
    setuptools \
    wheel && \
  cd /tmp/core && \
  NUMPY_VER=$(grep "numpy" requirements_all.txt) && \
  pip install ${PIPFLAGS} \
    "${NUMPY_VER}" && \
  pip install ${PIPFLAGS} \
    -r https://raw.githubusercontent.com/home-assistant/docker/${HASS_BASE}/requirements.txt && \
  pip install ${PIPFLAGS} \
    -r requirements_all.txt && \
  pip install ${PIPFLAGS} \
    homeassistant==${HASS_RELEASE} && \
  pip install ${PIPFLAGS} \
    pycups \
    PySwitchbot && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  for cleanfiles in *.pyc *.pyo; \
    do \
    find /usr/lib/python3.*  -iname "${cleanfiles}" -exec rm -f '{}' + \
    ; done && \
  rm -rf \
    /tmp/* \
    /root/.cache \
    /root/.cargo

# environment settings. used so pip packages installed by home assistant installs in /config
ENV HOME="/config"

# ports and volumes
EXPOSE 8123
VOLUME /config