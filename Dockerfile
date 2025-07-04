FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Args for build-time injection
ARG TEAMCITY_SERVER
ARG AGENT_NAME

# Install required packages and GCC 14
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

# Create user for buildagent
RUN useradd -m buildagent && echo "buildagent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER buildagent
WORKDIR /home/buildagent

# Download and set up the agent
RUN mkdir -p TeamCity && \
    curl --connect-timeout 15 --max-time 120 -O ${TEAMCITY_SERVER}/update/buildAgent.zip && \
    unzip buildAgent.zip -d TeamCity && rm buildAgent.zip && \
    chmod +x TeamCity/bin/agent.sh

ENTRYPOINT ["TeamCity/bin/agent.sh"]
