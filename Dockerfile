# Start from Ubuntu for compatibility, then layer TeamCity agent
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl ninja-build build-essential clang gcc-14 g++-14 ca-certificates && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 && \
    curl -LO https://github.com/Kitware/CMake/releases/download/v4.1.0-rc1/cmake-4.1.0-rc1-linux-x86_64.sh && \
    chmod +x cmake-4.1.0-rc1-linux-x86_64.sh && \
    ./cmake-4.1.0-rc1-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-4.1.0-rc1-linux-x86_64.sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

FROM jetbrains/teamcity-agent:latest

USER root

# Copy tools from base
COPY --from=base /usr/bin/gcc /usr/bin/
COPY --from=base /usr/bin/g++ /usr/bin/
COPY --from=base /usr/bin/cc /usr/bin/
COPY --from=base /usr/local/bin/cmake /usr/local/bin/
COPY --from=base /usr/local/share/cmake-4.1.0-rc1 /usr/local/share/
COPY --from=base /usr/local/share/doc/cmake-4.1.0-rc1 /usr/local/share/doc/cmake-4.1.0-rc1

USER buildagent
