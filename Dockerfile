FROM jetbrains/teamcity-agent:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl ninja-build build-essential clang gcc-14 g++-14 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 && \
    curl -LO https://github.com/Kitware/CMake/releases/download/v4.1.0-rc1/cmake-4.1.0-rc1-linux-x86_64.sh && \
    chmod +x cmake-4.1.0-rc1-linux-x86_64.sh && \
    ./cmake-4.1.0-rc1-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-4.1.0-rc1-linux-x86_64.sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER buildagent
