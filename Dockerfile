FROM jetbrains/teamcity-agent:latest

USER root

# Install dependencies, GCC 14, CMake 4.1.0-rc1, and build tools
RUN apt-get update && \
    apt-get install -y software-properties-common curl ninja-build build-essential clang && \
    add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update && \
    apt-get install -y gcc-14 g++-14 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 && \
    curl -LO https://github.com/Kitware/CMake/releases/download/v4.1.0-rc1/cmake-4.1.0-rc1-linux-x86_64.sh && \
    chmod +x cmake-4.1.0-rc1-linux-x86_64.sh && \
    ./cmake-4.1.0-rc1-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-4.1.0-rc1-linux-x86_64.sh && \
    apt-get clean

USER buildagent
