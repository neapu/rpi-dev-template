FROM debian:trixie AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture arm64 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        binutils-aarch64-linux-gnu \
        cmake \
        ninja-build \
        pkgconf \
        python3 \
        perl \
        git \
        curl \
        ca-certificates \
        file \
        rsync \
        xz-utils \
        unzip \
        bison \
        flex \
        gperf \
        libgl-dev \
        libegl-dev \
        libfontconfig-dev \
        libfreetype-dev \
        libxkbcommon-dev \
        libegl-dev:arm64 \
        libgles-dev:arm64 \
        libgbm-dev:arm64 \
        libdrm-dev:arm64 \
        libinput-dev:arm64 \
        libudev-dev:arm64 \
        libxkbcommon-dev:arm64 \
        libfontconfig-dev:arm64 \
        libfreetype-dev:arm64 \
        libharfbuzz-dev:arm64 \
        libicu-dev:arm64 \
        libssl-dev:arm64 \
        zlib1g-dev:arm64 \
        libpng-dev:arm64 \
        libjpeg-dev:arm64 \
        libsqlite3-dev:arm64 \
        libdbus-1-dev:arm64 \
        libpcre2-dev:arm64 \
    && rm -rf /var/lib/apt/lists/*

COPY aarch64-toolchain.cmake /opt/qt/aarch64-toolchain.cmake

FROM base AS qt-builder

RUN set -eux; \
    qt_version=6.11.3; \
    qt_url="https://download.qt.io/official_releases/qt/6.11/${qt_version}/submodules"; \
    mkdir -p /tmp/qt-src /tmp/qt-build; \
    cd /tmp/qt-src; \
    for module in qtbase qtshadertools qtdeclarative; do \
        curl -fL --retry 3 -o "${module}.tar.xz" "${qt_url}/${module}-everywhere-src-${qt_version}.tar.xz"; \
    done; \
    echo "46de0710b594945a5d446ae44354daa386141c6903c53781b2ca547bc62f8f8f  qtbase.tar.xz" | sha256sum -c -; \
    echo "d86079425ec71eecbb05f4d20623b0a403a7d21a5cfa7efb9734ea3d538d801b  qtshadertools.tar.xz" | sha256sum -c -; \
    echo "6d6db328a02ae3bb0b1e6944aeef8dfe44cd6b55ab59b1708bbf0400f5759cb5  qtdeclarative.tar.xz" | sha256sum -c -; \
    for module in qtbase qtshadertools qtdeclarative; do \
        mkdir "${module}"; \
        tar -xf "${module}.tar.xz" -C "${module}" --strip-components=1; \
        rm "${module}.tar.xz"; \
    done

ARG QT_BUILD_JOBS=8

RUN set -eux; \
    mkdir -p /tmp/qt-build/host-base; \
    cd /tmp/qt-build/host-base; \
    /tmp/qt-src/qtbase/configure -prefix /opt/qt/host -release -nomake examples -nomake tests; \
    cmake --build . --parallel "${QT_BUILD_JOBS}"; \
    cmake --install .; \
    rm -rf /tmp/qt-build/host-base

RUN set -eux; \
    for module in qtshadertools qtdeclarative; do \
        /opt/qt/host/bin/qt-cmake -S "/tmp/qt-src/${module}" -B "/tmp/qt-build/host-${module}" -G Ninja \
            -DCMAKE_BUILD_TYPE=Release -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF; \
        cmake --build "/tmp/qt-build/host-${module}" --parallel "${QT_BUILD_JOBS}"; \
        cmake --install "/tmp/qt-build/host-${module}"; \
        rm -rf "/tmp/qt-build/host-${module}"; \
    done

RUN set -eux; \
    export PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig; \
    mkdir -p /tmp/qt-build/target-base; \
    cd /tmp/qt-build/target-base; \
    /tmp/qt-src/qtbase/configure -prefix /opt/qt/6.11.3 -qt-host-path /opt/qt/host \
        -release -nomake examples -nomake tests -opengl es2 -eglfs -no-xcb \
        -- -DCMAKE_TOOLCHAIN_FILE=/opt/qt/aarch64-toolchain.cmake; \
    cmake --build . --parallel "${QT_BUILD_JOBS}"; \
    cmake --install .; \
    rm -rf /tmp/qt-build/target-base

RUN set -eux; \
    export PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig; \
    for module in qtshadertools qtdeclarative; do \
        /opt/qt/6.11.3/bin/qt-cmake -S "/tmp/qt-src/${module}" -B "/tmp/qt-build/target-${module}" -G Ninja \
            -DCMAKE_BUILD_TYPE=Release -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF; \
        cmake --build "/tmp/qt-build/target-${module}" --parallel "${QT_BUILD_JOBS}"; \
        cmake --install "/tmp/qt-build/target-${module}"; \
        rm -rf "/tmp/qt-build/target-${module}"; \
    done

FROM base

COPY --from=qt-builder /opt/qt /opt/qt

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}" \
    && mkdir -p /workspace \
    && chown "${USERNAME}:${USERNAME}" /workspace

WORKDIR /workspace