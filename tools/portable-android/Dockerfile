# Reproducible Linux toolchain for scripts/portable-android.sh, e.g. as a
# Render Docker service or on any Docker host. Same pins as the GitHub build:
# Flutter 3.44.9, JDK 17, Android platform 36, NDK 28.2.13676358, Godot 4.6.3.
#
# STATUS 2026-10-22: NOT BUILT YET. The authoring sandbox had no Docker daemon
# and could not reach dl.google.com. Build and run it once on a real host
# before relying on it. The image holds tools only: no Lumo source, no keys.
#
#   docker build --build-arg ACCEPT_ANDROID_SDK_LICENSES=yes \
#     -t lumo-android-build tools/portable-android
#   docker run --rm -it lumo-android-build bash -lc '
#     git clone https://github.com/Ullmann27/lumo-lernen.git lumo && cd lumo &&
#     git checkout --detach <commit> && bash scripts/portable-android.sh preview-apk'
FROM ubuntu:24.04

ARG FLUTTER_VERSION=3.44.9
# storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
ARG FLUTTER_SHA256=a9120fa4a01048bdef438ddc3a2d4b7389662ea98a95db86eeaf10382bc4efcb
ARG CMDLINE_TOOLS_BUILD=15859902
# developer.android.com/studio, "Command line tools only", Linux
ARG CMDLINE_TOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
# Same digest as scripts/install_godot_for_build.sh
ARG GODOT_SHA256=d0bc2113065e481c9c2c2b2c37daa4e8be3fe9e27f0ab9ab0b6096e9a37907f3
# Accepting the Android SDK license is the owner's decision, never a default.
ARG ACCEPT_ANDROID_SDK_LICENSES=no

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip file \
      openjdk-17-jdk-headless python3 python3-venv python3-pil nodejs ripgrep \
      tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng \
      xvfb xauth libgl1 libgl1-mesa-dri libegl1 libglu1-mesa libfontconfig1 \
      libxcursor1 libxinerama1 libxrandr2 libxi6 \
 && rm -rf /var/lib/apt/lists/*

# Flutter refuses to be comfortable as root; build as an ordinary user.
RUN useradd --create-home --uid 10001 lumo
USER lumo
WORKDIR /home/lumo
ENV ANDROID_SDK_ROOT=/home/lumo/android-sdk
ENV PATH=/home/lumo/bin:/home/lumo/flutter/bin:/home/lumo/android-sdk/cmdline-tools/latest/bin:/home/lumo/android-sdk/platform-tools:$PATH

RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
 && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/flutter.tar.xz -C /home/lumo \
 && rm /tmp/flutter.tar.xz \
 && flutter config --no-analytics \
 && flutter --version

RUN curl -fsSL -o /tmp/godot.zip \
      https://github.com/godotengine/godot/releases/download/4.6.3-stable/Godot_v4.6.3-stable_linux.x86_64.zip \
 && echo "${GODOT_SHA256}  /tmp/godot.zip" | sha256sum -c - \
 && mkdir -p /home/lumo/bin /home/lumo/godot \
 && unzip -q /tmp/godot.zip -d /home/lumo/godot \
 && ln -s /home/lumo/godot/Godot_v4.6.3-stable_linux.x86_64 /home/lumo/bin/godot \
 && rm /tmp/godot.zip \
 && godot --version

RUN curl -fsSL -o /tmp/cmdline-tools.zip \
      "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_BUILD}_latest.zip" \
 && echo "${CMDLINE_TOOLS_SHA256}  /tmp/cmdline-tools.zip" | sha256sum -c - \
 && mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools" \
 && unzip -q /tmp/cmdline-tools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools" \
 && mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest" \
 && rm /tmp/cmdline-tools.zip

RUN if [ "$ACCEPT_ANDROID_SDK_LICENSES" != yes ]; then \
      echo 'Read the Android SDK license, then build with --build-arg ACCEPT_ANDROID_SDK_LICENSES=yes' >&2; \
      exit 1; \
    fi \
 && yes | sdkmanager --licenses > /dev/null \
 && sdkmanager "platforms;android-36" "build-tools;36.0.0" "platform-tools" "ndk;28.2.13676358" \
 && flutter precache --android

# Shared build hosts are throttled by Maven Central (Actions run 38896179742).
ENV LUMO_GRADLE_CENTRAL_MIRROR=1
CMD ["bash"]
