# --------------------------------------------------------------
# JC-303 Linux builder environment - Debian 11 (Bullseye)
# 
# Why?
# 1: Build binary release with broad Linux OS compatibility
#    uses glibc 2.31 as base (Debian 11)
# 2: Make use of CI/CD
# 
# Debian 11 (Bullseye) + glibc 2.31 + Modern toolchain + All JUCE deps
# Mounts jc303 project root → /jc303
# 
# Build the image (once)
# docker build --platform linux/amd64 -t jc303-linux-builder .
# 
# Run – mounts current directory → /jc303
# docker run -it --rm --platform linux/amd64 -v "$(pwd):/jc303" jc303-linux-builder
# --------------------------------------------------------------
FROM debian:11

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Kitware's CMake (3.22+)
RUN apt-get update && \
    apt-get install -y ca-certificates gpg wget && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor - > /usr/share/keyrings/kitware-archive-keyring.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' > /etc/apt/sources.list.d/kitware.list && \
    apt-get update && \
    apt-get install -y cmake && \
    cmake --version
    
# 1. Update system and install build essentials
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        make \
        cmake-latest \
        git \
        wget \
        curl \
        pkg-config \
        ninja-build \
        # Graphics libraries
        libx11-dev \
        libxext-dev \
        libxrandr-dev \
        libxinerama-dev \
        libxcursor-dev \
        libxi-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libfreetype6-dev \
        # Audio libraries
        libasound2-dev \
        libjack-jackd2-dev \
        libsamplerate0-dev \
        libsndfile1-dev \
        # Network / utils
        libcurl4-openssl-dev \
        libavahi-client-dev \
        # JUCE extras
        libgtk-3-dev \
        libwebkit2gtk-4.0-dev \
        libxml2-dev \
        libzip-dev \
        libfftw3-dev \
        libjpeg-dev \
        libpng-dev \
        libgif-dev \
        librsvg2-dev \
        libbz2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Workdir = /jc303 (host mounted)
WORKDIR /jc303

# 4. Default: interactive shell
CMD ["/bin/bash"]
