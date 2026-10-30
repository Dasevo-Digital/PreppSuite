FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# The Flutter Linux toolchain, plus what this app's plugins pull in:
# webkit2gtk and libsoup for desktop_webview_window, lzma for the archive
# reader's xz path, libsecret for the keyring.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip \
      clang cmake ninja-build pkg-config \
      libgtk-3-dev liblzma-dev libstdc++-12-dev libglu1-mesa \
      libwebkit2gtk-4.1-dev libsoup-3.0-dev libsecret-1-dev \
      zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch 3.47.9 https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"

RUN git config --global --add safe.directory /opt/flutter \
    && flutter --version \
    && flutter config --enable-linux-desktop --no-analytics \
    && flutter precache --linux
