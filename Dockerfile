FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Set up dependencies and core tooling
RUN apt-get update && \
    apt-get install -y curl ca-certificates gnupg2 \
        build-essential clang ninja-build \
        openjdk-17-jdk git wget unzip software-properties-common \
        lsb-release sudo && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y gcc-14 g++-14 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100

# Install CMake 4.1.0-rc1
RUN curl -LO https://github.com/Kitware/CMake/releases/download/v4.1.0-rc1/cmake-4.1.0-rc1-linux-x86_64.sh && \
    chmod +x cmake-4.1.0-rc1-linux-x86_64.sh && \
    ./cmake-4.1.0-rc1-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-4.1.0-rc1-linux-x86_64.sh

# Add user for TeamCity Agent
RUN useradd -m buildagent && echo "buildagent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up TeamCity Agent
USER buildagent
WORKDIR /home/buildagent

ENV TEAMCITY_SERVER=http://66.179.253.124:8111
ENV AGENT_NAME=docker-agent-chaosrex

RUN mkdir TeamCity && cd TeamCity && \
    curl -O $TEAMCITY_SERVER/update/buildAgent.zip && \
    unzip buildAgent.zip && rm buildAgent.zip && \
    chmod +x bin/agent.sh

# Set entrypoint
ENTRYPOINT ["TeamCity/bin/agent.sh"]
